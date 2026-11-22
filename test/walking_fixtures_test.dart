import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The walking budgets, re-derived against a receiver that has been measured.
///
/// Every number in this file used to describe a guess. The suite was calibrated
/// to 15 m correlated error, then to 2.5 m correlated error, and the device
/// produced neither — see PROGRESS.md A1c-7 and A1c-8. It is now calibrated to
/// a structure function measured on the GPS stream of a walk whose length was
/// measured on the ground: ~2.5 m per axis, correlated over ~20 s, at exactly
/// 1.000 s between fixes.
///
/// **Two speeds, and the pair is still the point.** 1.6 m/s is what the device
/// recorded and is the primary case. 1.0 m/s is the pessimistic one: the
/// pipeline has no speed-dependent constant, so what changes with speed is the
/// ratio of the error envelope to the displacement between fixes, and a slower
/// walk is the same problem with less signal in it.
///
/// The group that used to sit here testing "at 1.6 m/s" separately is gone. It
/// ran `briskWalkingKm`, which after the rebuild IS the primary fixture, so it
/// was asserting the same numbers twice under two names.
void main() {
  group('the measured operating point', () {
    // THE BUDGET THAT COUNTS. 1.6 m/s, 2.5 m per axis over a 20 s correlation
    // time, reported accuracy log-normal about 2.5 m — the model measured off
    // the device rather than reasoned about.
    //
    // 2.5%, from a measurement of 1.14% on the default draw and 1.79% on the
    // worst of seven. Not 1%: that was the budget when the fixture carried an
    // uncorrelated error the device does not produce, and the pipeline would
    // fail it for being asked the wrong question rather than for regressing.
    // Not 5% either — a budget four times the measurement records that nothing
    // has broken yet rather than detecting when it does.
    test('a measured kilometre comes out within 2.5%', () {
      final processor = replay(measuredWalkKm());
      expect(processor.distanceM, closeTo(1000, 25));
    });

    test('an irregular cadence does not change that', () {
      final processor = replay(measuredVariableCadenceWalk());
      expect(processor.distanceM, closeTo(1000, 25));
    });

    test('the lean is long, small, and on every draw', () {
      // This assertion used to say the opposite. At the old 2.5 m UNCORRELATED
      // model the sign varied across draws, and that was recorded here as
      // evidence of an unbiased estimator. With the error correlated the way
      // the device actually correlates it, every draw runs long by ~1.25%.
      //
      // That is not a defect being papered over, it is the finding: correlated
      // error bends a track outward and a smoother cannot tell the bend from
      // the route. It is also why the real 1610 m walk reads +3.6% rather than
      // 0%. Stated as a direction and a size, so that a change of either fails.
      const seeds = [1, 7, 99, 20260821, 555111];
      final totals = [
        for (final seed in seeds) replay(measuredWalkKm(seed: seed)).distanceM,
      ];

      final mean = totals.reduce((a, b) => a + b) / totals.length;
      expect(mean, closeTo(1012, 12), reason: '$totals');
      for (var i = 0; i < seeds.length; i++) {
        expect(
          totals[i],
          closeTo(1000, 25),
          reason: 'seed ${seeds[i]} gave ${totals[i].toStringAsFixed(1)} m',
        );
        expect(
          totals[i],
          greaterThan(1000),
          reason:
              'the lean is long on every draw at this operating point; a draw '
              'reading short would mean the error model has changed',
        );
      }
    });

    test('the raw sum is 13% long and the pipeline removes all of it', () {
      // The measurement that says where the excess comes from. A naive sum of
      // the delivered fixes reads ~1136 m for a true 1000 m. The pipeline
      // returns ~1011.
      //
      // This test used to assert the raw sum was within 1%, which was true of
      // the uncorrelated fixture and is not true of the device. On the real
      // capture the GPS stream's raw path length was 1766 m against a 1610 m
      // walk — the same +10% shape, at the same sampling rate.
      final report = replay(measuredWalkKm()).diagnose();

      expect(report.rawDeliveredDistanceM, greaterThan(1100));
      expect(report.rawDeliveredDistanceM, lessThan(1180));
      expect(report.smoothedDistanceM, closeTo(1000, 25));
    });

    test('no smoothed step implies a speed a walker could not hold', () {
      final report = replay(measuredVariableCadenceWalk()).diagnose();
      expect(
        report.acceptedSpeedMps!.max,
        lessThan(3.5),
        reason:
            'measured ${report.acceptedSpeedMps!.max.toStringAsFixed(2)} m/s '
            'against a 1.6 m/s walk',
      );
    });
  });

  group('the second stream, which no fixture used to model', () {
    // 74 network fixes interleaved into the same 1000 m walk, on fractional
    // timestamps, reporting a 27 m median. This is the mechanism that put
    // +8.1% on the first ground-truth walk, and the suite was blind to it.
    test('the accuracy filter rejects almost all of it', () {
      final processor = replay(walkWithNetworkStream());
      final admitted = processor.points
          .where((p) => p.source.timestamp.millisecond != 0)
          .length;

      expect(processor.rejectedFor(FixRejection.accuracy), greaterThan(60));
      expect(
        admitted,
        lessThan(6),
        reason:
            'a handful survive because the fixture draws accuracy from a '
            'log-normal whose tail reaches under 9 m, which the device also '
            'could do and this capture happened not to',
      );
    });

    test('and the distance is unharmed by what does get through', () {
      // The property that matters. The raw sum over the merged stream is
      // ~3900 m for a 1000 m walk — the network fixes trace nearly three times
      // the route on their own, exactly as they did on the device — and the
      // pipeline still lands within 2.5%.
      final track = walkWithNetworkStream();
      final processor = replay(track);

      expect(processor.distanceM, closeTo(1000, 25));
      expect(
        processor.distanceM,
        closeTo(replay(measuredWalkKm()).distanceM, 5),
        reason:
            'the GPS fixes are byte-identical between the two fixtures, so '
            'any difference beyond a few metres is the network stream leaking '
            'into the track',
      );
    });
  });

  group('the pessimistic walk, at 1.0 m/s', () {
    // Same error, less signal. Every budget here is looser than the primary
    // one and deliberately so: the point of keeping this fixture is to turn
    // "walking slowly is harder" into a number, not to hold it to the same
    // standard.
    test('a slow walked kilometre comes out within 5%', () {
      final processor = replay(walkingKm());
      expect(processor.distanceM, closeTo(1000, 50));
    });

    test('it is consistent across noise draws', () {
      const seeds = [1, 7, 99, 20260821, 555111];
      final totals = [
        for (final seed in seeds) replay(walkingKm(seed: seed)).distanceM,
      ];

      final mean = totals.reduce((a, b) => a + b) / totals.length;
      expect(mean, closeTo(1035, 25), reason: '$totals');
      for (final total in totals) {
        expect(total, closeTo(1000, 50), reason: '$totals');
      }
    });

    test('an irregular cadence does not change the distance', () {
      final processor = replay(variableCadenceWalk());
      expect(processor.distanceM, closeTo(1000, 50));
    });

    test('the walk with a stop measures the walking, not the standing', () {
      // 10%, against 1% before the rebuild, and the change is the stationary
      // model rather than the pipeline. The stop used to carry 1.5 m of error
      // correlated over 300 s, which barely moves within a three-minute stand.
      // It now carries the measured 2.5 m over 20 s, so the receiver genuinely
      // wanders while the walker does not, and some of that wander reaches the
      // total. A phone on a wall really does do this.
      final track = walkWithStop();
      final processor = replay(track);
      expect(
        processor.distanceM,
        closeTo(track.groundTruthDistanceM, track.groundTruthDistanceM * 0.1),
      );
    });
  });

  group('the spur is rejected, and by the right filter', () {
    test('exactly one fix is thrown out for implied speed', () {
      final report = replay(walkWithSpurSpike()).diagnose();

      expect(
        report.rejections![FixRejection.implausibleSpeed],
        1,
        reason: 'the spur fix, and nothing else',
      );
      expect(
        report.rejections![FixRejection.accuracy] ?? 0,
        0,
        reason:
            'the spur reports 8 m, inside the 9 m threshold — if the accuracy '
            'filter caught it, the fixture is not testing the kinematic bound '
            'at all. It reported 30 m before maxAccuracyM fell to 9, which '
            'would now be caught here and would rot the test silently.',
      );
    });

    test('no accepted step goes anywhere near the spur', () {
      // Read this as defence in depth, not as a second proof that the
      // kinematic bound works — the test above is that proof, because it reads
      // the rejection count directly.
      //
      // VERIFIED BY MUTATION, with an informative result. Removing the bound
      // entirely (maxSpeedMps = 1e9) still leaves this passing: 601.8 m with a
      // largest step of 2.5 m. The smoother catches the spur on its own. The
      // fix reports a plausible accuracy against a filter that is confident in
      // a steady 1 m/s walk, so its Kalman gain is small and it barely moves
      // the estimate — a 250 m outlier lands as a 2.5 m nudge.
      //
      // That is worth knowing in both directions. The pipeline has two
      // independent defences against the Strava spur, which is reassuring; and
      // this assertion alone would not notice if one of them were removed,
      // which is why the rejection count is asserted separately.
      final report = replay(walkWithSpurSpike()).diagnose();
      expect(
        report.largestStepM,
        lessThan(10),
        reason:
            'a walk covers ~1 m between fixes; anything approaching '
            '${spurLengthM.toInt()} m means the spur reached the track',
      );
    });

    test('a clean walk with one spur comes out within 1%', () {
      // The noise-free budget. The spur must contribute nothing.
      final processor = replay(walkWithSpurSpike());
      expect(
        processor.distanceM,
        closeTo(600, 6),
        reason:
            'a ${spurLengthM.toInt()} m spur counted out and back would add '
            '${(2 * spurLengthM).toInt()} m',
      );
    });
  });

  group('moving time', () {
    test('the three-minute stop is excluded, within the decision window', () {
      final track = walkWithStop();
      final processor = replay(track);

      expect(
        processor.elapsed,
        track.groundTruthElapsed,
        reason: 'elapsed time is wall clock and includes the stop',
      );
      expect(
        processor.movingTime.inSeconds,
        closeTo(track.groundTruthMovingSeconds!, 12),
        reason:
            'the same ±12 s the runner is allowed: the 10 s window cannot '
            'know a stop has begun until it has watched 10 s go by',
      );
    });

    test('walking is not mistaken for standing still', () {
      // The margin that shrank. A walk is 1.0 m/s against a 0.5 m/s threshold,
      // where a run was 2.78 — so where the runner had five and a half times
      // the threshold to play with, a walker has two.
      final report = replay(walkingKm()).diagnose();
      expect(
        report.totalStopped.inSeconds,
        lessThan(20),
        reason:
            'nothing in this fixture stands still; every second called '
            'stopped is the detector losing a walker in the noise',
      );
    });

    test('an irregular cadence does not invent stops either', () {
      final report = replay(variableCadenceWalk()).diagnose();
      expect(report.totalStopped.inSeconds, lessThan(20));
    });

    test('a brisk walk is never mistaken for standing still', () {
      final report = replay(measuredVariableCadenceWalk()).diagnose();
      expect(report.totalStopped.inSeconds, lessThan(20));
    });
  });

  group('pace', () {
    test('a 1.0 m/s walk reads as about 16:40/km', () {
      // 965 s/km measured against a true 1000. The gap is the distance lean:
      // pace is moving time over distance, so a track that reads 3.4% long
      // reads correspondingly fast. Budgeted at ±45 s rather than ±30 for
      // exactly that reason — tightening it would be asserting the distance
      // budget twice, in the units where it is least legible.
      final processor = replay(walkingKm());
      expect(processor.averagePaceSecPerKm, closeTo(1000, 45));
    });

    test('a 1.6 m/s walk reads as about 10:25/km', () {
      final processor = replay(measuredWalkKm());
      expect(processor.averagePaceSecPerKm, closeTo(625, 25));
    });

    test('average pace still agrees with moving time over distance', () {
      // Against moving time in microseconds, not in whole seconds. At an
      // irregular cadence the accumulated moving time is genuinely fractional
      // — 847.2 s here — and comparing a fractional pace against a rounded
      // one disagrees by up to half a second per kilometre for no reason
      // except the rounding. The runner's version of this test never noticed,
      // because at exactly 1 Hz the total is always a whole number.
      final processor = replay(variableCadenceWalk());
      expect(
        processor.averagePaceSecPerKm,
        closeTo(
          processor.movingTime.inMicroseconds /
              1e6 /
              (processor.distanceM / 1000),
          0.01,
        ),
      );
    });
  });
}
