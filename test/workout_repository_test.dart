import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repository;
  late int lowerA;
  late int upperB;
  late int exerciseId;

  setUp(() async {
    db = openTestDatabase();
    repository = workoutRepositoryFor(db);
    lowerA = await planDayIdFor(db, PlanDayKey.lowerA);
    upperB = await planDayIdFor(db, PlanDayKey.upperB);
    exerciseId = await anyExerciseId(db);
  });

  group('openOrStartWorkout', () {
    test('resumes the original session after another one is opened', () async {
      // Start Lower A, leave it unfinished, open Upper B, come back.
      final firstLowerA = await repository.openOrStartWorkout(
        planDayId: lowerA,
      );
      final firstUpperB = await repository.openOrStartWorkout(
        planDayId: upperB,
      );
      final secondLowerA = await repository.openOrStartWorkout(
        planDayId: lowerA,
      );

      expect(
        firstUpperB,
        isNot(firstLowerA),
        reason: 'a different plan day is a different workout',
      );
      expect(
        secondLowerA,
        firstLowerA,
        reason: 'returning to Lower A must resume it, not fork a third workout',
      );
      expect(await allWorkouts(db), hasLength(2));
    });

    test('reuses the same workout when reopened repeatedly', () async {
      final first = await repository.openOrStartWorkout(planDayId: lowerA);
      final second = await repository.openOrStartWorkout(planDayId: lowerA);

      expect(second, first);
      expect(await allWorkouts(db), hasLength(1));
    });

    test('does not resume a session from a previous day', () async {
      final yesterday = await repository.openOrStartWorkout(
        planDayId: lowerA,
        now: DateTime(2026, 8, 10, 18),
      );
      final today = await repository.openOrStartWorkout(
        planDayId: lowerA,
        now: DateTime(2026, 8, 17, 18),
      );

      expect(today, isNot(yesterday));
    });

    test('does not resume a finished session', () async {
      final first = await repository.openOrStartWorkout(planDayId: lowerA);
      await repository.finishWorkout(first);
      final second = await repository.openOrStartWorkout(planDayId: lowerA);

      expect(second, isNot(first));
    });

    test(
      'ad-hoc sessions pair with each other, not with a planned one',
      () async {
        final planned = await repository.openOrStartWorkout(planDayId: lowerA);
        final adHoc = await repository.openOrStartWorkout(planDayId: null);
        final adHocAgain = await repository.openOrStartWorkout(planDayId: null);

        expect(adHoc, isNot(planned));
        expect(adHocAgain, adHoc);
      },
    );
  });

  group('openWorkoutId', () {
    test('is null until a session is started, and never starts one', () async {
      expect(await repository.openWorkoutId(planDayId: lowerA), isNull);
      expect(await allWorkouts(db), isEmpty);

      final started = await repository.openOrStartWorkout(planDayId: lowerA);
      expect(await repository.openWorkoutId(planDayId: lowerA), started);
      expect(await repository.openWorkoutId(planDayId: upperB), isNull);
    });

    test('goes back to null once the session is finished', () async {
      final started = await repository.openOrStartWorkout(planDayId: lowerA);
      await repository.finishWorkout(started);

      expect(await repository.openWorkoutId(planDayId: lowerA), isNull);
    });
  });

  group('set indexing', () {
    test('numbers sets from one, in order', () async {
      final workoutId = await repository.openOrStartWorkout(planDayId: lowerA);
      for (var i = 0; i < 3; i++) {
        await repository.logSet(
          workoutId: workoutId,
          exerciseId: exerciseId,
          reps: 8,
          weightKg: 60,
        );
      }

      final sets = await allSets(db);
      expect(sets.map((s) => s.setIndex), [1, 2, 3]);
    });

    test('does not reuse an index after a middle set is deleted', () async {
      final workoutId = await repository.openOrStartWorkout(planDayId: lowerA);
      for (var i = 0; i < 3; i++) {
        await repository.logSet(
          workoutId: workoutId,
          exerciseId: exerciseId,
          reps: 8,
          weightKg: 60,
        );
      }

      // Delete set 2. A count-based next index would now hand out 3 again and
      // collide with the set that is still there.
      final logged = await allSets(db);
      final middle = logged.firstWhere((s) => s.setIndex == 2);
      await repository.deleteSet(middle.id);

      await repository.logSet(
        workoutId: workoutId,
        exerciseId: exerciseId,
        reps: 8,
        weightKg: 60,
      );

      final indexes = (await allSets(db)).map((s) => s.setIndex).toList()
        ..sort();
      expect(indexes, [1, 3, 4]);
      expect(indexes.toSet(), hasLength(indexes.length));
    });

    test('counts indexes per exercise, not per workout', () async {
      final workoutId = await repository.openOrStartWorkout(planDayId: lowerA);
      final exercises = await db.planDao.allExercises();
      final other = exercises[1].id;

      await repository.logSet(
        workoutId: workoutId,
        exerciseId: exerciseId,
        reps: 8,
      );
      await repository.logSet(workoutId: workoutId, exerciseId: other, reps: 8);

      final sets = await allSets(db);
      expect(sets.map((s) => s.setIndex), [1, 1]);
    });

    test(
      'counts indexes per workout, not across the exercise history',
      () async {
        final first = await repository.openOrStartWorkout(
          planDayId: lowerA,
          now: DateTime(2026, 8, 10, 18),
        );
        await repository.logSet(
          workoutId: first,
          exerciseId: exerciseId,
          reps: 8,
        );

        final second = await repository.openOrStartWorkout(
          planDayId: lowerA,
          now: DateTime(2026, 8, 17, 18),
        );
        await repository.logSet(
          workoutId: second,
          exerciseId: exerciseId,
          reps: 8,
        );

        final sets = await allSets(db);
        expect(sets.map((s) => s.setIndex), [1, 1]);
      },
    );
  });
}
