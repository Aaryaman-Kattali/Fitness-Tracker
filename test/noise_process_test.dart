import 'dart:io';
import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/diagnostics/reconstruct_diagnostics.dart';
import 'package:fitness_tracker/features/activity/pipeline/noise_process.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The second-difference structure function, against fixtures whose noise
/// process is known exactly because it was generated.
///
/// This is the only oracle available for it. There is no ground truth for a
/// receiver's error, which is the whole reason the estimator exists — so the
/// thing that can be checked is whether it recovers a process that was drawn
/// from known parameters. Telling a correlated error from a white one is
/// exactly the failure PROGRESS.md A1c-8 records: an estimator that could not
/// see correlation reported the device's error as white and the fixture suite
/// was rebuilt on the wrong model twice.
///
/// `S(T) = E[|p(t+T) - 2p(t) + p(t-T)|^2]` is checked against the closed form
/// rather than through a fit, because there is no longer a fit. See
/// `measureNoiseProcess` for why one is not offered.
void main() {
  List<NoiseSample> samplesOf(List<RawFix> fixes) => [
    for (final fix in fixes)
      (at: fix.timestamp, latitude: fix.latitude, longitude: fix.longitude),
  ];

  /// `S(T)` for an exponentially-correlated error of magnitude [sigmaM] and
  /// correlation time [tau0S], from `S = 4.D(T) - D(2T)` with
  /// `D(t) = 4.sigma^2.(1 - exp(-t/tau0))`.
  double predictedS(double lagS, double sigmaM, double tau0S) =>
      4 *
      sigmaM *
      sigmaM *
      (3 - 4 * math.exp(-lagS / tau0S) + math.exp(-2 * lagS / tau0S));

  group('the estimator recovers a known process', () {
    test('the measured walk matches the closed form at the shortest lag', () {
      final measured = measureNoiseProcess(samplesOf(measuredWalkKm().fixes));

      expect(measured, isNotNull);
      final shortest = measured!.lags.first;
      expect(shortest.lagS, 1.0);

      // 2.50 m over 20 s predicts S(1) = 2.498 m^2. Generous, and deliberately
      // so: a structure function over one 10-minute walk is a noisy
      // instrument, and the question it is asked on a new receiver is "this
      // process, or something else entirely" — not "2.51 or 2.49".
      expect(
        shortest.secondDifferenceM2,
        closeTo(
          predictedS(1, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds),
          0.25,
        ),
      );
    });

    test('correlated rises with lag and white does not', () {
      // The contrast that proves the estimator sees correlation at all, and
      // the one the first-difference form got wrong. For white error D(T) is
      // flat from the first lag, so S is flat too; for a correlated error D
      // climbs toward its asymptote and S climbs with it.
      double spread(NoiseProcessReport r) =>
          r.lags.last.secondDifferenceM2 / r.lags.first.secondDifferenceM2;

      final correlated = measureNoiseProcess(
        samplesOf(measuredWalkKm().fixes),
      )!;
      final white = measureNoiseProcess(
        samplesOf(severeWhiteNoiseKm().fixes),
      )!;

      expect(spread(correlated), greaterThan(4));
      expect(spread(white), closeTo(1, 0.5));

      // And the white fixture's magnitude is the closed form with no
      // correlation to carry: D = 4.sigma^2 per lag, S = 3D.
      for (final lag in white.lags) {
        expect(lag.secondDifferenceM2, closeTo(3 * 4 * 15 * 15, 600));
      }
    });

    test('a straight fixture keeps lags that a loop does not', () {
      // The growth rule, from both sides. On a straight walk S/T falls and
      // most lags are noise-consistent; on a real loop every lag past the
      // first is the route turning, and reading one as receiver noise is the
      // error this rule exists to make visible.
      final straight = measureNoiseProcess(samplesOf(measuredWalkKm().fixes))!;
      expect(
        straight.lags.where((l) => l.noiseConsistent).length,
        greaterThan(1),
      );

      final processor = TrackProcessor();
      for (final arrival in parseCapture(
        File('captures/2026-08-23_1610m.ndjson').readAsStringSync(),
      )) {
        processor.add(arrival.fix);
      }
      final loop = processor.diagnose().noise!;
      expect(loop.lags.where((l) => l.noiseConsistent), hasLength(1));
    });

    test('the derived constant reproduces 0.035 at the A32 point', () {
      // Not a measurement — an identity. The scaling is anchored on what this
      // estimator read for the A32, so a receiver reading the same must come
      // back with the shipped value or the anchor has drifted.
      const point = NoiseProcessReport(
        medianDtS: referenceDtS,
        lags: [
          StructureLag(
            lagS: referenceDtS,
            triples: 1000,
            // S = 3.D at the white end, and D = 2.sigma_step^2.
            secondDifferenceM2:
                6 * referenceInterFixNoiseM * referenceInterFixNoiseM,
            noiseConsistent: true,
          ),
        ],
      );

      expect(
        point.derivedAccelerationNoiseMps2!.low,
        closeTo(referenceAccelerationNoiseMps2, 1e-9),
      );
    });

    test('the two A32 captures read the anchored bracket', () {
      // The anchor is a hardcoded number in lib/, taken from a replay. Pinned
      // here so it cannot drift: a change to the triples, the lag set or the
      // projection moves this reading, and moving it silently would make every
      // future ratio a comparison against a receiver nobody measured.
      //
      // The two walks are 17% apart at the white end. Recorded, not averaged:
      // it is the floor on what one walk can decide about a constant.
      const expected = {
        'captures/2026-08-23_1610m.ndjson': (
          low: referenceInterFixNoiseM,
          high: 0.496,
        ),
        'captures/2026-08-24_1610m.ndjson': (
          low: referenceInterFixNoiseSecondWalkM,
          high: 0.582,
        ),
      };

      for (final entry in expected.entries) {
        final processor = TrackProcessor();
        for (final arrival in parseCapture(
          File(entry.key).readAsStringSync(),
        )) {
          processor.add(arrival.fix);
        }

        final step = processor.diagnose().noise!.interFixNoise!;
        expect(step.lowM, closeTo(entry.value.low, 0.001), reason: entry.key);
        expect(step.highM, closeTo(entry.value.high, 0.001), reason: entry.key);
      }
    });

    test('the accepted stream is the sample, and it matters', () {
      // Measured 1 Sep 2026. The 23 Aug capture carries one fix the pipeline
      // rejects on the kinematic bound; a rejected fix sits at the centre of
      // one triple and at the end of two more, so it enters S(1) three times
      // and squared. Over the raw whole-second stream S(1) reads 1.746 m^2,
      // of which 790 comes from two triples; over the accepted stream it reads
      // 0.985. Measuring the wrong sample here inflates the receiver's noise
      // by 78% and there is nothing in the output to say so.
      final delivered = parseCapture(
        File('captures/2026-08-23_1610m.ndjson').readAsStringSync(),
      );

      final rawWholeSecond = [
        for (final arrival in delivered)
          if (arrival.fix.timestamp.millisecond == 0 &&
              arrival.fix.accuracyM <= TrackProcessor().maxAccuracyM)
            arrival.fix,
      ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final overRaw = measureNoiseProcess(samplesOf(rawWholeSecond))!;
      expect(overRaw.lags.first.secondDifferenceM2, closeTo(1.746, 0.01));

      final processor = TrackProcessor();
      for (final arrival in delivered) {
        processor.add(arrival.fix);
      }
      final overAccepted = processor.diagnose().noise!;
      expect(overAccepted.lags.first.secondDifferenceM2, closeTo(0.985, 0.01));
    });

    test('a track too short to measure returns null rather than a number', () {
      final short = samplesOf(measuredWalkKm().fixes.take(20).toList());
      expect(measureNoiseProcess(short), isNull);
    });
  });

  group('the report carries all three readings', () {
    test('a live capture states the split, the granularity and the noise', () {
      final text = replay(walkWithNetworkStream()).diagnose().plainText();

      expect(text, contains('STREAM DETECTION'));
      expect(text, contains('streams detected  2'));
      expect(text, contains('discriminator     timestamp granularity'));
      expect(text, contains('kept, receiver'));
      expect(text, contains('other producer'));

      expect(text, contains('TIMESTAMP GRANULARITY'));
      expect(text, contains('on a whole second'));
      expect(text, contains('both classes present'));

      expect(text, contains('MEASURED NOISE PROCESS'));
      expect(text, contains('derived accelerationNoiseMps2'));
      expect(text, contains('REPORT ONLY'));
    });

    test('the noise section reports a bracket and states its limitation', () {
      final text = replay(measuredWalkKm()).diagnose().plainText();

      expect(text, contains('S(T) = E[|p(t+T) - 2p(t) + p(t-T)|^2]'));
      expect(text, contains('a BRACKET, not a point'));
      expect(text, contains('NOT to'));
      expect(text, contains('acceleration'));
      expect(
        text,
        contains('no sigma, tau0 split is offered'),
        reason:
            'a split the data cannot resolve must be absent, not printed with '
            'a caveat under it',
      );
    });

    test('a single-stream capture says one stream and no cut', () {
      final text = replay(measuredWalkKm()).diagnose().plainText();

      expect(text, contains('streams detected  1'));
      expect(text, contains('n/a — no accuracy cut was used'));
      // Every fixture fix lands on a whole second, so the primary
      // discriminator has one class and nothing to separate. That is the
      // reading the S26 walk is being taken to get.
      expect(text, contains('EVERY fix is on a whole second'));
    });

    test('a reconstruction refuses to measure noise off smoothed points', () {
      final processor = replay(measuredWalkKm());
      final text = reconstructDiagnostics(
        points: processor.points,
        smoothedDistanceM: processor.distanceM,
        elapsed: processor.elapsed,
        movingTime: processor.movingTime,
        minMovingSpeedMps: TrackProcessor().minMovingSpeedMps,
        maxSpeedMps: TrackProcessor().maxSpeedMps,
        movingWindow: TrackProcessor().movingWindow,
      ).plainText();

      expect(text, contains('MEASURED NOISE PROCESS'));
      expect(
        text,
        contains('would\n  measure the filter rather than the receiver'),
        reason:
            'measuring the smoother and calling it the receiver is the '
            'exact failure A1c-8 records',
      );
    });
  });
}
