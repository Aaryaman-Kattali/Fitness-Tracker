import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// What does a sub-second inter-fix interval cost, by itself?
///
/// The device's accepted intervals bottom out at 0.03 s against a delivered p10
/// of 0.28 s, and its smoothed-speed distribution has a 13.63 m/s tail on a walk
/// whose median is 1.46. A smoothed step of noise size divided by a near-zero dt
/// is exactly that reading, so the mechanism is arithmetically obvious. Whether
/// it is also *expensive* is a separate question, and this file is where it gets
/// a number rather than an argument.
///
/// A minimum-elapsed-time gate is the obvious remedy and is deliberately NOT
/// implemented. This measures first. If the reorder buffer removes the excess on
/// its own the gate is unnecessary machinery, and if it does not, this is the
/// fixture the gate gets tested against.
void main() {
  group('bursts of fixes milliseconds apart', () {
    test('the fixture really does deliver sub-100 ms intervals', () {
      // The fixture has to plant what it claims before any measurement taken
      // over it means anything.
      final fixes = burstCadenceWalk().fixes;
      final gaps = <double>[
        for (var i = leadInFixes; i < fixes.length; i++)
          fixes[i].timestamp.difference(fixes[i - 1].timestamp).inMilliseconds /
              1000,
      ];

      expect(
        gaps.where((gap) => gap < 0.1).length,
        greaterThan(100),
        reason: 'a handful of short intervals would not be a measurement',
      );
      expect(gaps.reduce((a, b) => a < b ? a : b), lessThan(0.11));
      expect(
        gaps.where((gap) => gap >= 0.8).length,
        greaterThan(300),
        reason: 'the ordinary cadence has to still be the bulk of it',
      );
    });

    test('the burst walk still covers exactly its stated ground', () {
      // Sampling the same walk more densely covers no extra distance. If this
      // were not true the fixture would be measuring its own geometry.
      final track = burstCadenceWalk();
      expect(track.groundTruthDistanceM, closeTo(1000, 0.01));
    });

    test('sub-second steps add almost no distance beyond the walking', () {
      // THE MEASUREMENT. Split every accepted step by its own dt, and charge
      // each half only for what it did NOT walk: a 60 ms step at 1.6 m/s is
      // entitled to 0.10 m, and only the metres past that are phantom.
      //
      // Charging the short steps for their whole contribution would be the
      // wrong measurement and a flattering one. 142 steps averaging 65 ms
      // carry about 15 m of genuine travel between them, so a test that
      // compared 15.83 m against zero would look alarming while describing a
      // walker walking.
      final processor = replay(burstCadenceWalk());
      final points = processor.points;

      var shortSteps = 0;
      var shortMetres = 0.0;
      var shortWalkedM = 0.0;
      var longMetres = 0.0;
      var longWalkedM = 0.0;
      for (var i = 1; i < points.length; i++) {
        final step =
            points[i].cumulativeDistanceM - points[i - 1].cumulativeDistanceM;
        final dtS =
            points[i].timestamp
                .difference(points[i - 1].timestamp)
                .inMilliseconds /
            1000;
        if (dtS < 0.5) {
          shortSteps++;
          shortMetres += step;
          shortWalkedM += dtS * briskWalkSpeedMps;
        } else {
          longMetres += step;
          longWalkedM += dtS * briskWalkSpeedMps;
        }
      }

      expect(shortSteps, greaterThan(100), reason: 'nothing to measure');

      // THE FINDING, AND IT REVERSED WHEN THE ERROR MODEL WAS MEASURED.
      //
      // This assertion used to read `lessThan(3)` and the comment used to say
      // short steps were very nearly free, on the reasoning that GPS error is
      // correlated so two fixes 40 ms apart carry almost the same error. The
      // reasoning is right; the number in it was not. At the guessed 300 s
      // correlation time a 40 ms gap changes the error by nothing at all. At
      // the measured 20 s it changes it by ~0.14 m per axis, and 142 short
      // steps at ~0.15 m each is the ~21 m this now measures.
      //
      // So a burst is NOT free. It costs about a sixth of a metre per extra
      // fix, and the cost scales with how short the interval is, because the
      // walking that would have justified the step shrinks while the error
      // difference does not.
      //
      // What this still does not explain is the device's own excess, and that
      // is the useful part: the GPS stream arrives at exactly 1.000 s and has
      // no bursts in it. The sub-second intervals in the device diagnostics
      // were the network stream interleaving. This fixture therefore models a
      // hypothetical rather than an observed behaviour, and is kept because a
      // receiver that did burst would cost exactly this much.
      expect(
        shortMetres - shortWalkedM,
        lessThan(30),
        reason:
            '$shortSteps steps under 0.5 s carried '
            '${shortMetres.toStringAsFixed(2)} m over '
            '${shortWalkedM.toStringAsFixed(2)} m of genuine travel; the rest '
            'carried ${longMetres.toStringAsFixed(1)} m over '
            '${longWalkedM.toStringAsFixed(1)} m',
      );
    });

    test('and the total is within 3.5% of true', () {
      // 1030.2 m, against the 1011.4 m the same walk reads without bursts. The
      // ~19 m difference is the short steps measured above, and it is why this
      // budget is 3.5% where the burst-free operating point is held to 2.5%.
      final processor = replay(burstCadenceWalk());
      expect(processor.distanceM, closeTo(1000, 35));
    });

    test('but the speed tail appears, exactly as on the device', () {
      // The one device symptom this fixture DOES reproduce. A small step over a
      // 30 ms dt is a large speed, and the diagnostics report it as such — so
      // the speed distribution's tail is not by itself evidence of distance
      // being added. That is worth pinning: the max smoothed speed was the
      // number that started this investigation pointing at large artefacts,
      // and it can be produced by steps that carry no metres at all.
      final processor = replay(burstCadenceWalk());
      final report = processor.diagnose();
      final points = processor.points;
      expect(
        report.acceptedSpeedMps!.max,
        greaterThan(5),
        reason:
            'measured ${report.acceptedSpeedMps!.max.toStringAsFixed(2)} m/s '
            'on a 1.6 m/s walk',
      );
      // The largest step is the opening hole and nothing else, so it is
      // measured past it rather than over the whole track.
      //
      // This fixture's timestamps are fractional almost everywhere, so the
      // stream detector stays undecided through its 20-fix probe and refuses
      // 15 fixes at the head. The 16th accepted fix therefore lands 21.1 s
      // after the origin, and the walk really did cover 32.1 m in that time —
      // 1.52 m/s, exactly the pace of the fixture. It is a gap in the
      // sampling, not an artefact in the estimate, and it is the cost the
      // strict-undecided rule was accepted with. Everything after it stays
      // under the original bound, which is what this assertion was for: the
      // speed tail comes from short steps, not from large ones.
      final steps = [
        for (var i = 2; i < points.length; i++)
          points[i].cumulativeDistanceM - points[i - 1].cumulativeDistanceM,
      ];
      expect(
        steps.reduce(math.max),
        lessThan(10),
        reason: 'and it happens with no large step anywhere in the track',
      );
      expect(
        report.largestStepM,
        closeTo(32.13, 0.01),
        reason: 'the one large step is the undecided probe at the head',
      );
    });
  });
}
