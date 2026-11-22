import 'dart:async';
import 'dart:collection';

import 'package:fitness_tracker/data/db/dao/run_dao.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/data/repositories/barometer.dart';
import 'package:fitness_tracker/data/repositories/run_recorder.dart';
import 'package:fitness_tracker/data/repositories/sensors_plus_barometer.dart';
import 'package:fitness_tracker/data/repositories/tracelet_run_recorder.dart';
import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'run_recording_provider.g.dart';

@Riverpod(keepAlive: true)
RunDao runDao(Ref ref) => ref.watch(appDatabaseProvider).runDao;

/// The GPS boundary.
///
/// A provider rather than a direct construction so tests can replace it with
/// the fake, exactly as `healthRepository` exists for Health Connect. Nothing
/// below this line is reachable off a device.
@Riverpod(keepAlive: true)
RunRecorder runRecorder(Ref ref) {
  final recorder = TraceletRunRecorder();
  ref.onDispose(() => unawaited(recorder.dispose()));
  return recorder;
}

/// The pressure boundary, for elevation gain (A6-1). A provider for the same
/// reason as [runRecorder]: tests replace it, and nothing below it runs off a
/// device.
@Riverpod(keepAlive: true)
Barometer barometer(Ref ref) => SensorsPlusBarometer();

/// What the recording screen shows.
@immutable
class RunRecordingState {
  const RunRecordingState({
    this.isRecording = false,
    this.startedAt,
    this.distanceM = 0,
    this.elapsed = Duration.zero,
    this.movingTime = Duration.zero,
    this.averagePaceSecPerKm,
    this.currentPaceSecPerKm,
    this.pointCount = 0,
    this.route = const [],
    this.framingPosition,
    this.blocker,
    this.blockerDetail,
    this.oemWarning,
    this.savedRunId,
  });

  final bool isRecording;
  final DateTime? startedAt;
  final double distanceM;
  final Duration elapsed;
  final Duration movingTime;
  final double? averagePaceSecPerKm;
  final double? currentPaceSecPerKm;

  /// How many fixes survived the filter chain. Shown because a run that is
  /// recording but accepting nothing looks identical to one that is working,
  /// and the difference matters while standing outside deciding whether to
  /// trust it.
  final int pointCount;

  /// The smoothed track so far, for the live map.
  ///
  /// This comes off the CAUSAL filter and always will. It is the same track
  /// the numbers above are derived from, and a live map drawn from anything
  /// else would disagree with the distance sitting next to it on the same
  /// screen. The non-causal pass belongs to the saved track alone.
  ///
  /// A growing VIEW rather than a fresh copy per fix — see `_publish`. Safe
  /// only because the track is append-only: an old state's `route` can gain
  /// points, never lose or change them.
  final List<LatLng> route;

  /// Where the phone is, before the track can say.
  ///
  /// **Framing only, and it is never a point in a run.** It exists so the map
  /// opens on somewhere real instead of on nothing, and it is read only while
  /// [route] is empty — once there is a track, its head is the position by
  /// definition and this is ignored. Nothing downstream of here has ever seen
  /// it: it does not enter the pipeline, the distance, or the saved run.
  ///
  /// Null until the one-shot answers, and null forever on a phone that has no
  /// fix to give. That is the locating state, not an error.
  final LatLng? framingPosition;

  /// Why recording cannot start, when it cannot. Never silently swallowed:
  /// this is a platform boundary and CLAUDE.md section 4 requires the degraded
  /// state to reach the user.
  final RecorderBlocker? blocker;
  final String? blockerDetail;

  /// Set when the manufacturer is known to kill background services and the
  /// app has not been exempted.
  final OemPowerWarning? oemWarning;

  /// The id of the run just saved, so the screen can confirm it landed.
  final int? savedRunId;

  RunRecordingState copyWith({
    bool? isRecording,
    DateTime? startedAt,
    double? distanceM,
    Duration? elapsed,
    Duration? movingTime,
    double? averagePaceSecPerKm,
    double? currentPaceSecPerKm,
    int? pointCount,
    List<LatLng>? route,
    LatLng? framingPosition,
    RecorderBlocker? blocker,
    String? blockerDetail,
    OemPowerWarning? oemWarning,
    int? savedRunId,
    bool clearBlocker = false,
    bool clearSavedRun = false,
  }) {
    return RunRecordingState(
      isRecording: isRecording ?? this.isRecording,
      startedAt: startedAt ?? this.startedAt,
      distanceM: distanceM ?? this.distanceM,
      elapsed: elapsed ?? this.elapsed,
      movingTime: movingTime ?? this.movingTime,
      averagePaceSecPerKm: averagePaceSecPerKm ?? this.averagePaceSecPerKm,
      currentPaceSecPerKm: currentPaceSecPerKm ?? this.currentPaceSecPerKm,
      pointCount: pointCount ?? this.pointCount,
      route: route ?? this.route,
      framingPosition: framingPosition ?? this.framingPosition,
      blocker: clearBlocker ? null : (blocker ?? this.blocker),
      blockerDetail: clearBlocker
          ? null
          : (blockerDetail ?? this.blockerDetail),
      oemWarning: oemWarning ?? this.oemWarning,
      savedRunId: clearSavedRun ? null : (savedRunId ?? this.savedRunId),
    );
  }
}

