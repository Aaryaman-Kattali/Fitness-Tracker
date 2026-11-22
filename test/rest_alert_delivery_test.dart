import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/features/workout/providers/rest_timer_provider.dart';
import 'package:fitness_tracker/features/workout/services/rest_alerts.dart';
import 'package:fitness_tracker/features/workout/widgets/rest_timer_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// C-2's degraded states, on screen.
///
/// The phone is in a pocket between sets, so an alert that will not arrive —
/// or will arrive minutes late — is the whole feature failing. Both states
/// were previously computed and never shown: `RestAlerts` picked
/// `inexactAllowWhileIdle` silently, and a failed `initialize()` made every
/// scheduling call a no-op with nothing on screen. CLAUDE.md §4's
/// platform-boundary exception requires a degradation to be visible.
///
/// Driven through provider overrides so there is no plugin and no OS here.
void main() {
  /// A timer stuck in one state, so this file tests the notice rather than
  /// the countdown. The real notifier starts a periodic ticker, which this
  /// has no use for.
  RestTimerState running() => RestTimerState(
    total: const Duration(minutes: 3),
    remaining: const Duration(minutes: 3),
    isRunning: true,
    deadline: DateTime(2026, 9, 18, 18, 30),
    exerciseName: 'Back squat',
  );

  Future<void> pumpBar(
    WidgetTester tester, {
    required RestAlertDelivery delivery,
    RestTimerState? state,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restAlertsProvider.overrideWithValue(_FixedDelivery(delivery)),
          restTimerProvider.overrideWith(
            () => _StubTimer(state ?? running()),
          ),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(child: RestTimerBar()),
        ),
      ),
    );
    await tester.pump();
  }

  Finder lateNotice() => find.textContaining('may arrive a few minutes late');
  Finder offNotice() => find.textContaining('only alert on screen');

  group('the rest timer bar says how the alert will arrive', () {
    testWidgets('says nothing at all when the alarm is exact', (tester) async {
      await pumpBar(tester, delivery: RestAlertDelivery.exact);

      // The healthy case pays no height and no words for this.
      expect(lateNotice(), findsNothing);
      expect(offNotice(), findsNothing);
      expect(find.byType(Icon), findsOneWidget); // the dismiss button only
    });

    testWidgets('warns that an inexact alarm may be late', (tester) async {
      await pumpBar(tester, delivery: RestAlertDelivery.inexact);

      expect(lateNotice(), findsOneWidget);
      expect(offNotice(), findsNothing);
      expect(
        tester.widget<Text>(lateNotice()).style?.color,
        AppColors.warning,
        reason: 'a caution that degrades the feature rather than breaking it',
      );
    });

    testWidgets('says the alert will not arrive at all when it will not', (
      tester,
    ) async {
      await pumpBar(tester, delivery: RestAlertDelivery.unavailable);

      expect(offNotice(), findsOneWidget);
      expect(lateNotice(), findsNothing);
      expect(
        tester.widget<Text>(offNotice()).style?.color,
        AppColors.danger,
        reason: 'no notification is a failure, not a caution',
      );
    });

    testWidgets('the two degraded states do not render the same thing', (
      tester,
    ) async {
      // The state that must not collapse: "late" and "never" are different
      // instructions to the person in the gym. U-10 — colour alone must not
      // carry a distinction — so they differ in WORDS and in ICON, and the
      // tint only reinforces it.
      await pumpBar(tester, delivery: RestAlertDelivery.inexact);
      final lateIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((icon) => icon.icon)
          .toList();

      await pumpBar(tester, delivery: RestAlertDelivery.unavailable);
      final offIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((icon) => icon.icon)
          .toList();

      expect(lateIcons, isNot(offIcons));
    });

    testWidgets('is not shown when no rest is running', (tester) async {
      // The whole bar collapses on an idle timer, so a permanently-degraded
      // phone does not carry a permanent warning on every screen.
      await pumpBar(
        tester,
        delivery: RestAlertDelivery.unavailable,
        state: const RestTimerState.idle(),
      );

      expect(offNotice(), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('RestAlerts.delivery', () {
    test('reads unavailable until initialize has succeeded', () {
      // The real object, uninitialised — which is exactly the state a failed
      // initialize() leaves behind, and the one that used to be silent.
      expect(
        RestAlerts(FlutterLocalNotificationsPlugin()).delivery,
        RestAlertDelivery.unavailable,
      );
    });
  });
}

class _FixedDelivery extends RestAlerts {
  _FixedDelivery(this._delivery) : super(FlutterLocalNotificationsPlugin());

  final RestAlertDelivery _delivery;

  @override
  RestAlertDelivery get delivery => _delivery;
}

class _StubTimer extends RestTimer {
  _StubTimer(this._state);

  final RestTimerState _state;

  @override
  RestTimerState build() => _state;
}
