import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_providers.g.dart';

/// The prescribed session behind a plan day.
@riverpod
Future<SessionPlan?> sessionPlan(Ref ref, int planDayId) =>
    ref.watch(planRepositoryProvider).sessionById(planDayId);

/// The workout being logged into for [planDayId].
///
/// Kept alive so that moving between exercises does not re-run the lookup, and
/// idempotent regardless: an unfinished workout from the same day is reused
/// rather than replaced.
@Riverpod(keepAlive: true)
Future<int> activeWorkoutId(Ref ref, int planDayId) => ref
    .watch(workoutRepositoryProvider)
    .openOrStartWorkout(
      planDayId: planDayId,
      now: ref.watch(effectiveClockProvider).now(),
    );

/// The warm-up lines already ticked in [workoutId].
@riverpod
Stream<Set<WarmupCheckKey>> warmupChecks(Ref ref, int workoutId) =>
    ref.watch(workoutRepositoryProvider).watchWarmupChecks(workoutId);

/// Every set logged so far in [workoutId].
@riverpod
Stream<List<LoggedSet>> workoutSets(Ref ref, int workoutId) =>
    ref.watch(workoutRepositoryProvider).watchWorkoutSets(workoutId);

/// The sets logged for one exercise in the session in progress.
@riverpod
Stream<List<LoggedSet>> exerciseSets(
  Ref ref, {
  required int workoutId,
  required int exerciseId,
}) => ref
    .watch(workoutRepositoryProvider)
    .watchSets(workoutId: workoutId, exerciseId: exerciseId);

/// Last session's numbers for an exercise, excluding the one in progress.
@riverpod
Future<ExerciseSession?> lastExerciseSession(
  Ref ref, {
  required int exerciseId,
  int? excludingWorkoutId,
}) => ref
    .watch(workoutRepositoryProvider)
    .lastSession(exerciseId, excludingWorkoutId: excludingWorkoutId);

/// The workout history list.
@riverpod
Stream<List<WorkoutSummary>> workoutHistory(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchHistory();

/// Exercises trained in a past workout.
@riverpod
Future<List<({int exerciseId, String name, bool isUnilateral})>>
workoutExercises(Ref ref, int workoutId) =>
    ref.watch(workoutRepositoryProvider).exercisesInWorkout(workoutId);
