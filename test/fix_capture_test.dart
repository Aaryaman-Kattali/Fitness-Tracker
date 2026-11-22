import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// The capture has one job: a run replayed from it must be the same run.
///
/// Anything less and it is a lossy summary rather than a record, and the whole
/// point of writing it is that the questions asked of a walk are not known
/// while the walk is happening.
void main() {
  group('a capture round-trips', () {
    test('a replayed capture measures the recorded run exactly', () {
      // THE PROPERTY. Not "close to" — the same double. A capture that loses a
      // digit of longitude would still pass a tolerance and would quietly make
      // every later measurement approximate, which for a 200 m question over
      // 1.74 km is the difference between an answer and a suggestion.
      final track = measuredVariableCadenceWalk();
      final direct = replay(track);

      final ndjson = _capture(track.fixes);
      final replayed = replayCapture(ndjson);

      expect(replayed.smoothedDistanceM, direct.distanceM);
      expect(replayed.accepted, direct.points.length);
      expect(replayed.elapsed, direct.elapsed);
      expect(replayed.movingTime, direct.movingTime);
      expect(
        replayed.rejections,
        {
          for (final reason in FixRejection.values)
            if (direct.rejectedFor(reason) > 0)
              reason: direct.rejectedFor(reason),
        },
        reason: 'the same fixes must be discarded for the same reasons',
      );
    });

    test('every field survives, including the nullable ones', () {
      // Altitude and speed are genuinely absent on a real first lock, and a
      // capture that wrote them as zero would hand the replay a claim — sea
      // level, standing still — where the device reported nothing.
      final original = RawFix(
        latitude: 12.971612345678,
        longitude: 77.594698765432,
        timestamp: _instant,
        accuracyM: 2.4700000000000002,
      );

      final parsed = parseCapture(encodeFix(7, original)).single;

      expect(parsed.seq, 7);
      expect(parsed.fix.latitude, original.latitude);
      expect(parsed.fix.longitude, original.longitude);
      expect(parsed.fix.accuracyM, original.accuracyM);
      expect(parsed.fix.timestamp, original.timestamp);
      expect(parsed.fix.altitudeM, isNull);
      expect(parsed.fix.speedMps, isNull);
    });

    test('altitude and speed come back when they were there', () {
      final original = RawFix(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: _instant,
        accuracyM: 3.1,
        altitudeM: 919.5,
        speedMps: 1.62,
      );

      final parsed = parseCapture(encodeFix(0, original)).single.fix;
      expect(parsed.altitudeM, 919.5);
      expect(parsed.speedMps, 1.62);
    });
  });

  group('arrival order is what is preserved', () {
    test('a capture keeps fixes in the order they arrived, not sorted', () {
      // The entire reason this file exists. `outOfOrderArrivals` delivers two
      // pairs the wrong way round, and if the capture or the parse sorted them
      // the question "did the plugin reorder them" would answer no for every
      // run ever recorded.
      final track = outOfOrderArrivals();
      final parsed = parseCapture(_capture(track.fixes));

      expect(parsed, hasLength(track.fixes.length));
      for (var i = 0; i < parsed.length; i++) {
        expect(parsed[i].seq, i);
        expect(
          parsed[i].fix.timestamp,
          track.fixes[i].timestamp,
          reason: 'fix $i is not where it arrived',
        );
      }

      var backwards = 0;
      for (var i = 1; i < parsed.length; i++) {
        if (!parsed[i].fix.timestamp.isAfter(parsed[i - 1].fix.timestamp)) {
          backwards++;
        }
      }
      expect(
        backwards,
        2,
        reason: 'both reordered arrivals must still be visible in the file',
      );
    });

    test('the replay sees the same out-of-order count the live run saw', () {
      final track = outOfOrderArrivals();
      final live = replay(track).diagnose();
      final replayed = replayCapture(_capture(track.fixes));

      expect(replayed.outOfOrderArrivals, live.outOfOrderArrivals);
      expect(replayed.outOfOrderArrivals, 2);
    });

    test('the sequence number survives sorting the file by timestamp', () {
      // The obvious first thing anyone does with a capture, and it must not
      // destroy the evidence. After sorting, the timestamps are monotonic and
      // only `seq` still says what really happened.
      final lines = _capture(outOfOrderArrivals().fixes).trim().split('\n')
        ..sort();
      final sorted = parseCapture(lines.join('\n'));

      var outOfSequence = 0;
      for (var i = 1; i < sorted.length; i++) {
        if (sorted[i].seq < sorted[i - 1].seq) outOfSequence++;
      }
      expect(outOfSequence, greaterThan(0));
    });
  });

  group('the replay is a controlled experiment', () {
    test('the same capture through two configurations differs only by them', () {
      // What the capture is FOR. One recorded walk, two pipelines, and the
      // difference is attributable because the input is byte-identical — which
      // is not available from a device any other way, since two walks are two
      // walks.
      final ndjson = _capture(measuredWalkKm().fixes);

      final standard = replayCapture(ndjson);
      // Below the default, which is 9. A "strict" configuration that is looser
      // than the standard one inverts the comparison and the test then fails
      // for a reason that has nothing to do with the replay.
      final strict = replayCapture(
        ndjson,
        into: TrackProcessor(maxAccuracyM: 2),
      );

      expect(standard.accepted, greaterThan(strict.accepted));
      expect(
        standard.smoothedDistanceM,
        isNot(strict.smoothedDistanceM),
        reason: 'if a threshold change moved nothing, the replay is not wired',
      );
    });

    test('what the capture cannot know, it reports as unknown', () {
      // A fix the plugin emitted with an unparseable timestamp never reaches
      // the stream this file is written from. Printing the line count under
      // "delivered by plugin" would claim a clean delivery record the file has
      // no evidence for.
      final report = replayCapture(_capture(straightKm().fixes));

      expect(report.deliveredByPlugin, isNull);
      expect(report.undatableDropped, isNull);
      expect(
        report.reachedPipeline,
        straightKm().fixes.length,
        reason: 'what it can know, it knows exactly',
      );
    });
  });

  group('malformed input', () {
    test('blank lines are ignored and a bad line throws', () {
      final fix = RawFix(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: _instant,
        accuracyM: 3,
      );

      expect(parseCapture('\n${encodeFix(0, fix)}\n\n'), hasLength(1));
      expect(
        () => parseCapture('${encodeFix(0, fix)}\nnot json'),
        throwsA(isA<FormatException>()),
        reason:
            'silently dropping fixes out of a record whose whole purpose is '
            'completeness is the worst available failure',
      );
    });

    test('an empty capture parses to nothing rather than failing', () {
      expect(parseCapture(''), isEmpty);
    });
  });
}

/// A whole track as a capture file, exactly as the recorder writes one.
String _capture(List<RawFix> fixes) {
  final lines = [
    for (var i = 0; i < fixes.length; i++) encodeFix(i, fixes[i]),
  ];
  return '${lines.join('\n')}\n';
}

final _instant = DateTime.utc(2026, 8, 22, 6, 30, 15, 123);
