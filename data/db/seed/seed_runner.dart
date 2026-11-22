import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/seed/phase1_seed.dart';
import 'package:fitness_tracker/data/db/seed/seed_models.dart';

/// Writes the Phase 1 plan on first run.
///
/// Idempotent: if any plan day already exists the whole call is a no-op, so it
/// can run on every open without duplicating the plan or clobbering edits.
/// Returns true when a seed was actually written.
Future<bool> seedTrainingDataIfEmpty(
  AppDatabase db, {
  List<SeedPlanDay> plan = phase1Plan,
}) async {
  final existing = await db.managers.planDays.count();
  if (existing > 0) return false;
  await _seedTrainingData(db, plan);
  return true;
}

/// Writes [plan] into the database unconditionally, in one transaction.
///
/// Exercises are deduplicated by name across sessions, so an exercise that
/// appears in more than one session keeps a single row — and therefore a
/// single progression history.
Future<void> _seedTrainingData(AppDatabase db, List<SeedPlanDay> plan) async {
  await db.transaction(() async {
    final exerciseIds = <String, int>{};

    for (final day in plan) {
      final planDayId = await db
          .into(db.planDays)
          .insert(
            PlanDaysCompanion.insert(
              dayKey: day.dayKey,
              name: day.name,
              orderIndex: day.orderIndex,
            ),
          );

      for (final item in day.items) {
        final seedExercise = item.exercise;
        int? exerciseId;

        if (seedExercise != null) {
          exerciseId = exerciseIds[seedExercise.name] ??= await db
              .into(db.exercises)
              .insert(
                ExercisesCompanion.insert(
                  name: seedExercise.name,
                  pattern: seedExercise.pattern,
                  equipment: seedExercise.equipment,
                  isUnilateral: Value(seedExercise.isUnilateral),
                ),
              );
        }

        await db
            .into(db.planItems)
            .insert(
              PlanItemsCompanion.insert(
                planDayId: planDayId,
                exerciseId: Value(exerciseId),
                block: item.block,
                targetSets: Value(item.targetSets),
                repLow: Value(item.repLow),
                repHigh: Value(item.repHigh),
                notes: Value(item.notes),
              ),
            );
      }
    }
  });
}
