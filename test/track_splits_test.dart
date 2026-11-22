import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

void main() {
  group('per-kilometre splits', () {
    test('5.5 km gives five whole kilometres and a partial', () {
      final splits = replay(fiveAndAHalfKm()).splits;

      expect(splits, hasLength(6));
      expect(splits.take(5).every((split) => !split.isPartial), isTrue);
      expect(splits.take(5).every((split) => split.distanceM == 1000), isTrue);
      expect(splits.map((split) => split.km), [1, 2, 3, 4, 5, 6]);

      final last = splits.last;
      expect(last.isPartial, isTrue);
      expect(last.distanceM, closeTo(500, 15));
    });

    test('each whole kilometre took about six minutes', () {
      final splits = replay(fiveAndAHalfKm()).splits;
      for (final split in splits.take(5)) {
        expect(
          split.duration.inSeconds,
          closeTo(360, 3),
          reason: 'split ${split.km} came out at ${split.duration.inSeconds}s',
        );
        expect(split.paceSecPerKm, closeTo(360, 3));
      }
      expect(splits.last.duration.inSeconds, closeTo(180, 5));
    });

    test('the splits tile the run with no gap and no overlap', () {
      // The property that catches an off-by-one at a boundary: whatever the
      // individual numbers, they have to add back up to the run.
      final processor = replay(fiveAndAHalfKm());
      final splits = processor.splits;

      final totalDistance = splits
          .map((split) => split.distanceM)
          .reduce((a, b) => a + b);
      expect(totalDistance, closeTo(processor.distanceM, 0.01));

      final totalTime = splits
          .map((split) => split.duration.inMicroseconds)
          .reduce((a, b) => a + b);
      expect(totalTime, closeTo(processor.elapsed.inMicroseconds, 1000));
    });

    test('boundaries are interpolated, not snapped to the nearest fix', () {
      // At 1 Hz a fix lands every 2.8 m, so snapping is only a second wrong
      // and this would pass either way. At a 20 s cadence — where a phone
      // sits when it is saving battery — a fix lands every 55.6 m, and
      // snapping the boundary to one would put the split up to 10 s out.
      final processor = _lowCadenceRun();
      final splits = processor.splits;

      expect(splits.length, greaterThanOrEqualTo(2));
      for (final split in splits.where((split) => !split.isPartial)) {
        expect(
          split.duration.inMilliseconds,
          closeTo(360000, 1500),
          reason:
              'split ${split.km} was ${split.duration.inMilliseconds}ms; '
              'snapping to the fix before the boundary gives 357000ms, which '
              'is what this tolerance is set to catch',
        );
      }
    });

    test('a run shorter than a kilometre is one partial split', () {
      final processor = replay(straightKm());
      // 1 km exactly, so the interesting case is the one just under it: take
      // the same track and stop it early.
      expect(processor.splits.first.km, 1);

      final short = TrackProcessor();
      straightKm().fixes.take(200).forEach(short.add);

      expect(short.splits, hasLength(1));
      expect(short.splits.single.isPartial, isTrue);
      expect(short.splits.single.distanceM, lessThan(1000));
    });

    test('an empty or single-point track has no splits', () {
      expect(TrackProcessor().splits, isEmpty);

      final one = TrackProcessor();
      for (var i = 0; i < 4; i++) {
        one.add(
          RawFix(
            latitude: originLat,
            longitude: originLon,
            timestamp: DateTime.utc(2026, 8, 20, 6).add(Duration(seconds: i)),
            accuracyM: 5,
          ),
        );
      }
      expect(
        one.splits,
        isEmpty,
        reason: 'standing still covers no ground, so there is nothing to split',
      );
    });

    test('a stop lands inside the split it happened in', () {
      // Splits are elapsed time, so the kilometre containing a four-minute
      // stop must be about four minutes slower than the others.
      final splits = replay(standingStill()).splits;
      final slowest = splits
          .map((split) => split.duration.inSeconds)
          .reduce((a, b) => a > b ? a : b);
      expect(
        slowest,
        greaterThan(500),
        reason: 'the 240 s stop has to show up in exactly one split',
      );
    });
  });
}

/// 2.5 km at 6:00/km with a fix only every 17 seconds.
///
/// Seventeen rather than a round twenty on purpose: at 20 s a fix lands every
/// 55.556 m and the 1000 m mark falls exactly on the eighteenth one, so
/// snapping and interpolating would agree and the test would prove nothing.
/// At 17 s the boundary falls between fixes, where the two differ by ~8 s.
TrackProcessor _lowCadenceRun() {
  const cadence = 17;
  final processor = TrackProcessor();
  final start = DateTime.utc(2026, 8, 20, 6);

  // Lead-in, so the cold-start discard does not eat real distance.
  for (var i = 0; i < leadInFixes; i++) {
    final position = offsetMetres(north: 0, east: 0);
    processor.add(
      RawFix(
        latitude: position.lat,
        longitude: position.lon,
        timestamp: start.add(Duration(seconds: i * cadence)),
        accuracyM: 5,
      ),
    );
  }

  final base = start.add(
    const Duration(seconds: (leadInFixes - 1) * cadence),
  );
  for (var step = 1; step * cadence <= 900; step++) {
    final seconds = step * cadence;
    final position = offsetMetres(north: seconds * runSpeedMps, east: 0);
    processor.add(
      RawFix(
        latitude: position.lat,
        longitude: position.lon,
        timestamp: base.add(Duration(seconds: seconds)),
        accuracyM: 5,
      ),
    );
  }

  return processor;
}
