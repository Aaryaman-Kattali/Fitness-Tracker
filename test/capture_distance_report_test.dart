@Tags(['report', 'no-oracle'])
library;

import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every committed capture, replayed, with the numbers printed side by side.
///
/// **A reporting harness, not a budget.** It asserts only that each capture
/// still replays and produces a positive distance; the numbers themselves are
/// read by a person comparing a change against the run before it. Budgets that
/// mean something live in `device_capture_test.dart`, where there is ground
/// truth to score against.
///
/// It exists because A1c-J needed a before-and-after across all five captures
/// at once, and reading five separate test files for one number each is how a
/// regression on a capture nobody re-ran gets missed.
void main() {
  const captures = [
    'captures/2026-08-23_1610m.ndjson',
    'captures/2026-08-24_1610m.ndjson',
    'captures/2026-09-01_1930m.ndjson',
    'captures/2026-09-07_zurich_4310m.ndjson',
  ];

  test('every capture replays, and reports what it makes of itself', () {
    final rows = <String>[];
    for (final path in captures) {
      final processor = TrackProcessor(recordFilterStates: true);
      for (final delivered in parseCapture(File(path).readAsStringSync())) {
        processor.add(delivered.fix);
      }

      // The raw accepted path: the same accepted fixes summed fix to fix with
      // no smoothing and no stop rule at all. It is the number the phantom
      // distance was measured against, so it is worth printing beside the
      // pipeline's answer rather than inferring the gap.
      final points = processor.points;
      var rawAccepted = 0.0;
      for (var i = 1; i < points.length; i++) {
        rawAccepted += haversineMetres(
          points[i - 1].source.latitude,
          points[i - 1].source.longitude,
          points[i].source.latitude,
          points[i].source.longitude,
        );
      }

      final smoothed = processor.smoothedTrack();
      rows.add(
        '${path.split('/').last.padRight(32)} '
        'accepted ${points.length.toString().padLeft(5)}  '
        'raw ${rawAccepted.toStringAsFixed(0).padLeft(8)} m  '
        'forward ${processor.distanceM.toStringAsFixed(0).padLeft(6)} m  '
        'rts ${smoothed.distanceM.toStringAsFixed(0).padLeft(6)} m  '
        'moving ${processor.movingTime.inSeconds.toString().padLeft(5)} s',
      );

      expect(processor.distanceM, greaterThan(0));
      expect(smoothed.distanceM, greaterThan(0));
    }

    // Printing IS the deliverable here: this test reports numbers for a person
    // to compare across a change, and there is no assertion that could stand
    // in for reading them.
    // ignore: avoid_print
    print(['', 'CAPTURE DISTANCE REPORT', ...rows, ''].join('\n'));
  });
}
