import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two-point initialisation, and what it does when the two points are
/// milliseconds apart.
///
/// The mechanism, stated precisely, because the first diagnosis was wrong.
///
/// It is NOT the velocity state being corrupted. `_Axis.fromPair` does set the
/// opening speed to `displacement / dt`, which is equally unbounded, but
/// neutralising that alone changed nothing measurable on any fixture in this
/// suite — so it was a guess, and it was reverted.
///
/// What actually produces the number is simpler. At initialisation the pair's
/// position estimate IS the raw measurement, because there is nothing yet to
/// smooth it against. So the first step of the track is the raw displacement
/// between two measurements, and over a sub-second interval that displacement
/// is measurement noise. 0.9 m of noise over 30 ms reads as 30 m/s. The
/// distance it adds is 0.9 m and is negligible; what it corrupts is every
/// speed derived from that step.
///
/// On the A32 the GPS stream arrives on exact whole seconds, so the first two
/// accepted fixes are a second apart and this never fires. It is reachable the
/// moment anything changes WHICH fixes are the first two accepted — a
/// different cold-start rule, a rejection, a receiver that does not tick on
/// the second.
void main() {
  const originLat = 19.2183;
  const originLon = 72.9781;
  const metresPerDegreeLat = 111320.0;

  final start = DateTime.utc(2026, 8, 24, 10);

  RawFix fixAt({
    required double northM,
    required Duration after,
    double accuracyM = 2.5,
  }) => RawFix(
    latitude: originLat + northM / metresPerDegreeLat,
    longitude: originLon,
    timestamp: start.add(after),
    accuracyM: accuracyM,
  );

  /// A walk whose first two ACCEPTED fixes are [pairGapMs] apart, and which
  /// then proceeds at a steady 1.6 m/s at 1 Hz.
  ///
  /// The three cold-start fixes are there so the pair under test is the first
  /// pair the smoother actually sees, which is the real arrangement rather
  /// than a contrived one.
  List<RawFix> walkOpeningWith({required int pairGapMs}) {
    return <RawFix>[
      // Cold start eats these three, so the pair below is the first pair the
      // smoother actually sees — the real arrangement, not a contrived one.
      for (var i = 0; i < 3; i++)
        fixAt(northM: 0, after: Duration(milliseconds: i * 1000)),

      // The pair. Their true displacement is zero — a standing start — so the
      // 0.9 m between them is measurement noise and nothing else.
      fixAt(northM: 0, after: const Duration(milliseconds: 3000)),
      fixAt(northM: 0.9, after: Duration(milliseconds: 3000 + pairGapMs)),

      // Then a steady 1.6 m/s at 1 Hz.
      for (var i = 1; i <= 30; i++)
        fixAt(
          northM: 0.9 + 1.6 * i,
          after: Duration(milliseconds: 3000 + pairGapMs + i * 1000),
        ),
    ];
  }

  double maxSmoothedSpeed(List<RawFix> fixes) {
    final processor = TrackProcessor();
    fixes.forEach(processor.add);
    processor.flush();

    var fastest = 0.0;
    final points = processor.points;
    for (var i = 1; i < points.length; i++) {
      final dt =
          points[i].timestamp
              .difference(points[i - 1].timestamp)
              .inMicroseconds /
          1e6;
      final step =
          points[i].cumulativeDistanceM - points[i - 1].cumulativeDistanceM;
      if (dt > 0) fastest = fastest > step / dt ? fastest : step / dt;
    }
    return fastest;
  }

  test('a one-second opening pair behaves, which is the control', () {
    // Without this the test below proves only that the fixture is odd, not
    // that the interval is what breaks it.
    expect(maxSmoothedSpeed(walkOpeningWith(pairGapMs: 1000)), lessThan(4));
  });

  test('a 30 ms opening pair does NOT invent a sprint', () {
    // 0.9 m of noise over 0.03 s is 30 m/s if you divide one by the other.
    // Nothing in this walk moves faster than 1.6 m/s and the pair's true
    // displacement is zero.
    //
    // The bound is maxSpeedMps, because that is the pipeline's own statement
    // of what a person can do, and a smoothed track exceeding it is the filter
    // reporting something it has already ruled impossible for raw fixes.
    final fastest = maxSmoothedSpeed(walkOpeningWith(pairGapMs: 30));

    expect(
      fastest,
      lessThan(TrackProcessor().maxSpeedMps),
      reason:
          'smoothed speed reached ${fastest.toStringAsFixed(1)} m/s on a '
          '1.6 m/s walk whose opening pair did not move at all',
    );
  });

  test('never fires on either ground-truth walk', () {
    // The scope of the bug, asserted rather than argued. Both captures'
    // GPS streams arrive on exact whole seconds, so the opening pair is a
    // second apart and its error bar is ~3.5 m/s — comfortably inside
    // maxSpeedMps. Neither walk's numbers are affected by this fix.
    //
    // Which also says what would change that: a receiver that does not tick
    // on the second, or anything that alters which fixes are accepted first.
    for (final path in [
      'captures/2026-08-23_1610m.ndjson',
      'captures/2026-08-24_1610m.ndjson',
    ]) {
      final processor = TrackProcessor();
      replayCapture(File(path).readAsStringSync(), into: processor);

      expect(
        processor.rejected.where(
          (r) => r.reason == FixRejection.tooSoonToPair,
        ),
        isEmpty,
        reason: '$path should be untouched by this guard',
      );
    }
  });

  test('and the shorter the gap, the worse it was', () {
    // The signature of a division by dt rather than of anything physical: the
    // fault scales as 1/dt. Recorded so a fix that merely clamps the symptom
    // at one interval is visibly not enough.
    final gaps = [500, 100, 30, 10];
    final speeds = [
      for (final gap in gaps) maxSmoothedSpeed(walkOpeningWith(pairGapMs: gap)),
    ];

    for (final speed in speeds) {
      expect(
        speed,
        lessThan(TrackProcessor().maxSpeedMps),
        reason:
            'speeds by gap ${gaps.join("/")} ms: '
            '${speeds.map((s) => s.toStringAsFixed(1)).join(", ")}',
      );
    }
  });
}
