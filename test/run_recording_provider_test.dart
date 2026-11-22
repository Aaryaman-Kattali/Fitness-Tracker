import 'package:drift/native.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/data/repositories/run_recorder.dart';
import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_barometer.dart';
import 'support/fake_diagnostics_store.dart';
import 'support/fake_run_recorder.dart';
import 'support/synthetic_track.dart';

/// The controller, driven by the fake recorder — recorder in, pipeline in the
/// middle, database at the end.
void main() {
  late AppDatabase db;
  late FakeRunDiagnosticsStore diagnostics;

  ProviderContainer containerWith(FakeRunRecorder recorder) {
    db = AppDatabase(NativeDatabase.memory());
    diagnostics = FakeRunDiagnosticsStore();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        runRecorderProvider.overrideWithValue(recorder),
        barometerProvider.overrideWithValue(FakeBarometer.absent()),
        // The real store writes through path_provider, which is a method
        // channel and not available in a unit test.
        runDiagnosticsStoreProvider.overrideWithValue(diagnostics),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    addTearDown(recorder.dispose);
    return container;
  }

  test('a recording runs end to end and lands in the database', () async {
    final recorder = FakeRunRecorder(fiveAndAHalfKm());
    final container = containerWith(recorder);
    final controller = container.read(runRecordingProvider.notifier);

    await controller.start();
    expect(container.read(runRecordingProvider).isRecording, isTrue);
    expect(recorder.startCalls, 1);

    final runId = await controller.stopAndSave(notes: 'Felt easy.');
    expect(runId, isNotNull);
    expect(recorder.stopCalls, 1);

    final state = container.read(runRecordingProvider);
    expect(state.isRecording, isFalse);
    expect(state.savedRunId, runId);
    expect(state.distanceM, closeTo(5500, 55));
    expect(state.pointCount, greaterThan(1000));

    final run = (await db.runDao.recentRuns()).single;
    expect(run.distanceM, closeTo(5500, 55));
    expect(run.notes, 'Felt easy.');
    expect(await db.runDao.splitsFor(run.id), hasLength(6));
  });

  test('finishing a run captures its diagnostics', () async {
    // The capture has to happen here, at the one moment the processor still
    // exists. Nothing downstream can recover a rejection count from the
    // database, because rejected fixes are not written to it.
    final recorder = FakeRunRecorder(kmWithInaccurateFixes());
    final container = containerWith(recorder);

    await container.read(runRecordingProvider.notifier).start();
    await container.read(runRecordingProvider.notifier).stopAndSave();

    expect(diagnostics.written, isNotNull);
    expect(diagnostics.written, contains('live capture'));
    expect(
      diagnostics.written,
      contains('delivered by plugin'),
      reason: 'the count above the pipeline comes from the recorder',
    );
  });

  test('finishing a run writes the raw fix capture, replayable', () async {
    // End to end: the controller's capture must be a file that replays into
    // the run it was taken from. Asserting only that a file was written would
    // pass on a file of the wrong fixes in the wrong order.
    final track = kmWithInaccurateFixes();
    final recorder = FakeRunRecorder(track);
    final container = containerWith(recorder);

    await container.read(runRecordingProvider.notifier).start();
    await container.read(runRecordingProvider.notifier).stopAndSave();

    final ndjson = diagnostics.fixCapture;
    expect(ndjson, isNotNull);

    final parsed = parseCapture(ndjson!);
    expect(
      parsed,
      hasLength(track.fixes.length),
      reason: 'the capture is of DELIVERED fixes, including the rejected ones',
    );

    final replayed = replayCapture(ndjson);
    expect(
      replayed.smoothedDistanceM,
      container.read(runRecordingProvider).distanceM,
    );
    expect(replayed.rejections![FixRejection.accuracy], 3);
  });

  test('a recording that accepts nothing still leaves its capture', () async {
    // The case that most needs the file. A run with no usable fixes looks
    // identical from outside to one that never started, and the delivered
    // fixes are the only thing that can tell them apart.
    final recorder = FakeRunRecorder(_allTooInaccurate());
    final container = containerWith(recorder);

    await container.read(runRecordingProvider.notifier).start();
    expect(
      await container.read(runRecordingProvider.notifier).stopAndSave(),
      isNull,
    );

    expect(parseCapture(diagnostics.fixCapture!), isNotEmpty);
  });

  test('live metrics update while recording, not only at the end', () async {
    // A screen that shows nothing until you stop is not a run tracker.
    final recorder = FakeRunRecorder(straightKm());
    final container = containerWith(recorder);
    final controller = container.read(runRecordingProvider.notifier);

    await controller.start();

    final state = container.read(runRecordingProvider);
    expect(
      state.distanceM,
      closeTo(1000, 10),
      reason: 'distance accrues as fixes arrive',
    );
    expect(state.isRecording, isTrue, reason: 'still recording');
    expect(state.averagePaceSecPerKm, closeTo(360, 5));
  });

  test('a refused permission blocks the start and says so', () async {
    final recorder = FakeRunRecorder(
      straightKm(),
      status: const RecorderStatus.blocked(
        RecorderBlocker.permission,
        detail: 'deniedForever',
      ),
    );
    final container = containerWith(recorder);
    final controller = container.read(runRecordingProvider.notifier);

    await controller.start();

    final state = container.read(runRecordingProvider);
    expect(state.isRecording, isFalse);
    expect(state.blocker, RecorderBlocker.permission);
    expect(
      state.blockerDetail,
      'deniedForever',
      reason: 'the reason has to reach the screen, not a log',
    );
    expect(recorder.startCalls, 0);
    expect(await db.runDao.recentRuns(), isEmpty);
  });

  test('location services off is a different blocker from permission', () {
    // They need different remedies — one opens app settings, the other opens
    // the system location toggle — so collapsing them into one "failed" state
    // would leave the user with no route forward.
    expect(
      RecorderBlocker.locationServicesOff,
      isNot(RecorderBlocker.permission),
    );
  });

  test('an aggressive OEM surfaces a warning', () async {
    final recorder = FakeRunRecorder(
      straightKm(),
      warning: const OemPowerWarning(
        manufacturer: 'samsung',
        model: 'SM-S928B',
        aggressionRating: 4,
        isExemptFromBatteryOptimisation: false,
      ),
    );
    final container = containerWith(recorder);
    final controller = container.read(runRecordingProvider.notifier);

    await controller.refreshReadiness();

    final warning = container.read(runRecordingProvider).oemWarning;
    expect(warning, isNotNull);
    expect(warning!.manufacturer, 'samsung');
    expect(warning.needsAttention, isTrue);

    expect(await controller.openPowerManagerSettings(), isTrue);
    expect(recorder.powerManagerOpened, isTrue);
  });

  test('an OEM already exempted is not nagged', () async {
    final recorder = FakeRunRecorder(
      straightKm(),
      warning: const OemPowerWarning(
        manufacturer: 'samsung',
        model: 'SM-S928B',
        aggressionRating: 4,
        isExemptFromBatteryOptimisation: true,
      ),
    );
    final container = containerWith(recorder);

    await container.read(runRecordingProvider.notifier).refreshReadiness();

    expect(
      container.read(runRecordingProvider).oemWarning,
      isNull,
      reason: 'the user already fixed this; asking again is noise',
    );
  });

  test('a run with no usable fixes is not stored', () async {
    // Standing in a basement for a minute should leave no trace in the
    // history. A row saying nothing is worse than no row.
    final recorder = FakeRunRecorder(
      SyntheticTrack(
        name: 'nothing usable',
        fixes: straightKm().fixes.take(3).toList(),
        groundTruthDistanceM: 0,
      ),
    );
    final container = containerWith(recorder);
    final controller = container.read(runRecordingProvider.notifier);

    await controller.start();
    final runId = await controller.stopAndSave();

    expect(runId, isNull, reason: 'all three fixes were cold-start rejects');
    expect(await db.runDao.recentRuns(), isEmpty);
    expect(container.read(runRecordingProvider).isRecording, isFalse);
  });

  test('starting twice does not fork a second recording', () async {
    final recorder = FakeRunRecorder(straightKm());
    final container = containerWith(recorder);
    final controller = container.read(runRecordingProvider.notifier);

    await controller.start();
    await controller.start();

    expect(recorder.startCalls, 1);
  });

  test('stopping when nothing is recording is harmless', () async {
    final recorder = FakeRunRecorder(straightKm());
    final container = containerWith(recorder);

    expect(
      await container.read(runRecordingProvider.notifier).stopAndSave(),
      isNull,
    );
    expect(recorder.stopCalls, 0);
  });
}

/// A receiver that never produced a usable fix: every one reports 80 m, so the
/// accuracy filter takes all of them and the run has no track at all.
SyntheticTrack _allTooInaccurate() {
  final start = DateTime.utc(2026, 8, 22, 6);
  return SyntheticTrack(
    name: 'nothing usable',
    fixes: [
      for (var i = 0; i < 12; i++)
        RawFix(
          latitude: originLat,
          longitude: originLon,
          timestamp: start.add(Duration(seconds: i)),
          accuracyM: 80,
          altitudeM: 920,
        ),
    ],
    groundTruthDistanceM: 0,
  );
}
