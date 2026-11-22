import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/core/formatters.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:fitness_tracker/features/workout/providers/workout_providers.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A past session, exercise by exercise.
class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({required this.workoutId, super.key});

  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(workoutExercisesProvider(workoutId));
    final sets = ref.watch(workoutSetsProvider(workoutId)).value ?? const [];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      navigationBar: const CupertinoNavigationBar(middle: Text('Session')),
      child: SafeArea(
        child: switch (exercises) {
          AsyncData(value: final list) when list.isEmpty => Center(
            child: Text(
              'No sets were logged in this session.',
              style: AppTypography.subhead.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AsyncData(value: final list) => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final entry = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ExerciseBlock(
                  name: entry.name,
                  repUnit: entry.isUnilateral ? 'reps/side' : 'reps',
                  sets: sets
                      .where((set) => set.exerciseId == entry.exerciseId)
                      .toList(),
                ),
              );
            },
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CupertinoActivityIndicator()),
        },
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({
    required this.name,
    required this.repUnit,
    required this.sets,
  });

  final String name;
  final String repUnit;
  final List<LoggedSet> sets;

  @override
  Widget build(BuildContext context) {
    return InsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final set in sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                '${set.isWarmup ? 'Warm-up' : 'Set ${set.setIndex}'}  ·  '
                '${formatLoad(set.weightKg)} × ${set.reps} $repUnit'
                '${set.rir == null ? '' : '  ·  RIR ${set.rir}'}',
                style: AppTypography.subhead.copyWith(
                  color: set.isWarmup
                      ? AppColors.textLabel
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
