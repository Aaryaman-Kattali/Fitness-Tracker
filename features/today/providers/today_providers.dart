import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/core/weekday_session.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_providers.g.dart';

/// The date the Today screen is rendering.
///
/// Goes through the effective clock so a debug date override moves the whole
/// screen — the session, the date line and any workout started from here — in
/// one step. Overridden in tests to pin a weekday.
@riverpod
DateTime todayDate(Ref ref) => ref.watch(effectiveClockProvider).now();

/// Today's lifting session, or null on cardio/rest days.
@riverpod
Future<SessionPlan?> todaySession(Ref ref) async {
  final key = sessionForDate(ref.watch(todayDateProvider));
  if (key == null) return null;
  return ref.watch(planRepositoryProvider).sessionForKey(key);
}

/// Label for a day with no lifting session.
@riverpod
String todayRestLabel(Ref ref) =>
    restDayLabelForWeekday(ref.watch(todayDateProvider).weekday);

/// Every plan day, for the "start another session" picker.
@riverpod
Future<List<({int id, PlanDayKey dayKey, String name})>> allPlanDays(Ref ref) =>
    ref.watch(planRepositoryProvider).allDays();

/// The workout already in progress for today's session, if any.
///
/// Read-only on purpose — merely rendering the Today screen must not create a
/// workout row. Autodisposed so that returning from a session re-runs it and
/// the button label stays honest.
@riverpod
Future<int?> openSessionId(Ref ref, int planDayId) => ref
    .watch(workoutRepositoryProvider)
    .openWorkoutId(planDayId: planDayId, now: ref.watch(todayDateProvider));
