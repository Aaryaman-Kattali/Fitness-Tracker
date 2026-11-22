import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/core/formatters.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// A large tap target that repeats while held.
///
/// Adding 40 kg to a leg press two and a half kilos at a time should not need
/// sixteen taps, and holding is easier than tapping accurately while breathing
/// hard.
class RepeatButton extends StatefulWidget {
  const RepeatButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<RepeatButton> {
  Timer? _holdTimer;
  bool _isDown = false;

  void _fire() {
    unawaited(HapticFeedback.selectionClick());
    widget.onPressed();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() => _isDown = true);
    _fire();
    _holdTimer = Timer(const Duration(milliseconds: 450), () {
      _holdTimer = Timer.periodic(
        const Duration(milliseconds: 90),
        (_) => _fire(),
      );
    });
  }

  void _release() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_isDown) setState(() => _isDown = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: AppSpacing.stepperTapTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isDown ? AppColors.surfaceControl : AppColors.surfaceControl,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
        child: Text(
          widget.label,
          style: AppTypography.headline.copyWith(
            color: enabled ? AppColors.accentPrimary : AppColors.textLabel,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Weight entry in kilograms.
///
/// Machine and Smith-bar plates move in 2.5 kg steps and dumbbells in 1.25 kg
/// half-steps, so those are the two increments offered. Tapping the number
/// itself opens a keypad for the rare jump.
class WeightStepper extends StatelessWidget {
  const WeightStepper({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Null means unloaded (bodyweight, band, plyometric).
  final double? value;
  final ValueChanged<double?> onChanged;

  void _nudge(double delta) {
    final next = ((value ?? 0) + delta).clamp(0.0, 999.0);
    onChanged(next == 0 ? null : next);
  }

  Future<void> _editExact(BuildContext context) async {
    final controller = TextEditingController(
      text: value == null ? '' : formatKg(value),
    );
    final entered = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Weight (kg)'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            placeholder: 'Bodyweight',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (entered == null) return;
    if (entered.isEmpty) {
      onChanged(null);
      return;
    }
    final parsed = double.tryParse(entered.replaceAll(',', '.'));
    if (parsed != null) {
      onChanged(parsed <= 0 ? null : parsed.clamp(0.0, 999.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepperFrame(
      label: 'Weight',
      unit: 'kg',
      valueText: value == null ? 'BW' : formatKg(value),
      onEditExact: () => unawaited(_editExact(context)),
      decrements: [
        RepeatButton(label: '−2.5', onPressed: () => _nudge(-2.5)),
        RepeatButton(label: '−1.25', onPressed: () => _nudge(-1.25)),
      ],
      increments: [
        RepeatButton(label: '+1.25', onPressed: () => _nudge(1.25)),
        RepeatButton(label: '+2.5', onPressed: () => _nudge(2.5)),
      ],
    );
  }
}

/// Rep entry.
class RepStepper extends StatelessWidget {
  const RepStepper({
    required this.value,
    required this.onChanged,
    required this.unitLabel,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// "reps", or "reps/side" on a unilateral exercise.
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return _StepperFrame(
      label: 'Reps',
      unit: unitLabel,
      valueText: '$value',
      decrements: [
        RepeatButton(
          label: '−1',
          enabled: value > 1,
          onPressed: () => onChanged((value - 1).clamp(1, 100)),
        ),
      ],
      increments: [
        RepeatButton(
          label: '+1',
          onPressed: () => onChanged((value + 1).clamp(1, 100)),
        ),
      ],
    );
  }
}

/// Shared layout: decrement buttons, a big tabular value, increment buttons.
class _StepperFrame extends StatelessWidget {
  const _StepperFrame({
    required this.label,
    required this.unit,
    required this.valueText,
    required this.decrements,
    required this.increments,
    this.onEditExact,
  });

  final String label;
  final String unit;
  final String valueText;
  final List<Widget> decrements;
  final List<Widget> increments;
  final VoidCallback? onEditExact;

  @override
  Widget build(BuildContext context) {
    final readout = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valueText,
          maxLines: 1,
          style: AppTypography.numeric.copyWith(
            fontSize: 40,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          unit,
          style: AppTypography.footnote.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.footnoteEmphasis.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final button in decrements) ...[
              Expanded(child: button),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              flex: 2,
              child: onEditExact == null
                  ? readout
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: onEditExact,
                      child: readout,
                    ),
            ),
            for (final button in increments) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: button),
            ],
          ],
        ),
      ],
    );
  }
}
