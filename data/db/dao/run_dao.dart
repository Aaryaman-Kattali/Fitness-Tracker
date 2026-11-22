import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/tables/activity_tables.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart'
    as pipeline;

part 'run_dao.g.dart';

/// Reads and writes recorded runs.
///
/// A run is written once, when it finishes, rather than row by row as it is
/// recorded. The pipeline holds the whole track in memory anyway — a 5 km run
/// is a few thousand points — and a run that is only ever stored complete
/// cannot leave a half-written one behind to be cleaned up later.
@DriftAccessor(tables: [Runs, RunPoints, Splits])
class RunDao extends DatabaseAccessor<AppDatabase> with _$RunDaoMixin {
  RunDao(super.attachedDatabase);

  /// Store a finished run with its track and splits, and return its id.
  ///
  /// One transaction: a run with no points, or points belonging to no run, is
  /// not a state worth being able to reach.
  ///
  /// Distance, pace and splits come from [pipeline.TrackProcessor.savedTrack],
  /// one call, so the run row and its splits are cut from the same total
  /// (A1c-Q). Elapsed time is the processor's; it does not depend on which
  /// track the distance came from.
  Future<int> saveRun({
    required DateTime startedAt,
    required DateTime endedAt,
    required pipeline.TrackProcessor track,
    double? elevGainM,
    String? notes,
  }) {
    final saved = track.savedTrack();
    return transaction(() async {
      final runId = await into(runs).insert(
        RunsCompanion.insert(
          startedAt: startedAt,
          endedAt: Value(endedAt),
          distanceM: saved.distanceM,
          movingS: saved.movingTime.inSeconds,
          elapsedS: track.elapsed.inSeconds,
          avgPaceSPerKm: saved.averagePaceSecPerKm ?? 0,
          // Barometric only (A6-1); null when there was no barometer, it
          // failed, or nobody passed one. Never derived from `run_points`'
          // GPS altitude (A1-2).
          elevGainM: Value(elevGainM),
          notes: Value(notes),
          // polyline, avgHrBpm and maxHrBpm are deliberately left null: A2
          // and A7 fill them. Writing a zero would be a measurement nobody
          // took.
        ),
      );

      await batch((b) {
        b
          ..insertAll(runPoints, [
            for (final point in saved.points)
              RunPointsCompanion.insert(
                runId: runId,
                lat: point.latitude,
                lon: point.longitude,
                timestamp: point.timestamp,
                // The smoothed position is what the run is; the raw fix's own
                // altitude, accuracy and speed ride along unprocessed, which is
                // what lets A6 revisit altitude later without re-recording.
                elevM: Value(point.source.altitudeM),
                accuracyM: Value(point.source.accuracyM),
                speedMps: Value(point.source.speedMps),
              ),
          ])
          ..insertAll(splits, [
            for (final split in saved.splits)
              SplitsCompanion.insert(
                runId: runId,
                km: split.km,
                durationS: split.duration.inSeconds,
                distanceM: split.distanceM,
                isPartial: Value(split.isPartial),
              ),
          ]);
      });

      return runId;
    });
  }

  Future<List<Run>> recentRuns({int limit = 50}) =>
      (select(runs)
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
            ..limit(limit))
          .get();

  Stream<List<Run>> watchRecentRuns({int limit = 50}) =>
      (select(runs)
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
            ..limit(limit))
          .watch();

  Future<Run?> runById(int runId) =>
      (select(runs)..where((r) => r.id.equals(runId))).getSingleOrNull();

  Future<List<RunPoint>> pointsFor(int runId) =>
      (select(runPoints)
            ..where((p) => p.runId.equals(runId))
            ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
          .get();

  Future<List<Split>> splitsFor(int runId) =>
      (select(splits)
            ..where((s) => s.runId.equals(runId))
            ..orderBy([(s) => OrderingTerm.asc(s.km)]))
          .get();

  /// Points and splits go with it, by the cascade declared on the tables.
  Future<int> deleteRun(int runId) =>
      (delete(runs)..where((r) => r.id.equals(runId))).go();
}
