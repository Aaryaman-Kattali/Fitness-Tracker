import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The Rauch-Tung-Striebel backward pass, and what it actually does.
///
/// It was built expecting to fix corner-cutting: a causal filter reaching a
/// bend has not seen the bend, and a backward pass has. **It does the
/// opposite.** On noisy straight motion it is close to a complete fix — the
/// measured walk goes from +1.14% to +0.00% — and on turns it is far worse
/// than the filter, because the correction it applies is the constant-velocity
/// motion model, applied harder. A hairpin is a large acceleration, the model
/// says large accelerations do not happen, and the smoother has the whole
/// future as evidence for enforcing that. The switchback loses 48% of its
/// length, and both ground-truth walks — which are loops, so they have corners
/// — come out about 7 percentage points shorter and further from the truth.
///
/// So the numbers below are not a budget and nothing should be tuned toward
/// them. They are the record of a mechanism that works and is not, on this
/// evidence, an improvement to ship. See PROGRESS.md under A1c-14.
void main() {
  TrackProcessor capture(String path, {double an = 0.035}) {
    final processor = TrackProcessor(
      accelerationNoiseMps2: an,
      recordFilterStates: true,
    );
    replayCapture(File(path).readAsStringSync(), into: processor);
    return processor;
  }

  group('it is a smoother, and these are the checks that say so', () {
    test('a noise-free track is exact at every tuning', () {
      // The control. With exact measurements and no turns there is nothing to
      // smooth, and any pass that moves this number is wrong before any
      // question of tuning arises.
      for (final track in [straightKm(), straightControlWalk()]) {
        for (final an in const [0.2, 0.035, 0.005]) {
          final smoothed = replay(
            track,
            into: TrackProcessor(
              accelerationNoiseMps2: an,
              recordFilterStates: true,
            ),
          ).smoothedTrack();
          expect(
            smoothed.distanceM,
            closeTo(track.groundTruthDistanceM, 0.01),
            reason: '${track.name} at $an',
          );
        }
      }
    });

    group('the state tape is opt-in, and the default is off', () {
      // A1-7's backward pass is not wired to the saved track and nothing in
      // production calls it, but the tape it needs was being written on every
      // real recording anyway -- ~128 bytes per accepted fix, ~0.9 MB on a
      // two-hour walk. A Kalman filter forgets by design, so the tape cannot
      // be rebuilt afterwards; it is written during the run or the backward
      // pass is impossible. That makes "off by default, on in the harness"
      // the only arrangement that does not charge the phone for a laptop's
      // analysis.

      test('a processor built the ordinary way refuses to smooth', () {
        // The important half: it THROWS rather than smoothing an empty tape.
        // An empty tape would sail through _rtsPositions and return a track
        // with a plausible-looking distance on it, which is the exact failure
        // shape this repo keeps finding.
        final processor = replay(
          measuredWalkKm(),
          into: TrackProcessor(),
        );

        expect(processor.pointCount, greaterThan(100));
        expect(processor.smoothedTrack, throwsStateError);
      });

      test('and the forward pass is identical either way', () {
        // The tape is a pure observer. If turning it on moved the live track
        // by so much as a centimetre it would not be an opt-in cost, it would
        // be a second pipeline.
        final off = replay(measuredWalkKm(), into: TrackProcessor());
        final on = replay(
          measuredWalkKm(),
          into: TrackProcessor(recordFilterStates: true),
        );

        expect(on.distanceM, off.distanceM);
        expect(on.movingTime, off.movingTime);
        expect(on.pointCount, off.pointCount);
        expect(
          on.points.map((p) => p.latitude),
          off.points.map((p) => p.latitude),
        );
      });

      test('the live recorder does not ask for it', () {
        // Pinned against the constructor default rather than against the
        // recorder, because the recorder builds its processor inside a
        // provider. If this default is ever flipped, the phone starts paying
        // again silently and nothing else in the suite would notice.
        expect(TrackProcessor().recordFilterStates, isFalse);
      });
    });

    test("the last point is the filter's last point, exactly", () {
      // The recursion's boundary condition: there is nothing after the final
      // estimate to correct it with. Off-by-one errors in the backward walk
      // land here first.
      final processor = replay(measuredWalkKm());
      final smoothed = processor.smoothedTrack();

      expect(smoothed.points.last.latitude, processor.points.last.latitude);
      expect(smoothed.points.last.longitude, processor.points.last.longitude);
      expect(smoothed.points, hasLength(processor.pointCount));
    });

    test('at huge process noise it converges on the filter', () {
      // The structural test of the gain. C = P·Fᵀ·(P⁻)⁻¹ goes to zero as the
      // process noise swamps the state covariance, so a filter told the target
      // may accelerate arbitrarily has nothing to learn from its own future.
      // A wrong gain — transposed, mis-signed, or using the wrong dt — does
      // not have this limit.
      final processor = replay(
        rectangleCircuit(),
        into: TrackProcessor(
          accelerationNoiseMps2: 100,
          recordFilterStates: true,
        ),
      );
      expect(
        processor.smoothedTrack().distanceM,
        closeTo(processor.distanceM, 0.5),
      );
    });

    test('it does not disturb the forward pass', () {
      // The whole premise: the live numbers and the live map are the causal
      // estimate and stay that way. Calling the backward pass must be a pure
      // read.
      final processor = replay(measuredWalkKm());
      final before = processor.distanceM;
      final points = [...processor.points];

      processor
        ..smoothedTrack()
        ..smoothedTrack();

      expect(processor.distanceM, before);
      expect(
        processor.points.map((p) => p.latitude),
        points.map((p) => p.latitude),
      );
    });
  });

  group('where it wins: noise on a straight line', () {
    test('the measured walk goes from +1.14% to +0.00%', () {
      final processor = replay(measuredWalkKm());
      final smoothed = processor.smoothedTrack();

      expect(processor.distanceM, closeTo(1011.40, 0.01));
      expect(smoothed.distanceM, closeTo(1000.04, 0.01));
    });

    test('and the length it removed was noise, not path', () {
      // Decimate to every 20th point and re-measure. Length that survives is
      // geometry; length that vanishes was sub-20-fix wiggle. The filtered
      // track loses four times as much of itself as the smoothed one, which
      // is the independent evidence that what came off was jitter.
      for (final path in const [
        'captures/2026-08-23_1610m.ndjson',
        'captures/2026-08-24_1610m.ndjson',
      ]) {
        final processor = capture(path);
        final filterLoss = _decimationLoss(processor.points);
        final smoothedLoss = _decimationLoss(processor.smoothedTrack().points);

        expect(filterLoss, greaterThan(0.03), reason: path);
        expect(smoothedLoss, lessThan(0.02), reason: path);
        expect(smoothedLoss, lessThan(filterLoss / 2), reason: path);
      }
    });
  });

  group('where it loses: turns', () {
    test('the switchback loses 48% of its length', () {
      // Not corner-cutting made better. Corner ROUNDING, made much worse: the
      // filter overshoots each hairpin and is dragged back, which runs long,
      // and the smoother refuses the hairpin altogether.
      // The forward number is untouched by A1c-J: no fix on this fixture is
      // ever classified stopped in the forward pass, so accumulation stays
      // fix-to-fix and 271.56 is the same to the centimetre.
      //
      // The SMOOTHED number moved, 140.13 -> 137.23, and the mechanism is
      // worth recording because it is the one place the anchor rule costs
      // something on a walker who never stopped. The RTS track barely turns at
      // these hairpins, so its displacement over a 10 s window drops under
      // 0.5 m/s and the turn reads as a stop. The anchor then freezes and the
      // hairpin contributes the displacement ACROSS it rather than the path
      // around it — and out-and-back displacement is shorter than out-and-back
      // path. Three hairpins, ~1 m each.
      //
      // That is the same trade the fix makes everywhere and it is accepted
      // here on the same terms: it is bounded by the window, it cannot grow
      // with the length of the turn, and it goes the safe direction. On a
      // fixture already losing 48% to corner rounding it is not the problem.
      final processor = replay(switchbackWalk());
      expect(processor.distanceM, closeTo(271.56, 0.01));
      expect(processor.smoothedTrack().distanceM, closeTo(137.23, 0.05));
    });

    test('the rectangle loses 7%, and it has no noise at all', () {
      // The attribution. This fixture's measurements are exact, so nothing
      // here is the smoother removing error — it is the smoother removing
      // four 90-degree corners that genuinely happened.
      final processor = replay(rectangleCircuit());
      expect(processor.distanceM, closeTo(742.00, 0.01));
      expect(processor.smoothedTrack().distanceM, closeTo(677.38, 0.05));
    });
  });

  group('on the two ground-truth walks it is worse on both', () {
    // Two captures is a spread, not a point. Here they agree on the sign and
    // differ only in how much: the backward pass takes ~7 percentage points
    // off each walk, which carries 23 Aug from long past the truth and 24 Aug
    // from correct to far short. A real 1610 m loop has corners in it, so the
    // corner rounding measured on the fixtures above is being paid here too —
    // which is exactly why `measuredWalkKm`'s near-perfect result does not
    // transfer. That fixture is a straight line.
    const truthM = 1610.0;

    test('23 Aug: +3.54% becomes -4.21%, and 57 m of error becomes 68', () {
      final processor = capture('captures/2026-08-23_1610m.ndjson');
      expect(processor.distanceM, closeTo(1666.97, 0.05));
      expect(processor.smoothedTrack().distanceM, closeTo(1542.24, 0.05));
      // It crosses the truth and lands further out on the other side. The
      // percentage looks nearly symmetric; the metres are not.
      expect(processor.distanceM - truthM, closeTo(56.97, 0.05));
      expect(
        processor.smoothedTrack().distanceM - truthM,
        closeTo(-67.76, 0.05),
      );
    });

    test('24 Aug: -0.09% becomes -7.09%, and 1.5 m of error becomes 114', () {
      final processor = capture('captures/2026-08-24_1610m.ndjson');
      expect(processor.distanceM, closeTo(1608.51, 0.05));
      expect(processor.smoothedTrack().distanceM, closeTo(1495.84, 0.05));
      expect((processor.distanceM - truthM).abs(), closeTo(1.49, 0.05));
      expect(
        (processor.smoothedTrack().distanceM - truthM).abs(),
        closeTo(114.16, 0.05),
      );
    });

    test('so the smoothed track is further from the truth on both', () {
      for (final path in const [
        'captures/2026-08-23_1610m.ndjson',
        'captures/2026-08-24_1610m.ndjson',
      ]) {
        final processor = capture(path);
        expect(
          (processor.smoothedTrack().distanceM - truthM).abs(),
          greaterThan((processor.distanceM - truthM).abs()),
          reason: path,
        );
      }
    });

    test('lowering the tuning does not rescue it on either walk', () {
      // The headline question this was built to answer: if the backward pass
      // removed the corner penalty, the fork that pinned
      // accelerationNoiseMps2 at 0.035 would dissolve and a lower value would
      // be safe everywhere. It does not. Under the smoother, every dataset
      // gets monotonically SHORTER as the tuning drops — the fork does not
      // dissolve, it inverts.
      for (final path in const [
        'captures/2026-08-23_1610m.ndjson',
        'captures/2026-08-24_1610m.ndjson',
      ]) {
        var previous = double.infinity;
        for (final an in const [0.2, 0.1, 0.05, 0.035, 0.02, 0.01]) {
          final distance = capture(path, an: an).smoothedTrack().distanceM;
          expect(distance, lessThan(previous), reason: '$path at $an');
          previous = distance;
        }
      }
    });
  });

  test('the metrics come off the smoothed track, not carried across', () {
    // Moving time and splits are re-decided over the new positions. They land
    // on the same numbers here, which is the point: the stop detector reads
    // displacement over 10 s and 10 s of walking is far larger than anything
    // the backward pass moved.
    for (final path in const [
      'captures/2026-08-23_1610m.ndjson',
      'captures/2026-08-24_1610m.ndjson',
    ]) {
      final processor = capture(path);
      final smoothed = processor.smoothedTrack();

      expect(smoothed.movingTime, processor.movingTime, reason: path);
      expect(smoothed.elapsed, processor.elapsed, reason: path);
      expect(smoothed.splits, hasLength(processor.splits.length), reason: path);
      expect(
        smoothed.averagePaceSecPerKm,
        isNot(closeTo(processor.averagePaceSecPerKm!, 1)),
        reason: 'the pace must follow the distance it was divided by',
      );
    }
  });
}

/// The share of a track's length that disappears when only every 20th point is
/// kept.
double _decimationLoss(List<TrackPoint> points) {
  double length(int step) {
    var total = 0.0;
    var previous = points.first;
    for (var i = step; i < points.length; i += step) {
      total += haversineMetres(
        previous.latitude,
        previous.longitude,
        points[i].latitude,
        points[i].longitude,
      );
      previous = points[i];
    }
    return total +
        haversineMetres(
          previous.latitude,
          previous.longitude,
          points.last.latitude,
          points.last.longitude,
        );
  }

  final full = length(1);
  return (full - length(20)) / full;
}
