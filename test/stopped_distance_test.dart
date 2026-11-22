import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// A1c-J: distance must not accumulate while the walker is standing still.
///
/// **Found by a capture, not by a fixture, and that is worth recording.** Four
/// continuous walks could not exhibit this bug, because a bug in what happens
/// while stationary needs a track that is stationary. The 7 Sep Zurich walk
/// stood still for 22:19 across 16 segments and put 475 m of its 4529 m raw
/// accepted path — 11% — into standing around. The two long stops, 10:01 and
/// 7:02, contributed 202 m between them.
///
/// The cause was already written down and never acted on: stops excluded TIME
/// but not DISTANCE, so accumulation ran independently of the moving flag. At
/// 1 Hz and 3.79 m accuracy, a stationary receiver adds a small positive step
/// every second, and a sum of positive steps never cancels the way a
/// displacement does.
///
/// **The fix is a frozen anchor, and the second group here is why it has to
/// be.** Simply skipping accumulation during detected stops would be the
/// obvious fix and is the wrong one: the detector has a 10 s window and a
/// 0.5 m/s threshold, so genuinely slow movement reads as stopped and would be
/// discarded — the under-reporting failure that got the displacement gate ruled
/// out in the first place. Freezing the anchor gives drift nothing, because
/// drift returns to where it started, and still captures real movement as
/// displacement when it resumes.
///
/// Both groups are verified by mutation, in opposite directions. See the
/// comments on each.
void main() {
  /// Cumulative distance at the last point at or before [at].
  ///
  /// Read off the track rather than from a total, so a stop's contribution can
  /// be measured without the walking either side of it in the number.
  double cumulativeAt(TrackProcessor processor, DateTime at) {
    var metres = 0.0;
    for (final point in processor.points) {
      if (point.timestamp.isAfter(at)) break;
      metres = point.cumulativeDistanceM;
    }
    return metres;
  }

  group('a genuine stop contributes no distance', () {
    test('three minutes of standing still adds 25 m, not 200', () {
      // THE ASSERTION THE BUG WOULD HAVE FAILED. Measured across the stop's
      // own edges, so the walking either side contributes nothing to it and
      // the budget is about phantom distance alone.
      //
      // **25 m rather than the ~5 m this was first written with, and the
      // difference is the detector's blind spot rather than the anchor rule.**
      // Measured on this fixture: the first 12 s inside the stop are still
      // classified moving, because the rule judges displacement over a
      // trailing 10 s window and cannot know a stop has begun until it has
      // watched one go by. Those 21 fixes accumulate 19.0 m fix to fix. The
      // remaining 159 fixes of the stop add exactly nothing, which is the
      // property being bought here.
      //
      // So the residual is the leading EDGE of every stop, and it is bounded
      // by the window rather than by the stop's length — which is the whole
      // difference. A three-minute stop and a thirty-minute stop now cost the
      // same ~19 m; before, the thirty-minute one cost ten times more.
      //
      // VERIFIED BY MUTATION: accumulating `haversine(previous, smoothed)` on
      // every accepted fix regardless of the moving flag — the rule this
      // replaced — puts 51.5 m across this stop against the fix's 19.0 m, and
      // takes the total to 290.8 m against a 240 m truth.
      //
      // **51.5 m, not the hundreds the raw path would suggest, and the gap is
      // worth understanding before anyone reads this budget as slack.** The
      // Kalman filter already suppresses most stationary wander: a receiver
      // standing still produces a confident, barely-moving estimate, so the
      // smoothed steps being summed here are small. The phantom distance is
      // large in the RAW accepted path — 475 m on the Zurich capture — and much
      // of that never reached the smoothed total. What A1c-J removes is what
      // did.
      //
      // So the budget sits between two measured values rather than orders of
      // magnitude from either: 19.0 m with the fix, 51.5 m without it. That is
      // a real discriminator and it is stated honestly rather than dressed up.
      final track = walkStandWalk();
      final processor = replay(track);
      final stop = track.stopWindows.single;

      final phantom =
          cumulativeAt(processor, stop.to) - cumulativeAt(processor, stop.from);

      expect(
        phantom,
        lessThan(25),
        reason:
            'the walker did not move between ${stop.from} and ${stop.to}, so '
            'anything here is receiver wander that was summed instead of '
            'cancelled',
      );
    });

    test('and the walking on either side still measures', () {
      // The other half, and it is what stops the test above being satisfied by
      // a pipeline that has simply stopped counting. A fix that zeroed the
      // total would pass the phantom budget perfectly.
      //
      // The tolerance is the same 25 m as above and for the same reason: the
      // leading-edge residual lands in this total too. Expressed in metres
      // rather than as a percentage so it stays tied to the window that causes
      // it instead of scaling with a distance it has nothing to do with.
      final track = walkStandWalk();
      final processor = replay(track);

      expect(
        processor.distanceM,
        closeTo(track.groundTruthDistanceM, 25),
        reason: '240 m of real walking either side of the stop',
      );
    });

    test('the stop is still excluded from moving time, as it always was', () {
      // Unchanged behaviour, asserted because A1c-J moved the code that
      // decides it. Moving time was always correct; distance was not.
      final track = walkStandWalk();
      final processor = replay(track);

      expect(
        processor.movingTime.inSeconds,
        closeTo(track.groundTruthMovingSeconds!, 12),
        reason: 'the 10 s window cannot know a stop began until it has passed',
      );
    });
  });

  group('slow movement misread as stopped is still counted', () {
    test('the fixture really is misclassified, or it tests nothing', () {
      // **This assertion guards the premise of the next one.** A 0.3 m/s
      // shuffle is meant to read as stationary to the detector. If a future
      // change to `minMovingSpeedMps` or `movingWindow` made it read as
      // moving, the regression test below would still pass while no longer
      // testing anything at all, which is the quiet way a guard rots.
      final track = slowWalkMisreadAsStopped();
      final processor = replay(track);

      expect(
        processor.movingTime.inSeconds,
        lessThan(200),
        reason:
            'the 3-minute shuffle must be counted as stopped; if moving time '
            'approaches the full 300 s the detector is seeing it as movement '
            'and this group is no longer exercising the misclassified case',
      );
    });

    test('the 54 m covered at 0.3 m/s survives to the total', () {
      // THE REGRESSION THE DESIGN EXISTS TO PREVENT, and the reason the fix is
      // not simple exclusion.
      //
      // VERIFIED BY MUTATION: skipping accumulation for stopped fixes instead
      // of freezing the anchor reports 124.0 m here — it discards nearly the
      // whole shuffle. The frozen anchor reports 174.1 m against a ground
      // truth of 174 m, because on resume the contribution is the displacement
      // from where the walker stood when the stop began.
      //
      // The threshold sits at 160 m, clear of what exclusion produces and
      // below the truth, so the two designs cannot both pass. Note that the
      // mutation PASSES the genuine-stop group above — which is the point:
      // neither test alone distinguishes the two designs, and together they
      // pin the one design that satisfies both.
      final track = slowWalkMisreadAsStopped();
      final processor = replay(track);

      expect(
        processor.distanceM,
        greaterThan(160),
        reason:
            'plain exclusion would report ~120 m and lose the shuffle; the '
            'anchor must carry it across as displacement',
      );
      expect(
        processor.distanceM,
        closeTo(track.groundTruthDistanceM, track.groundTruthDistanceM * 0.05),
      );
    });
  });

  group('a fix the rule cannot judge is not treated as a stop', () {
    test('a 20 s cadence still measures distance', () {
      // **The bug A1c-J nearly shipped, caught by `track_splits_test` and
      // pinned here where it belongs.**
      //
      // The moving rule needs a point inside its 10 s window to measure
      // displacement against. A phone saving battery drops to a 20 or 30 s
      // cadence, and then there is never one — so every fix answered "not
      // moving". That was harmless while distance accumulated regardless of
      // the flag; the moment distance depended on it, a low-cadence run
      // reported ZERO metres, because nothing was ever classified moving and
      // so the anchor never advanced and no resume ever happened.
      //
      // The fix is that the rule returns null for "no basis to judge", which
      // is a different answer from "stopped". Moving time reads null as
      // not-moving, exactly as before; distance accumulates through it.
      //
      // VERIFIED BY MUTATION: making the unjudgeable case return 0 instead of
      // null — which is what the in-list form did through a division-by-zero
      // guard — reports 0.0 m here.
      final fixes = <RawFix>[];
      var when = DateTime.utc(2026, 9, 8, 6);
      for (var step = 0; step <= 30; step++) {
        // 20 s apart at 1.6 m/s: 32 m a step, and a 10 s window that can never
        // hold two of them.
        final metres = step * 32.0;
        fixes.add(
          RawFix(
            latitude: originLat + metres / 111320,
            longitude: originLon,
            timestamp: when,
            accuracyM: 5,
            altitudeM: 920,
            speedMps: 1.6,
          ),
        );
        when = when.add(const Duration(seconds: 20));
      }

      final processor = TrackProcessor();
      fixes.forEach(processor.add);
      processor.flush();

      expect(
        processor.distanceM,
        greaterThan(800),
        reason:
            'the walker covered ~960 m at a cadence the stop rule cannot see '
            'across; reporting nothing is the failure being guarded',
      );
    });
  });

  group('a continuous walk is untouched by the anchor rule', () {
    test('the measured kilometre is unchanged', () {
      // While moving, the anchor IS the previous point, so accumulation
      // reduces to fix-to-fix and nothing about a walk without stops can
      // change. Asserted rather than assumed, because "it only affects stops"
      // is exactly the claim a distance change would quietly break.
      final processor = replay(measuredWalkKm());
      expect(processor.distanceM, closeTo(1000, 25));
    });
  });
}
