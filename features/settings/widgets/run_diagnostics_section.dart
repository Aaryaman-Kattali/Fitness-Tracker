import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug-only read-out of what the GPS pipeline did to the last run.
///
/// It sits beside the Health Connect diagnostics and works the same way, for
/// the same reason. A run that comes out short has several causes that produce
/// an identical number on the recording screen — a receiver reporting every
/// three seconds instead of every one, an accuracy threshold discarding usable
/// fixes, a stop detector too eager at walking pace, a smoother tuned for a
/// runner — and the only way to tell them apart is to see the counts side by
/// side rather than reason about which is most likely.
///
/// This reports; it does not fix, and it does not tune anything.
class RunDiagnosticsSection extends ConsumerWidget {
  const RunDiagnosticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(runDiagnosticsReportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Run diagnostics', accent: AppColors.danger),
        InsetCard(
          child: switch (report) {
            AsyncData(value: final text) => _Mono(text),
            AsyncError(:final error) => _Mono('$error'),
            _ => const CupertinoActivityIndicator(),
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        InsetCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TapRow(
                label: 'Re-read',
                onTap: () => ref.invalidate(runDiagnosticsReportProvider),
              ),
              const InsetDivider(indent: 0),
              _TapRow(
                label: 'Copy report',
                // Forty lines of counts read off a phone screen and retyped is
                // how a transcription error becomes a wrong diagnosis.
                onTap: switch (report) {
                  AsyncData(value: final text) => () => unawaited(
                    Clipboard.setData(ClipboardData(text: text)),
                  ),
                  _ => null,
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fixed-pitch-ish block of report text.
///
/// Inter is the only bundled family, so this leans on tabular figures rather
/// than a real monospace face — enough to keep columns of counts aligned
/// without shipping a second font for a debug screen.
class _Mono extends StatelessWidget {
  const _Mono(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // Horizontally scrollable: the distribution lines are wide by design, and
    // wrapping them destroys the column alignment that makes them readable.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(
        text,
        style: AppTypography.footnote.copyWith(
          color: AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      minimumSize: const Size(0, AppSpacing.minTapTarget),
      onPressed: onTap,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTypography.body.copyWith(
          color: AppColors.accentPrimary,
        ),
      ),
    );
  }
}
