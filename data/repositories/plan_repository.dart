import 'package:fitness_tracker/data/db/dao/plan_dao.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';

/// Reads the training plan and hands the UI [SessionPlan] domain objects.
class PlanRepository {
  const PlanRepository(this._dao);

  final PlanDao _dao;

  /// Every plan day, in prescribed order, without hydrating their items.
  ///
  /// The session picker needs names and ids only; hydrating four full sessions
  /// to render four rows would read every plan item for nothing.
  Future<List<({int id, PlanDayKey dayKey, String name})>> allDays() async {
    final days = await _dao.allDays();
    return [
      for (final day in days) (id: day.id, dayKey: day.dayKey, name: day.name),
    ];
  }

  Future<SessionPlan?> sessionForKey(PlanDayKey key) async {
    final day = await _dao.dayByKey(key);
    if (day == null) return null;
    return _hydrate(day.id, day.dayKey, day.name);
  }

  Future<SessionPlan?> sessionById(int planDayId) async {
    final day = await _dao.dayById(planDayId);
    if (day == null) return null;
    return _hydrate(day.id, day.dayKey, day.name);
  }

  Future<SessionPlan> _hydrate(int id, PlanDayKey key, String name) async {
    final rows = await _dao.itemsForDay(id);
    final items = <PlannedItem>[];

    // Order is the row order the DAO returns; the seed writes each session in
    // the order the training plan prescribes.
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final exercise = row.exercise;
      items.add(
        PlannedItem(
          id: row.item.id,
          block: row.item.block,
          orderIndex: index,
          exercise: exercise == null
              ? null
              : PlannedExercise(
                  id: exercise.id,
                  name: exercise.name,
                  pattern: exercise.pattern,
                  equipment: exercise.equipment,
                  isUnilateral: exercise.isUnilateral,
                ),
          targetSets: row.item.targetSets,
          repLow: row.item.repLow,
          repHigh: row.item.repHigh,
          notes: row.item.notes,
        ),
      );
    }

    return SessionPlan(id: id, dayKey: key, name: name, items: items);
  }
}
