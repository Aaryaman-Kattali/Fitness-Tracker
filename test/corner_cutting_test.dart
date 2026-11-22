import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// What a turn does to a recorded distance.
///
/// This was written expecting to find corner-cutting — a smoother lagging
/// through a bend and shortening the track — because that is the one mechanism
/// that could explain a real walk coming out short. It found something else,
/// and the something else is the reverse.
///
/// Two effects are running at once and they point in opposite directions:
///
///   * AT the corner, the constant-velocity filter is still predicting the old
///     heading, so the smoothed track cuts inside the true path. Measured over
///     ±3 s around each turn, it is 10% short. Corner-cutting is real.
///   * IMMEDIATELY AFTER, the same inertia has carried the estimate past the
///     turn, and the measurements drag it back. That recovery is a longer path
///     than the truth, and it more than repays what the cut removed.
///
/// Which one wins is a matter of tuning, not of principle — see the sweep
/// below, where hard smoothing on a switchback flips the total from +5% to
/// −27%.
///
/// That sweep is what set `accelerationNoiseMps2`. 0.035 is the value where the
/// two effects cancel on the switchback, so the shipped pipeline reads a
/// hairpin almost exactly right (−0.16%) and a street corner slightly long
/// (+1.92%). Neither number is a property of turns; both are properties of the
/// knob, which is why every assertion below that depends on the balance names
/// the tuning it was measured at.
void main() {
  group('the control: no turns, no effect', () {
    test('a straight walk is accurate at every smoothing level', () {
      // The attribution. Same builder, same speed, same reported accuracy as
      // the circuit, differing in one thing: whether the path bends. Without
      // this, every number below could be the speed, the accuracy, or the
      // interpolation in the fixture generator rather than the turns.
      final track = straightControlWalk();

      for (final smoothing in [0.01, 0.2, 2.0]) {
        final processor = replay(
          track,
          into: TrackProcessor(accelerationNoiseMps2: smoothing),
        );
        expect(
          processor.distanceM,
          closeTo(track.groundTruthDistanceM, 1),
          reason:
              'a straight track must not move with the tuning; at $smoothing '
              'it read ${processor.distanceM.toStringAsFixed(1)} m',
        );
      }
    });
  });

  group('a clean rectangular circuit', () {
    test('the track is short AT the corners', () {
      // Corner-cutting itself, measured where it happens. Noise-free, so there
      // is no receiver error to blame: the filter did this.
      final track = rectangleCircuit();
      final loss = _lossProfile(track, replay(track));

      expect(
        loss.cornerErrorFraction,
        lessThan(-0.05),
        reason:
            'the smoothed path should cut inside the true one through a '
            'bend. Measured: ${loss.report}',
      );
    });

    test('but the total comes out LONG, not short', () {
      // The finding that reverses the expectation. What the corner removes,
      // the overshoot afterwards more than puts back.
      final track = rectangleCircuit();
      final processor = replay(track);

      expect(
        processor.distanceM,
        greaterThan(track.groundTruthDistanceM),
        reason:
            'measured ${processor.distanceM.toStringAsFixed(1)} m over a true '
            '${track.groundTruthDistanceM.toStringAsFixed(1)} m',
      );
      expect(
        _lossProfile(track, processor).straightErrorFraction,
        greaterThan(0.01),
        reason:
            'the excess has to appear on the stretches after the turns, or '
            'it is not overshoot and this reading is wrong',
      );
    });
  });

  group('tighter turns cost more — at a tuning that lets them', () {
    // This group asserted, unconditionally, that three hairpins distort a total
    // more than four right angles. That was measured at accelerationNoiseMps2
    // 0.2 and it is no longer true at the shipped value, because 0.035 was
    // chosen precisely to cancel the hairpin — see the sweep in TrackProcessor.
    //
    // The finding is not withdrawn; it is given back its condition. Turn error
    // is a property of the tuning and not of the geometry alone, which is this
    // file's own thesis, and a test stating it unconditionally was overclaiming
    // from a single sample of the knob.
    test('at soft smoothing, reversing direction costs more than a corner', () {
      // Stated as a comparison, which is stronger than either number alone: if
      // reversing direction did not cost more than turning ninety degrees, the
      // error would not be coming from the turns at all.
      TrackProcessor soft() => TrackProcessor(accelerationNoiseMps2: 0.2);

      final rectangleError = _errorFraction(rectangleCircuit(), into: soft());
      final switchbackError = _errorFraction(switchbackWalk(), into: soft());

      expect(
        switchbackError.abs(),
        greaterThan(rectangleError.abs() * 2),
        reason:
            'rectangle ${_pct(rectangleError)}, '
            'switchback ${_pct(switchbackError)}',
      );
    });

    test(
      'at the shipped tuning the hairpin is the one that is nearly right',
      () {
        // The reason 0.035 ships. The corner-cut going into a turn and the
        // overshoot-recovery coming out of it cancel on the switchback, so the
        // harshest geometry in the suite is the most accurate. That is a
        // coincidence of the tuning, not a property of hairpins, and it is
        // pinned here so that moving the constant has to come past this test.
        final switchbackError = _errorFraction(switchbackWalk());

        expect(
          switchbackError.abs(),
          lessThan(0.01),
          reason: 'switchback ${_pct(switchbackError)} at the shipped tuning',
        );
      },
    );
  });

  group('the fixtures are tight enough to tell two smoothers apart', () {
    test('the switchback total swings by tens of percent with the tuning', () {
      // The mutation, run through the smoother's own knob rather than by
      // editing it. `accelerationNoiseMps2` sets how far the filter trusts its
      // own prediction over the next measurement, which is exactly what
      // decides whether it sails through a hairpin or follows it.
      //
      // If the total barely moved, the fixture would not be measuring the
      // smoother and every number above would be decoration. It moves by 27
      // points of the true distance: 199.8 m at hard smoothing against 273.9 m
      // at soft, over a true 272 m.
      final track = switchbackWalk();

      final hard = replay(
        track,
        into: TrackProcessor(accelerationNoiseMps2: 0.01),
      ).distanceM;
      final soft = replay(
        track,
        into: TrackProcessor(accelerationNoiseMps2: 2),
      ).distanceM;
      final truth = track.groundTruthDistanceM;

      expect(
        (soft - hard) / truth,
        greaterThan(0.25),
        reason:
            'hard ${hard.toStringAsFixed(1)} m, soft ${soft.toStringAsFixed(1)} '
            'm, true ${truth.toStringAsFixed(1)} m',
      );
    });

    test('hard smoothing IS corner-cutting, and it dominates when it wins', () {
      // The mechanism this file went looking for, isolated. At a process noise
      // 3.5x below the shipped value the filter stops believing the hairpins at
      // all and draws through them, and the track collapses by a quarter.
      //
      // 0.01 is not an arbitrary "hard" setting: it is the value that reads
      // best on the real 1610 m capture (+1.6% against the shipped +3.6%), and
      // this test is the reason it does not ship.
      //
      // It is not the shipped behaviour and nothing here changes the shipped
      // value. It is the proof that corner-cutting can shorten a track badly,
      // and the record of what tuning does it.
      final track = switchbackWalk();
      final hard = replay(
        track,
        into: TrackProcessor(accelerationNoiseMps2: 0.01),
      ).distanceM;

      expect(
        hard,
        lessThan(track.groundTruthDistanceM * 0.8),
        reason: '${hard.toStringAsFixed(1)} m over a true 272 m',
      );
    });
  });

  group('with realistic noise', () {
    test('turning error and noise error add rather than cancel', () {
      // Both push the same way at this tuning, which is the unwelcome answer.
      // Had they opposed each other, a plausible total could have hidden two
      // large errors; instead they compound, and a walk with many corners
      // should be expected to read long.
      final clean = rectangleCircuit();
      final noisy = rectangleCircuit(noiseSigmaM: 8);

      final cleanTotal = replay(clean).distanceM;
      final noisyTotal = replay(noisy).distanceM;

      expect(cleanTotal, greaterThan(clean.groundTruthDistanceM));
      expect(
        noisyTotal,
        greaterThan(cleanTotal),
        reason:
            'clean ${cleanTotal.toStringAsFixed(1)} m, '
            'noisy ${noisyTotal.toStringAsFixed(1)} m, '
            'true ${clean.groundTruthDistanceM.toStringAsFixed(1)} m',
      );
    });
  });
}

