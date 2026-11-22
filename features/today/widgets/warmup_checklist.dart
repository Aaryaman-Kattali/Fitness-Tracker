import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/workout_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/workout/providers/workout_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a warm-up prescription as a checklist you can actually tick.
///
/// Warm-ups carry no sets to log, so they are stored as a single plan item
/// whose notes hold one prescription per line. Ticking is the only record
/// there is of a warm-up, and without it the list is unusable in the place it
/// is used: halfway through, trying to remember whether the pec stretch is
/// done. Ticks are keyed on the workout, so each session starts clear.
class WarmupChecklist extends ConsumerWidget {
  const WarmupChecklist({
    required this.checklist,
    required this.planItemId,
    required this.startWorkout,
    this.workoutId,
    super.key,
  });

  final String checklist;
  final int planItemId;

  /// The workout the ticks belong to, or null when none has started.
  final int? workoutId;

  /// Opens or starts the workout to record ticks against.
  ///
  /// Only called on the first tick from a screen where no session is under way
  /// yet — the Today screen. Ticking a warm-up line *is* starting to train, so
  /// it may create the workout; simply looking at the screen may not, which is
  /// why this is a callback rather than a watched provider.
  final Future<int> Function() startWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = checklistLines(checklist);
    final id = workoutId;
    final checked = id == null
        ? const <WarmupCheckKey>{}
        : ref.watch(warmupChecksProvider(id)).value ?? const <WarmupCheckKey>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines.length; index++)
          _ChecklistLine(
            text: lines[index],
            isChecked: checked.contains((
              planItemId: planItemId,
              lineIndex: index,
            )),
            onToggle: (isChecked) =>
                unawaited(_toggle(ref, index, isChecked: isChecked)),
          ),
      ],
    );
  }

  Future<void> _toggle(
    WidgetRef ref,
    int lineIndex, {
    required bool isChecked,
  }) async {
    unawaited(HapticFeedback.selectionClick());
    final id = workoutId ?? await startWorkout();

    await ref
        .read(workoutRepositoryProvider)
        .setWarmupCheck(
          workoutId: id,
          line: (planItemId: planItemId, lineIndex: lineIndex),
          isChecked: isChecked,
        );
  }
}

/// The non-blank lines of a checklist, in render order.
///
/// Shared with the persistence key: a line's index here is the `lineIndex`
/// stored against it, so both have to agree on what counts as a line.
List<String> checklistLines(String checklist) => checklist
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({
    required this.text,
    required this.isChecked,
    required this.onToggle,
  });

  final String text;
  final bool isChecked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    const tint = AppColors.warmup;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      minimumSize: const Size(0, AppSpacing.minTapTarget),
      alignment: Alignment.centerLeft,
      onPressed: () => onToggle(!isChecked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Icon(
              isChecked
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: AppSpacing.md,
              color: isChecked ? tint : AppColors.textLabel,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTypography.subhead.copyWith(
                color: isChecked ? AppColors.textLabel : AppColors.textPrimary,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
