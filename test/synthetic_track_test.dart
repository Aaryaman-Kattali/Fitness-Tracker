import 'dart:math' as math;
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The fixtures are the oracle for every other test in A1a, so their ground
/// truth has to be checked against something independent — otherwise a wrong
/// `groundTruthDistanceM` would make the pipeline tests agree with a lie.
///
/// Here that independent check is the geometry itself: sum the great-circle
/// distances along a clean track and it must come out at the number the
/// fixture claims.
void main() {
  group('ground truth', () {
    test('a clean 1 km track really is 1 km', () {
      final track = straightKm();
      expect(
        _rawDistance(track.fixes),
        closeTo(1000, 0.01),
        reason: 'the fixture generator and haversine must agree exactly',
      );
      expect(track.groundTruthDistanceM, closeTo(1000, 0.01));
    });

    test('the 5.5 km track really is 5.5 km', () {
      final track = fiveAndAHalfKm();
      expect(_rawDistance(track.fixes), closeTo(5500, 0.05));
      expect(track.groundTruthDistanceM, 5500);
    });

    test('every fixture has strictly increasing timestamps', () {
      for (final track in allTracks()) {
        for (var i = 1; i < track.fixes.length; i++) {
          expect(
            track.fixes[i].timestamp.isAfter(track.fixes[i - 1].timestamp),
            isTrue,
            reason: '${track.name}: fix $i does not advance the clock',
          );
        }
      }
    });

    test('every fixture carries an altitude and a lead-in', () {
      for (final track in allTracks()) {
        expect(
          track.fixes.length,
          greaterThan(leadInFixes),
          reason: track.name,
        );
        expect(
          track.fixes.every((fix) => fix.altitudeM != null),
          isTrue,
          reason:
              '${track.name}: altitude is stored even though nothing uses it',
        );
      }
    });
  });

  group('fixtures are deterministic', () {
    test('every track is byte-identical when built twice', () {
      // The noisy fixtures vary by a few percent between noise draws, so an
      // unseeded one would fail perhaps one run in twenty. An intermittent red
      // is worse than a permanent one: it teaches everyone to re-run instead
      // of to investigate, and the day it means something nobody looks.
      //
      // This is why the seed defaults are constants. The test exists so that
      // changing one to `Random()` fails here instead of failing at random
      // somewhere else, weeks later.
      for (final build in <SyntheticTrack Function()>[
        straightKm,
        urbanCanyonKm,
        severeWhiteNoiseKm,
        kmWithInaccurateFixes,
        kmWithTeleport,
        gapThenGenuineDisplacement,
        standingStill,
        fiveAndAHalfKm,
        walkingKm,
        variableCadenceWalk,
        measuredWalkKm,
        measuredVariableCadenceWalk,
        burstCadenceWalk,
        walkWithStop,
        walkWithSpurSpike,
        rectangleCircuit,
        switchbackWalk,
        straightControlWalk,
      ]) {
        final first = build();
        final second = build();
        expect(
          second.fixes.length,
          first.fixes.length,
          reason: '${first.name}: different length between builds',
        );
        for (var i = 0; i < first.fixes.length; i++) {
          expect(
            second.fixes[i].latitude,
            first.fixes[i].latitude,
            reason: '${first.name}: fix $i moved between builds',
          );
          expect(second.fixes[i].longitude, first.fixes[i].longitude);
          expect(second.fixes[i].timestamp, first.fixes[i].timestamp);
        }
      }
    });

    test('a different seed really does give a different track', () {
      // The other half: seeds that are fixed but ignored would make the
      // multi-seed distance test five copies of one measurement.
      final a = urbanCanyonKm(seed: 1);
      final b = urbanCanyonKm(seed: 2);
      expect(a.fixes.length, b.fixes.length);
      expect(
        List.generate(
          a.fixes.length,
          (i) => a.fixes[i].latitude == b.fixes[i].latitude,
        ).every((same) => same),
        isFalse,
      );
    });
  });

  group('planted defects are really there', () {
    test('exactly three fixes report 80 m accuracy', () {
      final bad = kmWithInaccurateFixes().fixes
          .where((fix) => fix.accuracyM > 50)
          .toList();
      expect(bad, hasLength(3));
      expect(bad.every((fix) => fix.accuracyM == 80), isTrue);
    });

    test('the inaccurate fixes are also in the wrong place', () {
      // A fix rejected for its accuracy while sitting on the true track would
      // let a filter that does nothing at all still pass the distance test.
      final clean = straightKm().fixes;
      final dirty = kmWithInaccurateFixes().fixes;
      var displaced = 0;
      for (var i = 0; i < clean.length; i++) {
        final offset = haversineMetres(
          clean[i].latitude,
          clean[i].longitude,
          dirty[i].latitude,
          dirty[i].longitude,
        );
        if (offset > 1) {
          displaced++;
          expect(offset, closeTo(60, 0.5));
        }
      }
      expect(displaced, 3);
    });

    test('the teleport is a 500 m jump across one second', () {
      final fixes = kmWithTeleport().fixes;
      var jumps = 0;
      for (var i = 1; i < fixes.length; i++) {
        final gap = haversineMetres(
          fixes[i - 1].latitude,
          fixes[i - 1].longitude,
          fixes[i].latitude,
          fixes[i].longitude,
        );
        if (gap > 100) {
          jumps++;
          // The bad fix is 500 m off the track, so the jump out also carries
          // one step of genuine travel and the jump back gives it away again.
          expect(gap, closeTo(500, runSpeedMps + 0.5));
          expect(
            fixes[i].timestamp.difference(fixes[i - 1].timestamp),
            const Duration(seconds: 1),
          );
        }
      }
      // Out and back: one bad fix produces two implausible transitions.
      expect(jumps, 2);
    });

    test('the signal gap is 60 s and 400 m', () {
      final fixes = gapThenGenuineDisplacement().fixes;
      final gapIndex = _indexOfLongestGap(fixes);
      expect(
        fixes[gapIndex].timestamp.difference(fixes[gapIndex - 1].timestamp),
        const Duration(seconds: 60),
      );
      expect(
        haversineMetres(
          fixes[gapIndex - 1].latitude,
          fixes[gapIndex - 1].longitude,
          fixes[gapIndex].latitude,
          fixes[gapIndex].longitude,
        ),
        closeTo(400, 1),
      );
    });

    test('the standing-still track really stands still for 240 s', () {
      final track = standingStill();
      expect(track.groundTruthMovingSeconds, 600);
      expect(track.groundTruthElapsed, const Duration(seconds: 840));
    });
  });

  group('the noisy track is calibrated, not guessed', () {
    test('noise is correlated, and calibrated to the naive over-report', () {
      // THIS is the assertion that keeps the fixture honest. The noise model
      // is pinned to an independently stated expectation — a naive
      // implementation over-reports by 10-30% here — rather than to whatever
      // happens to let the pipeline pass. Change the correlation time and this
      // fails; change the pipeline and it does not move at all.
      final raw = _rawDistance(urbanCanyonKm().fixes);
      expect(
        raw,
        inInclusiveRange(1100, 1300),
        reason:
            'raw sum was ${raw.toStringAsFixed(1)} m over a true 1000 m, '
            'outside the 10-30% the spec predicts for a naive integration',
      );
    });

    test('the correlation time is physically sensible', () {
      // If hitting that band needed a correlation time under ~30 s or over
      // ~10 min, the model would be fitted rather than physical.
      expect(noiseCorrelationSeconds, greaterThanOrEqualTo(30));
      expect(noiseCorrelationSeconds, lessThanOrEqualTo(600));
    });

    test('the error stays inside the stated 15 m envelope', () {
      // Correlating the noise must not have widened it. The sqrt(1 - rho^2)
      // term exists precisely so that tau changes how the error moves without
      // changing how large it gets.
      final offsets = _offsetsFromTruth(urbanCanyonKm());
      final mean = offsets.reduce((a, b) => a + b) / offsets.length;
      // Two axes at sigma 15 give a mean radial offset of 15*sqrt(pi/2) ~ 18.8
      // m. Wide bounds: a correlated process wanders, so any single track is a
      // sample rather than the ensemble mean.
      expect(mean, greaterThan(6));
      expect(mean, lessThan(34));
    });

    test('consecutive fixes disagree far less than in the white-noise case', () {
      // The whole difference between the two fixtures, stated directly.
      // Correlated error largely cancels between neighbours; independent error
      // does not, and that is what wrecks anything that differences positions.
      final correlated = _meanStepChange(urbanCanyonKm().fixes);
      final white = _meanStepChange(severeWhiteNoiseKm().fixes);
      expect(correlated, lessThan(white / 3));
    });
  });

  group('the walking fixtures state their ground truth truthfully', () {
    test('the walked kilometre really is a kilometre', () {
      // Independent of the pipeline, as every ground truth here must be:
      // summed great-circle distances along the noise-free twin, which is what
      // `truthAt` compares positions against. If this and the fixture's own
      // claim disagreed, every walking budget would be measured against a lie.
      final track = walkingKm();
      expect(track.groundTruthDistanceM, 1000);
      expect(_truthDistance(track), closeTo(1000, 0.01));
    });

    test('the irregular-cadence walk really covers its stated distance', () {
      // The one that could most easily be wrong. Position comes from
      // accumulated milliseconds rather than a step count, so an off-by-one in
      // the interval loop would leave the track a metre or two short of what
      // it claims — small enough to look like the pipeline drifting.
      final track = variableCadenceWalk();
      expect(track.groundTruthDistanceM, 1000);
      expect(_truthDistance(track), closeTo(1000, 0.01));
    });

    test('the walk with a stop covers 600 m and stands still for 180 s', () {
      final track = walkWithStop();
      expect(track.groundTruthDistanceM, 600);
      expect(track.groundTruthMovingSeconds, 600);
      expect(track.groundTruthElapsed, const Duration(seconds: 780));
    });

    test('the spur walk really is 600 m of walking', () {
      // The spur fix is displaced east, so the meridian sum over the whole
      // track would count it. Ground truth is the walk without it.
      final track = walkWithSpurSpike();
      expect(track.groundTruthDistanceM, 600);
      expect(
        _rawDistance(
          walkWithSpurSpike().fixes
              .where(
                (fix) => fix.accuracyM != gpsAccuracyMaxM,
              )
              .toList(),
        ),
        closeTo(600, 0.01),
      );
    });
  });

  group('the walking fixtures plant what they claim to plant', () {
    test('the walk is a walk and the run is a run', () {
      // Trivial-looking, and the reason the whole set exists: if the speed
      // parameter did not reach the generator, every walking fixture would be
      // a runner under a different name and the entire comparison would be a
      // measurement of nothing.
      // Over the moving part only. `_meanStepChange` includes the stationary
      // lead-in, whose zero-length steps dilute the mean by a different amount
      // on each track — 4 lead-in fixes out of 364 for the runner and out of
      // 1004 for the walker — which would make the ratio a fact about the
      // fixture lengths rather than about the speeds.
      final walkStep = _meanStepChange(
        walkingKm(noiseSigmaM: 0).fixes.skip(leadInFixes - 1).toList(),
      );
      final runStep = _meanStepChange(
        straightKm().fixes.skip(leadInFixes - 1).toList(),
      );
      expect(walkStep, closeTo(walkSpeedMps, 0.01));
      expect(runStep, closeTo(runSpeedMps, 0.01));
      expect(runStep / walkStep, closeTo(runSpeedMps / walkSpeedMps, 0.02));
    });

    test('the irregular cadence is actually irregular', () {
      final fixes = variableCadenceWalk().fixes;
      final gaps = <double>[
        for (var i = leadInFixes; i < fixes.length; i++)
          fixes[i].timestamp.difference(fixes[i - 1].timestamp).inMilliseconds /
              1000,
      ]..sort();

      expect(
        gaps[gaps.length ~/ 2],
        inInclusiveRange(1.2, 1.4),
        reason: 'the spec asks for a median near 1.3 s',
      );
      expect(gaps.first, greaterThanOrEqualTo(0.8));
      expect(
        gaps.where((g) => g >= 3 && g <= 5).length,
        greaterThan(20),
        reason: 'the occasional 3-5 s gap has to actually occur',
      );
      // At most a couple of intervals may land on exactly 1.000 s. One does:
      // the final interval is clamped so the walk ends on its stated duration,
      // and it happens to clamp to a whole second. What must not happen is a
      // fixture that is secretly 1 Hz, which would test nothing.
      expect(gaps.where((g) => g == 1).length, lessThan(3));
    });

    test('the stationary stretch really does not move', () {
      // The half of the mixed fixture that a stop detector is judged on. If
      // the "stop" quietly kept walking, excluding it from moving time would
      // be excluding real travel and the test would reward the wrong thing.
      final fixes = walkWithStop().fixes;
      final start = fixes.first.timestamp.add(
        const Duration(seconds: leadInFixes - 1 + 300),
      );
      final during = fixes.where(
        (fix) =>
            !fix.timestamp.isBefore(start) &&
            fix.timestamp.isBefore(start.add(const Duration(seconds: 180))),
      );

      expect(during, hasLength(180));
      final anchor = during.first;
      for (final fix in during) {
        expect(
          haversineMetres(
            anchor.latitude,
            anchor.longitude,
            fix.latitude,
            fix.longitude,
          ),
          lessThan(8),
          reason: 'standing still means wandering within the drift, not moving',
        );
      }
    });

    test(
      'the spur is one fix, 250 m out and back, at a believable accuracy',
      () {
        final fixes = walkWithSpurSpike().fixes;
        var jumps = 0;
        for (var i = 1; i < fixes.length; i++) {
          final gap = haversineMetres(
            fixes[i - 1].latitude,
            fixes[i - 1].longitude,
            fixes[i].latitude,
            fixes[i].longitude,
          );
          if (gap > 100) {
            jumps++;
            expect(gap, closeTo(spurLengthM, 1));
          }
        }
        expect(
          jumps,
          2,
          reason: 'one bad fix makes two implausible transitions',
        );

        final bad = fixes.where((fix) => fix.accuracyM != 5).toList();
        expect(bad, hasLength(1));
        expect(
          bad.single.accuracyM,
          lessThan(50),
          reason:
              'a spur the accuracy filter would catch anyway proves nothing '
              'about the kinematic bound, which is what has to catch this',
        );
      },
    );
  });

  group('the turning fixtures are the shape they claim to be', () {
    test('a straight walk through the path builder is exact', () {
      // The control first, because it is the one case where the sampled truth
      // and the stated perimeter must agree to the millimetre. Any
      // disagreement here is a bug in the builder rather than a property of
      // the geometry.
      final track = straightControlWalk();
      expect(track.groundTruthDistanceM, 728);
      expect(_truthDistance(track), closeTo(728, 0.01));
    });

    test('a sampled turn is unavoidably shorter than the path walked', () {
      // Worth stating precisely, because it is a limit on what ANY distance
      // algorithm can recover and it is easy to mistake for a filter defect.
      //
      // At 1 Hz the walker is sampled every 1.6 m, and a corner almost never
      // falls on a sample. The two samples that straddle it are joined by a
      // chord that cuts inside the true right angle, so summing sample to
      // sample along the perfect, noise-free truth is already short of the
      // perimeter — about 0.28 m per corner here.
      //
      // This is why `corner_cutting_test` compares the pipeline against the
      // SAMPLED truth at matching timestamps, not against the perimeter.
      // Measuring it against 728 m would charge the filter for a metre the
      // sampling had already lost.
      for (final track in [rectangleCircuit(), switchbackWalk()]) {
        final sampled = _truthDistance(track);
        final shortfall = track.groundTruthDistanceM - sampled;

        expect(
          shortfall,
          greaterThan(0),
          reason: '${track.name}: chords cut corners, they never add',
        );
        expect(
          shortfall,
          lessThan(0.5 * track.turnTimes.length),
          reason:
              '${track.name}: lost ${shortfall.toStringAsFixed(2)} m over '
              '${track.turnTimes.length} corners, which is more than a '
              '1.6 m sampling interval can account for',
        );
      }
    });

    test('the corners are where the fixture says they are', () {
      // The turn times drive the corner/straight split in
      // corner_cutting_test, so a wrong one would attribute the loss to the
      // wrong stretch and the whole measurement would be a fiction.
      //
      // Checked geometrically, and off the turn rather than across it: the
      // bearing is measured over a window ENDING before the corner and a
      // window STARTING after it. Straddling the turn itself would mix the two
      // legs and report something between them.
      final track = rectangleCircuit();
      expect(track.turnTimes, hasLength(4));

      for (final turn in track.turnTimes) {
        final before = _bearingOver(track, turn, -12, -4);
        final after = _bearingOver(track, turn, 4, 12);
        expect(
          _angleBetween(before, after),
          closeTo(90, 5),
          reason: 'a 90-degree corner must turn 90 degrees',
        );
      }

      // And a moment that is not a corner does not turn.
      final midLeg = track.turnTimes.first.subtract(
        const Duration(seconds: 30),
      );
      expect(
        _angleBetween(
          _bearingOver(track, midLeg, -12, -4),
          _bearingOver(track, midLeg, 4, 12),
        ),
        lessThan(5),
      );
    });

    test('the switchback really reverses direction', () {
      // A hairpin is not a corner. If these turned ninety degrees like the
      // rectangle's, the two fixtures would be the same test twice and the
      // "tighter turns cost more" comparison would be measuring nothing.
      final track = switchbackWalk();
      expect(track.turnTimes, hasLength(6));

      // Across a PAIR of turns — the two ends of a 10 m jog — which together
      // reverse the heading. The turns within a pair are 6.25 s apart, so the
      // windows go outside the pair rather than between its halves.
      final before = _bearingOver(track, track.turnTimes[0], -12, -4);
      final after = _bearingOver(track, track.turnTimes[1], 4, 12);
      final reversal = _angleBetween(before, after);
      expect(
        reversal,
        closeTo(180, 5),
        reason:
            'measured ${reversal.toStringAsFixed(1)} degrees across the '
            'first hairpin',
      );
    });

    test('the control has no turns at all', () {
      expect(straightControlWalk().turnTimes, isEmpty);
    });
  });

  group('the realistic fixtures report the accuracy the device reported', () {
    test('median and p90 land on 2.5 m and 3.1 m', () {
      // The fixture is parameterised by two order statistics, so the two order
      // statistics are what has to be checked. A log-normal drawn from a
      // sigma computed the wrong way round would still look plausible in a
      // scatter of numbers and would be wrong in exactly the place that sets
      // the Kalman gain.
      for (final track in [
        measuredWalkKm(),
        measuredVariableCadenceWalk(),
      ]) {
        final accuracies = track.fixes.map((fix) => fix.accuracyM).toList()
          ..sort();
        double at(double fraction) =>
            accuracies[((accuracies.length - 1) * fraction).round()];

        expect(
          at(0.5),
          closeTo(gpsAccuracyMedianM, 0.1),
          reason: '${track.name}: median accuracy',
        );
        expect(
          at(0.9),
          closeTo(gpsAccuracyP90M, 0.1),
          reason: '${track.name}: p90 accuracy',
        );
      }
    });

    test('the accuracy actually varies between fixes', () {
      // Guards the whole point of the draw. Every fixture that predates this
      // reports one constant, and a p90 that silently failed to reach the
      // builder would leave this one constant too while every order statistic
      // above still passed at a spread of zero... except that it would not,
      // which is why both tests exist.
      final distinct = measuredWalkKm().fixes
          .map((fix) => fix.accuracyM)
          .toSet();
      expect(distinct.length, greaterThan(100));
    });

    test('the realistic kilometre really is a kilometre', () {
      for (final track in [
        measuredWalkKm(),
        measuredVariableCadenceWalk(),
      ]) {
        expect(track.groundTruthDistanceM, 1000, reason: track.name);
        expect(_truthDistance(track), closeTo(1000, 0.01), reason: track.name);
      }
    });

    test('the error envelope is 2.5 m, not 15', () {
      // The measurement that separates this fixture from the one it was copied
      // from. Two axes at sigma s give a mean radial offset of s*sqrt(pi/2),
      // so 2.5 m of drift should sit near 3.1 m and 15 m near 18.8 m.
      //
      // The comparison is against the SAME builder at six times the sigma —
      // same speed, same cadence, same seed, one variable. Both sides briefly
      // read `measuredWalkKm` after a rename, which made this compare a
      // fixture with itself and assert that a number was less than a third of
      // itself.
      final realistic = _offsetsFromTruth(measuredWalkKm());
      final degraded = _offsetsFromTruth(
        walkingKm(seed: 20260822, noiseSigmaM: 15, speedMps: briskWalkSpeedMps),
      );
      double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;

      expect(mean(realistic), lessThan(mean(degraded) / 3));
      expect(mean(realistic), lessThan(8));
    });

    test('integrating it raw still over-reports, but far less', () {
      // The naive number, at the real operating point. At 15 m a naive sum
      // reads 10-30% long; the whole reason this fixture exists is that
      // nobody had ever measured what it reads at 2.5 m, and the pipeline's
      // budget was set against the former.
      final raw = _rawDistance(measuredWalkKm().fixes);
      expect(
        raw,
        greaterThan(1000),
        reason: 'summing noise can only add: ${raw.toStringAsFixed(1)} m',
      );
      expect(
        raw,
        lessThan(
          _rawDistance(
            walkingKm(
              seed: 20260822,
              noiseSigmaM: 15,
              speedMps: briskWalkSpeedMps,
            ).fixes,
          ),
        ),
        reason: 'less error must integrate to less phantom distance',
      );
    });
  });

  group('the pathological fixture is still pathological', () {
    test('integrating it raw over-reports by more than 500%', () {
      // Kept as a robustness case, not an accuracy one. If this ever comes
      // down near the realistic fixture, the two have stopped being different
      // tests and one of them is redundant.
      final raw = _rawDistance(severeWhiteNoiseKm().fixes);
      expect(raw, greaterThan(6000));
    });
  });
}

