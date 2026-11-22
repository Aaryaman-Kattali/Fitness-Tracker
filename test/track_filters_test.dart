import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The filter chain, one rule at a time, replayed from the synthetic tracks.
void main() {
  group('cold start', () {
    test('discards the first three fixes whatever they look like', () {
      final track = straightKm();
      final processor = replay(track);

      expect(processor.rejectedFor(FixRejection.coldStart), 3);
      expect(
        processor.rejected.take(3).map((entry) => entry.fix).toList(),
        track.fixes.take(3).toList(),
        reason: 'it must be the first three, not any three',
      );
    });

    test('rejects a cold-start fix that reports excellent accuracy', () {
      // The whole reason this filter cannot be folded into the accuracy test:
      // a receiver that has just woken up is confidently wrong.
      final processor = TrackProcessor();
      final start = DateTime.utc(2026, 8, 20, 6);
      for (var i = 0; i < 4; i++) {
        processor.add(
          RawFix(
            latitude: originLat,
            longitude: originLon,
            timestamp: start.add(Duration(seconds: i)),
            accuracyM: 3,
          ),
        );
      }

      // The stream has ended, so the reorder buffer has nothing left to wait
      // for. Without this the last fixes are still held and the counts below
      // describe a run that is not over.
      processor.flush();

      expect(processor.rejectedFor(FixRejection.coldStart), 3);
      expect(processor.points, hasLength(1));
    });

    test('does not spend the discard on real distance', () {
      // The fixtures carry a stationary lead-in for exactly this reason. If
      // the first accepted point were three steps up the track, every distance
      // assertion in the suite would start 8 m short.
      final processor = replay(straightKm());
      final first = processor.points.first;
      expect(
        haversineMetres(first.latitude, first.longitude, originLat, originLon),
        lessThan(0.01),
      );
    });
  });

  group('accuracy', () {
    test('rejects fixes worse than 50 m', () {
      final processor = replay(kmWithInaccurateFixes());

      expect(processor.rejectedFor(FixRejection.accuracy), 3);
      expect(
        processor.rejected
            .where((entry) => entry.reason == FixRejection.accuracy)
            .every((entry) => entry.fix.accuracyM == 80),
        isTrue,
      );
    });

    test('keeps every good fix on the same track', () {
      final track = kmWithInaccurateFixes();
      final processor = replay(track);
      expect(
        processor.points.length,
        track.fixes.length - 3 - 3,
        reason: 'three cold-start and three inaccurate, and nothing else',
      );
    });

    test('accepts a fix exactly at the limit', () {
      // 50 m is the worst *acceptable* accuracy, not the best rejected one.
      // Getting this backwards is a one-character bug that no fixture with a
      // round 80 m would ever catch.
      final processor = TrackProcessor();
      final start = DateTime.utc(2026, 8, 20, 6);
      for (var i = 0; i < 5; i++) {
        processor.add(
          RawFix(
            latitude: originLat,
            longitude: originLon + i * 0.00001,
            timestamp: start.add(Duration(seconds: i)),
            accuracyM: i == 4 ? 50 : 5,
          ),
        );
      }
      expect(processor.rejectedFor(FixRejection.accuracy), 0);
    });
  });

  group('clock order', () {
    test('rejects a fix that does not move the clock forward', () {
      // Driven with the reorder buffer off, because this is the clock filter's
      // own test and the buffer sits in front of it. With the buffer running a
      // late fix is put back in sequence instead of refused, which is a
      // different mechanism with its own tests in reorder_buffer_test — and
      // folding the two together here would leave neither one measured.
      final processor = TrackProcessor(bufferHorizon: Duration.zero);
      final start = DateTime.utc(2026, 8, 20, 6);
      for (var i = 0; i < 4; i++) {
        processor.add(_fixAt(start.add(Duration(seconds: i))));
      }
      expect(processor.points, hasLength(1));

      // A repeat of the accepted timestamp, and one from before it.
      processor
        ..add(_fixAt(start.add(const Duration(seconds: 3))))
        ..add(_fixAt(start.add(const Duration(seconds: 1))));

      expect(processor.rejectedFor(FixRejection.outOfOrder), 2);
      expect(
        processor.points,
        hasLength(1),
        reason: 'a zero or negative dt is a division waiting to happen in pace',
      );
    });
  });

  group('the accepted track carries the raw fix', () {
    test('altitude, accuracy and reported speed survive filtering', () {
      // A1a computes nothing from altitude, but RunPoints has to store it, so
      // the pipeline must not throw it away on the way through.
      final point = replay(straightKm()).points.last;
      expect(point.source.altitudeM, 920);
      expect(point.source.accuracyM, 5);
      expect(point.source.speedMps, isNotNull);
    });
  });
}

RawFix _fixAt(DateTime time) => RawFix(
  latitude: originLat,
  longitude: originLon,
  timestamp: time,
  accuracyM: 5,
);
