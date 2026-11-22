import 'package:fitness_tracker/features/workout/providers/workout_providers.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_draft_provider.g.dart';

/// The set currently being entered, before it is saved.
@immutable
class SetDraft {
  const SetDraft({
    required this.reps,
    this.weightKg,
    this.rir,
    this.isWarmup = false,
  });

  final double? weightKg;
  final int reps;
  final int? rir;
  final bool isWarmup;

  SetDraft copyWith({
    double? weightKg,
    int? reps,
    int? rir,
    bool? isWarmup,
    bool clearWeight = false,
    bool clearRir = false,
  }) => SetDraft(
    weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
    reps: reps ?? this.reps,
    rir: clearRir ? null : (rir ?? this.rir),
    isWarmup: isWarmup ?? this.isWarmup,
  );
}

/// The draft set for one exercise, pre-filled from last session.
///
/// Starting from last session's numbers is the point: double progression means
/// the user almost always repeats the weight and tries to add a rep, so the
/// screen should open on the answer and let them nudge it.
@riverpod
class SetDraftController extends _$SetDraftController {
  @override
  Future<SetDraft> build({
    required int exerciseId,
    required int workoutId,
    int? repLow,
  }) async {
    final last = await ref.watch(
      lastExerciseSessionProvider(
        exerciseId: exerciseId,
        excludingWorkoutId: workoutId,
      ).future,
    );

    final previous = last?.workingSets;
    if (previous == null || previous.isEmpty) {
      return SetDraft(reps: repLow ?? 8);
    }

    // The heaviest working set is the one worth matching or beating.
    final heaviest = previous.reduce(
      (a, b) => (b.weightKg ?? 0) > (a.weightKg ?? 0) ? b : a,
    );
    return SetDraft(weightKg: heaviest.weightKg, reps: heaviest.reps);
  }

  SetDraft get _current => state.value ?? SetDraft(reps: repLow ?? 8);

  void setWeight(double? weightKg) {
    state = AsyncData(
      weightKg == null
          ? _current.copyWith(clearWeight: true)
          : _current.copyWith(weightKg: weightKg),
    );
  }

  void setReps(int reps) => state = AsyncData(_current.copyWith(reps: reps));

  void setRir(int? rir) => state = AsyncData(
    rir == null
        ? _current.copyWith(clearRir: true)
        : _current.copyWith(rir: rir),
  );

  void setWarmup({required bool isWarmup}) =>
      state = AsyncData(_current.copyWith(isWarmup: isWarmup));
}
