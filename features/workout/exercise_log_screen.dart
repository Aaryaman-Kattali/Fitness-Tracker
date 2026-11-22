import 'dart:async';

import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/workout/providers/rest_timer_provider.dart';
import 'package:fitness_tracker/features/workout/providers/set_draft_provider.dart';
import 'package:fitness_tracker/features/workout/providers/workout_providers.dart';
import 'package:fitness_tracker/features/workout/widgets/last_session_card.dart';
import 'package:fitness_tracker/features/workout/widgets/rest_timer_bar.dart';
import 'package:fitness_tracker/features/workout/widgets/set_log_row.dart';
import 'package:fitness_tracker/features/workout/widgets/stepper_controls.dart';
import 'package:fitness_tracker/shared/widgets/centered_message.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set-by-set logging for one exercise.
class ExerciseLogScreen extends ConsumerWidget {
  const ExerciseLogScreen({
    required this.planDayId,
    required this.exerciseId,
    super.key,
  });

  final int planDayId;
  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(sessionPlanProvider(planDayId));
    final workoutId = ref.watch(activeWorkoutIdProvider(planDayId));

    final session = plan.value;
    final item = session?.items
        .where((candidate) => candidate.exercise?.id == exerciseId)
        .firstOrNull;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      navigationBar: CupertinoNavigationBar(
        middle: Text(item?.exercise?.name ?? 'Exercise'),
      ),
      child: switch ((session, item, workoutId)) {
        (final s?, final i?, AsyncData(value: final id)) => _LogBody(
          session: s,
          item: i,
          workoutId: id,
        ),
        (_, _, AsyncError(:final error)) => CenteredMessage('$error'),
        (final s?, null, _) when plan.hasValue => CenteredMessage(
          '${s.name} does not prescribe this exercise.',
        ),
        _ => const Center(child: CupertinoActivityIndicator()),
      },
    );
  }
}

class _LogBody extends ConsumerWidget {
  const _LogBody({
    required this.session,
    required this.item,
    required this.workoutId,
  });

  final SessionPlan session;
  final PlannedItem item;
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = item.exercise!;
    final draftProvider = setDraftControllerProvider(
      exerciseId: exercise.id,
      workoutId: workoutId,
      repLow: item.repLow,
    );
    final draft = ref.watch(draftProvider);
    final sets =
        ref
            .watch(
              exerciseSetsProvider(
                workoutId: workoutId,
                exerciseId: exercise.id,
              ),
            )
            .value ??
        const <LoggedSet>[];
    final last = ref
        .watch(
          lastExerciseSessionProvider(
            exerciseId: exercise.id,
            excludingWorkoutId: workoutId,
          ),
        )
        .value;

    final workingCount = sets.where((set) => !set.isWarmup).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  0,
                ),
                child: _TargetLine(item: item, done: workingCount),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: LastSessionCard(session: last),
              ),
              InsetCard(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  0,
                ),
                child: switch (draft) {
                  AsyncData(:final value) => _Entry(
                    draft: value,
                    exercise: exercise,
                    onWeight: ref.read(draftProvider.notifier).setWeight,
                    onReps: ref.read(draftProvider.notifier).setReps,
                    onRir: ref.read(draftProvider.notifier).setRir,
                    onWarmup: (isWarmup) => ref
                        .read(draftProvider.notifier)
                        .setWarmup(isWarmup: isWarmup),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CupertinoActivityIndicator(),
                  ),
                },
              ),
              if (sets.isNotEmpty) ...[
                SectionHeader('This session · ${sets.length} sets'),
                InsetCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (var index = 0; index < sets.length; index++) ...[
                        if (index > 0) const InsetDivider(indent: 0),
                        SetLogRow(
                          set: sets[index],
                          ordinal: sets
                              .take(index + 1)
                              .where((s) => !s.isWarmup)
                              .length,
                          repUnit: exercise.repUnit,
                          onDelete: () => unawaited(
                            ref
                                .read(workoutRepositoryProvider)
                                .deleteSet(sets[index].id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const RestTimerBar(),
        _SaveBar(
          enabled: draft.hasValue,
          onSave: () => unawaited(_saveSet(ref, draft.value)),
        ),
      ],
    );
  }

  Future<void> _saveSet(WidgetRef ref, SetDraft? draft) async {
    if (draft == null) return;
    final exercise = item.exercise!;

    unawaited(HapticFeedback.mediumImpact());
    await ref
        .read(workoutRepositoryProvider)
        .logSet(
          workoutId: workoutId,
          exerciseId: exercise.id,
          reps: draft.reps,
          weightKg: draft.weightKg,
          rir: draft.rir,
          isWarmup: draft.isWarmup,
          // Same clock the workout was dated with, so an overridden date
          // cannot leave a set timestamped before its own session started.
          now: ref.read(effectiveClockProvider).now(),
        );

    // Warm-up sets do not earn a full rest.
    ref
        .read(restTimerProvider.notifier)
        .start(
          draft.isWarmup ? const Duration(seconds: 60) : session.restFor(item),
          exerciseName: exercise.name,
        );
  }
}

/// "Target 4 × 6–8 · 2 done", plus the rest this exercise gets.
class _TargetLine extends StatelessWidget {
  const _TargetLine({required this.item, required this.done});

  final PlannedItem item;
  final int done;

  @override
  Widget build(BuildContext context) {
    final notes = item.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.prescription.isEmpty
              ? '$done sets logged'
              : 'Target ${item.prescription} · $done done',
          style: AppTypography.subhead.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            notes,
            style: AppTypography.footnote.copyWith(
              color: AppColors.textLabel,
            ),
          ),
        ],
      ],
    );
  }
}

/// The entry controls: weight, reps, RIR and the warm-up flag.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.draft,
    required this.exercise,
    required this.onWeight,
    required this.onReps,
    required this.onRir,
    required this.onWarmup,
  });

  final SetDraft draft;
  final PlannedExercise exercise;
  final ValueChanged<double?> onWeight;
  final ValueChanged<int> onReps;
  final ValueChanged<int?> onRir;
  final ValueChanged<bool> onWarmup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeightStepper(value: draft.weightKg, onChanged: onWeight),
        const SizedBox(height: AppSpacing.lg),
        RepStepper(
          value: draft.reps,
          onChanged: onReps,
          unitLabel: exercise.repUnit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text(
              'RIR',
              style: AppTypography.footnoteEmphasis.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: draft.rir ?? -1,
                onValueChanged: (value) =>
                    onRir(value == null || value < 0 ? null : value),
                children: const {
                  -1: Text('—'),
                  0: Text('0'),
                  1: Text('1'),
                  2: Text('2'),
                  3: Text('3+'),
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Warm-up set',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            CupertinoSwitch(value: draft.isWarmup, onChanged: onWarmup),
          ],
        ),
      ],
    );
  }
}

/// The wide save button, kept within thumb reach at the bottom of the screen.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.enabled, required this.onSave});

  final bool enabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfacePage,
        border: Border(
          top: BorderSide(color: AppColors.surfaceControl),
        ),
      ),
      child: SizedBox(
        height: AppSpacing.stepperTapTarget,
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: enabled ? onSave : null,
          child: const Text('Save set'),
        ),
      ),
    );
  }
}
