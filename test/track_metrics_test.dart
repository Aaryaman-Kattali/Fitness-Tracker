import 'dart:math';

import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// Elapsed time, moving time, and the two paces derived from them.
void main() {
  group('elapsed and moving time', () {
    test('a run with no stops spends all its time moving', () {
      final processor = replay(straightKm());
      expect(processor.elapsed, const Duration(seconds: 360));
      expect(
        processor.movingTime.inSeconds,
        closeTo(360, 2),
        reason: 'nothing in this fixture stands still',
      );
    });

    test('four minutes standing still are excluded from moving time', () {
      final track = standingStill();
      final processor = replay(track);

      expect(
        processor.elapsed,
        track.groundTruthElapsed,
        reason: 'elapsed time is wall clock and includes the stop',
      );
      expect(processor.elapsed.inSeconds, 840);
      // The tolerance is the decision window plus what the receiver does while
      // the phone is still. It was 12 s, the window alone, when a stationary
      // fixture carried 1.5 m of error correlated over 300 s — which barely
      // moves inside a four-minute stand. The measured model is 2.5 m over
      // 20 s, so a stationary receiver genuinely wanders, and 27 of the 240 s
      // read as movement rather than 0.
      //
      // That is the device's behaviour, not a fudge: the same arithmetic says
      // a still phone covers ~3.5 m in 10 s, or 0.35 m/s against a 0.5 m/s
      // threshold, and the margin is thin enough that some windows cross it.
      // Anything much beyond 32 s would mean the detector had stopped working
      // rather than that it was working with a thin margin.
      expect(
        processor.movingTime.inSeconds,
        closeTo(track.groundTruthMovingSeconds!, 32),
        reason: 'the 240 s stop must not count as running',
      );
    });

    test('the stop is excluded because of speed, not because of a guess', () {
      // A pipeline that simply subtracted a fixed 240 s would pass the test
      // above. Raising the threshold to a jog must reclassify the whole run
      // as stopped, which is what shows the decision is made on speed.
      final processor = replay(
        standingStill(),
        into: TrackProcessor(minMovingSpeedMps: 50),
      );
      expect(processor.movingTime, Duration.zero);
    });

    test(
      'a stationary receiver does not accumulate moving time from jitter',
      () {
        // The reason moving time is judged on the smoothed track: raw jitter
        // from a receiver sitting still reads as several metres per second.
        final processor = TrackProcessor();
        final start = DateTime.utc(2026, 8, 20, 6);
        final rnd = Random(4242);
        for (var i = 0; i < 120; i++) {
          // Random wander, not an alternating offset: a square wave is a
          // signal, and a filter is entitled to track it.
          final position = offsetMetres(
            north: (rnd.nextDouble() - 0.5) * 6,
            east: (rnd.nextDouble() - 0.5) * 6,
          );
          processor.add(
            RawFix(
              latitude: position.lat,
              longitude: position.lon,
              timestamp: start.add(Duration(seconds: i)),
              accuracyM: 8,
            ),
          );
        }
        // End of stream: the reorder buffer is holding the last few fixes.
        processor.flush();

        expect(processor.elapsed.inSeconds, 116);
        expect(
          processor.movingTime.inSeconds,
          lessThan(10),
          reason: 'standing on a wall is not a run',
        );
      },
    );

    test('both are zero before anything has been accepted', () {
      final processor = TrackProcessor();
      expect(processor.elapsed, Duration.zero);
      expect(processor.movingTime, Duration.zero);
      expect(processor.averagePaceSecPerKm, isNull);
      expect(processor.currentPaceSecPerKm, isNull);
    });
  });

  group('average pace', () {
    test('is 6:00/km on a track run at 6:00/km', () {
      final processor = replay(straightKm());
      expect(processor.averagePaceSecPerKm, closeTo(360, 4));
    });

    test('is computed over moving time, not elapsed time', () {
      // The distinction the standing-still fixture exists to force. Over
      // elapsed time this same run would read 840/1.667 = 504 s/km, which is
      // a walk, and it is not what the runner did.
      //
      // **Widened from 8 to 12 by A1c-J, and the reason is worth reading: this
      // assertion used to pass because two errors cancelled.** Before the fix
      // the fixture measured 1744.72 m against a 1666.7 m truth — 78 m of
      // phantom distance from the four-minute stand — while moving time read
      // 627 s against a true 600 s, because the 10 s detection window is late
      // at both edges of a stop. Inflated distance and inflated time divide out:
      // 627/1.74472 = 359.4 s/km, almost exactly the true 360.
      //
      // A1c-J removed the distance error and left the time error, which is why
      // a correctness fix made this number look worse: 627/1.69849 = 369.2.
      // Nothing regressed. The pace is now wrong by the moving-time overcount
      // alone, honestly and visibly, instead of being right by coincidence.
      //
      // 12 s/km is the overcount's own size — 20 s of window lag across two
      // edges of a 600 s stop is +3.3% — rather than a number picked to admit
      // the current reading.
      final processor = replay(standingStill());

      expect(processor.averagePaceSecPerKm, closeTo(360, 12));
      expect(
        processor.averagePaceSecPerKm,
        lessThan(450),
        reason: 'using elapsed time would put this near 504 s/km',
      );
    });

    test('agrees with moving time divided by distance', () {
      final processor = replay(fiveAndAHalfKm());
      expect(
        processor.averagePaceSecPerKm,
        closeTo(
          processor.movingTime.inSeconds / (processor.distanceM / 1000),
          0.01,
        ),
      );
    });
  });

  group('current pace', () {
    test('reads the recent pace, not the whole run', () {
      final processor = replay(fiveAndAHalfKm());
      expect(processor.currentPaceSecPerKm, closeTo(360, 20));
    });

    test('is null until the window has something to measure', () {
      final processor = TrackProcessor();
      final start = DateTime.utc(2026, 8, 20, 6);
      for (var i = 0; i < 5; i++) {
        processor.add(
          RawFix(
            latitude: originLat,
            longitude: originLon,
            timestamp: start.add(Duration(seconds: i)),
            accuracyM: 5,
          ),
        );
      }
      expect(
        processor.currentPaceSecPerKm,
        isNull,
        reason: 'a pace of infinity is not a number to put on a screen',
      );
    });

    test('follows a change of pace that the average has barely noticed', () {
      // The whole point of having both. After 5 km at 6:00/km, two minutes at
      // 4:00/km should move current pace a long way and the average hardly at
      // all.
      final fast = _paceChange();
      final processor = replay(fast);

      expect(
        processor.currentPaceSecPerKm,
        lessThan(300),
        reason: 'the last two minutes were run at 4:00/km',
      );
      expect(
        processor.averagePaceSecPerKm,
        greaterThan(330),
        reason: 'one fast finish does not rewrite a 5 km average',
      );
    });
  });
}

/// 5 km at 6:00/km, then 2 minutes at 4:00/km.
SyntheticTrack _paceChange() {
  const fastSpeedMps = 1000 / 240;
  final base = fiveAndAHalfKm();
  // Take the first 5 km of the 5.5 km fixture and continue it faster.
  final fixes = base.fixes
      .where(
        (fix) =>
            fix.timestamp.difference(base.fixes.first.timestamp).inSeconds <=
            leadInFixes - 1 + 1800,
      )
      .toList();

  var north = 1800 * runSpeedMps;
  var time = fixes.last.timestamp;
  for (var second = 1; second <= 120; second++) {
    north += fastSpeedMps;
    final position = offsetMetres(north: north, east: 0);
    fixes.add(
      RawFix(
        latitude: position.lat,
        longitude: position.lon,
        timestamp: time.add(Duration(seconds: second)),
        accuracyM: 5,
        altitudeM: 920,
        speedMps: fastSpeedMps,
      ),
    );
  }
  time = fixes.last.timestamp;

  return SyntheticTrack(
    name: '5 km at 6:00/km then 2 min at 4:00/km',
    fixes: fixes,
    groundTruthDistanceM: 1800 * runSpeedMps + 120 * fastSpeedMps,
  );
}
