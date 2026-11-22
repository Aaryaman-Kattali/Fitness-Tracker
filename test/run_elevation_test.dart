import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_barometer.dart';
import 'support/fake_diagnostics_store.dart';
import 'support/fake_run_recorder.dart';
import 'support/synthetic_track.dart';

/// A6 end to end: barometer in, run row and report and capture out.
///
/// The recorder replays `straightKm`, whose fixes all carry a GPS altitude of
/// 920 m. That is A1-2's check in every test below: whatever the gain reads,
/// it is never something derived from that column.
void main() {
  late AppDatabase db;
  late FakeRunDiagnosticsStore diagnostics;

  Future<Run> record(FakeBarometer barometer) async {
    db = AppDatabase(NativeDatabase.memory());
    diagnostics = FakeRunDiagnosticsStore();
    final recorder = FakeRunRecorder(straightKm());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        runRecorderProvider.overrideWithValue(recorder),
        barometerProvider.overrideWithValue(barometer),
        runDiagnosticsStoreProvider.overrideWithValue(diagnostics),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    addTearDown(recorder.dispose);

    final controller = container.read(runRecordingProvider.notifier);
    await controller.start();
    expect(await controller.stopAndSave(), isNotNull);
    return (await db.runDao.recentRuns()).single;
  }

  /// A 20 m climb over two minutes, flat either side, noise-free: the pure
  /// function is tested for noise in `elevation_gain_test`; here the question
  /// is only whether the number reaches the row.
  final start = DateTime.utc(2026, 8, 20, 6);
  final climb = [
    for (var s = 0; s < 300; s++)
      (
        at: start.add(Duration(seconds: s)),
        hPa:
            1013.25 *
            math
                .pow(
                  1 - (s < 60 ? 0 : (s < 180 ? (s - 60) / 6 : 20)) / 44330,
                  5.255,
                )
                .toDouble(),
      ),
  ];

  test('a barometer that records puts its gain on the run row', () async {
    final run = await record(FakeBarometer(climb));

    expect(run.elevGainM, closeTo(20, 0.01));
    expect(diagnostics.written, contains('gain 20.0 m from 300 readings'));
  });

  test('no barometer: the run records, stores no gain, and says so', () async {
    final run = await record(FakeBarometer.absent());

    expect(run.distanceM, closeTo(1000, 10), reason: 'the run is unaffected');
    expect(
      run.elevGainM,
      isNull,
      reason: 'absent is not flat, and 920 m of GPS altitude is not a source',
    );
    expect(diagnostics.written, contains('NO BAROMETER on this phone'));
  });

  test('a barometer that fails keeps no partial gain', () async {
    final run = await record(
      FakeBarometer(climb.take(150).toList(), thenError: StateError('gone')),
    );

    expect(run.elevGainM, isNull);
    expect(diagnostics.written, contains('BAROMETER FAILED after 150'));
  });

  test('pressure goes into the capture without disturbing the fixes', () async {
    await record(FakeBarometer(climb));
    final ndjson = diagnostics.fixCapture!;

    expect(parseCapture(ndjson), hasLength(straightKm().fixes.length));
    expect(
      diagnostics.fixCaptureCount,
      straightKm().fixes.length,
      reason: 'the cached count is of fixes, not of lines',
    );
    expect(
      [for (final f in parseCapture(ndjson)) f.seq],
      [for (var i = 0; i < straightKm().fixes.length; i++) i],
      reason: 'fix seq stays contiguous with pressure lines between fixes',
    );

    final pressure = parsePressure(ndjson);
    expect(pressure, hasLength(climb.length));
    expect(elevationGainM(pressure), closeTo(20, 0.01));
  });
}
