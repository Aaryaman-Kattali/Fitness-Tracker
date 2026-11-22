@Tags(['report'])
library;

import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The receiver's own speed field, and the one thing wrong with it.
///
/// `RawFix.speedMps` is Doppler, not differenced positions, and **nothing
/// bounds it**. The recorder rejects the plugin's negative "not available"
/// sentinel and passes everything else through; `run_dao.dart` writes it
/// straight into `run_points.speedMps`. So the column has held values like
/// **39708 m/s — 143,000 km/h** — on fixes whose *positions* are perfectly
/// good, because the implied-speed filter bounds a pair of positions and has
/// never looked at this field.
///
/// Measured 9 Sep 2026 across the six committed captures: Zurich 156 accepted
/// fixes over 50 m/s, the forest walk 340 of 6594 (5.2%), 23 Aug a max of
/// 285 m/s. Harmless to every number the pipeline computes, and not harmless
/// at all to anything that later reads the column — A7, a pace chart, an
/// export — none of which has any way to tell a real 3 m/s from a stored
/// 39708.
///
/// **Nulled, not clamped, and at the pipeline boundary rather than at the
/// DAO.** A clamp writes a wrong number that looks right; null is the honest
/// form of "the receiver said something impossible", and the precedent is
/// `SetLogs.weightKg`, which is null for unloaded work rather than zero. The
/// DAO is the last place this could be caught and therefore the wrong one —
/// every other consumer of a `TrackPoint` would still see the bad value.
void main() {
  /// A whole-second fix walking north at a metre a second.
  ///
  /// Whole-second because `StreamDetector`'s primary discriminator is
  /// timestamp granularity: a fractional timestamp here would be classified
  /// as the other producer and never reach the question being asked.
  RawFix at(int second, {double? speedMps}) => RawFix(
    latitude: 19.2 + second / 111320,
    longitude: 72.97,
    timestamp: DateTime.utc(2026, 9, 9, 12, 0, second),
    accuracyM: 4,
    speedMps: speedMps,
  );

  List<TrackPoint> run(List<RawFix> fixes) {
    final processor = TrackProcessor();
    fixes.forEach(processor.add);
    processor.diagnose();
    return processor.points;
  }

  group('an impossible reported speed', () {
    test('is dropped, while the fix that carried it is kept', () {
      // The two halves that make this a boundary problem rather than a filter
      // problem: the POSITION is fine and belongs on the track, and only the
      // speed field is nonsense. A rule that threw the fix away would lose a
      // good position to a bad annotation.
      final points = run([
        for (var s = 0; s < 8; s++) at(s, speedMps: s == 6 ? 39708.29 : 1),
      ]);

      expect(points, hasLength(5), reason: 'three go to cold start');
      final tainted = points.singleWhere(
        (p) => p.timestamp == DateTime.utc(2026, 9, 9, 12, 0, 6),
      );
      expect(
        tainted.source.speedMps,
        isNull,
        reason:
            'null, not 12: a clamped speed is a wrong number that looks '
            'right, and run_points cannot tell one from the other',
      );
      expect(
        points.where((p) => p.source.speedMps == 1),
        hasLength(4),
        reason: 'a plausible speed is untouched',
      );
    });

    test('is bounded by maxSpeedMps and not by a second constant', () {
      // The bound is the one the kinematic filter already applies to a pair of
      // positions. Two numbers for one physical claim is two sources of truth,
      // and only one of them would get edited.
      final processor = TrackProcessor(maxSpeedMps: 40);
      for (var s = 0; s < 8; s++) {
        processor.add(at(s, speedMps: s == 6 ? 39 : 1));
      }
      processor.diagnose();

      expect(
        processor.points
            .singleWhere(
              (p) => p.timestamp == DateTime.utc(2026, 9, 9, 12, 0, 6),
            )
            .source
            .speedMps,
        39,
        reason: '39 is implausible at the shipped 12 and fine at 40',
      );
    });

    test('covers the negative sentinel too, wherever it comes from', () {
      // The recorder nulls `coords.speed < 0` on the way in, so a live run
      // cannot produce one. A replayed capture can — `parseCapture` reads the
      // field straight out of the file — and "implausible" has to mean the
      // same thing on both paths.
      final points = run([
        for (var s = 0; s < 8; s++) at(s, speedMps: s == 6 ? -1 : 1),
      ]);

      expect(
        points
            .singleWhere(
              (p) => p.timestamp == DateTime.utc(2026, 9, 9, 12, 0, 6),
            )
            .source
            .speedMps,
        isNull,
      );
    });

    test('is counted, so the report does not quietly improve', () {
      // The failure this guards: nulling bad values makes the printed
      // distribution look healthy, which is indistinguishable from a receiver
      // that was healthy. The count is what keeps those apart.
      final processor = TrackProcessor();
      for (var s = 0; s < 8; s++) {
        processor.add(at(s, speedMps: s.isEven ? 39708.29 : 1));
      }
      final report = processor.diagnose();

      expect(report.implausibleReportedSpeeds, 4);
      expect(report.reportedSpeedMps!.max, lessThanOrEqualTo(12));
      expect(report.plainText(), contains('dropped as implausible'));
    });
  });

  test('no committed capture can put an impossible speed on the track', () {
    const captures = <String, String>{
      '23 Aug A32': 'captures/2026-08-23_1610m.ndjson',
      '24 Aug A32': 'captures/2026-08-24_1610m.ndjson',
      '01 Sep S26': 'captures/2026-09-01_1930m.ndjson',
      '07 Sep Zurich': 'captures/2026-09-07_zurich_4310m.ndjson',
      '08 Sep forest': 'captures/run_fixes_20260908-102553.ndjson',
      '08 Sep shop': 'captures/run_fixes_20260908-162309.ndjson',
    };

    final lines = <String>[
      '',
      'REPORTED SPEED, what the boundary drops',
      '',
      'delivered: every fix the pipeline was handed. accepted: the ones that',
      'became run_points rows, which is where the bad values were landing.',
      '',
      'capture           delivered   dropped   accepted   was stored   now stored   max kept',
    ];

    for (final entry in captures.entries) {
      final fixes = parseCapture(File(entry.value).readAsStringSync());
      final processor = TrackProcessor();
      for (final captured in fixes) {
        processor.add(captured.fix);
      }
      final report = processor.diagnose();

      // What the DAO would have written before this change, against what it
      // writes now. The middle column is the one that mattered: a bad speed
      // on a REJECTED fix never reached the database, and a bad speed on an
      // accepted one became a `run_points` row.
      bool isBad(double? speed) => speed != null && (speed < 0 || speed > 12);

      final badBySecond = {
        for (final captured in fixes)
          if (isBad(captured.fix.speedMps)) captured.fix.timestamp,
      };
      final wasStored = processor.points
          .where((p) => badBySecond.contains(p.timestamp))
          .length;
      final bad = fixes.where((c) => isBad(c.fix.speedMps)).length;
      final onTrack = processor.points
          .where((p) => isBad(p.source.speedMps))
          .length;

      lines.add(
        '${entry.key.padRight(15)} '
        '${fixes.length.toString().padLeft(9)} '
        '${bad.toString().padLeft(9)} '
        '${report.accepted.toString().padLeft(10)} '
        '${wasStored.toString().padLeft(11)} '
        '${onTrack.toString().padLeft(12)} '
        '${(report.reportedSpeedMps?.max ?? 0).toStringAsFixed(2).padLeft(10)}',
      );

      expect(
        onTrack,
        0,
        reason: '${entry.key} still puts an impossible speed on the track',
      );
      expect(
        report.implausibleReportedSpeeds,
        bad,
        reason: 'the count has to match what the capture actually holds',
      );
    }

    // Printing IS the deliverable, as in every report harness here.
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
