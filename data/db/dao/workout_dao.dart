import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/tables/training_tables.dart';

part 'workout_dao.g.dart';

/// A set joined to the workout it belongs to.
class SetLogWithWorkout {
  const SetLogWithWorkout(this.set, this.workout);

  final SetLog set;
  final Workout workout;
}

/// Reads and writes workouts and their sets.
@DriftAccessor(tables: [Workouts, SetLogs, Exercises, PlanDays, WarmupChecks])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.attachedDatabase);

  // ---------- Workouts ----------

  Future<int> startWorkout({required int? planDayId, DateTime? now}) {
    final at = now ?? DateTime.now();
    return into(workouts).insert(
      WorkoutsCompanion.insert(
        date: DateTime(at.year, at.month, at.day),
        planDayId: Value(planDayId),
        startedAt: at,
      ),
    );
  }

  /// The unfinished workout for one calendar day *and* one plan day.
  ///
  /// Both halves of the key matter. Matching on the most recent unfinished
  /// workout alone forks the log the moment two sessions overlap: opening
  /// Upper B while Lower A is still unfinished would otherwise hand Upper B's
  /// sets to the Lower A row, and coming back to Lower A would then start a
  /// third workout.
  ///
  /// [planDayId] is null for ad-hoc sessions, which pair with each other and
  /// never with a planned one — hence the explicit IS NULL branch, since SQL
  /// equality against NULL is never true.
  Future<Workout?> openWorkoutFor({
    required DateTime date,
    required int? planDayId,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    return (select(workouts)
          ..where(
            (w) =>
                w.endedAt.isNull() &
                w.date.equals(day) &
                (planDayId == null
                    ? w.planDayId.isNull()
                    : w.planDayId.equals(planDayId)),
          )
          ..orderBy([(w) => OrderingTerm.asc(w.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> endWorkout(int id, {DateTime? now}) =>
      (update(workouts)..where((w) => w.id.equals(id))).write(
        WorkoutsCompanion(endedAt: Value(now ?? DateTime.now())),
      );

  Future<void> deleteWorkout(int id) =>
      (delete(workouts)..where((w) => w.id.equals(id))).go();

  Stream<List<Workout>> watchRecentWorkouts({int limit = 100}) =>
      (select(workouts)
            ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
            ..limit(limit))
          .watch();

  // ---------- Sets ----------

  Future<int> insertSet(SetLogsCompanion entry) => into(setLogs).insert(entry);

  Future<void> deleteSet(int id) =>
      (delete(setLogs)..where((s) => s.id.equals(id))).go();

  /// The index the next set of [exerciseId] in [workoutId] should carry.
  ///
  /// Derived from the highest index in use, not from how many rows exist:
  /// deleting a mistyped set from the middle of an exercise leaves the row
  /// count one below the top index, and a count-based next index would then
  /// collide with a set that is still there.
  Future<int> nextSetIndex(int workoutId, int exerciseId) async {
    final highest = setLogs.setIndex.max();
    final query = selectOnly(setLogs)
      ..addColumns([highest])
      ..where(
        setLogs.workoutId.equals(workoutId) &
            setLogs.exerciseId.equals(exerciseId),
      );

    final row = await query.getSingleOrNull();
    return (row?.read(highest) ?? 0) + 1;
  }

  // ---------- Warm-up checklist ----------

  Stream<List<WarmupCheck>> watchWarmupChecks(int workoutId) =>
      (select(warmupChecks)
            ..where((c) => c.workoutId.equals(workoutId))
            ..orderBy([(c) => OrderingTerm.asc(c.lineIndex)]))
          .watch();

  /// Ticks or unticks one checklist line.
  ///
  /// The insert ignores a duplicate rather than failing, so double-tapping a
  /// line cannot throw at the user mid-warm-up.
  Future<void> setWarmupCheck({
    required int workoutId,
    required int planItemId,
    required int lineIndex,
    required bool isChecked,
  }) async {
    if (!isChecked) {
      await (delete(warmupChecks)..where(
            (c) =>
                c.workoutId.equals(workoutId) &
                c.planItemId.equals(planItemId) &
                c.lineIndex.equals(lineIndex),
          ))
          .go();
      return;
    }

    await into(warmupChecks).insert(
      WarmupChecksCompanion.insert(
        workoutId: workoutId,
        planItemId: planItemId,
        lineIndex: lineIndex,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Stream<List<SetLog>> watchSetsForWorkout(int workoutId) =>
      (select(setLogs)
            ..where((s) => s.workoutId.equals(workoutId))
            ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
          .watch();

  Stream<List<SetLog>> watchSetsForExerciseInWorkout(
    int workoutId,
    int exerciseId,
  ) =>
      (select(setLogs)
            ..where(
              (s) =>
                  s.workoutId.equals(workoutId) &
                  s.exerciseId.equals(exerciseId),
            )
            ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
          .watch();

  Future<List<SetLog>> setsForExerciseInWorkout(
    int workoutId,
    int exerciseId,
  ) =>
      (select(setLogs)
            ..where(
              (s) =>
                  s.workoutId.equals(workoutId) &
                  s.exerciseId.equals(exerciseId),
            )
            ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
          .get();

  /// The sets of the previous session that trained [exerciseId].
  ///
  /// Used to put last session's numbers in front of the user while they log,
  /// which is the whole mechanism of double progression.
  Future<SetLogWithWorkout?> lastSessionMarker(
    int exerciseId, {
    int? excludingWorkoutId,
  }) async {
    final query =
        select(setLogs).join([
            innerJoin(workouts, workouts.id.equalsExp(setLogs.workoutId)),
          ])
          ..where(setLogs.exerciseId.equals(exerciseId))
          ..orderBy([OrderingTerm.desc(workouts.startedAt)])
          ..limit(1);

    if (excludingWorkoutId != null) {
      query.where(setLogs.workoutId.equals(excludingWorkoutId).not());
    }

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return SetLogWithWorkout(row.readTable(setLogs), row.readTable(workouts));
  }

  /// Distinct exercises trained in [workoutId], in the order first logged.
  Future<List<Exercise>> exercisesInWorkout(int workoutId) async {
    final query =
        select(setLogs).join([
            innerJoin(exercises, exercises.id.equalsExp(setLogs.exerciseId)),
          ])
          ..where(setLogs.workoutId.equals(workoutId))
          ..orderBy([OrderingTerm.asc(setLogs.id)]);

    final rows = await query.get();
    final seen = <int>{};
    final result = <Exercise>[];
    for (final row in rows) {
      final exercise = row.readTable(exercises);
      if (seen.add(exercise.id)) result.add(exercise);
    }
    return result;
  }

  /// Set counts per workout, for the history list.
  Future<Map<int, int>> setCountsByWorkout() async {
    final count = setLogs.id.count();
    final query = selectOnly(setLogs)
      ..addColumns([setLogs.workoutId, count])
      ..groupBy([setLogs.workoutId]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(setLogs.workoutId)!: row.read(count) ?? 0,
    };
  }
}
