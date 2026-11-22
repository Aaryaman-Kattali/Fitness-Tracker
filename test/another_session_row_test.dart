import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/today/providers/steps_providers.dart';
import 'package:fitness_tracker/features/today/providers/today_providers.dart';
import 'package:fitness_tracker/features/today/today_screen.dart';
import 'package:fitness_tracker/features/today/widgets/another_session_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_health_repository.dart';
import 'support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeHealthRepository health;

  setUp(() {
    db = openTestDatabase();
    health = FakeHealthRepository()
      ..availabilityResult = HealthAvailability.unsupported;
  });

  Widget wrap(Widget child, DateTime today) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      healthRepositoryProvider.overrideWithValue(health),
      todayDateProvider.overrideWithValue(today),
      todayActivityProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: CupertinoApp(home: CupertinoPageScaffold(child: child)),
  );

  /// The Today screen animates a loading indicator forever, so it can never be
  /// settled — pump a fixed number of frames instead.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// A viewport tall enough for the whole screen.
  ///
  /// The row sits below a full session's plan items, and a sliver that is off
  /// the bottom of an 800×600 test surface is never built — the finder would
  /// fail for a reason that has nothing to do with the row.
  void useTallViewport(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1000, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('AnotherSessionRow', () {
    // Days chosen to be rest and lifting under both the old and the new
    // weekday mapping, so this test is not asserting the schedule.
    final restDay = DateTime(2026, 8, 23); // Sunday
    final liftingDay = DateTime(2026, 8, 21); // Friday

    testWidgets('is offered on a rest day, where nothing else can be logged', (
      tester,
    ) async {
      useTallViewport(tester);
      await tester.pumpWidget(wrap(const TodayScreen(), restDay));
      await pumpFrames(tester);

      expect(find.text('No lifting today'), findsOneWidget);
      expect(find.byType(AnotherSessionRow), findsOneWidget);
      expect(find.text('Start another session'), findsOneWidget);
    });

    testWidgets('is offered on a lifting day too, for a shifted session', (
      tester,
    ) async {
      useTallViewport(tester);
      await tester.pumpWidget(wrap(const TodayScreen(), liftingDay));
      await pumpFrames(tester);

      expect(find.text('Start session'), findsOneWidget);
      expect(find.text('Start another session'), findsOneWidget);
    });

    testWidgets('lists every plan day, not just the four weekdays', (
      tester,
    ) async {
      useTallViewport(tester);
      await tester.pumpWidget(wrap(const TodayScreen(), restDay));
      await pumpFrames(tester);

      await tester.tap(find.text('Start another session'));
      await pumpFrames(tester);

      final days = await db.planDao.allDays();
      expect(days, hasLength(PlanDayKey.values.length));
      for (final day in days) {
        expect(
          find.text(day.name),
          findsOneWidget,
          reason: '${day.dayKey.shortLabel} must be startable on any day',
        );
      }
    });
  });
}
