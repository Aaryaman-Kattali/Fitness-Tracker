import 'package:fitness_tracker/core/weekday_session.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sessionForWeekday', () {
    test('maps each lifting day to its session', () {
      expect(sessionForWeekday(DateTime.tuesday), PlanDayKey.lowerA);
      expect(sessionForWeekday(DateTime.wednesday), PlanDayKey.upperA);
      expect(sessionForWeekday(DateTime.friday), PlanDayKey.lowerB);
      expect(sessionForWeekday(DateTime.saturday), PlanDayKey.upperB);
    });

    test('returns null on the closed day and the two cardio days', () {
      expect(sessionForWeekday(DateTime.monday), isNull);
      expect(sessionForWeekday(DateTime.thursday), isNull);
      expect(sessionForWeekday(DateTime.sunday), isNull);
    });

    test('covers all four sessions exactly once across a week', () {
      final resolved = [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          sessionForWeekday(day),
      ].nonNulls.toList();

      expect(resolved, hasLength(4));
      expect(resolved.toSet(), PlanDayKey.values.toSet());
    });

    test(
      'runs the sessions as two pairs, never three lifting days in a row',
      () {
        // The pairing is the point of the shift: Lower A then Upper A, a rest,
        // then Lower B then Upper B. A third consecutive lifting day would mean
        // the mapping had been mis-shifted.
        var run = 0;
        var longestRun = 0;
        for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
          run = sessionForWeekday(day) == null ? 0 : run + 1;
          if (run > longestRun) longestRun = run;
        }
        expect(longestRun, 2);
      },
    );
  });

  group('sessionForDate', () {
    test('resolves a concrete date through its weekday', () {
      // 2026-08-17 is a Monday.
      expect(sessionForDate(DateTime(2026, 8, 17)), isNull);
      expect(sessionForDate(DateTime(2026, 8, 18)), PlanDayKey.lowerA);
      expect(sessionForDate(DateTime(2026, 8, 19)), PlanDayKey.upperA);
      expect(sessionForDate(DateTime(2026, 8, 20)), isNull);
      expect(sessionForDate(DateTime(2026, 8, 21)), PlanDayKey.lowerB);
      expect(sessionForDate(DateTime(2026, 8, 22)), PlanDayKey.upperB);
      expect(sessionForDate(DateTime(2026, 8, 23)), isNull);
    });

    test('ignores the time of day', () {
      expect(
        sessionForDate(DateTime(2026, 8, 18, 23, 59)),
        PlanDayKey.lowerA,
      );
    });
  });

  group('restDayLabelForWeekday', () {
    test('names the prescribed non-lifting work', () {
      expect(restDayLabelForWeekday(DateTime.thursday), 'Cardio + Daily 15');
      expect(restDayLabelForWeekday(DateTime.sunday), 'Cardio + Daily 15');
      expect(
        restDayLabelForWeekday(DateTime.monday),
        'Daily 15 only — the gym is shut',
      );
    });

    test('has a label for every non-lifting day, none of them empty', () {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        if (sessionForWeekday(day) != null) continue;
        expect(restDayLabelForWeekday(day), isNotEmpty);
      }
    });
  });
}
