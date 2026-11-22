import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/core/weekday_session.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('without an override', () {
    const clock = EffectiveClock(null);

    test('today() is midnight on the real date', () {
      final today = clock.today();
      final now = DateTime.now();

      expect(today, DateTime(now.year, now.month, now.day));
    });
  });

  group('with an override', () {
    // 2026-08-14 is a Friday — Lower B.
    final clock = EffectiveClock(DateTime(2026, 8, 14));

    test('moves the date but keeps the real time of day', () {
      final now = clock.now();
      final actual = DateTime.now();

      expect(clock.isOverridden, isTrue);
      expect((now.year, now.month, now.day), (2026, 8, 14));
      expect((now.hour, now.minute), (actual.hour, actual.minute));
    });

    test('is what the weekday resolver then sees', () {
      expect(sessionForDate(clock.now()), PlanDayKey.lowerB);
    });

    test('today() is midnight on the overridden date', () {
      expect(clock.today(), DateTime(2026, 8, 14));
    });

    test('ignores any time of day given to it', () {
      final withTime = EffectiveClock(DateTime(2026, 8, 14, 23, 45));

      expect(withTime.today(), DateTime(2026, 8, 14));
    });
  });
}