/// Great-circle distance summed over consecutive fixes, with no filtering and
/// no smoothing. Deliberately naive — it is the thing the pipeline must beat.
double _rawDistance(List<RawFix> fixes) {
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

/// Great-circle distance summed along a track's noise-free twin.
///
/// The twin is what [SyntheticTrack.truthAt] returns, so this measures the
/// path the walker actually took rather than the path the receiver reported.
double _truthDistance(SyntheticTrack track) => _rawDistance([
  for (final fix in track.fixes) _truthFixAt(track, fix.timestamp),
]);

RawFix _truthFixAt(SyntheticTrack track, DateTime time) {
  final position = track.truthAt(time)!;
  return RawFix(
    latitude: position.lat,
    longitude: position.lon,
    timestamp: time,
    accuracyM: 0,
  );
}

/// Read off the noise-free twin, because a heading differenced over a few
/// seconds of a noisy track is mostly noise, and this measures the fixture's
/// geometry rather than the receiver's.
/// Bearing of travel between two instants either side of [anchor], in seconds.
double _bearingOver(
  SyntheticTrack track,
  DateTime anchor,
  int fromSeconds,
  int toSeconds,
) => _bearing(
  _truthNear(track, anchor.add(Duration(seconds: fromSeconds))),
  _truthNear(track, anchor.add(Duration(seconds: toSeconds))),
);

({double lat, double lon}) _truthNear(SyntheticTrack track, DateTime time) {
  var best = track.fixes.first.timestamp;
  var bestDelta = best.difference(time).inMicroseconds.abs();
  for (final fix in track.fixes) {
    final delta = fix.timestamp.difference(time).inMicroseconds.abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      best = fix.timestamp;
    }
  }
  return track.truthAt(best)!;
}