double _errorFraction(SyntheticTrack track, {TrackProcessor? into}) =>
    replay(track, into: into).distanceM / track.groundTruthDistanceM - 1;

/// Where the smoothed track disagrees with the truth, split by whether it was
/// turning at the time.
class _Loss {
  _Loss({
    required this.cornerMeasured,
    required this.cornerTrue,
    required this.straightMeasured,
    required this.straightTrue,
  });

  final double cornerMeasured;
  final double cornerTrue;
  final double straightMeasured;
  final double straightTrue;

  /// Negative means the track came out short through the bends.
  double get cornerErrorFraction =>
      cornerTrue <= 0 ? 0 : cornerMeasured / cornerTrue - 1;

  double get straightErrorFraction =>
      straightTrue <= 0 ? 0 : straightMeasured / straightTrue - 1;

  String get report =>
      'corners ${cornerMeasured.toStringAsFixed(1)} of '
      '${cornerTrue.toStringAsFixed(1)} m (${_pct(cornerErrorFraction)}) · '
      'straights ${straightMeasured.toStringAsFixed(1)} of '
      '${straightTrue.toStringAsFixed(1)} m (${_pct(straightErrorFraction)})';
}

/// Seconds either side of a turn that count as "at the corner".
///
/// Three, and the width matters more than it looks. The cut and the overshoot
/// that repays it are adjacent in time, so a wide window contains both and
/// reports their sum — at ±15 s the corners read +0.75%, which would say
/// nothing is happening. Narrow enough to catch the turn and not its recovery
/// is what separates the two effects. Measured across ±3, 6, 10, 15 and 25 s
/// before settling here.
const _cornerWindowSeconds = 3;

