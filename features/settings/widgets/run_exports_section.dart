import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';
import 'package:fitness_tracker/features/activity/providers/run_exports_provider.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Debug-only: get a run's diagnostic files off the phone.
///
/// The three files a run writes — the report, the raw track and the fix
/// capture — are the evidence behind every accuracy question this project has
/// asked, and until now the only way to read one was
/// `adb exec-out run-as com.personal.fitness_tracker cat ...` from a PC. That
/// is friction on the one artifact that cannot be regenerated: a capture not
/// taken because a laptop was not to hand is a walk that has to be repeated.
///
/// Share only, and that is a decision rather than a first step. Writing to
/// public Downloads spans the scoped-storage boundary at minSdk 26 —
/// a raw path on API 28 and below, MediaStore on 29 and above — so it needs
/// two code paths, a runtime permission and a second dependency, to reach a
/// destination the share sheet already offers through Files in one tap.
class RunExportsSection extends ConsumerWidget {
  const RunExportsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exports = ref.watch(runExportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Export run data', accent: AppColors.danger),
        InsetCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: switch (exports) {
            AsyncData(value: final runs) when runs.isEmpty => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: _Hint(
                'No run has written diagnostics yet. Record one and its '
                'report, raw track and fix capture appear here.',
              ),
            ),
            AsyncData(value: final runs) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final export in runs) ...[
                  if (export != runs.first) const InsetDivider(indent: 0),
                  _ExportRow(export: export),
                ],
              ],
            ),
            AsyncError(:final error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: _Hint('$error'),
            ),
            _ => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: CupertinoActivityIndicator(),
            ),
          },
        ),
      ],
    );
  }
}

class _ExportRow extends ConsumerWidget {
  const _ExportRow({required this.export});

  final RunExport export;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(runExportActionsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            // Local time, unlike the filename. The stamp is UTC so it sorts
            // and cannot collide across a DST boundary; a person reading a
            // list of their own walks wants the clock they walked by.
            DateFormat(
              'EEE d MMM, HH:mm',
            ).format(export.startedAt.toLocal()),
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          _Hint(
            '${_fixes(export.fixCount)} · ${_size(export.bytes)} · '
            '${export.sharablePaths.length} files',
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _Action(
                label: 'Share',
                onTap: () => unawaited(actions.share(export)),
              ),
              const SizedBox(width: AppSpacing.md),
              _Action(
                label: 'Delete',
                colour: AppColors.danger,
                onTap: () => unawaited(_confirmDelete(context, actions)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Confirmed, never immediate.
  ///
  /// C-7-1 exists because a capture was destroyed by a fixed filename being
  /// reused — a deletion nobody asked for. A confirmed manual delete is the
  /// opposite of that failure, and the confirmation is what keeps it so.
  Future<void> _confirmDelete(
    BuildContext context,
    RunExportActions actions,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Delete this run's data?"),
        content: Text(
          'The report, raw track and fix capture for '
          '${DateFormat('d MMM, HH:mm').format(export.startedAt.toLocal())} '
          'are removed from the phone. A capture cannot be regenerated — '
          'share it first if it has not left the device.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await actions.delete(export);
  }

  static String _fixes(int? count) =>
      count == null ? 'fix count unknown' : '$count fixes';

  static String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} kB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    this.colour = AppColors.accentPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, AppSpacing.minTapTarget),
      onPressed: onTap,
      child: Text(
        label,
        style: AppTypography.body.copyWith(
          color: colour,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.footnote.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}