/// Drives a recording: recorder in, pipeline in the middle, database at the end.
///
/// The controller owns the [TrackProcessor] for the length of one run and
/// throws it away afterwards. The processor accumulates state by design and
/// reusing one across runs would silently join two runs into one.
@Riverpod(keepAlive: true)
class RunRecording extends _$RunRecording {
  TrackProcessor? _processor;
  StreamSubscription<void>? _subscription;

  /// Every delivered fix, encoded as it arrives and written out at the end.
  ///
  /// Held in memory rather than appended per fix, and the trade is worth
  /// stating. A 48-minute walk is ~2,000 lines, a few hundred kilobytes, which
  /// is nothing next to the track the pipeline is already holding — so the cost
  /// is that a process killed mid-run loses the capture entirely. That is the
  /// same exposure the diagnostics report has always had, and the alternative
  /// is two thousand file writes during a run for a debugging artefact.
  final _capture = <String>[];

  /// Fix lines in [_capture], which also carries pressure lines (A6-3). Both
  /// the fix `seq` and the cached count are of fixes only.
  int _fixCount = 0;

  StreamSubscription<PressureSample>? _pressureSubscription;
  final _pressure = <PressureSample>[];
  BarometerOutcome _barometerOutcome = BarometerOutcome.recorded;
  String? _barometerDetail;

