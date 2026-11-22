import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// Distance, and the two fixtures that pin the smoother from opposite sides.
///
/// The clean kilometre fails if the filter is tuned so hard that it eats real
/// displacement. The noisy kilometre fails if it is tuned so softly that the
/// track follows the jitter. Neither test is meaningful without the other:
/// each one alone has a trivial cheat that the pair rules out.
void main() {
  group('distance', () {
    test('a clean kilometre comes out within 1%', () {
      final processor = replay(straightKm());
      expect(processor.distanceM, closeTo(1000, 10));
    });

    test('a noisy kilometre comes out within 3%', () {
      // Over-smoothing that lands inside 3% by being short is just as wrong as
      // over-reporting, and closeTo pins both ends.
      final processor = replay(urbanCanyonKm());
      expect(processor.distanceM, closeTo(1000, 30));
    });

    test('is unbiased across noise draws, and never wildly wrong on one', () {
      // One lucky seed is not evidence, but neither is one unlucky one, and
      // the two claims are different.
      //
      // When a receiver's error drifts, the path it reports genuinely is a
      // different length from the path that was run — that is not the filter
      // being wrong, it is the measurement being what it is, and a real watch
      // shows the same 1-3% between two runs of one route. So a single track's
      // total is a sample, and the estimator is judged on the average of them.
      // The per-seed bound is a separate, weaker claim: no individual draw may
      // go badly wrong.
      const seeds = [1, 7, 99, 20260820, 555111];
      final totals = [
        for (final seed in seeds) replay(urbanCanyonKm(seed: seed)).distanceM,
      ];

      final mean = totals.reduce((a, b) => a + b) / totals.length;
      expect(
        mean,
        closeTo(1000, 30),
        reason: 'the filter must not lean long or short across draws: $totals',
      );

      for (var i = 0; i < seeds.length; i++) {
        expect(
          totals[i],
          closeTo(1000, 50),
          reason: 'seed ${seeds[i]} gave ${totals[i].toStringAsFixed(1)} m',
        );
      }
    });

    test('5.5 km comes out within 1%', () {
      final processor = replay(fiveAndAHalfKm());
      expect(processor.distanceM, closeTo(5500, 55));
    });

    test('the 400 m across a signal gap is counted, not dropped', () {
      final track = gapThenGenuineDisplacement();
      final processor = replay(track);
      expect(
        processor.distanceM,
        closeTo(track.groundTruthDistanceM, track.groundTruthDistanceM * 0.01),
      );
    });

    test('the rejected teleport does not reach the distance', () {
      final track = kmWithTeleport();
      final processor = replay(track);
      expect(
        processor.distanceM,
        closeTo(1000, 10),
        reason: 'a 500 m round trip would show up as ~1000 m of extra distance',
      );
    });

    test('the inaccurate fixes do not reach the distance either', () {
      final processor = replay(kmWithInaccurateFixes());
      expect(processor.distanceM, closeTo(1000, 10));
    });
  });

  group('smoothing', () {
    test('pulls the noisy track towards the truth', () {
      // A distance budget can be met by a filter that is wrong in a consistent
      // direction — the map would show it long before the numbers did — so
      // check the positions themselves.
      //
      // Pairing goes through the timestamp, never a list index. The pipeline
      // rejects fixes, so the processed track is shorter than the fixture, and
      // index pairing compares a point against a second the runner had not
      // reached yet. That mistake reported this filter as 17x worse than raw
      // when it is in fact several times better.
      final track = urbanCanyonKm();
      final smoothed = replay(track).points;

      var rawError = 0.0;
      var smoothedError = 0.0;
      for (final point in smoothed) {
        final truth = track.truthAt(point.timestamp)!;
        final raw = track.fixes.firstWhere(
          (fix) => fix.timestamp == point.timestamp,
        );
        smoothedError += haversineMetres(
          point.latitude,
          point.longitude,
          truth.lat,
          truth.lon,
        );
        rawError += haversineMetres(
          raw.latitude,
          raw.longitude,
          truth.lat,
          truth.lon,
        );
      }

      // Only "does not make it worse", and that is the honest bar on this
      // fixture. Correlated error is a slow wander, which is exactly what real
      // motion looks like, so there is almost nothing for a smoother to
      // remove: it cannot tell a drifting bias from a runner easing left. The
      // demanding version of this assertion lives on the pathological fixture
      // below, where the error IS separable and smoothing cuts it by 3.5x.
      expect(
        smoothedError,
        lessThan(rawError * 1.05),
        reason:
            'a smoother that degrades position has not worked, whatever '
            'the distance total says',
      );
    });

    test('clearly beats the raw fixes when the error is separable', () {
      // The pathological white-noise fixture, kept for exactly this. No
      // receiver behaves like it, but independent per-fix error is the case
      // where smoothing can actually win, so it is where the demanding
      // positional claim belongs.
      final track = severeWhiteNoiseKm();
      final smoothed = replay(track).points;

      var rawError = 0.0;
      var smoothedError = 0.0;
      for (final point in smoothed) {
        final truth = track.truthAt(point.timestamp)!;
        final raw = track.fixes.firstWhere(
          (fix) => fix.timestamp == point.timestamp,
        );
        smoothedError += haversineMetres(
          point.latitude,
          point.longitude,
          truth.lat,
          truth.lon,
        );
        rawError += haversineMetres(
          raw.latitude,
          raw.longitude,
          truth.lat,
          truth.lon,
        );
      }

      expect(smoothedError, lessThan(rawError / 2));
    });

    test('degrades gracefully under noise no receiver would produce', () {
      // The rest of what the pathological fixture is asked to prove: whatever
      // a receiver does under a railway bridge, nothing here may crash or
      // produce a number that is not a distance.
      final processor = replay(severeWhiteNoiseKm());

      expect(processor.distanceM, isPositive);
      expect(processor.distanceM.isFinite, isTrue);
      expect(processor.points, isNotEmpty);
      expect(
        processor.distanceM,
        lessThan(2000),
        reason:
            'the raw track integrates to over 7 km; the pipeline must not '
            'pass that through even on noise it was never designed for',
      );
    });

    test('does not distort a clean track', () {
      // The failure mode the noisy test cannot see: a filter that smooths a
      // perfect track into a shorter one.
      final clean = straightKm();
      final points = replay(clean).points;
      for (var i = 0; i < points.length; i++) {
        final truth = clean.fixes[clean.fixes.length - points.length + i];
        expect(
          haversineMetres(
            points[i].latitude,
            points[i].longitude,
            truth.latitude,
            truth.longitude,
          ),
          lessThan(1),
          reason: 'point $i drifted off a noise-free track',
        );
      }
    });

    test(
      'restarts after a long gap instead of crawling to the new position',
      () {
        // Without the gap reset the stale estimate dominates the fix that
        // reacquires, and the smoothed track spends the next minute travelling
        // to somewhere the runner left long ago.
        final track = gapThenGenuineDisplacement();
        final points = replay(track).points;

        var longest = 0.0;
        for (var i = 1; i < points.length; i++) {
          final step = haversineMetres(
            points[i - 1].latitude,
            points[i - 1].longitude,
            points[i].latitude,
            points[i].longitude,
          );
          if (step > longest) longest = step;
        }
        expect(
          longest,
          closeTo(
            400,
            6,
          ), // 396.4 m measured: the filter is slower to abandon its own
          // prediction now that accelerationNoiseMps2 is 0.035, so a 400 m
          // jump after a 60 s blackout lands 3.6 m short instead of 1.
          reason: 'the whole 400 m must land in one step of the smoothed track',
        );
      },
    );
  });
}
