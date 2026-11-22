import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_run_recorder.dart';
import 'support/synthetic_track.dart';
import 'support/test_database.dart';

/// Storing a run, end to end from a recorder to the v7 tables.
///
/// The recorder here is the fake, replaying an A1a fixture. That is the point
/// of the exercise as much as a convenience: the fixtures were written before
/// any plugin existed, so if they cannot be delivered through `RunRecorder`
/// unchanged then the interface has been shaped around tracelet rather than
/// around what a run recorder is.
void main() {
  test('a recorded run round-trips through the database', () async {
    final db = openTestDatabase();
    final track = fiveAndAHalfKm();
    final recorder = FakeRunRecorder(track);
    addTearDown(recorder.dispose);

    final processor = TrackProcessor();
    recorder.fixes.listen(processor.add);

    expect((await recorder.prepare()).canRecord, isTrue);
    await recorder.start();
    await recorder.stop();

    expect(
      processor.points,
      isNotEmpty,
      reason: 'the fixtures must reach the pipeline through the interface',
    );

    final startedAt = processor.points.first.timestamp;
    final endedAt = processor.points.last.timestamp;
    final runId = await db.runDao.saveRun(
      startedAt: startedAt,
      endedAt: endedAt,
      track: processor,
      notes: 'Evening loop.',
    );

    final run = (await db.runDao.recentRuns()).single;
    expect(run.id, runId);
    expect(run.distanceM, closeTo(5500, 55));
    expect(run.elapsedS, processor.elapsed.inSeconds);
    expect(run.movingS, processor.movingTime.inSeconds);
    expect(run.avgPaceSPerKm, closeTo(360, 5));
    expect(run.notes, 'Evening loop.');

    // Instant, not object. Drift stores a DateTime as whole seconds since the
    // epoch, which is absolute and round-trips exactly, but hands it back
    // flagged local rather than UTC. The fixes arrive from the plugin in UTC,
    // so a plain == comparison fails on the flag while the moment in time is
    // identical. Everything downstream cares about the instant.
    expect(run.endedAt!.isAtSameMomentAs(endedAt), isTrue);
    expect(run.startedAt.isAtSameMomentAs(startedAt), isTrue);

    // Nothing computed from altitude, and nothing invented for the features
    // that have not been built.
    expect(run.elevGainM, isNull);
    expect(run.polyline, isNull);
    expect(run.avgHrBpm, isNull);
    expect(run.maxHrBpm, isNull);

    final points = await db.runDao.pointsFor(runId);
    expect(points, hasLength(processor.points.length));
    expect(points.first.lat, closeTo(processor.points.first.latitude, 1e-9));
    expect(
      points.first.timestamp.isAtSameMomentAs(
        processor.points.first.timestamp,
      ),
      isTrue,
      reason: 'point times survive the round trip as instants',
    );
    expect(
      points.every((point) => point.elevM == 920),
      isTrue,
      reason: 'raw altitude is stored per point, for A6 to use later',
    );
    expect(points.first.accuracyM, 5);

    final splits = await db.runDao.splitsFor(runId);
    expect(splits, hasLength(6));
    expect(splits.take(5).every((split) => !split.isPartial), isTrue);
    expect(splits.last.isPartial, isTrue);
    expect(splits.last.distanceM, closeTo(500, 15));
    expect(splits.map((split) => split.km), [1, 2, 3, 4, 5, 6]);
  });

  test('the stored splits sum to the stored distance, on both sides of '
      'the A1c-Q bypass', () async {
    // Checked through the database rather than on SavedTrack alone: the DAO is
    // where a total from one track and splits from another would be glued
    // into one run, and nothing upstream can see that happen.
    final db = openTestDatabase();

    for (final (track, bypassed) in [
      (rectangleCircuit(), true),
      (measuredWalkKm(), false),
    ]) {
      final processor = replay(track);
      expect(
        processor.savedTrack().source == DistanceSource.rawAccepted,
        bypassed,
        reason: '${track.name}: the fixture must land on its intended side',
      );

      final runId = await db.runDao.saveRun(
        startedAt: processor.points.first.timestamp,
        endedAt: processor.points.last.timestamp,
        track: processor,
      );

      final run = await db.runDao.runById(runId);
      final splits = await db.runDao.splitsFor(runId);
      expect(
        splits.fold<double>(0, (sum, split) => sum + split.distanceM),
        closeTo(run!.distanceM, 1e-6),
        reason: track.name,
      );
      expect(run.distanceM, processor.savedTrack().distanceM);
      expect(run.movingS, processor.movingTime.inSeconds);
    }
  });

  test('deleting a run takes its points and splits with it', () async {
    final db = openTestDatabase();
    final recorder = FakeRunRecorder(straightKm());
    addTearDown(recorder.dispose);

    final processor = TrackProcessor();
    recorder.fixes.listen(processor.add);
    await recorder.start();

    final runId = await db.runDao.saveRun(
      startedAt: processor.points.first.timestamp,
      endedAt: processor.points.last.timestamp,
      track: processor,
    );
    expect(await db.runDao.pointsFor(runId), isNotEmpty);

    await db.runDao.deleteRun(runId);

    expect(await db.runDao.recentRuns(), isEmpty);
    expect(await db.runDao.pointsFor(runId), isEmpty);
    expect(await db.runDao.splitsFor(runId), isEmpty);
  });

  test('a run is written whole or not at all', () async {
    // saveRun is one transaction. A run row with no points is a state the
    // rest of the app would have to defend against forever, so it must not be
    // reachable — including when the track is empty.
    final db = openTestDatabase();
    final empty = TrackProcessor();

    final runId = await db.runDao.saveRun(
      startedAt: DateTime.utc(2026, 8, 21, 6),
      endedAt: DateTime.utc(2026, 8, 21, 6, 30),
      track: empty,
    );

    final run = (await db.runDao.recentRuns()).single;
    expect(run.distanceM, 0);
    expect(
      run.avgPaceSPerKm,
      0,
      reason:
          'a pace of null has nowhere to go in a non-null column; zero '
          'over zero distance is the honest reading of "no run happened"',
    );
    expect(await db.runDao.pointsFor(runId), isEmpty);
    expect(await db.runDao.splitsFor(runId), isEmpty);
  });

  test('runs come back newest first', () async {
    final db = openTestDatabase();
    final empty = TrackProcessor();

    for (final day in [12, 19, 5]) {
      await db.runDao.saveRun(
        startedAt: DateTime.utc(2026, 8, day, 6),
        endedAt: DateTime.utc(2026, 8, day, 7),
        track: empty,
      );
    }

    expect(
      (await db.runDao.recentRuns()).map((run) => run.startedAt.day),
      [19, 12, 5],
    );
  });
}
