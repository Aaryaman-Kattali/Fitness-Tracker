import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/tables/training_tables.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';

part 'plan_dao.g.dart';

/// A plan item joined to the exercise it prescribes, if any.
class PlanItemWithExercise {
  const PlanItemWithExercise(this.item, this.exercise);

  final PlanItem item;

  /// Null for warm-up checklists.
  final Exercise? exercise;
}

/// Reads the training plan. The plan is seeded, not user-edited, in M2.
@DriftAccessor(tables: [PlanDays, PlanItems, Exercises])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.attachedDatabase);

  Future<List<PlanDay>> allDays() => (select(
    planDays,
  )..orderBy([(d) => OrderingTerm.asc(d.orderIndex)])).get();

  Future<PlanDay?> dayByKey(PlanDayKey key) => (select(
    planDays,
  )..where((d) => d.dayKey.equalsValue(key))).getSingleOrNull();

  Future<PlanDay?> dayById(int id) =>
      (select(planDays)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// Items of a session in prescribed order.
  ///
  /// Order is insertion order — the seed writes each session's items in the
  /// order the training plan lists them, and nothing reorders them in M2.
  Future<List<PlanItemWithExercise>> itemsForDay(int planDayId) async {
    final query =
        select(planItems).join([
            leftOuterJoin(
              exercises,
              exercises.id.equalsExp(planItems.exerciseId),
            ),
          ])
          ..where(planItems.planDayId.equals(planDayId))
          ..orderBy([OrderingTerm.asc(planItems.id)]);

    final rows = await query.get();
    return rows
        .map(
          (row) => PlanItemWithExercise(
            row.readTable(planItems),
            row.readTableOrNull(exercises),
          ),
        )
        .toList();
  }

  Future<Exercise?> exerciseById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<Exercise>> allExercises() =>
      (select(exercises)..orderBy([(e) => OrderingTerm.asc(e.name)])).get();
}
