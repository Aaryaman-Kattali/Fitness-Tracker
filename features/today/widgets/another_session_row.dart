import 'dart:async';

import 'package:fitness_tracker/app/router/app_router.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/features/today/providers/today_providers.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens any plan day's session, dated today.
///
/// Today's weekday decides what the screen *leads* with, not what can be
/// logged: the gym is shut some days, sessions get shifted, and a missed
/// Lower A is done on Thursday. The (date, planDayId) resume key already
/// scopes a workout to both halves, so a session opened from here starts or
/// resumes exactly like the one on today's card.
class AnotherSessionRow extends ConsumerWidget {
  const AnotherSessionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(allPlanDaysProvider).value ?? const [];
    if (days.isEmpty) return const SizedBox.shrink();

    return InsetCard(
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, AppSpacing.minTapTarget),
        onPressed: () => unawaited(_pick(context, days)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Start another session',
                style: AppTypography.body.copyWith(
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: AppSpacing.md,
              color: AppColors.textLabel,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    List<({int id, PlanDayKey dayKey, String name})> days,
  ) async {
    final chosen = await showCupertinoModalPopup<int>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Which session?'),
        actions: [
          for (final day in days)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, day.id),
              child: Text(day.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (chosen == null || !context.mounted) return;
    context.go(Routes.session(chosen));
  }
}
