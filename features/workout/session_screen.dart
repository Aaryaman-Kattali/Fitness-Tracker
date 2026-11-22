import 'dart:async';

import 'package:fitness_tracker/app/router/app_router.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/today/widgets/plan_item_row.dart';
import 'package:fitness_tracker/features/today/widgets/warmup_checklist.dart';
import 'package:fitness_tracker/features/workout/providers/workout_providers.dart';
import 'package:fitness_tracker/features/workout/widgets/rest_timer_bar.dart';
import 'package:fitness_tracker/shared/widgets/centered_message.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The session in progress: every prescribed item, with sets-done counts.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({required this.planDayId, super.key});

  final int planDayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(sessionPlanProvider(planDayId));
    final workoutId = ref.watch(activeWorkoutIdProvider(planDayId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      navigationBar: CupertinoNavigationBar(
        middle: Text(plan.value?.dayKey.shortLabel ?? 'Session'),
        trailing: workoutId.value == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _confirmFinish(context, ref, workoutId.value!),
                child: const Text('Finish'),
              ),
      ),
      child: switch ((plan, workoutId)) {
        (AsyncData(value: final session?), AsyncData(value: final id)) =>
          _SessionBody(session: session, workoutId: id),
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
          CenteredMessage('Could not open the session.\n$error'),
        (AsyncData(value: null), _) => const CenteredMessage(
          'That session is not in the plan.',
        ),
        _ => const Center(child: CupertinoActivityIndicator()),
      },
    );
  }

  void _confirmFinish(BuildContext context, WidgetRef ref, int workoutId) {
    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: const Text('Finish this session?'),
          message: const Text('You can still view it in history afterwards.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_finish(context, ref, workoutId));
              },
              child: const Text('Finish session'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Keep logging'),
          ),
        ),
      ),
    );
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    int workoutId,
  ) async {
    await ref.read(workoutRepositoryProvider).finishWorkout(workoutId);
    ref.invalidate(activeWorkoutIdProvider(planDayId));
    if (context.mounted) context.go(Routes.workout);
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.session, required this.workoutId});

  final SessionPlan session;
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(workoutSetsProvider(workoutId)).value ?? const [];
    final countsByExercise = <int, int>{};
    for (final set in sets) {
      if (set.isWarmup) continue;
      countsByExercise.update(
        set.exerciseId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final warmups = session.itemsIn(TrainingBlock.warmup);
    final plyos = session.itemsIn(TrainingBlock.plyo);
    final mains = session.itemsIn(TrainingBlock.main);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              if (warmups.isNotEmpty) ...[
                SectionHeader(
                  TrainingBlock.warmup.label,
                  accent: AppColors.warmup,
                ),
                InsetCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in warmups)
                        WarmupChecklist(
                          checklist: item.notes ?? '',
                          planItemId: item.id,
                          workoutId: workoutId,
                          // The session is already open, so nothing to start.
                          startWorkout: () async => workoutId,
                        ),
                    ],
                  ),
                ),
              ],
              if (plyos.isNotEmpty) ...[
                SectionHeader(TrainingBlock.plyo.label, accent: AppColors.plyo),
                _ItemGroup(
                  items: plyos,
                  session: session,
                  counts: countsByExercise,
                ),
              ],
              if (mains.isNotEmpty) ...[
                SectionHeader(TrainingBlock.main.label),
                _ItemGroup(
                  items: mains,
                  session: session,
                  counts: countsByExercise,
                ),
              ],
            ],
          ),
        ),
        const RestTimerBar(),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

class _ItemGroup extends StatelessWidget {
  const _ItemGroup({
    required this.items,
    required this.session,
    required this.counts,
  });

  final List<PlannedItem> items;
  final SessionPlan session;
  final Map<int, int> counts;

  @override
  Widget build(BuildContext context) {
    return InsetCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const InsetDivider(indent: 0),
            _SessionItemRow(
              item: items[index],
              done: counts[items[index].exercise?.id] ?? 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionItemRow extends StatelessWidget {
  const _SessionItemRow({required this.item, required this.done});

  final PlannedItem item;
  final int done;

  @override
  Widget build(BuildContext context) {
    final exercise = item.exercise;
    final target = item.targetSets;
    final complete = target != null && done >= target;

    return PlanItemRow(
      item: item,
      onTap: exercise == null
          ? null
          : () => context.go(
              Routes.exerciseLog(
                planDayId: _planDayIdOf(context),
                exerciseId: exercise.id,
              ),
            ),
      trailing: target == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: complete
                    ? AppColors.accentSuccess.withValues(alpha: 0.15)
                    : AppColors.surfaceControl,
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              ),
              child: Text(
                '$done/$target',
                style: AppTypography.footnoteEmphasis.copyWith(
                  color: complete
                      ? AppColors.accentSuccess
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
    );
  }

  /// The plan day is in the current route, so rows do not need it passed down.
  int _planDayIdOf(BuildContext context) {
    final param = GoRouterState.of(context).pathParameters[Routes.planDayParam];
    return int.parse(param!);
  }
}
