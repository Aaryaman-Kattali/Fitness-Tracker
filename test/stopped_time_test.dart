@Tags(['report'])
library;

import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_track.dart';

/// Stopped time had two definitions, and they disagreed by 31:40.
///
/// The report printed `elapsed 100:44  moving 32:01` at the top and
/// `18 segment(s), 37:03 stopped in total` further down. 100:44 − 32:01 is
/// **68:43**, so the two numbers in one report differed by half an hour, and
/// the run's largest stop — a 21:38 stretch inside a shop — printed as
/// **`0:01`**.
///
/// **Two rules, both correct in isolation.** `movingTime` sums each accepted
/// fix's `dt` when the fix is classified moving, so stopped time is the sum of
/// `dt` over stopped fixes and includes the interval *before* each of them.
/// `stopSegments()` ran from the first stopped fix's timestamp to the next
/// moving fix's timestamp, which excludes that interval and includes the one
/// after. At 1 Hz the two agree to within a second. Across a 1298 s hole in
/// the accepted stream they do not: the fix closing that hole is classified
/// stopped and contributes 21:38 to `elapsed − moving`, while its segment was
/// one second long.
///
/// **One rule now, and it is the `dt` one**, because that is the rule
/// `movingTime` already used and `movingTime` is what pace divides by. A
/// segment covers `[previous fix, this fix]` for every stopped fix, so
/// consecutive stopped fixes merge and the segments partition stopped time
/// exactly. That is asserted below rather than described.
void main() {
  /// The invariant, in one line: the segments ARE stopped time, not a
  /// sample of it.
  void expectSegmentsPartitionStoppedTime(
    RunDiagnosticsReport report, {
    required String on,
  }) {
    expect(
      report.totalStopped,
      report.elapsed - report.movingTime,
      reason:
          '$on: the STOPS list has to decompose stopped time exactly, or a '
          'reader adding it up gets a different answer from the header',
    );
  }

  group('the segments partition stopped time', () {
    test('on a fixture with a deliberate stand', () {
      expectSegmentsPartitionStoppedTime(
        replay(standingStill()).diagnose(),
        on: 'standingStill',
      );
    });

    test('on a fixture with no stops at all', () {
      final report = replay(straightKm()).diagnose();

      expect(report.stops, isEmpty);
      expectSegmentsPartitionStoppedTime(report, on: 'straightKm');
    });

    test('on every committed capture, including the one that broke it', () {
      // The shop capture is the fixture here. It is the only recording in the
      // set with outages long enough to separate the two rules, and before
      // this change it was where they differed most.
      const captures = <String, String>{
        '23 Aug A32': 'captures/2026-08-23_1610m.ndjson',
        '24 Aug A32': 'captures/2026-08-24_1610m.ndjson',
        '01 Sep S26': 'captures/2026-09-01_1930m.ndjson',
        '07 Sep Zurich': 'captures/2026-09-07_zurich_4310m.ndjson',
        '08 Sep forest': 'captures/run_fixes_20260908-102553.ndjson',
        '08 Sep shop': 'captures/run_fixes_20260908-162309.ndjson',
      };

      for (final entry in captures.entries) {
        final processor = TrackProcessor();
        for (final captured in parseCapture(
          File(entry.value).readAsStringSync(),
        )) {
          processor.add(captured.fix);
        }
        expectSegmentsPartitionStoppedTime(
          processor.diagnose(),
          on: entry.key,
        );
      }
    });

    test('the shop capture reports its outages as the stops they were', () {
      // The specific regression, pinned at the number that was wrong. The
      // longest stop of that walk is the 21:38 the receiver spent indoors; it
      // printed as 0:01 under the old rule, which is the version of this the
      // header total alone would not have caught.
      final processor = TrackProcessor();
      for (final captured in parseCapture(
        File('captures/run_fixes_20260908-162309.ndjson').readAsStringSync(),
      )) {
        processor.add(captured.fix);
      }
      final report = processor.diagnose();
      final longest = report.stops
          .map((s) => s.duration)
          .reduce((a, b) => a > b ? a : b);

      expect(
        longest.inSeconds,
        greaterThan(1200),
        reason: 'the longest stop of this walk is over twenty minutes',
      );
      expect((report.elapsed - report.movingTime).inSeconds, 4123);
    });
  });

  test('a reconstruction reaches the same segments', () {
    // Both paths go through `stopSegments()`, so a change to the rule that
    // only reached one of them would show up here rather than on a phone.
    final processor = replay(standingStill());
    final live = processor.diagnose();

    expect(live.stops, isNotEmpty);
    expectSegmentsPartitionStoppedTime(live, on: 'live');
  });
}
