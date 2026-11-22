import 'package:fitness_tracker/data/models/training_enums.dart';

/// Maps an ISO weekday (`DateTime.monday` == 1 … `DateTime.sunday` == 7) to the
/// lifting session scheduled for that day.
///
/// The gym is shut on Mondays, so the lifting week runs Tue–Wed, Fri–Sat with
/// cardio on Thursday and Sunday. Monday, Thursday and Sunday return `null` —
/// there is no lifting session to log.
///
/// This mapping is the *only* place the weekday lives: `PlanDays` stores a
/// `dayKey`, a name and an order, never a weekday, so moving the week needs no
/// migration and cannot leave an installed app on the old schedule.
///
/// It also only decides what Today *leads* with. Any plan day can be started
/// on any date from the Today screen's session picker.
PlanDayKey? sessionForWeekday(int weekday) => switch (weekday) {
  DateTime.tuesday => PlanDayKey.lowerA,
  DateTime.wednesday => PlanDayKey.upperA,
  DateTime.friday => PlanDayKey.lowerB,
  DateTime.saturday => PlanDayKey.upperB,
  _ => null,
};

/// Convenience wrapper around [sessionForWeekday] for a full [DateTime].
PlanDayKey? sessionForDate(DateTime date) => sessionForWeekday(date.weekday);

/// What the Today screen shows when there is no lifting session.
///
/// The training plan still prescribes work on these days, so the screen never
/// renders an empty state — it names the actual session instead.
String restDayLabelForWeekday(int weekday) => switch (weekday) {
  DateTime.thursday || DateTime.sunday => 'Cardio + Daily 15',
  DateTime.monday => 'Daily 15 only — the gym is shut',
  _ => 'Rest',
};
