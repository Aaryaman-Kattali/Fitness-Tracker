import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/tables/activity_tables.dart';

part 'steps_dao.g.dart';

/// Reads and writes the daily step/active-energy totals.
///
/// [DailySteps] is keyed on the date alone, so a day has exactly one row and
/// re-syncing the same day overwrites rather than accumulating. Every write
/// here goes through `insertOrReplace` for that reason; there is no plain
/// insert on this DAO by design.
@DriftAccessor(tables: [DailySteps])
class StepsDao extends DatabaseAccessor<AppDatabase> with _$StepsDaoMixin {
  StepsDao(super.attachedDatabase);

  /// Midnight on [date], which is the value the primary key is keyed on.
  ///
  /// Health Connect reports totals for a local calendar day, so the key has to
  /// be the local date with the time stripped — storing an arbitrary instant
  /// would let the same day land under two different keys.
  static DateTime dayKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<DailyStep?> forDate(DateTime date) => (select(
    dailySteps,
  )..where((s) => s.date.equals(dayKey(date)))).getSingleOrNull();

  Stream<DailyStep?> watchDate(DateTime date) => (select(
    dailySteps,
  )..where((s) => s.date.equals(dayKey(date)))).watchSingleOrNull();

  /// Writes each day's totals, replacing whatever was there.
  Future<void> upsertAll(Iterable<DailyStepsCompanion> rows) => batch(
    (b) => b.insertAll(dailySteps, rows, mode: InsertMode.insertOrReplace),
  );
}
