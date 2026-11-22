import 'dart:math' as math;

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';

/// The activity ring: a track, an arc for progress, and the count inside.
///
/// Purely presentational — it takes a fraction and a label and knows nothing
/// about Health Connect, so every degraded state is somebody else's problem
/// and the ring can be rendered in a test without a platform.
class StepsRing extends StatelessWidget {
  const StepsRing({
    required this.progress,
    required this.label,
    this.isMuted = false,
    super.key,
  });

  /// 0..1. Values outside that are clamped by the painter.
  final double progress;

  /// Rendered in the middle of the ring. Usually the step count.
  final String label;

  /// Draws the arc in a grey rather than the ring colour, for a figure that
  /// is stale or unverified.
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final arc = isMuted ? AppColors.textLabel : AppColors.accentSuccess;

    return SizedBox(
      width: AppSpacing.ringDiameter,
      height: AppSpacing.ringDiameter,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          track: AppColors.surfaceControl,
          arc: arc,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.numericSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSpacing.ringStroke;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;

    canvas.drawArc(circle, 0, 2 * math.pi, false, trackPaint);

    final fraction = progress.clamp(0.0, 1.0);
    if (fraction <= 0) return;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      // Rounded, so a barely-started day still shows a visible cap rather
      // than a sliver that reads as nothing.
      ..strokeCap = StrokeCap.round
      ..color = arc;

    // Starts at twelve o'clock and runs clockwise, like every activity ring
    // the user has already seen.
    canvas.drawArc(
      circle,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.arc != arc || old.track != track;
}
