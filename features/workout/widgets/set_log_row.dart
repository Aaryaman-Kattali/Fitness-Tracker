import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/core/formatters.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:flutter/cupertino.dart';

/// One saved set in the current session.
class SetLogRow extends StatelessWidget {
  const SetLogRow({
    required this.set,
    required this.ordinal,
    required this.repUnit,
    required this.onDelete,
    super.key,
  });

  final LoggedSet set;

  /// Position within this exercise, 1-based.
  final int ordinal;
  final String repUnit;
  final VoidCallback onDelete;

  /// "W" for a warm-up set, otherwise its 1-based position.
  String get label => set.isWarmup ? 'W' : '$ordinal';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.footnoteEmphasis.copyWith(
                color: set.isWarmup
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${formatLoad(set.weightKg)}  ×  ${set.reps} $repUnit',
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (set.rir case final rir?)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                'RIR $rir',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            onPressed: () => _confirmDelete(context),
            child: const Icon(
              CupertinoIcons.minus_circle,
              size: 20,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: Text(
            'Delete set $label of '
            '${formatLoad(set.weightKg)} × ${set.reps}?',
          ),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
              child: const Text('Delete set'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ),
      ),
    );
  }
}
