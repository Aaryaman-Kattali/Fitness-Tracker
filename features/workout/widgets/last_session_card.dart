import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/core/formatters.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Last session's numbers for this exercise, shown inline while logging.
///
/// Progressive overload is only obvious if the previous numbers are on the
/// same screen as the entry controls — never a navigation away.
class LastSessionCard extends StatelessWidget {
  const LastSessionCard({required this.session, super.key});

  /// Null when this exercise has never been logged.
  final ExerciseSession? session;

  @override
  Widget build(BuildContext context) {
    final last = session;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceControl,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md - AppSpacing.xs),
        child: last == null || last.workingSets.isEmpty
            ? Text(
                'First time logging this exercise. Pick a weight you could do '
                '3–4 more reps with.',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.clock,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text(
                        'LAST SESSION · '
                        '${DateFormat('d MMM').format(last.date).toUpperCase()}',
                        style: AppTypography.footnoteEmphasis.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    last.summaryLine,
                    style: AppTypography.numericSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (last.bestEstimatedOneRepMax case final best?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Best e1RM ${formatKg(best)} kg',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
