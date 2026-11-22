import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/stream_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// Separating the receiver's stream from the other one, without needing a gap
/// in reported accuracy to exist.
///
/// The oracle is both ground-truth captures, because between them they contain
/// the case the old threshold handled and the case that broke it. Every
/// synthetic fixture below covers something the captures do not.
void main() {
  List<RawFix> capture(String path) => [
    for (final captured in parseCapture(File(path).readAsStringSync()))
      captured.fix,
  ];

  final firstWalk = capture('captures/2026-08-23_1610m.ndjson');
  final secondWalk = capture('captures/2026-08-24_1610m.ndjson');

  ({int admitted, int rejected, StreamReport report}) run(List<RawFix> fixes) {
    final detector = StreamDetector();
    var admitted = 0;
    for (final fix in fixes) {
      if (detector.admits(fix)) admitted++;
    }
    return (
      admitted: admitted,
      rejected: fixes.length - admitted,
      report: detector.report(),
    );
  }

  group('against the walk with a clean accuracy gap (23 Aug)', () {
    test('reproduces the 1051 / 154 split', () {
      final result = run(firstWalk);

      expect(result.admitted, 1051);
      expect(result.rejected, 154);
      expect(result.report.discriminator, StreamDiscriminator.granularity);
    });
  });

  group('against the walk where the accuracy gap CROSSED (24 Aug)', () {
    test('reproduces the 819 / 94 split anyway', () {
      // The whole point. Reported accuracy cannot separate these — worst GPS
      // 5.00 m, best network 4.20 m — and granularity does it exactly.
      final result = run(secondWalk);

      expect(result.admitted, 819);
      expect(result.rejected, 94);
      expect(result.report.discriminator, StreamDiscriminator.granularity);
    });

    test('rejects the 4.20 m network fix on its own merits', () {
      // Previously this survived the accuracy threshold and was removed by the
      // cold-start rule, which is a filter that had no opinion about it and
      // happened to fire. Now it is rejected for what it is, wherever it lands.
      final detector = StreamDetector();
      final offender = secondWalk.firstWhere(
        (fix) => fix.timestamp.millisecond != 0 && fix.accuracyM < 5,
      );

      // Feed the run with the offending fix moved deep into the sequence,
      // where cold start cannot reach it.
      final reordered = [
        ...secondWalk.where((fix) => !identical(fix, offender)).take(400),
        offender,
      ];
      var admittedOffender = false;
      for (final fix in reordered) {
        final admitted = detector.admits(fix);
        if (identical(fix, offender)) admittedOffender = admitted;
      }

      expect(offender.accuracyM, closeTo(4.20, 0.01));
      expect(
        admittedOffender,
        isFalse,
        reason:
            'at seq 400 the cold-start rule is long past; only stream '
            'detection can stop this fix, and it must',
      );
    });

    test('AN ACCURACY THRESHOLD ALONE FAILS THIS WALK', () {
      // The mutation, kept as a test rather than run by hand, because it is
      // the entire justification for the class above. If this ever stops
      // failing, the 24 Aug capture has stopped being a case that
      // distinguishes the two approaches and the fixture is decoration.
      //
      // The old rule, exactly: reject accuracy > 9, and nothing else.
      const oldThresholdM = 9.0;

      final offender = secondWalk.firstWhere(
        (fix) => fix.timestamp.millisecond != 0 && fix.accuracyM < 5,
      );
      expect(
        offender.accuracyM <= oldThresholdM,
        isTrue,
        reason: 'a network fix the old threshold would have admitted',
      );

      final admittedByOldRule = [
        for (final fix in secondWalk)
          if (fix.accuracyM <= oldThresholdM) fix,
      ];
      final networkAdmitted = admittedByOldRule
          .where((fix) => fix.timestamp.millisecond != 0)
          .length;

      expect(
        networkAdmitted,
        1,
        reason: 'the old rule lets a network fix through on this walk',
      );

      // And the detector does not.
      final detector = StreamDetector();
      var networkAdmittedNow = 0;
      for (final fix in secondWalk) {
        if (detector.admits(fix) && fix.timestamp.millisecond != 0) {
          networkAdmittedNow++;
        }
      }
      expect(networkAdmittedNow, 0);
    });

    test('never admits a fractional fix before granularity settles', () {
      // The claim that matters, and it is not "granularity settles quickly".
      // It does not: both walks open with a run of fixes from the other
      // stream — five on 23 Aug, two on 24 Aug — so the detector is still
      // undecided when they arrive. What protects the track is that the
      // undecided state already refuses fractional timestamps, not that it
      // resolves before any arrive. Measured first, then asserted; the
      // original version of this test asserted the opposite and was wrong.
      for (final walk in [firstWalk, secondWalk]) {
        final detector = StreamDetector();
        for (final fix in walk) {
          final admitted = detector.admits(fix);
          if (fix.timestamp.millisecond != 0) {
            expect(
              admitted,
              isFalse,
              reason:
                  'a fractional fix got in while the detector was still '
                  '${detector.discriminator}',
            );
          }
        }
      }
    });

    test('costs no GPS fix while undecided', () {
      // The other half of that asymmetry. Dropping whole-second fixes during
      // the probe would cost a single-stream receiver its first minute.
      final detector = StreamDetector();
      var admitted = 0;
      for (final fix in secondWalk) {
        if (detector.admits(fix)) admitted++;
      }
      expect(admitted, 819);
    });
  });

  group('a receiver delivering one stream', () {
    // Not a failure to detect anything. A phone with no network positioning
    // active must not have a second stream invented so there is something to
    // reject.
    List<RawFix> gpsOnly(List<RawFix> walk) => [
      for (final fix in walk)
        if (fix.timestamp.millisecond == 0) fix,
    ];

    test('admits all of it and says singleStream', () {
      final result = run(gpsOnly(secondWalk));

      expect(result.admitted, 819);
      expect(result.rejected, 0);
      expect(result.report.discriminator, StreamDiscriminator.singleStream);
      expect(result.report.granularityAvailable, isFalse);
      expect(result.report.cutM, isNull);
    });

    test('the first walk too, whose accuracies are wider', () {
      // 2.0 to 8.10 m. A gap-finder tuned too eagerly would split this into
      // "good GPS" and "bad GPS" and throw away a third of a real walk.
      final result = run(gpsOnly(firstWalk));

      expect(result.admitted, 1051);
      expect(result.report.discriminator, StreamDiscriminator.singleStream);
    });
  });

  group('the fallback, for a receiver that rounds its timestamps', () {
    /// Both captures' fixes with every timestamp forced onto a whole second —
    /// exactly what happens if `tracelet` ever normalises them. The primary
    /// discriminator is then blind, and only the accuracy distribution is
    /// left.
    List<RawFix> rounded(List<RawFix> walk) => [
      for (final fix in walk)
        RawFix(
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracyM: fix.accuracyM,
          altitudeM: fix.altitudeM,
          speedMps: fix.speedMps,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (fix.timestamp.millisecondsSinceEpoch ~/ 1000) * 1000,
            isUtc: true,
          ),
        ),
    ];

    test('finds the gap on the 23 Aug walk, where one exists', () {
      final result = run(rounded(firstWalk));

      expect(result.report.granularityAvailable, isFalse);
      expect(result.report.discriminator, StreamDiscriminator.accuracyGap);
      expect(
        result.report.cutM,
        inInclusiveRange(8.10, 9.60),
        reason: 'the cut belongs in the measured gap, not at a chosen number',
      );
    });

    test('degrades honestly on the 24 Aug walk, where none exists', () {
      // This is the case with no good answer, and the honest outcome is a
      // worse split rather than a confident wrong one. Recorded so nobody
      // reads the fallback as equivalent to the primary.
      final result = run(rounded(secondWalk));

      expect(result.report.granularityAvailable, isFalse);
      expect(
        result.admitted,
        greaterThan(819),
        reason:
            'with granularity gone and the accuracy ranges crossed, some '
            'network fixes get through. That is the cost of the dependency '
            'breaking, and it is why granularity is primary.',
      );
    });
  });

  group('the gap finder itself', () {
    test('finds nothing in a single tight cluster', () {
      final tight = [for (var i = 0; i < 100; i++) 2.0 + (i % 7) * 0.1];
      expect(findAccuracyGap(tight), isNull);
    });

    test('finds nothing in a smooth spread', () {
      // Continuous, no gap. A finder that returns the largest spacing without
      // a ratio test would split this in half.
      final spread = [for (var i = 0; i < 100; i++) 2.0 + i * 0.5];
      expect(findAccuracyGap(spread), isNull);
    });

    test('finds a real split', () {
      final two = [
        for (var i = 0; i < 60; i++) 2.0 + (i % 5) * 0.2,
        for (var i = 0; i < 40; i++) 25.0 + (i % 5) * 0.5,
      ];
      expect(findAccuracyGap(two), inInclusiveRange(2.8, 25.0));
    });

    test('ignores a gap that only a handful of samples sit beyond', () {
      // Three outliers are not a second stream. Without the mode-share test
      // this splits off the tail and calls it one.
      final tailed = [
        for (var i = 0; i < 100; i++) 2.0 + (i % 5) * 0.2,
        60.0,
        61.0,
        62.0,
      ];
      expect(findAccuracyGap(tailed), isNull);
    });

    test('refuses to answer on too few samples', () {
      expect(findAccuracyGap([2, 2.1, 30, 31]), isNull);
    });

    test('survives every value being identical', () {
      // Typical spacing is zero, so a ratio test against it admits anything.
      expect(findAccuracyGap([for (var i = 0; i < 50; i++) 3.0]), isNull);
    });
  });
}
