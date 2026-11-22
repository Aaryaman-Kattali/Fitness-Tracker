import 'package:fitness_tracker/app/router/app_router.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/core/formatters.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:fitness_tracker/features/workout/providers/workout_providers.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Every logged session, newest first.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Workout')),
          SliverSafeArea(
            top: false,
            sliver: switch (history) {
              AsyncData(value: final workouts) when workouts.isEmpty =>
                const SliverToBoxAdapter(child: _EmptyHistory()),
              AsyncData(value: final workouts) => SliverList.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _WorkoutCard(summary: workouts[index]),
                ),
              ),
              AsyncError(:final error) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('$error'),
                ),
              ),
              _ => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CupertinoActivityIndicator(),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final duration = summary.duration;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => context.go(Routes.workoutDetail(summary.id)),
      child: InsetCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.planDayName ?? 'Session',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    DateFormat('EEE d MMM').format(summary.date),
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    [
                      '${summary.setCount} sets',
                      if (duration != null) formatSessionLength(duration),
                      if (summary.isInProgress) 'in progress',
                    ].join(' · '),
                    style: AppTypography.footnote.copyWith(
                      color: summary.isInProgress
                          ? AppColors.accentPrimary
                          : AppColors.textLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Icon(
            CupertinoIcons.flame,
            size: 44,
            color: AppColors.textLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No sessions logged yet.\nStart one from the Today tab.',
            textAlign: TextAlign.center,
            style: AppTypography.subhead.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
