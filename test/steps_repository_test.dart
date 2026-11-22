import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/repositories/steps_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_health_repository.dart';
import 'support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeHealthRepository health;
  late StepsRepository repository;

  final today = DateTime(2026, 8, 18);

  /// Every stored row, to prove a day never lands twice.
  Future<List<DailyStep>> allDailySteps() => db.select(db.dailySteps).get();

  setUp(() {
    db = openTestDatabase();
    health = FakeHealthRepository();
    repository = StepsRepository(health: health, dao: db.stepsDao);
  });

  group('syncToday', () {
    test('stores the platform total for today', () async {
      health.setDay(today, steps: 6231, activeKcal: 289.5);

      expect(await repository.syncToday(today: today), StepsSyncOutcome.synced);

      final stored = await repository.forDate(today);
      expect(stored!.steps, 6231);
      expect(stored.activeKcal, 289.5);
      expect(stored.source, ActivitySource.healthConnect);
      expect(
        stored.date,
        today,
        reason: 'the row must be keyed on midnight, not on the sync time',
      );
    });

    test(
      're-syncing the same day replaces the row rather than adding one',
      () async {
        health.setDay(today, steps: 2000);
        await repository.syncToday(today: today);

        // The step count only ever goes up during a day; the second sync is the
        // one that has to win.
        health.setDay(today, steps: 9000);
        await repository.syncToday(today: today);

        expect((await repository.forDate(today))!.steps, 9000);
        expect(
          await allDailySteps(),
          hasLength(1),
          reason:
              'date is the primary key — a day must never fork into two rows',
        );
      },
    );

    test(
      'a sync at a different clock time still lands on the same row',
      () async {
        health.setDay(today, steps: 1200);
        await repository.syncToday(today: today);

        health.setDay(today, steps: 4400);
        await repository.syncToday(today: DateTime(2026, 8, 18, 21, 47, 13));

        expect(await allDailySteps(), hasLength(1));
        expect((await repository.forDate(today))!.steps, 4400);
      },
    );

    test('reports noData when the platform has nothing for today', () async {
      expect(await repository.syncToday(today: today), StepsSyncOutcome.noData);
      expect(
        await repository.forDate(today),
        isNull,
        reason: 'no data is an absent row, not a zero one',
      );
    });

    test(
      'reports unavailable and writes nothing when there is no provider',
      () async {
        health
          ..availabilityResult = HealthAvailability.notInstalled
          ..setDay(today, steps: 500);

        expect(
          await repository.syncToday(today: today),
          StepsSyncOutcome.unavailable,
        );
        expect(await allDailySteps(), isEmpty);
      },
    );

    test('notices a permission revoked since the last sync', () async {
      health.setDay(today, steps: 3000);
      expect(await repository.syncToday(today: today), StepsSyncOutcome.synced);

      // Revoked from the Health Connect app, with no callback to the app.
      health.permissionResult = HealthPermissionStatus.denied;

      expect(
        await repository.syncToday(today: today),
        StepsSyncOutcome.permissionDenied,
      );
      expect(
        (await repository.forDate(today))!.steps,
        3000,
        reason: 'the last known total stays readable after a revocation',
      );
    });
  });

  group('watchDate', () {
    test('emits the stored total and then every update', () async {
      final seen = <int?>[];
      final subscription = repository
          .watchDate(today)
          .listen((activity) => seen.add(activity?.steps));

      await pumpEventQueue();
      health.setDay(today, steps: 1500);
      await repository.syncToday(today: today);
      await pumpEventQueue();

      await subscription.cancel();
      expect(seen.first, isNull, reason: 'nothing stored for today yet');
      expect(seen.last, 1500);
    });
  });
}