  @override
  RunRecordingState build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      unawaited(_pressureSubscription?.cancel());
    });
    return const RunRecordingState();
  }

  /// Check permissions and OEM power management without starting anything.
  Future<void> refreshReadiness() async {
    final recorder = ref.read(runRecorderProvider);
    final status = await recorder.prepare();
    final warning = await recorder.oemPowerWarning();

    state = status.canRecord
        ? state.copyWith(
            clearBlocker: true,
            oemWarning: warning?.needsAttention ?? false ? warning : null,
          )
        : state.copyWith(
            blocker: status.blocker,
            blockerDetail: status.detail,
            oemWarning: warning?.needsAttention ?? false ? warning : null,
          );
  }

  /// Find where the phone is, so the map opens on it rather than on nothing.
  ///
  /// Pre-start only, and it fails quietly by design: a phone that cannot say
  /// where it is leaves [RunRecordingState.framingPosition] null, the screen
  /// says it is locating, and Start is unaffected. This is a camera position,
  /// so there is no degraded state to report — the map either has somewhere to
  /// point or it says it is looking.
  Future<void> locate() async {
    if (state.isRecording) return;

    final fix = await ref.read(runRecorderProvider).currentPosition();
    if (fix == null || state.isRecording) return;

    state = state.copyWith(
      framingPosition: LatLng(fix.latitude, fix.longitude),
    );
  }

  Future<void> start() async {
    if (state.isRecording) return;

    final recorder = ref.read(runRecorderProvider);
    final status = await recorder.prepare();
    if (!status.canRecord) {
      state = state.copyWith(
        blocker: status.blocker,
        blockerDetail: status.detail,
      );
      return;
    }

    final processor = TrackProcessor();
    _processor = processor;
    _capture.clear();
    // Same reason the processor is thrown away between runs: a live polyline
    // carried over would draw the last run joined to this one.
    _route.clear();

    // Both of these happen before `recorder.start()` is awaited, and the order
    // is not incidental. Subscribing later loses the opening fixes; setting
    // the recording state later overwrites whatever those fixes had already
    // accumulated, so the screen would start from zero having already thrown
    // away the first few seconds of the run.
    state = RunRecordingState(
      isRecording: true,
      startedAt: DateTime.now(),
      oemWarning: state.oemWarning,
      // Carried across the reset on purpose. The seconds between Start and the
      // first accepted point are exactly the window this value exists for —
      // dropping it here would blank the map at the one moment someone is
      // watching to see whether the run took.
      framingPosition: state.framingPosition,
    );
    _fixCount = 0;
    _subscription = recorder.fixes.listen((fix) {
      // Captured BEFORE the pipeline sees it. A capture taken anywhere further
      // down would be a record of what survived, which is the thing that
      // already exists and the thing that cannot answer anything.
      _capture.add(encodeFix(_fixCount++, fix));
      processor.add(fix);
      _publish(processor);
    });

    // The barometer is a platform boundary and must never be able to stop a
    // run: a phone without one records exactly as before, and the outcome is
    // carried to the run row and the report rather than swallowed (A6-1).
    _pressure.clear();
    _barometerOutcome = BarometerOutcome.recorded;
    _barometerDetail = null;
    _pressureSubscription = ref
        .read(barometerProvider)
        .readings()
        .listen(
          (sample) {
            _pressure.add(sample);
            _capture.add(encodePressure(sample));
          },
          onError: (Object error) {
            _barometerOutcome = error is BarometerAbsent
                ? BarometerOutcome.absent
                : BarometerOutcome.failed;
            _barometerDetail = error.toString();
          },
          cancelOnError: true,
        );

    await recorder.start();
  }

  /// Stop recording and store the run. Returns the new run's id, or null if
  /// nothing was worth keeping.
  Future<int?> stopAndSave({String? notes}) async {
    if (!state.isRecording) return null;

    // Names all three diagnostic files, so a run's report, raw track and
    // capture are one set you can see belong together in a directory listing.
    // Read here because the empty-run branch below clears the state before the
    // capture is written. Non-null because `start` sets it in the same
    // assignment that sets `isRecording`, which the line above just tested.
    final runStart = state.startedAt!;

    final recorder = ref.read(runRecorderProvider);
    await recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    await _pressureSubscription?.cancel();
    _pressureSubscription = null;
    final elevation = ElevationReport(
      outcome: _barometerOutcome,
      samples: List.of(_pressure),
      detail: _barometerDetail,
    );

    final processor = _processor;
    _processor = null;

    // Before anything reads the track. The reorder buffer is still holding the
    // last few seconds of the run, and they are as much a part of it as the
    // first few.
    if (processor != null) {
      processor.flush();
      // And publish what the flush released. Without this the screen keeps the
      // total it had one horizon ago while the database gets the real one, so
      // the run you just watched finish and the run you open afterwards
      // disagree by a few metres for no visible reason.
      _publish(processor);
    }

    if (processor == null || processor.points.length < 2) {
      // A run that never got a second fix has no distance, no duration and no
      // track. Storing it would put a row in the history that says nothing.
      //
      // The capture is still written, and this is the case that most needs it:
      // a recording that accepted nothing looks identical from outside to one
      // that was never started, and the delivered fixes are the only thing
      // that can tell them apart.
      await ref
          .read(runDiagnosticsStoreProvider)
          .saveFixCapture(
            _captureText,
            runStart: runStart,
            fixCount: _fixCount,
          );
      // Everything else resets; the framing position does not. The map has no
      // track to draw now, and sending it back to a blank panel would make a
      // failed run look like a broken screen.
      state = RunRecordingState(framingPosition: state.framingPosition);
      return null;
    }

    final runId = await ref
        .read(runDaoProvider)
        .saveRun(
          startedAt: processor.points.first.timestamp,
          endedAt: processor.points.last.timestamp,
          track: processor,
          elevGainM: elevation.gainM,
          notes: notes,
        );

    // After the run is safely stored, never before: a failure to write a debug
    // text file must not be able to cost someone their run.
    final store = ref.read(runDiagnosticsStoreProvider);
    await store.save(
      processor
          .diagnose(
            deliveredByPlugin: recorder.delivery.received,
            undatableDropped: recorder.delivery.undatable,
            elevation: elevation,
          )
          .plainText(),
      runStart: runStart,
    );

    // The unsmoothed positions, for the map's debug overlay. They exist only
    // here: `run_points` keeps each fix's accuracy and speed but replaces its
    // latitude and longitude with the smoothed ones, so this is the last
    // moment the measurements themselves are still in hand.
    await store.saveRawTrack(
      runId,
      [
        for (final point in processor.points)
          (lat: point.source.latitude, lon: point.source.longitude),
      ],
      runStart: runStart,
    );

    // And the input to all of it, in arrival order.
    await store.saveFixCapture(
      _captureText,
      runStart: runStart,
      fixCount: _fixCount,
    );

    state = state.copyWith(isRecording: false, savedRunId: runId);
    return runId;
  }

  /// The capture as one NDJSON document. Trailing newline, so appending to it
  /// or concatenating two of them cannot glue two objects onto one line.
  String get _captureText => _capture.isEmpty ? '' : '${_capture.join('\n')}\n';

  /// Send the user to the manufacturer's power-management screen.
  Future<bool> openPowerManagerSettings() =>
      ref.read(runRecorderProvider).openPowerManagerSettings();

  /// The live polyline, extended in place rather than rebuilt.
  ///
  /// Cost matters here because this runs once per accepted fix for the length
  /// of a run. Rebuilding the list each time is O(n) per fix and O(n²) over
  /// the run — for a two-hour walk at 1 Hz that is ~26 million LatLng
  /// allocations to redraw a line that gained one point.
  ///
  /// Published as an UnmodifiableListView, which is a O(1) window onto this
  /// list, not a copy of it. The state object is therefore not deeply
  /// immutable, and that is a deliberate and bounded exception: the track is
  /// append-only, so the only way an old state's view can differ from the one
  /// it was built with is by having MORE of the same track. Nothing here
  /// compares two states by content — Riverpod notifies on identity, and this
  /// class has no operator== — so nothing can be fooled by it.
  final _route = <LatLng>[];

  void _publish(TrackProcessor processor) {
    for (final point in processor.pointsFrom(_route.length)) {
      _route.add(LatLng(point.latitude, point.longitude));
    }

    state = state.copyWith(
      distanceM: processor.distanceM,
      elapsed: processor.elapsed,
      movingTime: processor.movingTime,
      averagePaceSecPerKm: processor.averagePaceSecPerKm,
      currentPaceSecPerKm: processor.currentPaceSecPerKm,
      pointCount: processor.pointCount,
      route: UnmodifiableListView(_route),
    );
  }
}
