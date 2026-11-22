import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// Smoothing must happen BEFORE distance accumulates, not after.
///
/// This is the one ordering in the pipeline that is silently wrong rather than
/// loudly wrong. Smooth after accumulating and the map looks clean while the
/// total quietly integrated every metre of jitter, so the bug ships looking
/// correct and is only visible against a known distance.
///
/// The order is therefore encoded here as a *failing alternative* rather than
/// as a comment in the implementation. Each test builds the wrong-order
/// version from the same accepted fixes the pipeline used — `TrackPoint.source`
/// is the raw fix behind each smoothed point — and asserts it is wrong, beside
/// the real pipeline being right. A comment cannot fail; this can.
void main() {
  group('accumulating before smoothing over-reports', () {
    test('on the realistic fixture, on every noise draw', () {
      // Measured over the ACCEPTED fixes, so filtering is held constant and
      // the only difference between the two numbers is the order of smoothing
      // and accumulation. That is a slightly smaller over-report than the
      // fixture's own 10-30% calibration, which covers every fix including the
      // three cold-start ones that are discarded before either order runs.
      for (final seed in [1, 7, 99, 20260820, 555111]) {
        final processor = replay(urbanCanyonKm(seed: seed));
        final wrongOrder = _distanceOverRawFixes(processor);
        final rightOrder = processor.distanceM;
        final detail =
            'seed $seed: wrong=${wrongOrder.toStringAsFixed(1)} '
            'right=${rightOrder.toStringAsFixed(1)}';

        expect(rightOrder, closeTo(1000, 50), reason: detail);
        expect(
          wrongOrder,
          greaterThan(1080),
          reason: '$detail — the wrong order must be visibly long',
        );
        expect(
          wrongOrder,
          greaterThan(rightOrder * 1.05),
          reason:
              '$detail — the orders must be far enough apart that this '
              'could not pass by accident',
        );
      }
    });

    test('catastrophically on independent per-fix noise', () {
      // The same mistake, with the volume turned up: on white noise the
      // wrong order returns more than seven times the true distance.
      // 4000, not the 6000 this asserted before. The fixture's reported
      // accuracy fell from 15 m to 8 m so that the accuracy filter would stop
      // rejecting every fix in it — which means the kinematic bound now sees
      // those fixes and throws out 132 of them, and the raw sum over what is
      // left is correspondingly shorter. The ratio the test is really about is
      // untouched: 4179 m the wrong way round against 1180 m the right way.
      final processor = replay(severeWhiteNoiseKm());

      expect(_distanceOverRawFixes(processor), greaterThan(4000));
      expect(processor.distanceM, lessThan(2000));
    });

    test('and both orders agree when there is no noise to integrate', () {
      // The control. On a clean track the two orders must give the same
      // answer, which proves the gap above is the jitter and not some other
      // difference between the two code paths.
      final processor = replay(straightKm());

      expect(
        _distanceOverRawFixes(processor),
        closeTo(processor.distanceM, 1),
      );
      expect(processor.distanceM, closeTo(1000, 10));
    });
  });
}

/// Distance accumulated from the accepted fixes *before* smoothing — the
/// wrong order, built from exactly the fixes the pipeline accepted so that
/// filtering is not what the comparison is measuring.
double _distanceOverRawFixes(TrackProcessor processor) {
  final points = processor.points;
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += haversineMetres(
      points[i - 1].source.latitude,
      points[i - 1].source.longitude,
      points[i].source.latitude,
      points[i].source.longitude,
    );
  }
  return total;
}
