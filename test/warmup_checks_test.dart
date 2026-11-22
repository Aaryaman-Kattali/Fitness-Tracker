import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/today/widgets/warmup_checklist.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

void main() {
  group('checklistLines', () {
    test('keeps one entry per prescription, trimmed', () {
      expect(
        checklistLines(
          'Band pull-aparts — 2 × 20\n'
          '  Doorway pec stretch — 30 sec/side  \n'
          'Cable face pull, very light — 2 × 15',
        ),
        [
          'Band pull-aparts — 2 × 20',
          'Doorway pec stretch — 30 sec/side',
          'Cable face pull, very light — 2 × 15',
        ],
      );
    });

    test('drops blank lines, so indexes stay stable', () {
      // The stored lineIndex is a position in this list; a blank line that
      // counted would shift every tick below it onto the wrong prescription.
      expect(checklistLines('First\n\n  \nSecond'), ['First', 'Second']);
      expect(checklistLines(''), isEmpty);
    });
  });

  group('warm-up checks', () {
    late AppDatabase db;
    late WorkoutRepository repository;
    late int lowerA;
    late int planItemId;
    late int otherItemId;

    setUp(() async {
      db = openTestDatabase();
      repository = workoutRepositoryFor(db);
      lowerA = await planDayIdFor(db, PlanDayKey.lowerA);

      final items = await db.planDao.itemsForDay(lowerA);
      final warmups = items
          .where((row) => row.item.block == TrainingBlock.warmup)
          .toList();
      planItemId = warmups.first.item.id;
      otherItemId = items.last.item.id;
    });

    test('ticking records the line, unticking removes it', () async {
      final workoutId = await repository.openOrStartWorkout(planDayId: lowerA);
      const line = (planItemId: 0, lineIndex: 2);

      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: planItemId, lineIndex: line.lineIndex),
        isChecked: true,
      );
      expect(
        await repository.watchWarmupChecks(workoutId).first,
        {(planItemId: planItemId, lineIndex: 2)},
      );

      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: planItemId, lineIndex: 2),
        isChecked: false,
      );
      expect(await repository.watchWarmupChecks(workoutId).first, isEmpty);
    });

    test('ticking the same line twice does not throw or duplicate', () async {
      final workoutId = await repository.openOrStartWorkout(planDayId: lowerA);

      for (var i = 0; i < 2; i++) {
        await repository.setWarmupCheck(
          workoutId: workoutId,
          line: (planItemId: planItemId, lineIndex: 0),
          isChecked: true,
        );
      }

      expect(await repository.watchWarmupChecks(workoutId).first, hasLength(1));
    });

    test('keeps lines of the same item apart', () async {
      final workoutId = await repository.openOrStartWorkout(planDayId: lowerA);

      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: planItemId, lineIndex: 0),
        isChecked: true,
      );
      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: planItemId, lineIndex: 3),
        isChecked: true,
      );
      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: otherItemId, lineIndex: 0),
        isChecked: true,
      );

      // Unticking line 0 of one item must not disturb the other two.
      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: planItemId, lineIndex: 0),
        isChecked: false,
      );

      expect(await repository.watchWarmupChecks(workoutId).first, {
        (planItemId: planItemId, lineIndex: 3),
        (planItemId: otherItemId, lineIndex: 0),
      });
    });

    test('resets per workout rather than staying ticked', () async {
      final monday = await repository.openOrStartWorkout(
        planDayId: lowerA,
        now: DateTime(2026, 8, 10, 18),
      );
      await repository.setWarmupCheck(
        workoutId: monday,
        line: (planItemId: planItemId, lineIndex: 0),
        isChecked: true,
      );

      final nextMonday = await repository.openOrStartWorkout(
        planDayId: lowerA,
        now: DateTime(2026, 8, 17, 18),
      );

      expect(await repository.watchWarmupChecks(monday).first, hasLength(1));
      expect(
        await repository.watchWarmupChecks(nextMonday).first,
        isEmpty,
        reason: 'a new session starts from an unticked checklist',
      );
    });

    test('goes away with the workout it belonged to', () async {
      final workoutId = await repository.openOrStartWorkout(
        planDayId: lowerA,
        now: DateTime(2026, 8, 10, 18),
      );
      await repository.setWarmupCheck(
        workoutId: workoutId,
        line: (planItemId: planItemId, lineIndex: 0),
        isChecked: true,
      );

      // Deleting the workout must take its ticks with it rather than leaving
      // orphans behind — the cascade, and PRAGMA foreign_keys being on.
      await repository.deleteWorkout(workoutId);

      expect(await allWorkouts(db), isEmpty);
      expect(await db.select(db.warmupChecks).get(), isEmpty);
    });
  });
}