double _bearing(
  ({double lat, double lon}) from,
  ({double lat, double lon}) to,
) {
  // Flat-earth is exact enough over the tens of metres these legs span, and it
  // keeps this helper from re-deriving spherical trigonometry that the fixture
  // itself does not use.
  final north = to.lat - from.lat;
  final east = (to.lon - from.lon) * math.cos(from.lat * math.pi / 180);
  return math.atan2(east, north) * 180 / math.pi;
}

/// Smallest angle between two bearings, in degrees, always 0–180.
double _angleBetween(double a, double b) {
  final diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

/// How far each fix sits from where the runner really was.
List<double> _offsetsFromTruth(SyntheticTrack track) => [
  for (final fix in track.fixes)
    haversineMetres(
      fix.latitude,
      fix.longitude,
      track.truthAt(fix.timestamp)!.lat,
      track.truthAt(fix.timestamp)!.lon,
    ),
];

/// Mean distance between consecutive fixes. On a straight track at a steady
/// pace the true value is one step; everything above it is the noise model
/// disagreeing with itself.
double _meanStepChange(List<RawFix> fixes) {
  var total = 0.0;
  for (var i = 1; i < fixes.length; i++) {
    total += haversineMetres(
      fixes[i - 1].latitude,
      fixes[i - 1].longitude,
      fixes[i].latitude,
      fixes[i].longitude,
    );
  }
  return total / (fixes.length - 1);
}

int _indexOfLongestGap(List<RawFix> fixes) {
  var best = 1;
  var bestGap = Duration.zero;
  for (var i = 1; i < fixes.length; i++) {
    final gap = fixes[i].timestamp.difference(fixes[i - 1].timestamp);
    if (gap > bestGap) {
      bestGap = gap;
      best = i;
    }
  }
  return best;
}
