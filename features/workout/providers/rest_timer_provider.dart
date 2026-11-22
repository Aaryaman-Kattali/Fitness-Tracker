import 'dart:async';

import 'package:fitness_tracker/features/workout/services/rest_alerts.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rest_timer_provider.g.dart';

/// State of the between-sets rest timer.
///
/// The rest is defined by [deadline] — a wall-clock instant — and [remaining]
/// is only ever a rendering of it. A counter decremented once per tick drifts:
/// timers fire late under load and are throttled outright while the app is
/// backgrounded, so a three-minute rest spent with the phone in a pocket would
/// come back reading well over three minutes.
@immutable
class RestTimerState {
  const RestTimerState({
    required this.total,
    required this.remaining,
    required this.isRunning,
    this.deadline,
    this.exerciseName,
  });

  const RestTimerState.idle()
    : total = Duration.zero,
      remaining = Duration.zero,
      isRunning = false,
      deadline = null,
      exerciseName = null;

  final Duration total;

  /// What the timer shows, rounded up to whole seconds.
  final Duration remaining;

  final bool isRunning;

  /// When the rest ends. Null only on [RestTimerState.idle] — every other
  /// state this class can reach was produced by [RestTimer.start] or
  /// [RestTimer._restartFrom], and both always set one.
  ///
  /// It used to read "null while paused, finished or idle". Pause was deleted
  /// in the August 2026 audit and finished keeps its deadline in the past, so
  /// two of those three states have no producer; [remainingAt]'s null branch
  /// is therefore the idle case alone and not a third behaviour.
  final DateTime? deadline;

  /// Which exercise the rest belongs to, shown on the timer bar.
  final String? exerciseName;

  /// True once a timer has been started and not dismissed.
  bool get isActive => total > Duration.zero;

  bool get isFinished => isActive && remaining <= Duration.zero;

  /// What the timer should read at [now].
  ///
  /// Rounded up so a three-minute rest reads 3:00 for its first second rather
  /// than flicking to 2:59 the instant it starts.
  Duration remainingAt(DateTime now) {
    final at = deadline;
    if (at == null) return remaining;

    final left = at.difference(now);
    if (left <= Duration.zero) return Duration.zero;
    return Duration(seconds: (left.inMilliseconds / 1000).ceil());
  }

  /// 0.0 at the start of the rest, 1.0 when it elapses.
  double get progress {
    if (total.inMilliseconds == 0) return 0;
    final elapsed = total.inMilliseconds - remaining.inMilliseconds;
    return (elapsed / total.inMilliseconds).clamp(0.0, 1.0);
  }

  RestTimerState copyWith({
    Duration? total,
    Duration? remaining,
    bool? isRunning,
    DateTime? deadline,
    String? exerciseName,
    bool clearDeadline = false,
  }) => RestTimerState(
    total: total ?? this.total,
    remaining: remaining ?? this.remaining,
    isRunning: isRunning ?? this.isRunning,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    exerciseName: exerciseName ?? this.exerciseName,
  );
}

/// The rest timer, started automatically whenever a set is saved.
///
/// Kept alive above the screen so navigating between exercises — or back to
/// the session list — does not reset a rest that is already running.
@Riverpod(keepAlive: true)
class RestTimer extends _$RestTimer {
  Timer? _ticker;

  /// Faster than the one-second display step: every tick recomputes from the
  /// clock, so a short period keeps the seconds digit turning over close to
  /// when it should without the state changing more often than the text does.
  static const _tickInterval = Duration(milliseconds: 200);

  @override
  RestTimerState build() {
    ref.onDispose(_stopTicking);
    return const RestTimerState.idle();
  }

  RestAlerts get _alerts => ref.read(restAlertsProvider);

  /// Starts (or restarts) a rest of [duration].
  void start(Duration duration, {String? exerciseName}) {
    if (duration <= Duration.zero) return;

    final deadline = DateTime.now().add(duration);
    state = RestTimerState(
      total: duration,
      remaining: duration,
      isRunning: true,
      deadline: deadline,
      exerciseName: exerciseName,
    );
    _startTicking();
    unawaited(
      _alerts.scheduleRestOver(deadline: deadline, exerciseName: exerciseName),
    );
  }

  /// Recomputes against the wall clock.
  ///
  /// Called when the app comes back to the foreground: the ticker may have
  /// been throttled or stopped entirely while backgrounded, and the timer has
  /// to be correct in the frame the user sees, not one tick later.
  void sync() {
    if (state.isRunning) _tick();
  }

  /// Adds time without disturbing the elapsed count — the "+30s" button.
  void extend(Duration extra) {
    if (!state.isActive) return;
    state = state.copyWith(total: state.total + extra);
    _restartFrom(state.remainingAt(DateTime.now()) + extra);
  }

  void dismiss() {
    _stopTicking();
    state = const RestTimerState.idle();
    unawaited(_alerts.cancelRestOver());
  }

  /// Puts the deadline [remaining] from now and runs from there.
  void _restartFrom(Duration remaining) {
    final deadline = DateTime.now().add(remaining);
    state = state.copyWith(
      remaining: remaining,
      isRunning: true,
      deadline: deadline,
    );
    _startTicking();
    unawaited(
      _alerts.scheduleRestOver(
        deadline: deadline,
        exerciseName: state.exerciseName,
      ),
    );
  }

  void _startTicking() {
    _stopTicking();
    _ticker = Timer.periodic(_tickInterval, (_) => _tick());
  }

  void _stopTicking() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    final remaining = state.remainingAt(DateTime.now());

    if (remaining <= Duration.zero) {
      _stopTicking();
      state = state.copyWith(
        remaining: Duration.zero,
        isRunning: false,
        clearDeadline: true,
      );
      unawaited(_alerts.ringRestOver());
      return;
    }

    // Only publish when the displayed second actually changes.
    if (remaining != state.remaining) {
      state = state.copyWith(remaining: remaining);
    }
  }
}
