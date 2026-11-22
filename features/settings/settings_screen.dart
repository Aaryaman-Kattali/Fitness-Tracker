import 'dart:async';

import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/features/settings/widgets/health_diagnostics_section.dart';
import 'package:fitness_tracker/features/settings/widgets/run_diagnostics_section.dart';
import 'package:fitness_tracker/features/settings/widgets/run_exports_section.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Settings. Mostly a placeholder still, plus the debug date override.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Settings')),
          SliverSafeArea(
            top: false,
            sliver: SliverList.list(
              children: [
                InsetCard(
                  child: Text(
                    'Units, katori calibration and data export land alongside '
                    'the milestones that need them.',
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Never built into a release binary. The provider's setter is
                // independently inert outside debug, so even a stray
                // reference could not move the clock in a shipped app.
                if (kDebugMode) const _DateOverrideSection(),
                if (kDebugMode) const HealthDiagnosticsSection(),
                if (kDebugMode) const RunDiagnosticsSection(),
                if (kDebugMode) const RunExportsSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateOverrideSection extends ConsumerWidget {
  const _DateOverrideSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(effectiveClockProvider);
    final override = clock.overrideDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Debug', accent: AppColors.danger),
        InsetCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Row(
                label: 'Effective today',
                value: DateFormat('EEE d MMM y').format(clock.today()),
                isHighlighted: clock.isOverridden,
                onTap: () => unawaited(_pickDate(context, ref, clock.today())),
              ),
              if (clock.isOverridden) ...[
                const InsetDivider(indent: 0),
                _Row(
                  label: 'Use the real date',
                  value: DateFormat('EEE d MMM y').format(DateTime.now()),
                  onTap: () => ref.read(dateOverrideProvider.notifier).clear(),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter + AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.gutter + AppSpacing.xs,
            0,
          ),
          child: Text(
            override == null
                ? 'Sets which weekday Today resolves, and dates any workout '
                      'started from here. Debug builds only.'
                : 'Today is pinned to '
                      '${DateFormat('EEEE d MMMM').format(override)}. The time '
                      'of day is still the real one.',
            style: AppTypography.footnote.copyWith(
              color: AppColors.textLabel,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime initial,
  ) => showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => Container(
      height: AppSpacing.pickerSheetHeight,
      color: AppColors.surfacePage,
      child: SafeArea(
        top: false,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initial,
          onDateTimeChanged: ref.read(dateOverrideProvider.notifier).setDate,
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.onTap,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      minimumSize: const Size(0, AppSpacing.minTapTarget),
      onPressed: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: isHighlighted ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            CupertinoIcons.chevron_right,
            size: AppSpacing.md,
            color: AppColors.textLabel,
          ),
        ],
      ),
    );
  }
}
