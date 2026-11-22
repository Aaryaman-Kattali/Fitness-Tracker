import 'package:fitness_tracker/features/workout/providers/rest_timer_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final startedAt = DateTime(2026, 8, 14, 18, 30);

  RestTimerState running(Duration total) => RestTimerState(
    total: total,
    remaining: total,
    isRunning: true,
    deadline: startedAt.add(total),
  );

  group('remainingAt', () {
    test('is derived from the deadline, not from elapsed ticks', () {
      final state = running(const Duration(minutes: 3));

      // No ticks have run at all; the answer still has to be right.
      expect(
        state.remainingAt(startedAt.add(const Duration(seconds: 100))),
        const Duration(seconds: 80),
      );
    });

    test('survives a gap with no ticks, as backgrounding produces', () {
      final state = running(const Duration(minutes: 3));

      // A counter decremented once per tick would still read close to 3:00
      // here, because it never got the ticks.
      expect(
        state.remainingAt(
          startedAt.add(const Duration(minutes: 2, seconds: 30)),
        ),
        const Duration(seconds: 30),
      );
    });

    test('rounds up so a fresh rest reads its full length', () {
      final state = running(const Duration(minutes: 3));

      expect(state.remainingAt(startedAt), const Duration(minutes: 3));
      expect(
        state.remainingAt(startedAt.add(const Duration(milliseconds: 1))),
        const Duration(minutes: 3),
      );
      expect(
        state.remainingAt(startedAt.add(const Duration(milliseconds: 1001))),
        const Duration(seconds: 179),
      );
    });

    test('floors at zero once the deadline has passed', () {
      final state = running(const Duration(minutes: 3));

      expect(
        state.remainingAt(startedAt.add(const Duration(hours: 2))),
        Duration.zero,
      );
    });
  });

  group('progress', () {
    test('runs from zero to one across the rest', () {
      const total = Duration(minutes: 3);

      expect(running(total).progress, 0);
      expect(
        running(
          total,
        ).copyWith(remaining: const Duration(seconds: 90)).progress,
        0.5,
      );
      expect(
        running(total).copyWith(remaining: Duration.zero).progress,
        1.0,
      );
    });

    test('is zero on an idle timer rather than dividing by nothing', () {
      expect(const RestTimerState.idle().progress, 0);
    });
  });

  group('copyWith', () {
    test('clears the deadline only when asked', () {
      final state = running(const Duration(minutes: 3));

      expect(state.copyWith(isRunning: false).deadline, state.deadline);
      expect(state.copyWith(clearDeadline: true).deadline, isNull);
    });
  });

  group('lifecycle flags', () {
    test('an idle timer is neither active nor finished', () {
      const idle = RestTimerState.idle();

      expect(idle.isActive, isFalse);
      expect(idle.isFinished, isFalse);
    });

    test('a run-out timer is active and finished', () {
      final finished = running(const Duration(minutes: 3)).copyWith(
        remaining: Duration.zero,
        isRunning: false,
        clearDeadline: true,
      );

      expect(finished.isActive, isTrue);
      expect(finished.isFinished, isTrue);
    });
  });
}
