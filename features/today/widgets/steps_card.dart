import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/repositories/steps_repository.dart';
import 'package:fitness_tracker/features/today/providers/steps_providers.dart';
import 'package:fitness_tracker/features/today/widgets/steps_ring.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The steps ring on the Today screen, plus every state it can be in.
///
/// Health Connect is absent on emulators and optional on real phones, so this
/// card is written to always render something and never to throw. It renders
/// nothing at all — taking up no space — only while the very first check is
/// still in flight, so the screen does not flash a placeholder on every
/// resume.
class StepsCard extends ConsumerWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(stepsPanelProvider);
    final activity = ref.watch(todayActivityProvider).value;

    // No spinner and no empty card on the first frame: the Today screen's
    // real content must not be pushed around by something optional.
    if (panel.isLoading && !panel.hasValue) return const SizedBox.shrink();

    final status = panel.value;
    if (status == null) return const SizedBox.shrink();

    return InsetCard(child: _body(ref, status, activity));
  }

  /// An if-chain rather than a switch so that ruling out a null [activity]
  /// promotes it for the summary branch.
  Widget _body(WidgetRef ref, StepsStatus status, DailyActivity? activity) {
    // Nothing to read from, and nothing the user can do about it in this app.
    if (status.availability == HealthAvailability.unsupported) {
      return const _StepsMessage(
        title: 'Steps unavailable',
        detail:
            'Health Connect is not available on this device, so step and '
            'active-energy totals cannot be read. Everything else works as '
            'normal.',
      );
    }

    // Fixable by installing or updating the provider app.
    if (status.availability.isResolvableByInstall) {
      final needsUpdate = status.availability == HealthAvailability.needsUpdate;
      return _StepsMessage(
        title: needsUpdate
            ? 'Health Connect needs updating'
            : 'Health Connect not installed',
        detail: needsUpdate
            ? 'The installed version of Health Connect is older than this app '
                  'can read from.'
            : 'Steps and active energy come from Health Connect. Install it '
                  'to see them here.',
        actionLabel: needsUpdate
            ? 'Update Health Connect'
            : 'Get Health Connect',
        onAction: () =>
            unawaited(ref.read(stepsPanelProvider.notifier).openInstall()),
      );
    }

    // Never granted, refused, or revoked from the Health Connect app since
    // the last sync. The same offer covers all three: an app that stops
    // asking after one refusal can never be turned back on.
    if (status.needsPermission) {
      return _StepsMessage(
        title: 'Steps not connected',
        detail:
            'Allow this app to read steps and active energy from Health '
            'Connect to fill the ring.',
        actionLabel: 'Allow access',
        onAction: () => unawaited(
          ref.read(stepsPanelProvider.notifier).requestPermission(),
        ),
      );
    }

    // Permission is in place, but the day has produced nothing yet and there
    // is no earlier figure to fall back on.
    if (activity == null) {
      return const _StepsMessage(
        title: 'No steps yet today',
        detail:
            'Health Connect has nothing recorded for today. It will appear '
            'here once your phone or a connected app records some.',
      );
    }

    return _StepsSummary(
      activity: activity,
      // A sync that could not complete leaves whatever was last stored on
      // screen, greyed rather than removed, so the number is never a silent
      // claim about right now.
      isStale: status.lastSync != StepsSyncOutcome.synced,
    );
  }
}

class _StepsSummary extends StatelessWidget {
  const _StepsSummary({required this.activity, required this.isStale});

  final DailyActivity activity;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern();
    final reached = activity.steps >= stepsTarget;

    return Row(
      children: [
        StepsRing(
          progress: activity.progressTowards(stepsTarget),
          label: NumberFormat.compact().format(activity.steps),
          isMuted: isStale,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Steps',
                style: AppTypography.headline.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${number.format(activity.steps)} of '
                '${number.format(stepsTarget)}',
                style: AppTypography.subhead.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _footnote(reached: reached),
                style: AppTypography.footnote.copyWith(
                  color: reached && !isStale
                      ? AppColors.accentSuccess
                      : AppColors.textLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _footnote({required bool reached}) {
    if (isStale) return 'Last known total — could not refresh.';
    if (reached) return 'Goal reached.';
    final kcal = activity.activeKcal.round();
    return kcal > 0 ? '$kcal kcal active' : 'Keep going.';
  }
}

/// A titled explanation with an optional single action.
class _StepsMessage extends StatelessWidget {
  const _StepsMessage({
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headline.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          detail,
          style: AppTypography.footnote.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (label != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, AppSpacing.minTapTarget),
              onPressed: onAction,
              child: Text(label, style: AppTypography.body),
            ),
          ),
        ],
      ],
    );
  }
}
