import 'dart:async';

import 'package:fitness_tracker/data/repositories/run_recorder.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';

import 'synthetic_track.dart';

/// A [RunRecorder] that replays a synthetic track instead of a receiver.
///
/// This is the check on the interface as much as a test tool. The A1a fixtures
/// were written before any plugin existed, so if they cannot be delivered
/// through [RunRecorder] unchanged, the interface has been shaped around
/// tracelet rather than around what a run recorder is — and everything above
/// it would inherit that shape.
class FakeRunRecorder implements RunRecorder {
  FakeRunRecorder(
    this.track, {
    this.status = const RecorderStatus.ready(),
    this.warning,
    this.powerManagerOpens = true,
    this.framingFix,
  });

  final SyntheticTrack track;
  final RecorderStatus status;
  final OemPowerWarning? warning;
  final bool powerManagerOpens;

  /// What [currentPosition] answers before a run starts.
  ///
  /// Null by default, and that default is the harder case rather than the lazy
  /// one: a phone with no cached fix is what the locating state exists for, so
  /// every test that does not opt in is exercising it.
  final RawFix? framingFix;

  final _fixes = StreamController<RawFix>.broadcast();

  int prepareCalls = 0;
  int currentPositionCalls = 0;
  int startCalls = 0;
  int stopCalls = 0;
  bool powerManagerOpened = false;

  int _received = 0;

  @override
  Stream<RawFix> get fixes => _fixes.stream;

  /// A synthetic track has no unparseable timestamps to lose, so `undatable`
  /// is always zero here. It is not a stub: it is the correct answer for a
  /// source that cannot produce one.
  @override
  ({int received, int undatable}) get delivery =>
      (received: _received, undatable: 0);

  @override
  Future<RecorderStatus> prepare() async {
    prepareCalls++;
    return status;
  }

  @override
  Future<RawFix?> currentPosition() async {
    currentPositionCalls++;
    return framingFix;
  }

  @override
  Future<void> start() async {
    startCalls++;
    // Delivered synchronously on start rather than on a timer: a test that
    // waits out a 5.5 km track in real time is a test nobody runs.
    for (final fix in track.fixes) {
      _received++;
      _fixes.add(fix);
    }
    // Let the listener drain before anything asserts on the result.
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<OemPowerWarning?> oemPowerWarning() async => warning;

  @override
  Future<bool> openPowerManagerSettings() async {
    powerManagerOpened = true;
    return powerManagerOpens;
  }

  @override
  Future<void> dispose() async {
    await _fixes.close();
  }
}
