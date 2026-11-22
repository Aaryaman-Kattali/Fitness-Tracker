import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/stream_detector.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// [StreamDetector] inside the chain, rather than beside it.
///
/// `stream_detector_test` proves the detector separates the streams. This file
/// proves the pipeline actually asks it, that cold start runs behind it, and
/// what that cost and bought on each capture. Every claim here is a difference
/// between `detectStreams: true` and `detectStreams: false`, so none of it can
/// pass against a detector that is present but ignored.
void main() {
  ({TrackProcessor on, TrackProcessor off}) replayBoth(String path) {
    final contents = File(path).readAsStringSync();
    final on = TrackProcessor();
    final off = TrackProcessor(detectStreams: false);
    replayCapture(contents, into: on);
    replayCapture(contents, into: off);
    return (on: on, off: off);
  }

  group('the split is reproduced through the pipeline', () {
    test('23 Aug: 1051 GPS / 154 network, on granularity', () {
      final streams = replayBoth('captures/2026-08-23_1610m.ndjson').on.streams;

      expect(streams.discriminator, StreamDiscriminator.granularity);
      expect(streams.primaryCount, 1051);
      expect(streams.otherCount, 154);
      expect(streams.cutM, isNull, reason: 'granularity needs no accuracy cut');
      expect(streams.granularityAvailable, isTrue);
    });

    test(
      '24 Aug: 819 GPS / 94 network, less the one the buffer never released',
      () {
        final replay = replayBoth('captures/2026-08-24_1610m.ndjson');
        final streams = replay.on.streams;

        expect(streams.discriminator, StreamDiscriminator.granularity);
        // Every GPS fix, exactly.
        expect(streams.primaryCount, 819);
        // 93, not the capture's 94. The detector sits inside `_process`, behind
        // the reorder buffer, and this walk had one fix delivered so late the
        // buffer refused it before any filter ran. Counting 94 here would mean
        // the detector had been moved in front of the buffer and was judging
        // fixes the track never saw.
        expect(streams.otherCount, 93);
        expect(replay.on.rejectedFor(FixRejection.arrivedTooLate), 1);
        expect(
          streams.primaryCount + streams.otherCount,
          912,
          reason: '913 delivered, one never released',
        );
      },
    );
  });

  group('the 4.20 m network fix of 24 Aug', () {
    late TrackProcessor on;
    late TrackProcessor off;

    setUpAll(() {
      final replay = replayBoth('captures/2026-08-24_1610m.ndjson');
      on = replay.on;
      off = replay.off;
    });

    test(
      'is rejected for what it is, and by cold start without the detector',
      () {
        expect(on.rejectedFor(FixRejection.otherStream), 1);
        expect(
          off.rejectedFor(FixRejection.otherStream),
          0,
          reason:
              'the mutation: with the detector off nothing fires this reason',
        );

        // Neither track carries it, and that is not the detector's doing here:
        // it arrived second, so with the detector off cold start still takes it,
        // exactly as the old test recorded. What changes is WHY, and what that
        // costs — off, it eats one of the three cold-start slots, so one fewer
        // GPS fix survives the head of the walk.
        expect(off.pointCount, on.pointCount + 1);
        for (final processor in [on, off]) {
          expect(
            processor.points.any((p) => p.source.timestamp.millisecond != 0),
            isFalse,
          );
        }
      },
    );

    test('mid-track, the detector is the only thing that stops one', () {
      // The 24 Aug fix was stopped by its position in the sequence, so it
      // cannot show what happens to one that arrives at seq 400 — and that is
      // the case the whole mechanism exists for. `walkWithNetworkStream`
      // interleaves its second stream throughout, and 8 of those fixes claim
      // better than the quality bound. With the detector off, 3 of the 8 reach
      // the track in the middle of the walk; the other 5 are stopped further
      // down the chain, which is luck again rather than design.
      final on = replay(walkWithNetworkStream());
      final off = TrackProcessor(detectStreams: false);
      walkWithNetworkStream().fixes.forEach(off.add);
      off.flush();

      expect(on.rejectedFor(FixRejection.otherStream), 8);
      expect(
        on.points.any((p) => p.source.timestamp.millisecond != 0),
        isFalse,
      );
      expect(
        off.points.where((p) => p.source.timestamp.millisecond != 0).length,
        3,
      );
    });

    test('and keeping it off the track is worth 2.3 m on a 1610 m walk', () {
      // The decomposition of 1605.2 -> 1608.5. 1605.2 m is the pre-detector
      // figure recorded in PROGRESS.md under A1c-11; 1606.2 is this build with
      // the detector off, so the 1.0 m between them is cold start moving
      // behind the quality gate, and the 2.3 m above it is the detector.
      expect(off.distanceM, closeTo(1606.2, 0.1));
      expect(on.distanceM, closeTo(1608.5, 0.1));
    });
  });

  group('cold start spends its budget on the stream being kept', () {
    test('24 Aug: all three are GPS fixes inside the quality bound', () {
      final on = replayBoth('captures/2026-08-24_1610m.ndjson').on;
      final coldStarted = [
        for (final rejected in on.rejected)
          if (rejected.reason == FixRejection.coldStart) rejected.fix,
      ];

      expect(coldStarted, hasLength(3));
      for (final fix in coldStarted) {
        expect(
          fix.timestamp.millisecond,
          0,
          reason: 'a network fix is not the receiver settling',
        );
        expect(fix.accuracyM, lessThanOrEqualTo(TrackProcessor().maxAccuracyM));
      }
    });

    test('23 Aug is unchanged end to end, which is the null result', () {
      // Both walks open with network fixes, so this one was expected to move
      // too. It does not: its network fixes are all worse than 9 m, so the
      // quality gate already took them and cold start already landed on GPS.
      // Recorded because "the change reached nothing here" is a measurement.
      final replay = replayBoth('captures/2026-08-23_1610m.ndjson');
      expect(replay.on.distanceM, closeTo(replay.off.distanceM, 0.001));
      expect(replay.on.rejectedFor(FixRejection.otherStream), 0);
    });
  });

  group('what strict-undecided costs', () {
    test('no GPS fix on either capture: the probe closes within 8 fixes', () {
      // The cost of the rule is the fixes refused while the detector is still
      // UNDECIDED, so it is counted directly: replay the same fixes through a
      // bare detector and find where it makes up its mind.
      //
      // It is not zero. 5 fixes on 23 Aug and 3 on 24 Aug are refused before
      // it resolves — and every one of them is fractional, which on these two
      // receivers means network. The probe never cost a GPS fix, which is the
      // claim that matters; it would on a receiver whose own timestamps are
      // fractional, and that is what burstCadenceWalk below prices.
      const resolvedBy = {
        'captures/2026-08-23_1610m.ndjson': (7, 5),
        'captures/2026-08-24_1610m.ndjson': (5, 3),
      };

      for (final path in resolvedBy.keys) {
        final fixes = [
          for (final captured in parseCapture(File(path).readAsStringSync()))
            captured.fix,
        ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        final detector = StreamDetector(
          ceilingM: TrackProcessor().maxAccuracyM,
        );
        final refused = <int>[];
        var resolvedAt = -1;
        for (var i = 0; i < fixes.length; i++) {
          final undecided =
              detector.discriminator == StreamDiscriminator.undecided;
          final admitted = detector.admits(fixes[i]);
          if (undecided) {
            if (!admitted) refused.add(i);
            if (detector.discriminator != StreamDiscriminator.undecided) {
              resolvedAt = i;
            }
          }
        }

        expect(resolvedAt, resolvedBy[path]!.$1, reason: path);
        expect(refused, hasLength(resolvedBy[path]!.$2), reason: path);
        for (final index in refused) {
          expect(
            fixes[index].timestamp.millisecond,
            isNot(0),
            reason: '$path refused a whole-second fix during the probe',
          );
        }
      }
    });

    test('15 fixes and 21 s at the head of a fractional-timestamp fixture', () {
      // The other side of the same rule, and the reason it was a decision
      // rather than an obvious win. This fixture's fixes almost never land on
      // a whole second, so granularity never resolves and the detector refuses
      // them until the 20-fix probe finishes.
      final on = replay(burstCadenceWalk());
      final off = TrackProcessor(detectStreams: false);
      burstCadenceWalk().fixes.forEach(off.add);
      off.flush();

      expect(on.rejectedFor(FixRejection.otherStream), 15);
      expect(off.rejectedFor(FixRejection.otherStream), 0);
      expect(on.pointCount, off.pointCount - 15);

      final hole = on.points[1].timestamp.difference(on.points[0].timestamp);
      expect(hole.inMilliseconds, closeTo(21103, 1));

      // Distance survives it — the step across the hole still measures the
      // walk — and that is what makes the cost affordable. Moving time does
      // not: a 10 s window cannot see across a 21 s gap, so the one step is
      // scored stopped.
      expect(on.distanceM, closeTo(off.distanceM, 1.5));
      expect(off.movingTime.inSeconds - on.movingTime.inSeconds, 22);
    });
  });

  test('the report prints the discriminator and the split', () {
    final text = replayCapture(
      File('captures/2026-08-24_1610m.ndjson').readAsStringSync(),
    ).plainText();

    // Same intent, new layout: the section was renamed and the one-line
    // `kept / other` split became a row per stream carrying its own median
    // accuracy. Nothing about what is asserted here changed.
    expect(text, contains('STREAM DETECTION'));
    expect(text, contains('streams detected  2'));
    expect(text, contains('timestamp granularity'));
    expect(text, contains('819 fixes'));
    expect(text, contains('93 fixes'));
    expect(text, contains('both classes present and distinct'));
  });
}
