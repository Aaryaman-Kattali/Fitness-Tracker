import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'effective_clock.g.dart';

/// The clock the app reasons about "today" with.
///
/// Only the *date* can be overridden, never the time of day: the weekday is
/// what selects the session, and a rest timer or a set's timestamp still has
/// to run on the real clock to mean anything.
@immutable
class EffectiveClock {
  const EffectiveClock(this.overrideDate);

  /// The date standing in for today, or null when the real one is in use.
  final DateTime? overrideDate;

  bool get isOverridden => overrideDate != null;

  /// Now, on the effective date.
  DateTime now() {
    final date = overrideDate;
    final actual = DateTime.now();
    if (date == null) return actual;

    return DateTime(
      date.year,
      date.month,
      date.day,
      actual.hour,
      actual.minute,
      actual.second,
      actual.millisecond,
    );
  }

  /// Midnight on the effective date.
  DateTime today() {
    final at = now();
    return DateTime(at.year, at.month, at.day);
  }
}

/// The debug-only date override.
///
/// Testing a Saturday session by changing the phone's date is miserable and
/// drags every other app's notion of time with it, so the override lives here
/// instead. [setDate] is inert outside a debug build, which — together with
/// the `kDebugMode` guard on the Settings UI — is what keeps it from shipping.
@Riverpod(keepAlive: true)
class DateOverride extends _$DateOverride {
  @override
  DateTime? build() => null;

  void setDate(DateTime? date) {
    if (!kDebugMode) return;
    state = date == null ? null : DateTime(date.year, date.month, date.day);
  }

  void clear() => setDate(null);
}

@Riverpod(keepAlive: true)
EffectiveClock effectiveClock(Ref ref) =>
    EffectiveClock(ref.watch(dateOverrideProvider));
