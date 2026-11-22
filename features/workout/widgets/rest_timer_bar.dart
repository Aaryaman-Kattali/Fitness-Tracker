import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/core/formatters.dart';
import 'package:fitness_tracker/features/workout/providers/rest_timer_provider.dart';
import 'package:fitness_tracker/features/workout/services/rest_alerts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The rest countdown, pinned above the save button while a rest is running.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    if (!timer.isActive) return const SizedBox.shrink();

    final controller = ref.read(restTimerProvider.notifier);
    final finished = timer.isFinished;
    final tint = finished ? AppColors.accentSuccess : AppColors.accentPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadius),
              ),
              child: SizedBox(
                height: 3,
                child: LinearProgressBar(value: timer.progress, color: tint),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    formatClock(timer.remaining),
                    style: AppTypography.numericSmall.copyWith(
                      fontSize: 28,
                      color: tint,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Text(
                      finished
                          ? 'Rest done — next set'
                          : 'Resting${timer.exerciseName == null ? '' : ' · ${timer.exerciseName}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    onPressed: () =>
                        controller.extend(const Duration(seconds: 30)),
                    child: const Text('+30s'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    onPressed: controller.dismiss,
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 22,
                      color: AppColors.textLabel,
                    ),
                  ),
                ],
              ),
            ),
            const _AlertDeliveryNotice(),
          ],
        ),
      ),
    );
  }
}

/// Says so when the off-screen alert will be late, or will not arrive.
///
/// **A second line rather than a badge in the row above, and that is a layout
/// decision taken from U-5.** The row already carries a 28pt clock, a
/// flexible label and two buttons; adding anything to it puts a warning in
/// width contention with the label, and the loser of that contention gets
/// ellipsised — which is swallowing the degradation in a different way. On its
/// own line it wraps instead of clipping and nothing else has to give way.
///
/// It renders nothing at all in the healthy case, so the common path pays no
/// height for it.
///
/// **Freshness.** `initialize()` is not awaited at launch (`main.dart`), so
/// [RestAlerts.delivery] can still read `unavailable` for the first moments of
/// a cold start. That is not a stale-read bug here: this widget is only built
/// while a rest is running, which is several taps away, and the parent rebuilds
/// once a second off the timer tick, so the notice corrects itself within a
/// second of initialisation finishing either way.
class _AlertDeliveryNotice extends ConsumerWidget {
  const _AlertDeliveryNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delivery = ref.watch(restAlertsProvider).delivery;
    if (delivery == RestAlertDelivery.exact) return const SizedBox.shrink();

    final unavailable = delivery == RestAlertDelivery.unavailable;
    final tint = unavailable ? AppColors.danger : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unavailable
                ? CupertinoIcons.bell_slash_fill
                : CupertinoIcons.exclamationmark_triangle_fill,
            // Sized off the type ramp rather than a magic number, so the icon
            // tracks the text it sits beside.
            size: AppTypography.footnote.fontSize,
            color: tint,
          ),
          const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          Expanded(
            // Deliberately no maxLines and no ellipsis: this is the message
            // that must not be truncated on a narrow phone.
            child: Text(
              unavailable
                  ? 'Notifications are off — this rest will only alert on '
                        'screen.'
                  : 'Exact alarms are off — the notification may arrive a few '
                        'minutes late.',
              style: AppTypography.footnote.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

/// A minimal determinate progress bar.
///
/// Cupertino ships no progress bar (iOS uses one, but Flutter only exposes it
/// under Material as `LinearProgressIndicator`), so this draws the two-tone
/// track directly rather than importing material.dart for it.
class LinearProgressBar extends StatelessWidget {
  const LinearProgressBar({
    required this.value,
    required this.color,
    super.key,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          const ColoredBox(
            color: AppColors.surfaceControl,
            child: SizedBox(width: double.infinity, height: 3),
          ),
          SizedBox(
            width: constraints.maxWidth * value.clamp(0.0, 1.0),
            height: 3,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    );
  }
}
