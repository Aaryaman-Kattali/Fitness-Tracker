import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/features/settings/providers/health_diagnostics_provider.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Debug-only read-out of everything the app can see of Health Connect.
///
/// This reports; it does not fix. Steps reading zero while another app shows a
/// figure has several causes that look identical from the Today screen — no
/// provider, a refused or silently revoked permission, an empty store, or a
/// query window an hour or a day off — and the only way to tell them apart is
/// to show the SDK status, each permission separately, the raw records with
/// their source packages, and the exact query window in both local time and
/// UTC at once.
class HealthDiagnosticsSection extends ConsumerWidget {
  const HealthDiagnosticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(healthDiagnosticsPanelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Health diagnostics', accent: AppColors.danger),
        switch (panel) {
          AsyncData(value: final report) => _Report(report: report),
          AsyncError(:final error) => InsetCard(child: _Mono('$error')),
          _ => const InsetCard(child: CupertinoActivityIndicator()),
        },
        const SizedBox(height: AppSpacing.sm),
        _Actions(report: panel.value),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.report});

  final HealthDiagnostics? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.read(healthDiagnosticsPanelProvider.notifier);
    final text = report;

    return InsetCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TapRow(
            label: 'Re-request permissions',
            onTap: () => unawaited(panel.requestPermissions()),
          ),
          const InsetDivider(indent: 0),
          _TapRow(
            label: 'Re-read',
            onTap: () => unawaited(panel.refresh()),
          ),
          const InsetDivider(indent: 0),
          _TapRow(
            label: 'Copy report',
            // The report exists to be sent to someone. Reading 40 lines of
            // timestamps off a phone screen and retyping them is how a
            // transcription error becomes a wrong diagnosis.
            onTap: text == null
                ? null
                : () => unawaited(
                    Clipboard.setData(ClipboardData(text: _plainText(text))),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});

  final HealthDiagnostics report;

  @override
  Widget build(BuildContext context) {
    return InsetCard(child: _Mono(_plainText(report)));
  }
}

/// The whole report as text, so the screen and the clipboard cannot disagree.
String _plainText(HealthDiagnostics report) {
  final out = StringBuffer()
    ..writeln('SDK status:   ${report.rawSdkStatus}')
    ..writeln('Mapped to:    ${report.availability.name}')
    ..writeln('Device zone:  ${_zone(report.todayWindowFrom)}')
    ..writeln()
    ..writeln('Today window (what feeds the ring):')
    ..writeln('  from  ${_both(report.todayWindowFrom)}')
    ..writeln('  to    ${_both(report.todayWindowTo)}')
    ..writeln('  getTotalStepsInInterval -> ${report.todayStepsAggregate}')
    ..writeln()
    ..writeln('Raw dump window:')
    ..writeln('  from  ${_both(report.rawWindowFrom)}')
    ..writeln('  to    ${_both(report.rawWindowTo)}');

  if (report.error != null) {
    out
      ..writeln()
      ..writeln('ERROR: ${report.error}');
  }

  for (final type in report.types) {
    out
      ..writeln()
      ..writeln('${type.type}  granted: ${type.isGranted ?? "unknown"}')
      ..writeln('  ${type.records.length} record(s)');
    if (type.error != null) out.writeln('  ERROR: ${type.error}');
    for (final record in type.records) {
      out
        ..writeln(
          '  ${_stamp(record.start)} -> ${_stamp(record.end)}  '
          '${record.value} ${record.unit}',
        )
        ..writeln('    ${record.sourcePackage} · ${record.recordingMethod}');
    }
  }
  return out.toString();
}

final _stampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

String _stamp(DateTime value) => _stampFormat.format(value);

/// Both zones for one instant.
///
/// A midnight-boundary or timezone mismatch is a prime suspect for the ring
/// reading zero, and it is invisible unless both are printed side by side.
String _both(DateTime value) =>
    '${_stamp(value)} local  |  ${_stamp(value.toUtc())} UTC';

String _zone(DateTime value) {
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${value.timeZoneName} (UTC$sign$hours:$minutes)';
}

/// Fixed-pitch-ish block of report text.
///
/// Inter is the only bundled family, so this leans on tabular figures rather
/// than a real monospace face — enough to keep columns of timestamps aligned
/// without shipping a second font for a debug screen.
class _Mono extends StatelessWidget {
  const _Mono(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // Not selectable: SelectableText is Material-only, and "Copy report"
    // already covers getting the text off the phone.
    return Text(
      text,
      style: AppTypography.footnote.copyWith(
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
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
