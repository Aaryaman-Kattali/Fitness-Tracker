import 'package:fitness_tracker/core/one_rep_max.dart';
import 'package:meta/meta.dart';

/// Identifies one line of one warm-up checklist.
///
/// A record rather than a class so that sets and map lookups compare by value
/// without an == to maintain.
typedef WarmupCheckKey = ({int planItemId, int lineIndex});

/// One recorded set, as the UI consumes it.
@immutable
class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    required this.isWarmup,
    this.weightKg,
    this.rir,
  });

  final int id;
  final int exerciseId;
  final int setIndex;

  /// Null for unloaded work. Never zero-filled — see `SetLogs.weightKg`.
  final double? weightKg;

  /// Reps per side on a unilateral exercise, total reps otherwise.
  final int reps;
  final int? rir;
  final bool isWarmup;

  /// Shorthand for feeding the 1RM helpers.
  ({double? weightKg, int reps}) get load => (weightKg: weightKg, reps: reps);
}

/// One exercise's sets within a single session.
@immutable
class ExerciseSession {
  const ExerciseSession({
    required this.workoutId,
    required this.date,
    required this.startedAt,
    required this.sets,
  });

  final int workoutId;

  /// The calendar day, for headings that read as dates.
  final DateTime date;

  /// When the session actually began.
  ///
  /// Distinct from [date] because two sessions can share a day; anything that
  /// orders or plots sessions has to use this, not the truncated date.
  final DateTime startedAt;

  final List<LoggedSet> sets;

  /// Working sets only — warm-ups do not represent performance.
  List<LoggedSet> get workingSets =>
      sets.where((set) => !set.isWarmup).toList();

  double? get bestEstimatedOneRepMax =>
      bestOneRepMax(workingSets.map((set) => set.load));

  /// "60 kg × 8, 60 kg × 7, 57.5 kg × 8" — last session at a glance.
  String get summaryLine => workingSets
      .map(
        (set) => set.weightKg == null
            ? '${set.reps}'
            : '${_trimZeros(set.weightKg!)} × ${set.reps}',
      )
      .join(', ');
}

/// A row in the workout history list.
@immutable
class WorkoutSummary {
  const WorkoutSummary({
    required this.id,
    required this.date,
    required this.startedAt,
    required this.setCount,
    this.endedAt,
    this.planDayName,
  });

  final int id;
  final DateTime date;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int setCount;
  final String? planDayName;

  bool get isInProgress => endedAt == null;

  Duration? get duration => endedAt?.difference(startedAt);
}

String _trimZeros(double value) {
  final text = value.toStringAsFixed(2);
  return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}
