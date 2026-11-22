import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/today/providers/steps_providers.dart';
import 'package:fitness_tracker/features/today/providers/today_providers.dart';
import 'package:fitness_tracker/features/today/today_screen.dart';
import 'package:fitness_tracker/features/today/widgets/steps_card.dart';
import 'package:fitness_tracker/features/today/widgets/steps_ring.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_health_repository.dart';
import 'support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeHealthRepository health;

  // A Tuesday, so the Today screen has a lifting session to render too.
  final today = DateTime(2026, 8, 18);

  setUp(() {
    db = openTestDatabase();
    health = FakeHealthRepository();
  });

  /// The drift-backed stream is overridden with a plain value here.
  ///
  /// Not to avoid the database — [appDatabaseProvider] is still the real one —
  /// but because a drift query stream cancelled during ProviderScope disposal
  /// schedules a zero-duration timer that flutter_test then reports as a
  /// pending timer after the tree is gone. What these tests are actually about
  /// is which state the card renders; the stream wiring is covered against a
  /// real database in steps_repository_test.dart.
  Widget wrap(Widget child, {DailyActivity? activity}) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      healthRepositoryProvider.overrideWithValue(health),
      todayDateProvider.overrideWithValue(today),
      todayActivityProvider.overrideWith((ref) => Stream.value(activity)),
    ],
    child: CupertinoApp(home: CupertinoPageScaffold(child: child)),
  );

  /// Pumps a fixed number of frames instead of settling.
  ///
  /// [WidgetTester.pumpAndSettle] cannot be used on the Today screen: it
  /// renders a CupertinoActivityIndicator while the session loads, and an
  /// indicator animates forever, so settling never completes.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  DailyActivity activityFor(int steps, {double kcal = 0}) => DailyActivity(
    date: today,
    steps: steps,
    activeKcal: kcal,
    source: ActivitySource.healthConnect,
  );

  group('StepsCard', () {
    testWidgets('draws the ring and the totals once a day is stored', (
      tester,
    ) async {
      health.setDay(today, steps: 6231, activeKcal: 289);

      await tester.pumpWidget(
        wrap(const StepsCard(), activity: activityFor(6231, kcal: 289)),
      );
      await pumpFrames(tester);

      expect(find.byType(StepsRing), findsOneWidget);
      expect(find.text('6,231 of 8,000'), findsOneWidget);
      expect(find.text('289 kcal active'), findsOneWidget);
    });

    testWidgets('offers the Play Store when Health Connect is missing', (
      tester,
    ) async {
      health.availabilityResult = HealthAvailability.notInstalled;

      await tester.pumpWidget(wrap(const StepsCard()));
      await pumpFrames(tester);

      expect(find.text('Health Connect not installed'), findsOneWidget);

      await tester.tap(find.text('Get Health Connect'));
      await pumpFrames(tester);
      expect(health.installPrompts, 1);
    });

    testWidgets('offers an inline re-request when permission is refused', (
      tester,
    ) async {
      health
        ..permissionResult = HealthPermissionStatus.denied
        ..grantOnRequest = false
        ..setDay(today, steps: 4000);

      await tester.pumpWidget(
        wrap(const StepsCard(), activity: activityFor(4000)),
      );
      await pumpFrames(tester);

      expect(find.text('Steps not connected'), findsOneWidget);

      // Refused again: the offer has to stay, or it can never be turned on.
      await tester.tap(find.text('Allow access'));
      await pumpFrames(tester);
      expect(health.permissionRequests, 1);
      expect(find.text('Allow access'), findsOneWidget);

      // And it takes effect when the answer finally changes.
      health.grantOnRequest = true;
      await tester.tap(find.text('Allow access'));
      await pumpFrames(tester);
      expect(find.byType(StepsRing), findsOneWidget);
    });

    testWidgets('offers the grant back when it is revoked externally', (
      tester,
    ) async {
      // Revoked from the Health Connect app, which the app is never told
      // about — the next status read is the only way it finds out.
      health.permissionResult = HealthPermissionStatus.denied;

      await tester.pumpWidget(
        wrap(const StepsCard(), activity: activityFor(5100)),
      );
      await pumpFrames(tester);

      expect(
        find.text('Steps not connected'),
        findsOneWidget,
        reason: 'a revoked grant is offered back, not silently ignored',
      );
    });

    testWidgets('says so plainly when the day has no data', (tester) async {
      await tester.pumpWidget(wrap(const StepsCard()));
      await pumpFrames(tester);

      expect(find.text('No steps yet today'), findsOneWidget);
      expect(find.byType(StepsRing), findsNothing);
    });

    testWidgets('mutes the ring when the total could not be refreshed', (
      tester,
    ) async {
      // Permission and provider are fine, but the platform returned nothing
      // for today, so the stored figure is the last known one.
      await tester.pumpWidget(
        wrap(const StepsCard(), activity: activityFor(5100)),
      );
      await pumpFrames(tester);

      expect(
        find.text('Last known total — could not refresh.'),
        findsOneWidget,
      );
      expect(
        tester.widget<StepsRing>(find.byType(StepsRing)).isMuted,
        isTrue,
      );
    });
  });

  group('TodayScreen', () {
    testWidgets('renders in full with Health Connect unavailable', (
      tester,
    ) async {
      // The emulator case: no provider, every plugin call failing.
      health.availabilityResult = HealthAvailability.unsupported;

      await tester.pumpWidget(wrap(const TodayScreen()));
      await pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Start session'), findsOneWidget);
      expect(find.text('Steps unavailable'), findsOneWidget);
    });

    testWidgets('does not wait on the steps check to render the session', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const TodayScreen()));
      // A single frame, deliberately not pumped further: the steps providers
      // are still in flight here.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byType(StepsRing),
        findsNothing,
        reason: 'the ring takes no space until it has something to say',
      );
    });
  });
}
