import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:flutter/cupertino.dart';

/// One prescribed exercise: name, set × rep prescription, and coaching note.
class PlanItemRow extends StatelessWidget {
  const PlanItemRow({
    required this.item,
    this.onTap,
    this.trailing,
    super.key,
  });

  final PlannedItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final exercise = item.exercise;
    final notes = item.notes;
    final trailingWidget = trailing;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise?.name ?? '',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.prescription.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.prescription,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
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
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailingWidget,
          ],
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textLabel,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: content,
    );
  }
}
