import 'package:fitness_tracker/features/activity/diagnostics/reconstruct_diagnostics.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The diagnostics collector, and the one property that matters most about it:
/// that it is a passive observer.
void main() {
  group('the collector does not change the pipeline', () {
    test('every fixture still measures exactly what it measured', () {
      // What the pipeline DOES, as of the A1c recalibration. Not what it
      // should do — walking_fixtures_test.dart says that, and confusing the
      // two is how a budget quietly gets rewritten to match a defect.
      //
      // Re-baselined wholesale in the commit that rebuilt the fixtures. Every
      // previous number here described a pipeline with maxAccuracyM 50 and
      // accelerationNoiseMps2 0.2, measuring fixtures built on a noise model
      // the device does not produce. Keeping them would have been pinning a
      // description of something that no longer exists.
      //
      // Four entries moved again when StreamDetector was wired into the
      // chain. Sixteen of the twenty did not move at all, which is the useful
      // half of the result: the change reaches only fixtures whose timestamps
      // are fractional, and every whole-second fixture is byte-identical.
      //
      // It remains a change detector, and the job it does is unchanged:
      // "distance moved by 9 m and nobody noticed" is the failure that makes
      // the next round of measurements meaningless. Re-baseline it only
      // alongside a deliberate pipeline change, never to make it pass.
      const expected = <String, (double, int)>{
        'straight 1 km, 6:00/km, no noise': (1000.00, 360),
        // The two stress fixtures. The canyon's 15 m of correlated error
        // barely touches the distance (-0.24%) because correlated error moves
        // the whole track rather than lengthening it; the severe white one
        // reads +18%, which is what uncorrelated error of that size does and
        // why the pair is worth having.
        'straight 1 km, 15 m correlated multipath, reported as 2.5 m': (
          997.64,
          360,
        ),
        'straight 1 km with 15 m white error, reported as 8 m': (1179.94, 360),
        '1 km with 3 fixes at 80 m accuracy': (1000.00, 360),
        '1 km with a 500 m teleport': (1000.00, 360),
        '60 s signal gap with a genuine 400 m displacement': (1233.19, 300),
        // RE-BASELINED for A1c-J, 8 Sep 2026, and this is the deliberate
        // pipeline change the note above allows for. 1744.72 before, against a
        // ground truth of 1666.7: +4.68% error, and 78 m of it was the four
        // minutes of standing being summed instead of frozen. Now +1.91%.
        // Moving time is untouched at 627 s, which is the point — the stop was
        // always excluded from TIME and never from DISTANCE.
        '5 min run, 4 min standing, 5 min run': (1698.49, 627),
        '5.5 km at 6:00/km': (5500.00, 1980),
        // The pessimistic walk. Slower means less displacement per fix against
        // the same error, and it shows: +3.4% against the primary +1.1%.
        //
        // A1c-J moved this by 5 cm, 1034.32 -> 1034.27, and it is the ONLY
        // fixture without a deliberate stop that moved at all. Worth keeping
        // rather than rounding away: at 1.0 m/s a 10 s window covers 10 m, and
        // 2.5 m of correlated error is enough to pull the occasional window
        // under the 5 m the 0.5 m/s threshold needs. Two seconds of this walk
        // are classified stopped — moving time is 998 s, not 1000 — and the
        // anchor takes displacement across them instead of path.
        //
        // So the rule does touch an ordinary slow walk, and the size of the
        // effect is 0.005%. The 1.6 m/s fixtures, where a window covers 16 m,
        // are untouched to the centimetre.
        'straight 1 km walked at 1.0 m/s, 2.5 m GPS error over 20 s': (
          1034.27,
          998,
        ),
        // The three fractional-timestamp fixtures below, and only those three,
        // moved when the stream detector was wired in. Their fixes almost
        // never land on a whole second, so the detector stays UNDECIDED for
        // its 20-fix probe and refuses them; the head of each track loses 15
        // fixes and about 21 s. Distance barely moves — the walk still
        // happened and the step across the hole still measures it — but moving
        // time drops by ~22 s, because the 10 s moving window cannot see
        // across a 21 s gap and scores that one step as stopped.
        // A1c-J moves this by 0.33 m for the same reason as its regular-cadence
        // twin above: at 1.0 m/s the occasional 10 s window falls under the
        // threshold. Slightly larger here because an irregular cadence puts
        // fewer, longer steps inside each window.
        'walk at 1.0 m/s delivered at an irregular cadence, '
            '2.5 m correlated GPS error': (
          1037.02,
          976,
        ),
        // The measured operating point.
        'straight 1 km walked at 1.6 m/s, 2.5 m GPS error over 20 s': (
          1011.40,
          625,
        ),
        'walk at 1.6 m/s delivered at an irregular cadence, '
            '2.5 m correlated GPS error': (
          1011.41,
          603,
        ),
        // The second stream, interleaved. It now lands on the GPS-only
        // fixture's total to the centimetre rather than within 0.1 m, and that
        // is the detector's doing: the accuracy threshold had kept 66 of the
        // 74 network fixes out, and the granularity discriminator takes the
        // remaining 8. Its own timestamps are whole-second GPS, so it pays
        // nothing for the undecided probe.
        'measured walk with 74 interleaved network fixes at 27 m': (
          1011.40,
          625,
        ),
        // Sub-100 ms bursts. Reads +3.0% now, against +0.25% when the error
        // model was correlated over 300 s. At the measured 20 s a 40 ms gap
        // carries a real error difference, so a burst is no longer free —
        // see sub_second_steps_test.
        'brisk walk with sub-100 ms fix bursts, 2.5 m correlated GPS error': (
          1028.85,
          603,
        ),
        // Also re-baselined for A1c-J, and these two are the clearest evidence
        // the change does what it claims. Ground truths are 600.0 and 960.0.
        //   1.0 m/s: 647.42 (+7.90%) -> 600.92 (+0.15%)
        //   1.6 m/s: 1012.34 (+5.45%) -> 977.11 (+1.78%)
        // Moving time is unchanged in both. Every fixture in this table that
        // does NOT stand still is unchanged to the last centimetre, which is
        // what says the anchor rule reduces to fix-to-fix while moving.
        'walk 5 min at 1.0 m/s, stand 3 min, walk 5 min': (600.92, 600),
        'walk 5 min at 1.6 m/s, stand 3 min, walk 5 min': (977.11, 612),
        '600 m walk with a single 250 m spur fix': (600.00, 600),
        // The turning fixtures. The rectangle still reads long; the switchback
        // now reads almost exactly right, because accelerationNoiseMps2 was
        // set to the value that cancels it — see corner_cutting_test.
        '728 m rectangular circuit, four 90-degree turns, no noise': (
          742.00,
          455,
        ),
        '272 m switchback, three hairpins, no noise': (271.56, 169),
        '728 m straight at 1.6 m/s, no turns (control)': (728.00, 455),
      };

      for (final track in allTracks()) {
        final target = expected[track.name];
        expect(target, isNotNull, reason: 'no baseline for ${track.name}');
        final processor = replay(track);
        expect(
          processor.distanceM,
          closeTo(target!.$1, 0.01),
          reason: track.name,
        );
        expect(
          processor.movingTime.inSeconds,
          target.$2,
          reason: track.name,
        );
      }
    });
  });

  group('counts', () {
    test('delivered, accepted and rejected account for every fix', () {
      final track = kmWithInaccurateFixes();
      final report = replay(track).diagnose();

      expect(report.reachedPipeline, track.fixes.length);
      final rejected = report.rejections!.values.fold(0, (a, b) => a + b);
      expect(
        report.accepted + rejected,
        track.fixes.length,
        reason: 'a fix that is neither accepted nor rejected has vanished',
      );
    });

    test('rejections are attributed to the filter that actually fired', () {
      final report = replay(kmWithInaccurateFixes()).diagnose();

      expect(report.rejections![FixRejection.coldStart], 3);
      expect(
        report.rejections![FixRejection.accuracy],
        3,
        reason: 'the fixture plants exactly three 80 m fixes',
      );
      expect(report.rejections![FixRejection.implausibleSpeed] ?? 0, 0);
    });

    test('the teleport is counted under implied speed, not accuracy', () {
      // The teleport fix reports a normal accuracy. If it showed up under the
      // accuracy count, the two filters would be indistinguishable in the
      // report and it would point at the wrong constant.
      final report = replay(kmWithTeleport()).diagnose();
      expect(report.rejections![FixRejection.implausibleSpeed], 1);
      expect(report.rejections![FixRejection.accuracy] ?? 0, 0);
    });

    test('out-of-order arrivals are counted over arrivals, not rejections', () {
      // The distinction this field exists for. A fix that arrives late AND is
      // inaccurate is rejected for its accuracy, so FixRejection.outOfOrder
      // never fires and the rejection count says the clock was fine.
      final track = outOfOrderArrivals();
      final report = replay(track).diagnose();

      expect(
        report.outOfOrderArrivals,
        2,
        reason: 'both reordered arrivals must be seen, whatever rejected them',
      );
      expect(
        report.rejections![FixRejection.outOfOrder] ?? 0,
        lessThan(2),
        reason:
            'if this equalled 2 the fixture would not be exercising the '
            'difference between the two counts',
      );
      // Since the reorder buffer landed, the gap between the two counts is
      // total rather than partial: both reordered arrivals are seen, and
      // neither is rejected, because the buffer puts them back in sequence.
      // The claim above is unchanged and is now satisfied more strongly.
      expect(report.rejections![FixRejection.outOfOrder] ?? 0, 0);
    });
  });

  group('distributions', () {
    test('accuracy reflects the fixture, including the planted bad fixes', () {
      final report = replay(kmWithInaccurateFixes()).diagnose();

      expect(report.deliveredAccuracyM!.median, 5);
      expect(
        report.deliveredAccuracyM!.max,
        80,
        reason: 'the delivered distribution must include what was rejected',
      );
      expect(
        report.acceptedAccuracyM!.max,
        5,
        reason: 'the accepted distribution must not',
      );
    });

    test('dt is 1 s on a 1 Hz fixture and the gap shows in the tail', () {
      final report = replay(gapThenGenuineDisplacement()).diagnose();

      expect(report.deliveredDtS!.median, 1);
      expect(report.deliveredDtS!.max, 60);
      expect(report.deliveredDtOver3s, 1);
    });

    test('speed is the pace the fixture was built at', () {
      final report = replay(straightKm()).diagnose();
      expect(report.acceptedSpeedMps!.median, closeTo(runSpeedMps, 0.1));
    });
  });

  group('distance, three ways', () {
    test('raw over-reports the noisy track and the pipeline does not', () {
      final report = replay(urbanCanyonKm()).diagnose();

      expect(
        report.rawDeliveredDistanceM,
        greaterThan(1100),
        reason: 'this is the naive number the pipeline exists to beat',
      );
      expect(report.smoothedDistanceM, closeTo(1000, 30));
      expect(
        report.rawAcceptedDistanceM,
        greaterThan(report.smoothedDistanceM),
        reason: 'filtering alone does not remove the jitter; smoothing does',
      );
    });
  });

  group('stops', () {
    test('the four-minute stand shows up, in one or two segments', () {
      // It was one segment, asserted as `.single`, when a stationary fixture
      // carried 1.5 m of error correlated over 300 s and therefore barely
      // moved. Under the measured model — 2.5 m over 20 s — a still receiver
      // wanders about 3.5 m in 10 s, which is 0.35 m/s against a 0.5 m/s
      // threshold. The margin is real but thin, and one window inside the
      // stand crosses it, splitting the stand in two.
      //
      // Asserted as a range rather than re-pinned at two, because which side
      // of a thin margin a particular noise draw falls on is not a property of
      // the pipeline. The total is what carries the meaning, so the total is
      // what is held tightly.
      final report = replay(standingStill()).diagnose();

      expect(report.stops.length, inInclusiveRange(1, 2));
      expect(
        report.totalStopped.inSeconds,
        closeTo(240, 32),
        reason:
            'the 10 s decision window is late at each edge, and the receiver '
            'genuinely moves while the phone does not',
      );
    });

    test('a run with no stops reports none', () {
      expect(replay(straightKm()).diagnose().stops, isEmpty);
    });
  });

  group('reconstruction from stored points', () {
    test('recovers the stops and the cadence, and admits what it cannot', () {
      // The fallback path, checked against a live capture of the same track:
      // whatever it does claim has to agree with what really happened.
      final processor = replay(standingStill());
      final live = processor.diagnose();
      final rebuilt = reconstructDiagnostics(
        points: processor.points,
        smoothedDistanceM: processor.distanceM,
        elapsed: processor.elapsed,
        movingTime: processor.movingTime,
        minMovingSpeedMps: TrackProcessor().minMovingSpeedMps,
        maxSpeedMps: TrackProcessor().maxSpeedMps,
        movingWindow: TrackProcessor().movingWindow,
      );

      expect(rebuilt.source, DiagnosticsSource.reconstructed);
      expect(rebuilt.accepted, live.accepted);
      expect(rebuilt.stops.length, live.stops.length);
      // Every segment, not just the first: the stand now splits into two under
      // the measured stationary model, and `.single` both threw and would have
      // compared only one of them if it had not.
      for (var i = 0; i < live.stops.length; i++) {
        expect(
          rebuilt.stops[i].duration,
          live.stops[i].duration,
          reason: 'both go through the same displacement rule, so they must',
        );
        expect(rebuilt.stops[i].startedAt, live.stops[i].startedAt);
      }
      expect(rebuilt.acceptedDtS!.median, live.acceptedDtS!.median);

      // And the honesty half. These are gone, and the report must say so
      // rather than print a plausible number.
      expect(rebuilt.reachedPipeline, isNull);
      expect(rebuilt.rejections, isNull);
      expect(rebuilt.outOfOrderArrivals, isNull);
      expect(rebuilt.rawDeliveredDistanceM, isNull);
      expect(
        rebuilt.rawAcceptedDistanceM,
        isNull,
        reason:
            'the stored positions are already smoothed; differencing them '
            'would report the pipeline total twice under two labels',
      );
    });
  });

  group('the report renders', () {
    test(
      'a live capture names every rejection reason, including the zeroes',
      () {
        final text = replay(kmWithInaccurateFixes()).diagnose().plainText();

        for (final reason in FixRejection.values) {
          expect(
            text,
            contains(
              switch (reason) {
                FixRejection.coldStart => 'cold start',
                FixRejection.accuracy => 'accuracy',
                FixRejection.otherStream => 'other stream',
                FixRejection.implausibleSpeed => 'implied speed',
                FixRejection.tooSoonToPair => 'too soon to pair',
                FixRejection.outOfOrder => 'non-monotonic clock',
                FixRejection.arrivedTooLate => 'past the buffer',
              },
            ),
            reason: 'a missing line reads as an oversight, not as a zero',
          );
        }
      },
    );

    test('a late arrival carries its accuracy and what it means', () {
      // **A1c-K.** `past the buffer 172` on the forest capture reads as 172
      // lost fixes and is not one: 1205 + 172 = 1377 exactly, and `accepted`
      // and distance are identical at every horizon from 0 to 8 s, because
      // every one of them is a fix the accuracy gate throws out one step
      // later. The number is the alarming half of a benign finding, and the
      // report has to carry the other half — otherwise the only defence
      // against it is having read NOTES.md.
      final text = replay(shuffledArrivalWalk()).diagnose().plainText();

      // Anchored to the rejection line itself. "median accuracy" appears in
      // the stream detection block too, so a bare `contains` would pass
      // against a report that never learned to print this one.
      expect(
        text,
        matches(RegExp(r'past the buffer\s+\d+\s+median accuracy\s+[\d.]+ m')),
        reason: 'the count alone cannot say which producer these came from',
      );
      expect(text, contains('is not data loss'));
      expect(
        text,
        contains('signature of the other producer'),
        reason: 'the general finding, not a note about this one run',
      );
    });

    test('a low acceptance rate is named as an environment signal', () {
      // 68.5% on the 8 Sep shop walk is the lowest recorded, and it is what a
      // receiver with no sky looks like rather than what a broken filter
      // looks like. Unconditional prose: a threshold deciding when to print
      // this would be a constant invented to describe a sentence.
      final text = replay(kmWithInaccurateFixes()).diagnose().plainText();

      expect(text, contains('ENVIRONMENT signal'));
    });

    test('a reconstruction says so at the top and prints unknowns', () {
      final processor = replay(straightKm());
      final text = reconstructDiagnostics(
        points: processor.points,
        smoothedDistanceM: processor.distanceM,
        elapsed: processor.elapsed,
        movingTime: processor.movingTime,
        minMovingSpeedMps: TrackProcessor().minMovingSpeedMps,
        maxSpeedMps: TrackProcessor().maxSpeedMps,
        movingWindow: TrackProcessor().movingWindow,
      ).plainText();

      expect(text, contains('REBUILT from stored points'));
      expect(text, contains('unknown'));
    });
  });
}
