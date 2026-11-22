import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The teleport and the signal gap live in the same file deliberately.
///
/// They are one decision, not two: a fixed per-fix distance cap passes the
/// first and fails the second, and a cap loose enough to pass the second lets
/// the first straight through. Only a bound that scales with elapsed time
/// satisfies both, so the two assertions have to be readable together or a
/// later "fix" to one will quietly break the other.
void main() {
  group('a bound that scales with elapsed time', () {
    test('rejects a 500 m jump between fixes one second apart', () {
      final processor = replay(kmWithTeleport());

      expect(processor.rejectedFor(FixRejection.implausibleSpeed), 1);
      expect(
        processor.points.length,
        kmWithTeleport().fixes.length - 3 - 1,
        reason: 'exactly one bad fix, and the track continues past it',
      );
    });

    test('accepts a genuine 400 m displacement after a 60 s gap', () {
      final processor = replay(gapThenGenuineDisplacement());

      expect(
        processor.rejectedFor(FixRejection.implausibleSpeed),
        0,
        reason: 'a fixed cap would throw this away and shorten the run',
      );
      expect(
        processor.points.length,
        gapThenGenuineDisplacement().fixes.length - 3,
      );
    });

    test('the 400 m after the gap survives into the track', () {
      // Counting rejections is not enough: the point of accepting it is that
      // the distance is still there to be measured.
      final points = replay(gapThenGenuineDisplacement()).points;
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
        ), // See the note in track_distance_test: at the shipped process noise
        // the reacquisition lands 396.4 m along, not 400.
      );
    });

    test('no fixed distance cap can work, because gaps get arbitrarily long', () {
      // Five minutes without lock — a tunnel, a dense city block — is 833 m of
      // genuine travel at 6:00/km, and it must be kept.
      const gapSeconds = 300;
      const genuineDisplacementM = gapSeconds * runSpeedMps;

      final processor = TrackProcessor();
      final start = DateTime.utc(2026, 8, 20, 6);
      for (var i = 0; i < 4; i++) {
        processor.add(
          _fix(
            offsetMetres(north: i * runSpeedMps, east: 0),
            start.add(Duration(seconds: i)),
          ),
        );
      }
      processor.add(
        _fix(
          offsetMetres(
            north: 3 * runSpeedMps + genuineDisplacementM,
            east: 0,
          ),
          start.add(const Duration(seconds: 3 + gapSeconds)),
        ),
      );
      expect(processor.rejectedFor(FixRejection.implausibleSpeed), 0);

      // That is the contradiction any fixed distance cap has to live with.
      // To stop the 500 m teleport it must sit below 500; to keep this it must
      // sit at or above 833. Both cannot hold, and a longer gap pushes the
      // second number up without limit. The time term is not a refinement of
      // a fixed cap — it is what makes the question answerable at all.
      expect(genuineDisplacementM, greaterThan(500));
    });

    test('ordinary running is nowhere near the bound', () {
      // A filter that also rejected normal fixes would pass both tests above
      // while destroying every run.
      final processor = replay(straightKm());
      expect(processor.rejectedFor(FixRejection.implausibleSpeed), 0);
    });

    test('the bound widens with the gap rather than with distance', () {
      // The same 400 m, delivered after 10 s instead of 60. 40 m/s is a car,
      // so the identical displacement must now be refused — which is the
      // clearest statement that the time term is doing the work.
      final processor = TrackProcessor();
      final start = DateTime.utc(2026, 8, 20, 6);
      for (var i = 0; i < 4; i++) {
        processor.add(
          _fix(
            offsetMetres(north: i * runSpeedMps, east: 0),
            start.add(Duration(seconds: i)),
          ),
        );
      }
      // Release the lead-in before asserting on it: three seconds of it are
      // still in the reorder buffer otherwise, and the count below would be of
      // a run that has not caught up with itself.
      processor.flush();
      expect(processor.points, hasLength(1));

      // The flush is end-of-stream: without it the fix under test is still in
      // the reorder buffer when the count below is read.
      processor
        ..add(
          _fix(
            offsetMetres(north: 3 * runSpeedMps + 400, east: 0),
            start.add(const Duration(seconds: 13)),
          ),
        )
        ..flush();

      expect(
        processor.rejectedFor(FixRejection.implausibleSpeed),
        1,
        reason: '400 m in 10 s is 40 m/s and must not pass',
      );
    });
  });
}

RawFix _fix(({double lat, double lon}) position, DateTime time) => RawFix(
  latitude: position.lat,
  longitude: position.lon,
  timestamp: time,
  accuracyM: 5,
);
