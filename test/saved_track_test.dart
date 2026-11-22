import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// A1c-Q: on a quiet receiver the saved distance comes from the raw accepted
/// positions, while stops and moving time stay on the smoothed track.
///
/// The claim is HYBRID, and the tests below are shaped around the two ways it
/// can quietly stop being hybrid. Deciding stops on raw positions instead
/// reopens A1c-J (+311 m and +3:43 moving on 7 Sep Zurich), which the moving
/// time equality catches. Taking splits from a different track than the total
/// makes the saved run disagree with itself, which the points-and-splits check
/// catches.
void main() {
  /// Splits and the stored cumulative distance describe the same total.
  ///
  /// The split SUM alone cannot fail: `splitsOf` computes the remainder as
  /// `distanceM - (km - 1) * 1000`, so it sums to whatever total it is handed.
  /// What can fail is handing it a total from one track and points from
  /// another, and that shows up as the last point's cumulative distance
  /// disagreeing with the total, and as the wrong number of whole kilometres.
  void expectSelfConsistent(SavedTrack saved, {required String on}) {
    final sum = saved.splits.fold<double>(
      0,
      (total, split) => total + split.distanceM,
    );
    expect(sum, closeTo(saved.distanceM, 1e-6), reason: '$on: split sum');
    expect(
      saved.points.last.cumulativeDistanceM,
      closeTo(saved.distanceM, 1e-6),
      reason: '$on: the points carry the same total the run row does',
    );
    expect(
      saved.splits.where((split) => !split.isPartial),
      hasLength(saved.distanceM ~/ 1000),
      reason: '$on: every whole kilometre of the saved total is a split',
    );
  }

  group('the side is decided by the measured inter-fix error', () {
    test('a quiet receiver saves its raw length: the noise-free rectangle', () {
      // Noise-free, so every metre the smoother loses here is corner-cutting
      // and nothing else. It is the case the bypass exists for: the smoothed
      // total is 1.9% long on a track with no noise to remove.
      final track = rectangleCircuit();
      final processor = replay(track);
      final saved = processor.savedTrack();

      expect(saved.source, DistanceSource.rawAccepted);
      expect(saved.interFixNoiseHighM, lessThan(bypassBelowInterFixNoiseM));

      double error(double metres) =>
          (metres - track.groundTruthDistanceM).abs() /
          track.groundTruthDistanceM;
      expect(
        error(processor.distanceM),
        greaterThan(0.015),
        reason: 'the fixture must discriminate: the smoother is off here',
      );
      expect(error(saved.distanceM), lessThan(0.005));
      expectSelfConsistent(saved, on: 'rectangle');
    });

    test('a noisy receiver keeps the smoother: the measured A32 walk', () {
      final processor = replay(measuredWalkKm());
      final saved = processor.savedTrack();

      expect(saved.source, DistanceSource.smoothed);
      expect(saved.interFixNoiseHighM, greaterThan(bypassBelowInterFixNoiseM));
      expect(saved.distanceM, processor.distanceM);
      expect(saved.splits.map((s) => s.distanceM), [
        for (final split in processor.splits) split.distanceM,
      ]);
      expectSelfConsistent(saved, on: 'measuredWalkKm');
    });

    test('a run too short to measure keeps the smoother', () {
      // Under 30 accepted fixes the estimator returns nothing, and "unknown"
      // must read as noisy: the conservative side is the one already shipped.
      final processor = TrackProcessor();
      straightKm().fixes.take(20).forEach(processor.add);
      processor.flush();
      final saved = processor.savedTrack();

      expect(saved.interFixNoiseHighM, isNull);
      expect(saved.source, DistanceSource.smoothed);
      expect(saved.distanceM, processor.distanceM);
    });

    test('an empty run saves nothing and says smoothed', () {
      final saved = TrackProcessor().savedTrack();

      expect(saved.source, DistanceSource.smoothed);
      expect(saved.distanceM, 0);
      expect(saved.splits, isEmpty);
    });
  });

  group('the report says which side was taken, and on what number', () {
    test('bypassed', () {
      final text = replay(rectangleCircuit()).diagnose().plainText();
      final saved = replay(rectangleCircuit()).savedTrack();

      expect(text, contains('raw accepted, stops from smoothed'));
      expect(
        text,
        contains('${saved.interFixNoiseHighM!.toStringAsFixed(3)} m'),
      );
      expect(text, contains(saved.distanceM.toStringAsFixed(0)));
    });

    test('kept', () {
      final text = replay(measuredWalkKm()).diagnose().plainText();

      expect(text, contains('the smoother is load-bearing'));
      expect(text, isNot(contains('raw accepted, stops from smoothed')));
    });
  });

  group('on every committed capture', () {
    // Pinned on the code of 19 Sep 2026. Distances to the metre; the noise to
    // the millimetre, because the side depends on it and a drift of the
    // estimator would otherwise move a receiver across 0.30 unannounced.
    const captures =
        <
          String,
          ({
            String path,
            bool bypass,
            double noise,
            double saved,
            double? truth,
          })
        >{
          '23 Aug A32': (
            path: 'captures/2026-08-23_1610m.ndjson',
            bypass: false,
            noise: 0.496,
            saved: 1667,
            truth: null,
          ),
          '24 Aug A32': (
            path: 'captures/2026-08-24_1610m.ndjson',
            bypass: false,
            noise: 0.582,
            saved: 1609,
            truth: null,
          ),
          '01 Sep Thane S26': (
            path: 'captures/2026-09-01_1930m.ndjson',
            bypass: true,
            noise: 0.179,
            saved: 1930,
            truth: 1930,
          ),
          '07 Sep Zurich S26': (
            path: 'captures/2026-09-07_zurich_4310m.ndjson',
            bypass: true,
            noise: 0.225,
            saved: 4160,
            truth: null,
          ),
          '08 Sep forest S26': (
            path: 'captures/run_fixes_20260908-102553.ndjson',
            bypass: true,
            noise: 0.178,
            saved: 4586,
            truth: null,
          ),
          '08 Sep shop S26': (
            path: 'captures/run_fixes_20260908-162309.ndjson',
            bypass: true,
            noise: 0.197,
            saved: 2448,
            truth: null,
          ),
          '18 Sep Zurich S26': (
            path: 'captures/2026-09-18_zurich_1890m.ndjson',
            bypass: true,
            noise: 0.151,
            saved: 1887,
            truth: 1890,
          ),
        };

    for (final entry in captures.entries) {
      final expected = entry.value;

      test(entry.key, () {
        final processor = TrackProcessor();
        for (final captured in parseCapture(
          File(expected.path).readAsStringSync(),
        )) {
          processor.add(captured.fix);
        }
        processor.flush();
        final saved = processor.savedTrack();

        expect(
          saved.source,
          expected.bypass
              ? DistanceSource.rawAccepted
              : DistanceSource.smoothed,
        );
        expect(saved.interFixNoiseHighM, closeTo(expected.noise, 0.0005));

        // The whole claim of hybrid over a plain bypass. The saved side
        // re-derives moving time from its own classification, so rewiring
        // stops onto the raw positions moves this number rather than
        // inheriting the forward pass's.
        expect(
          saved.movingTime,
          processor.movingTime,
          reason: 'moving time must not move when the distance source does',
        );
        expect(saved.distanceM, closeTo(expected.saved, 0.5));

        expectSelfConsistent(saved, on: entry.key);

        final truth = expected.truth;
        if (truth != null) {
          expect((saved.distanceM - truth).abs() / truth, lessThan(0.0025));
        }
      });
    }
  });
}
