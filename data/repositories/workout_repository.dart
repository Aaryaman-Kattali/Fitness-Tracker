import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/dao/plan_dao.dart';
import 'package:fitness_tracker/data/db/dao/workout_dao.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';

/// Records and reads training sessions.
class WorkoutRepository {
  const WorkoutRepository(this._dao, this._planDao);

  final WorkoutDao _dao;
  final PlanDao _planDao;

  // ---------- Sessions ----------

  /// The id of the workout to log into for [planDayId] right now.
  ///
  /// Reuses the unfinished workout for the same (day, plan day) pair, so that
  /// leaving a session and coming back — even by way of a different session —
  /// resumes it rather than forking a second one.
  Future<int> openOrStartWorkout({
    required int? planDayId,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final open = await _dao.openWorkoutFor(date: at, planDayId: planDayId);
    return open?.id ?? await _dao.startWorkout(planDayId: planDayId, now: at);
  }

  /// The unfinished workout for [planDayId] on [now]'s date, if one exists.
  ///
  /// Read-only counterpart of [openOrStartWorkout]: the Today screen needs to
  /// know whether a session is already under way without creating one just by
  /// being looked at.
  Future<int?> openWorkoutId({required int? planDayId, DateTime? now}) async {
    final open = await _dao.openWorkoutFor(
      date: now ?? DateTime.now(),
      planDayId: planDayId,
    );
    return open?.id;
  }

  Future<void> finishWorkout(int workoutId) => _dao.endWorkout(workoutId);

  Future<void> deleteWorkout(int workoutId) => _dao.deleteWorkout(workoutId);

  // ---------- Set logging ----------

  /// Appends a set to [exerciseId] within [workoutId].
  ///
  /// The set index is derived here rather than passed in: the caller's view of
  /// how many sets exist is a stream snapshot that can lag a delete, and two
  /// sets sharing an index would silently corrupt the session's ordering.
  Future<void> logSet({
    required int workoutId,
    required int exerciseId,
    required int reps,
    double? weightKg,
    int? rir,
    bool isWarmup = false,
    DateTime? now,
  }) async {
    await _dao.insertSet(
      SetLogsCompanion.insert(
        workoutId: workoutId,
        exerciseId: exerciseId,
        setIndex: await _dao.nextSetIndex(workoutId, exerciseId),
        weightKg: Value(weightKg),
        reps: reps,
        rir: Value(rir),
        isWarmup: Value(isWarmup),
        loggedAt: Value(now ?? DateTime.now()),
      ),
    );
  }

  Future<void> deleteSet(int setLogId) => _dao.deleteSet(setLogId);

  // ---------- Warm-up checklist ----------

  /// The warm-up lines ticked so far in [workoutId].
  Stream<Set<WarmupCheckKey>> watchWarmupChecks(int workoutId) => _dao
      .watchWarmupChecks(workoutId)
      .map(
        (rows) => {
          for (final row in rows)
            (planItemId: row.planItemId, lineIndex: row.lineIndex),
        },
      );

  Future<void> setWarmupCheck({
    required int workoutId,
    required WarmupCheckKey line,
    required bool isChecked,
  }) => _dao.setWarmupCheck(
    workoutId: workoutId,
    planItemId: line.planItemId,
    lineIndex: line.lineIndex,
    isChecked: isChecked,
  );

  Stream<List<LoggedSet>> watchSets({
    required int workoutId,
    required int exerciseId,
  }) => _dao
      .watchSetsForExerciseInWorkout(workoutId, exerciseId)
      .map((rows) => rows.map(_toLoggedSet).toList());

  Stream<List<LoggedSet>> watchWorkoutSets(int workoutId) => _dao
      .watchSetsForWorkout(workoutId)
      .map(
        (rows) => rows.map(_toLoggedSet).toList(),
      );

  // ---------- History ----------

  /// The previous session's sets for [exerciseId], excluding the one in
  /// progress. This is what makes progressive overload visible while logging.
  Future<ExerciseSession?> lastSession(
    int exerciseId, {
    int? excludingWorkoutId,
  }) async {
    final marker = await _dao.lastSessionMarker(
      exerciseId,
      excludingWorkoutId: excludingWorkoutId,
    );
    if (marker == null) return null;

    final sets = await _dao.setsForExerciseInWorkout(
      marker.workout.id,
      exerciseId,
    );
    return ExerciseSession(
      workoutId: marker.workout.id,
      date: marker.workout.date,
      startedAt: marker.workout.startedAt,
      sets: sets.map(_toLoggedSet).toList(),
    );
  }

  Stream<List<WorkoutSummary>> watchHistory({int limit = 100}) {
    return _dao.watchRecentWorkouts(limit: limit).asyncMap((rows) async {
      final counts = await _dao.setCountsByWorkout();
      final days = await _planDao.allDays();
      final names = {for (final day in days) day.id: day.name};

      return [
        for (final row in rows)
          WorkoutSummary(
            id: row.id,
            date: row.date,
            startedAt: row.startedAt,
            endedAt: row.endedAt,
            setCount: counts[row.id] ?? 0,
            planDayName: row.planDayId == null ? null : names[row.planDayId],
          ),
      ];
    });
  }

  Future<List<({int exerciseId, String name, bool isUnilateral})>>
  exercisesInWorkout(int workoutId) async {
    final rows = await _dao.exercisesInWorkout(workoutId);
    return [
      for (final row in rows)
        (exerciseId: row.id, name: row.name, isUnilateral: row.isUnilateral),
    ];
  }

  LoggedSet _toLoggedSet(SetLog row) => LoggedSet(
    id: row.id,
    exerciseId: row.exerciseId,
    setIndex: row.setIndex,
    weightKg: row.weightKg,
    reps: row.reps,
    rir: row.rir,
    isWarmup: row.isWarmup,
  );
}
