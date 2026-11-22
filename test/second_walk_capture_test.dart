import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The second ground-truth walk: same 1.61 km loop, 24 Aug 2026.
///
/// `device_capture_test` holds the 23 Aug walk and stays as it is. This file
/// exists because one capture cannot show what two can, and what two show is
/// the point: the same route, the same phone, the same code, +3.6% predicted
/// from one and -0.3% measured on the other.
///
/// Committed at `captures/2026-08-24_1610m.ndjson`, renamed from the device's
/// `run_fixes_20260824-152512.ndjson` to match the naming the first capture
/// already uses. Not reproducible: it cost a walk.
const capturePath = 'captures/2026-08-24_1610m.ndjson';

/// The same loop, measured the same way, as the 23 Aug walk.
const groundTruthM = 1610.0;

/// Strava on the same walk. Not a budget — a scale.
const stravaM = 1590.0;

void main() {
  final contents = File(capturePath).readAsStringSync();
  final delivered = parseCapture(contents);
  final all = [for (final captured in delivered) captured.fix];

  List<RawFix> streamOf({required bool wholeSecond}) => [
    for (final fix in all)
      if ((fix.timestamp.millisecond == 0) == wholeSecond) fix,
  ];

  final gps = streamOf(wholeSecond: true);
  final network = streamOf(wholeSecond: false);

  group('the capture itself', () {
    test('is intact: 913 fixes, in arrival order, with the seq numbers', () {
      expect(delivered.length, 913);
      for (var i = 0; i < delivered.length; i++) {
        expect(delivered[i].seq, i);
      }
    });

    test('carries 73 out-of-order arrivals', () {
      var outOfOrder = 0;
      for (var i = 1; i < delivered.length; i++) {
        if (!delivered[i].fix.timestamp.isAfter(
          delivered[i - 1].fix.timestamp,
        )) {
          outOfOrder++;
        }
      }
      expect(outOfOrder, 73);
    });

    test('splits 819 GPS / 94 network on the millisecond field', () {
      expect(gps.length, 819);
      expect(network.length, 94);
    });
  });

  group('THE STREAMS OVERLAP ON THIS WALK', () {
    // The regression the first capture's test was written to catch, and it has
    // now happened. `device_capture_test` says, of the 23 Aug walk:
    //
    //   "These assertions are about the DATA, not about the pipeline. They
    //    exist so that if a second capture is ever added and the two streams
    //    overlap in reported accuracy, this fails loudly rather than the
    //    threshold quietly starting to admit wifi fixes again."
    //
    // On 23 Aug the gap was clean: worst GPS 8.10 m, best network 9.60 m, and
    // `maxAccuracyM: 9` sat between them. On this walk the ranges cross.
    test('best network accuracy is BETTER than worst GPS accuracy', () {
      final worstGps = gps
          .map((f) => f.accuracyM)
          .reduce((a, b) => a > b ? a : b);
      final bestNetwork = network
          .map((f) => f.accuracyM)
          .reduce((a, b) => a < b ? a : b);

      expect(worstGps, closeTo(5.00, 0.01));
      expect(bestNetwork, closeTo(4.20, 0.01));
      expect(
        bestNetwork,
        lessThan(worstGps),
        reason:
            'the streams cross here — reported accuracy alone can no longer '
            'separate them, and A1c-A rested on the claim that it could',
      );
    });

    test('one network fix passes the accuracy threshold', () {
      // Not many. One. But the count is not the finding — the mechanism is.
      final admitted = [
        for (final fix in network)
          if (fix.accuracyM < TrackProcessor().maxAccuracyM) fix,
      ];
      expect(admitted, hasLength(1));
      expect(admitted.single.accuracyM, closeTo(4.20, 0.01));
    });

    test('and it is now stopped for what it is, not by luck', () {
      // It used to be stopped by COLD START, at seq 1, and only because it
      // arrived second. At seq 400 it would have been accepted, and a 4.2 m
      // network fix lands tens of metres off the GPS position — that is what
      // the other 93 do — so it was a spur that did not happen rather than a
      // spur the pipeline prevented. That is the whole reason StreamDetector
      // exists, and the reason recorded here is the proof it is wired in:
      // rejected on its timestamp granularity, at any position in the
      // sequence. The mutation is in stream_wiring_test.
      final processor = TrackProcessor();
      replayCapture(contents, into: processor);

      final subThreshold = network.firstWhere(
        (fix) => fix.accuracyM < TrackProcessor().maxAccuracyM,
      );
      expect(delivered.indexWhere((c) => identical(c.fix, subThreshold)), 1);

      final reasons = processor.rejected
          .where((r) => r.fix.timestamp == subThreshold.timestamp)
          .map((r) => r.reason)
          .toList();
      expect(reasons, [FixRejection.otherStream]);
    });

    test('so no network fix reached the track — on this walk', () {
      final processor = TrackProcessor();
      replayCapture(contents, into: processor);

      final admitted = processor.points
          .where((point) => point.source.timestamp.millisecond != 0)
          .length;
      expect(admitted, 0);
    });
  });

  group('what the two streams trace', () {
    test('network alone traces 4602 m across a 1610 m walk', () {
      expect(_pathLength(network), closeTo(4602, 5));
      expect(_pathLength(network), greaterThan(2.8 * groundTruthM));
    });

    test('GPS alone is 1642 m, +2.0% before any smoothing', () {
      expect(_pathLength(gps), closeTo(1642, 5));
    });

    test('the raw total depends on which order you sum it in', () {
      // 7913 in arrival order, 7994 in timestamp order, and the difference is
      // the 73 out-of-order arrivals. Neither is wrong; they answer different
      // questions, and the diagnostics report accumulates in arrival order
      // because that is what the pipeline actually saw.
      expect(_arrivalOrderLength(all), closeTo(7913, 5));
      expect(_pathLength(all), closeTo(7994, 5));
    });
  });

  group('distance against 1610 m measured on the ground', () {
    final processor = TrackProcessor();

    setUpAll(() => replayCapture(contents, into: processor));

    test('the filter chain is clean on this walk', () {
      final byReason = <FixRejection, int>{};
      for (final rejected in processor.rejected) {
        byReason[rejected.reason] = (byReason[rejected.reason] ?? 0) + 1;
      }

      // 92, not the 91 this used to read, and cold start is the reason. It
      // runs after the quality and stream gates now, so its three fixes come
      // out of the stream being kept; the network fix it used to spend one of
      // them on is filed under accuracy instead.
      expect(byReason[FixRejection.accuracy], 92);
      expect(byReason[FixRejection.otherStream], 1);
      expect(byReason[FixRejection.coldStart], 3);
      expect(byReason[FixRejection.arrivedTooLate], 1);
      expect(
        byReason[FixRejection.implausibleSpeed],
        isNull,
        reason: 'nothing needed the kinematic bound once the streams were out',
      );
    });

    test('reads 1609 m, within 2% of the truth', () {
      // The stated goal: within 2% on any geometry. Ground truth is
      // Google-Maps-traced and carries +/-1-2% itself, so -0.09% and Strava's
      // -1.2% are indistinguishable. Parity, not victory.
      //
      // 1605.2 m before the stream detector, and the 3.3 m is two separate
      // effects measured apart in stream_wiring_test: +1.0 m from cold start
      // moving behind the quality and stream gates, and +2.3 m from the 4.20 m
      // network fix no longer reaching the track.
      final error = (processor.distanceM - groundTruthM) / groundTruthM;
      expect(processor.distanceM, closeTo(1608.5, 2));
      expect(
        error.abs(),
        lessThan(0.02),
        reason:
            'measured ${processor.distanceM.toStringAsFixed(1)} m '
            '(${(100 * error).toStringAsFixed(1)}%) against $groundTruthM m; '
            'Strava got $stravaM m on the same walk',
      );
    });

    test('this walk was faster and cleaner than the first one', () {
      // The reason the same route and the same code moved from +3.6% to -0.3%.
      // Recorded as an assertion rather than a note so that a future reader
      // cannot mistake the two walks for a repeat measurement of one thing.
      final acceptedAccuracy = [
        for (final point in processor.points) point.source.accuracyM,
      ]..sort();
      // 4.80, and it was 4.90 before the chain was reordered: the 4.90 m fix
      // is one of the three cold start now spends its budget on.
      expect(acceptedAccuracy.last, closeTo(4.80, 0.01));

      final speed = processor.distanceM / processor.movingTime.inSeconds;
      expect(speed, closeTo(1.96, 0.02));
    });
  });
}

/// Summed great-circle length through the fixes in timestamp order.
double _pathLength(List<RawFix> fixes) {
  final ordered = [...fixes]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return _sum(ordered);
}

/// The same sum, in the order the fixes were delivered.
double _arrivalOrderLength(List<RawFix> fixes) => _sum(fixes);

double _sum(List<RawFix> fixes) {
  var total = 0.0;
  for (var i = 1; i < fixes.length; i++) {
    total += haversineMetres(
      fixes[i - 1].latitude,
      fixes[i - 1].longitude,
      fixes[i].latitude,
      fixes[i].longitude,
    );
  }
  return total;
}