_Loss _lossProfile(SyntheticTrack track, TrackProcessor processor) {
  final points = processor.points;

  var cornerMeasured = 0.0;
  var cornerTrue = 0.0;
  var straightMeasured = 0.0;
  var straightTrue = 0.0;

  for (var i = 1; i < points.length; i++) {
    final previous = points[i - 1];
    final current = points[i];

    // Both sides walk the same pair of instants: the smoothed step, against
    // the true distance covered between those same two moments. Comparing
    // against a fixed per-second figure would mis-attribute anything the
    // pipeline rejected.
    final fromTruth = track.truthAt(previous.timestamp);
    final toTruth = track.truthAt(current.timestamp);
    if (fromTruth == null || toTruth == null) continue;

    final measured = haversineMetres(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    final actual = haversineMetres(
      fromTruth.lat,
      fromTruth.lon,
      toTruth.lat,
      toTruth.lon,
    );

    if (_nearATurn(track, previous.timestamp) ||
        _nearATurn(track, current.timestamp)) {
      cornerMeasured += measured;
      cornerTrue += actual;
    } else {
      straightMeasured += measured;
      straightTrue += actual;
    }
  }

  return _Loss(
    cornerMeasured: cornerMeasured,
    cornerTrue: cornerTrue,
    straightMeasured: straightMeasured,
    straightTrue: straightTrue,
  );
}

bool _nearATurn(SyntheticTrack track, DateTime time) => track.turnTimes.any(
  (turn) => time.difference(turn).inSeconds.abs() <= _cornerWindowSeconds,
);

String _pct(double fraction) => '${(fraction * 100).toStringAsFixed(2)}%';
