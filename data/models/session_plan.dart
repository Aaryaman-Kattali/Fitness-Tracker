import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:meta/meta.dart';

/// An exercise as the UI consumes it, independent of its storage row.
@immutable
class PlannedExercise {
  const PlannedExercise({
    required this.id,
    required this.name,
    required this.pattern,
    required this.equipment,
    required this.isUnilateral,
  });

  final int id;
  final String name;
  final MovementPattern pattern;
  final String equipment;

  /// When true, `SetLogs.reps` records reps **per side**.
  final bool isUnilateral;

  /// The unit word for a rep count on this exercise.
  String get repUnit => isUnilateral ? 'reps/side' : 'reps';
}

/// One prescribed row of a session.
@immutable
class PlannedItem {
  const PlannedItem({
    required this.id,
    required this.block,
    required this.orderIndex,
    this.exercise,
    this.targetSets,
    this.repLow,
    this.repHigh,
    this.notes,
  });

  final int id;
  final TrainingBlock block;
  final int orderIndex;

  /// Null for warm-up checklists, which carry their prescription in [notes].
  final PlannedExercise? exercise;
  final int? targetSets;
  final int? repLow;
  final int? repHigh;
  final String? notes;

  /// "4 × 6–8", "3 × 15", or "3 sets" when the plan prescribes a duration
  /// instead of reps (the seconds then live in [notes]).
  String get prescription {
    final sets = targetSets;
    if (sets == null) return '';
    final low = repLow;
    final high = repHigh;
    if (low == null || high == null) {
      return '$sets ${sets == 1 ? 'set' : 'sets'}';
    }
    final reps = low == high ? '$low' : '$low–$high';
    final perSide = exercise?.isUnilateral ?? false ? '/side' : '';
    return '$sets × $reps$perSide';
  }
}

/// A full session, ready to render.
@immutable
class SessionPlan {
  const SessionPlan({
    required this.id,
    required this.dayKey,
    required this.name,
    required this.items,
  });

  final int id;
  final PlanDayKey dayKey;
  final String name;
  final List<PlannedItem> items;

  /// Items in [block], in prescribed order.
  List<PlannedItem> itemsIn(TrainingBlock block) =>
      items.where((item) => item.block == block).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  /// The loggable exercises of the lift, in order.
  List<PlannedItem> get mainItems => itemsIn(TrainingBlock.main);

  /// Rest between sets for [item].
  ///
  /// The training plan prescribes 3 min on the first two exercises of the lift
  /// and 90 sec on everything after — plyometrics included, since the weeks 1–4
  /// progressions are short and low-fatigue.
  Duration restFor(PlannedItem item) {
    final index = mainItems.indexWhere((candidate) => candidate.id == item.id);
    return index >= 0 && index < 2
        ? const Duration(seconds: 180)
        : const Duration(seconds: 90);
  }
}
