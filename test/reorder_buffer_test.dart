import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// A fix that arrives late is still a fix.
///
/// The device delivered 119 arrivals out of sequence and the pipeline threw 106
/// of them away, because its only defence against a clock that goes backwards
/// is to refuse the fix. That is the correct handling for a stream nobody can
/// reorder, and the wrong handling for one that can: three seconds of patience
/// turns a discarded fix into a used one.
///
/// The fixture holds one in five fixes back by 2.5 s and four of them by 5 s,
/// on the same walk over the same 1000 m. Only the delivery order changes, so
/// anything that moves is caused by the ordering and by nothing else.
void main() {
  group('the fixture delivers what it claims', () {
    test('the same fixes, the same ground, a different order', () {
      final ordered = measuredVariableCadenceWalk();
      final shuffled = shuffledArrivalWalk();

      expect(shuffled.fixes, hasLength(ordered.fixes.length));
      expect(
        shuffled.groundTruthDistanceM,
        ordered.groundTruthDistanceM,
        reason: 'reordering delivery cannot change how far someone walked',
      );
      expect(
        shuffled.fixes.map((fix) => fix.timestamp).toSet(),
        ordered.fixes.map((fix) => fix.timestamp).toSet(),
        reason: 'no fix invented, none lost, only the order changed',
      );
      expect(
        shuffled.fixes.map((fix) => fix.timestamp).toList(),
        isNot(ordered.fixes.map((fix) => fix.timestamp).toList()),
      );
    });

    test('the disorder is real and bounded', () {
      final fixes = shuffledArrivalWalk().fixes;

      var backwards = 0;
      var worstLagSeconds = 0.0;
      var newest = fixes.first.timestamp;
      for (final fix in fixes) {
        final lag = newest.difference(fix.timestamp).inMilliseconds / 1000;
        if (lag > 0) backwards++;
        if (lag > worstLagSeconds) worstLagSeconds = lag;
        if (fix.timestamp.isAfter(newest)) newest = fix.timestamp;
      }

      expect(
        backwards,
        greaterThan(50),
        reason: 'a handful of inversions would not be a measurement',
      );
      expect(
        worstLagSeconds,
        greaterThan(lateArrivalSeconds),
        reason: 'the hopeless fixes have to actually be hopeless',
      );
    });
  });

  group('a buffered pipeline recovers the late fixes', () {
    test('out-of-order delivery costs the distance nothing', () {
      // THE TEST. Same walk, same 1000 m, delivered in a mess.
      //
      // 2.5% is the operating point's own budget, not a concession to the
      // shuffling: the ordered fixture reads +1.25% under the measured error
      // model, so anything tighter here would be failing the reorder buffer
      // for the error model's lean. The test that isolates the shuffling is
      // the next one, which compares the two deliveries against each other
      // rather than against the truth.
      final processor = replay(shuffledArrivalWalk());
      expect(processor.distanceM, closeTo(1000, 25));
    });

    test('it lands where the same walk delivered in order lands', () {
      // Tighter, and the one that says the buffer actually reconstructs the
      // sequence rather than merely surviving it. Four fixes are beyond the
      // horizon and genuinely lost, so the two totals differ by those and by
      // nothing else.
      final ordered = replay(measuredVariableCadenceWalk()).distanceM;
      final shuffled = replay(shuffledArrivalWalk()).distanceM;

      expect(
        shuffled,
        closeTo(ordered, 5),
        reason:
            'in-order ${ordered.toStringAsFixed(2)} m against out-of-order '
            '${shuffled.toStringAsFixed(2)} m',
      );
    });

    test('almost every late fix is recovered, and the rest are counted', () {
      final report = replay(shuffledArrivalWalk()).diagnose();

      expect(
        report.outOfOrderArrivals,
        greaterThan(50),
        reason: 'the arrivals were still out of order; that is not in dispute',
      );
      expect(
        report.rejections![FixRejection.arrivedTooLate],
        hopelessLateFixes,
        reason: 'exactly the fixes the fixture held past the horizon',
      );
      expect(
        report.rejections![FixRejection.outOfOrder] ?? 0,
        0,
        reason:
            'nothing should reach the clock test out of order any more; if '
            'this fires the buffer released something early',
      );
      // The 15 are the stream detector's undecided probe, not the buffer.
      // This fixture's timestamps are fractional almost everywhere, so the
      // detector cannot use granularity and refuses fractional fixes until
      // its 20-fix probe resolves the receiver as a single stream. On both
      // ground-truth walks that costs nothing; here it is 15 of 410, 3.7%,
      // and it is the price of not letting a network fix reach the track
      // ahead of the first GPS fix. Named rather than folded into the
      // arithmetic so it cannot grow unnoticed.
      const undecidedProbeCost = 15;
      expect(
        report.accepted,
        shuffledArrivalWalk().fixes.length -
            hopelessLateFixes -
            undecidedProbeCost -
            TrackProcessor().coldStartFixes,
        reason: 'everything else got through',
      );
    });

    test('the accepted track comes out in timestamp order', () {
      // The property everything downstream assumes. Splits walk the points
      // forward, pace differences two of them, and the map draws a line
      // through them in order; a track that goes backwards anywhere breaks all
      // three quietly rather than loudly.
      final points = replay(shuffledArrivalWalk()).points;
      for (var i = 1; i < points.length; i++) {
        expect(
          points[i].timestamp.isAfter(points[i - 1].timestamp),
          isTrue,
          reason: 'point $i does not advance the clock',
        );
      }
    });
  });

  group('the buffer is what does it', () {
    test('with the horizon at zero, the late fixes are thrown away', () {
      // MUTATION, in the test rather than in the source. A horizon of zero is
      // the pipeline as it was before the buffer existed: every fix processed
      // on arrival, every late one refused by the clock test.
      final unbuffered = replay(
        shuffledArrivalWalk(),
        into: TrackProcessor(bufferHorizon: Duration.zero),
      );
      final buffered = replay(shuffledArrivalWalk());

      expect(
        unbuffered.diagnose().rejections![FixRejection.outOfOrder] ?? 0,
        greaterThan(50),
        reason: 'without the buffer the late fixes are simply discarded',
      );
      expect(
        buffered.points.length - unbuffered.points.length,
        greaterThan(50),
        reason: 'and with it they are on the track instead',
      );
    });

    test('THE FINDING: recovering them barely moves the distance', () {
      // This test asserts a negative result, and it is here because the
      // negative result is the whole point of having measured.
      //
      // The reorder buffer was expected to be the primary fix for a recorded
      // walk that read 1.94 km against a true 1.74 km. It is not. Discarding a
      // late fix does not add a step; it makes the next accepted step longer
      // over a proportionally longer dt, and the smoother reconstructs almost
      // the same path from what is left. Measured on this fixture: 67 of 417
      // fixes discarded, and the total moves by about a third of a metre.
      //
      // The buffer is worth having anyway — a sixth of the evidence recovered
      // is better splits, a better map and a better stop detector — but it is
      // a data-recovery improvement, not a distance fix, and calling it one
      // would send the next person looking in the wrong place.
      //
      // If this test ever starts failing, out-of-order arrival has become a
      // distance problem and the reasoning above needs redoing.
      final unbuffered = replay(
        shuffledArrivalWalk(),
        into: TrackProcessor(bufferHorizon: Duration.zero),
      ).distanceM;
      final buffered = replay(shuffledArrivalWalk()).distanceM;

      expect(
        (buffered - unbuffered).abs(),
        lessThan(5),
        reason:
            'unbuffered ${unbuffered.toStringAsFixed(2)} m against buffered '
            '${buffered.toStringAsFixed(2)} m, over a true 1000',
      );
      expect(unbuffered, closeTo(1000, 25));
    });

    test('on an in-order track the buffer changes nothing at all', () {
      // The other half, and the one that protects every existing baseline.
      // Holding a fix for three seconds and then processing it must produce
      // the same track as processing it immediately, to the last bit.
      for (final track in [
        measuredVariableCadenceWalk(),
        measuredWalkKm(),
        fiveAndAHalfKm(),
      ]) {
        final buffered = replay(track);
        final immediate = replay(
          track,
          into: TrackProcessor(bufferHorizon: Duration.zero),
        );

        expect(
          buffered.distanceM,
          immediate.distanceM,
          reason: '${track.name}: the buffer moved an in-order track',
        );
        expect(buffered.points.length, immediate.points.length);
      }
    });

    test('a flush releases what the horizon is still holding', () {
      // Without it the last few seconds of every run are silently dropped —
      // which on a 20-minute walk is 5 m, small enough to be mistaken for
      // rounding and permanent.
      final track = measuredVariableCadenceWalk();

      final unflushed = TrackProcessor();
      track.fixes.forEach(unflushed.add);
      final held = unflushed.points.length;

      unflushed.flush();

      expect(
        unflushed.points.length,
        greaterThan(held),
        reason: 'the buffer was holding fixes that flush has to release',
      );
      expect(
        unflushed.points.last.timestamp,
        track.fixes.last.timestamp,
        reason: 'the last fix of the run must reach the track',
      );
    });

    test('flushing twice is not a second run', () {
      final processor = replay(measuredVariableCadenceWalk());
      final distance = processor.distanceM;
      final points = processor.points.length;

      processor.flush();

      expect(processor.distanceM, distance);
      expect(processor.points.length, points);
    });

    test('the buffer is bounded even if the clock never advances', () {
      // A receiver stuck on one timestamp never satisfies the release rule, so
      // without a cap the buffer would grow for the length of the run. The cap
      // releases the oldest instead, which is the same thing the horizon would
      // have done had the clock been moving.
      final processor = TrackProcessor();
      final stuck = shuffledArrivalWalk().fixes.first;
      for (var i = 0; i < 500; i++) {
        processor.add(stuck);
      }

      final report = processor.diagnose();
      expect(
        report.reachedPipeline,
        500,
        reason: 'every fix is still counted as delivered',
      );
      expect(
        report.accepted + report.rejections!.values.fold(0, (a, b) => a + b),
        500,
        reason: 'and every one is accounted for rather than stuck in a buffer',
      );
    });
  });
}
