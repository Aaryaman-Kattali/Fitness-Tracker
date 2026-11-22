import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:meta/meta.dart';

/// An exercise as described by the training plan, before it reaches a database.
@immutable
class SeedExercise {
  const SeedExercise({
    required this.name,
    required this.pattern,
    required this.equipment,
    this.isUnilateral = false,
  });

  final String name;
  final MovementPattern pattern;
  final String equipment;

  /// When true, a logged set records reps *per side*, not total.
  final bool isUnilateral;
}

/// One row of a session: either a loggable exercise, or — for warm-ups — a
/// checklist carried entirely in [notes].
///
/// [exercise] is null exactly when [block] is [TrainingBlock.warmup]: a warm-up
/// is a list of things to do, not something with sets to record. [targetSets]
/// and the rep range are likewise null for warm-ups, and [repLow]/[repHigh] are
/// null for duration-prescribed plyometrics (where [notes] carries the seconds).
@immutable
class SeedPlanItem {
  const SeedPlanItem({
    required this.block,
    this.exercise,
    this.targetSets,
    this.repLow,
    this.repHigh,
    this.notes,
  });

  /// A warm-up checklist item: no exercise, no sets, just the prescription.
  const SeedPlanItem.warmup(String checklist)
    : block = TrainingBlock.warmup,
      exercise = null,
      targetSets = null,
      repLow = null,
      repHigh = null,
      notes = checklist;

  final TrainingBlock block;
  final SeedExercise? exercise;
  final int? targetSets;
  final int? repLow;
  final int? repHigh;
  final String? notes;
}

/// A full session.
@immutable
class SeedPlanDay {
  const SeedPlanDay({
    required this.dayKey,
    required this.name,
    required this.orderIndex,
    required this.items,
  });

  final PlanDayKey dayKey;
  final String name;
  final int orderIndex;
  final List<SeedPlanItem> items;
}
