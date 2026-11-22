@Tags(['report', 'no-oracle'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two questions the Zurich forest walk raised, asked of every capture at once.
///
/// **A reporting harness, not a budget**, same contract as
/// `capture_distance_report_test.dart`: it asserts only that each capture still
/// replays, and prints numbers for a person to read. Both questions came from a
/// single walk, and a threshold moved on a single walk is a threshold fitted to
/// one afternoon's weather.
///
///   1. `minMovingSpeedMps` — the forest walk's median smoothed speed was
///      0.88 m/s against a 0.5 m/s stop threshold, 1.76x, where a street walk
///      gives ~3x. Is the threshold wrong, or is this walk simply slow?
///   2. `bufferHorizon` — 172 fixes were rejected `arrivedTooLate`, the first
///      capture where that count is not zero. How late did they actually
///      arrive, and what horizon would have caught them?
void main() {
  const captures = <String, String>{
    '23 Aug A32 1610 m': 'captures/2026-08-23_1610m.ndjson',
    '24 Aug A32 1610 m': 'captures/2026-08-24_1610m.ndjson',
    '01 Sep S26 1930 m': 'captures/2026-09-01_1930m.ndjson',
    '07 Sep Zurich 4310 m': 'captures/2026-09-07_zurich_4310m.ndjson',
    '08 Sep forest 4532 m': 'captures/run_fixes_20260908-102553.ndjson',
    '08 Sep shop, indoors': 'captures/run_fixes_20260908-162309.ndjson',
  };

  /// Strava's moving time on the same walk, where there is one.
  ///
  /// Three of the six. The A32 pair and the first S26 walk were recorded
  /// without a Strava activity beside them, and a moving time cannot be
  /// recovered from a distance — so the pace-relative comparison below has
  /// three anchors, not six, and that is a limit of the evidence rather than
  /// an omission. Sources: NOTES.md "Elapsed and moving, against Strava on
  /// the same walk" (Zurich), "the stop threshold is not wrong" (forest), and
  /// the 8 Sep shop walk, where ours ran 5:45 long.
  const stravaMoving = <String, Duration>{
    '07 Sep Zurich 4310 m': Duration(minutes: 30, seconds: 14),
    '08 Sep forest 4532 m': Duration(minutes: 53, seconds: 29),
    '08 Sep shop, indoors': Duration(minutes: 26, seconds: 16),
  };

  final delivered = {
    for (final entry in captures.entries)
      entry.key: parseCapture(File(entry.value).readAsStringSync()),
  };

  test('stop threshold: where each walk sits relative to 0.5 m/s', () {
    final endSeparation = <String, double>{};
    final lines = <String>[
      '',
      'STOP THRESHOLD, shipped minMovingSpeedMps = 0.5 over a 10 s window',
      '',
      'capture                med spd   ratio     p10     p90    elapsed   moving  stopped  segs',
    ];

    for (final entry in delivered.entries) {
      // The tape is on because this block reads the RTS track's endpoints to
      // decide which captures can serve as the coincident-marker fixture.
      final processor = TrackProcessor(recordFilterStates: true);
      for (final captured in entry.value) {
        processor.add(captured.fix);
      }
      final report = processor.diagnose();
      final speed = report.acceptedSpeedMps!;
      final stopped = report.elapsed - report.movingTime;

      lines.add(
        '${entry.key.padRight(21)} '
        '${speed.median.toStringAsFixed(2).padLeft(7)} '
        '${'${(speed.median / 0.5).toStringAsFixed(2)}x'.padLeft(7)} '
        '${speed.p10.toStringAsFixed(2).padLeft(7)} '
        '${speed.p90.toStringAsFixed(2).padLeft(7)} '
        '${_hms(report.elapsed).padLeft(10)} '
        '${_hms(report.movingTime).padLeft(8)} '
        '${_hms(stopped).padLeft(8)} '
        '${report.stops.length.toString().padLeft(5)}',
      );

      expect(report.smoothedDistanceM, greaterThan(0));

      // Printed here because it decides which captures can serve as the
      // fixture for the coincident start/finish marker, and the answer is not
      // guessable from the route name.
      final track = processor.smoothedTrack().points;
      endSeparation[entry.key] = haversineMetres(
        track.first.latitude,
        track.first.longitude,
        track.last.latitude,
        track.last.longitude,
      );
    }

    lines
      ..add('')
      ..add('START TO FINISH, straight line (m). Under 15 m is a loop for')
      ..add('marker purposes — see AppSpacing.runMarkerCoincidentM.')
      ..add('');
    for (final entry in endSeparation.entries) {
      lines.add(
        '${entry.key.padRight(21)} ${entry.value.toStringAsFixed(1).padLeft(9)}',
      );
    }

    lines
      ..add('')
      ..add('SENSITIVITY: stopped time at other thresholds (m/s)')
      ..add('')
      ..add(
        'capture               ${[
          for (final t in _thresholds) t.toStringAsFixed(2).padLeft(9),
        ].join()}',
      );

    for (final entry in delivered.entries) {
      final cells = <String>[];
      for (final threshold in _thresholds) {
        final processor = TrackProcessor(minMovingSpeedMps: threshold);
        for (final captured in entry.value) {
          processor.add(captured.fix);
        }
        final report = processor.diagnose();
        cells.add(_hms(report.elapsed - report.movingTime).padLeft(9));
      }
      lines.add('${entry.key.padRight(21)} ${cells.join()}');
    }

    // Printing IS the deliverable: there is no assertion that could stand in
    // for reading these side by side.
    // ignore: avoid_print
    print(lines.join('\n'));
  });

  test('buffer horizon: how late the late fixes were', () {
    final lateAccuracy = <String, List<double>>{};
    final lines = <String>[
      '',
      'ARRIVAL LAG, shipped bufferHorizon = 3 s',
      '',
      'Lag is how far behind the newest timestamp already seen a fix arrived.',
      '"late" counts lag > 0; "lost" are the fixes rejected arrivedTooLate at',
      'the shipped 3 s horizon, measured by the same lag.',
      '',
      'capture                fix/s     late      p50     p90     p99     max     lost  lost p50  lost p90  lost max',
    ];

    for (final entry in delivered.entries) {
      final lags = <double>[];
      final lagOf = <RawFix, double>{};
      DateTime? newest;
      for (final captured in entry.value) {
        final fix = captured.fix;
        if (newest != null) {
          final lag = newest.difference(fix.timestamp).inMicroseconds / 1e6;
          if (lag > 0) lags.add(lag);
          lagOf[fix] = lag;
        }
        if (newest == null || fix.timestamp.isAfter(newest)) {
          newest = fix.timestamp;
        }
      }

      final processor = TrackProcessor();
      for (final captured in entry.value) {
        processor.add(captured.fix);
      }
      final report = processor.diagnose();
      final late = [
        for (final rejected in processor.rejected)
          if (rejected.reason == FixRejection.arrivedTooLate) rejected.fix,
      ];
      final lost = [for (final fix in late) lagOf[fix] ?? 0.0]..sort();
      final lostAccuracy = [for (final fix in late) fix.accuracyM]..sort();
      lags.sort();
      if (late.isNotEmpty) {
        lateAccuracy[entry.key] = lostAccuracy;
      }

      final seconds = report.elapsed.inMicroseconds / 1e6;
      lines.add(
        '${entry.key.padRight(21)} '
        '${(entry.value.length / seconds).toStringAsFixed(2).padLeft(5)} '
        '${lags.length.toString().padLeft(8)} '
        '${_p(lags, 0.50).padLeft(8)} '
        '${_p(lags, 0.90).padLeft(7)} '
        '${_p(lags, 0.99).padLeft(7)} '
        '${_p(lags, 1).padLeft(7)} '
        '${lost.length.toString().padLeft(8)} '
        '${_p(lost, 0.50).padLeft(9)} '
        '${_p(lost, 0.90).padLeft(9)} '
        '${_p(lost, 1).padLeft(9)}',
      );
    }

    lines
      ..add('')
      ..add('HORIZON SWEEP. maxBufferedFixes = 64 caps the hold regardless,')
      ..add('so at ~1.2 fix/s the cap binds somewhere past 50 s.')
      ..add('')
      ..add(
        'capture               ${[
          for (final h in _horizons) '${h.inSeconds}s'.padLeft(9),
        ].join()}',
      );

    for (final entry in delivered.entries) {
      final lostCells = <String>[];
      final distanceCells = <String>[];
      final acceptedCells = <String>[];
      for (final horizon in _horizons) {
        final processor = TrackProcessor(bufferHorizon: horizon);
        for (final captured in entry.value) {
          processor.add(captured.fix);
        }
        final report = processor.diagnose();
        lostCells.add(
          (report.rejections?[FixRejection.arrivedTooLate] ?? 0)
              .toString()
              .padLeft(9),
        );
        distanceCells.add(
          report.smoothedDistanceM.toStringAsFixed(0).padLeft(9),
        );
        acceptedCells.add(report.accepted.toString().padLeft(9));
      }
      lines
        ..add('${'${entry.key}  lost'.padRight(21)} ${lostCells.join()}')
        ..add('${'  accepted'.padRight(21)} ${acceptedCells.join()}')
        ..add('${'  distance m'.padRight(21)} ${distanceCells.join()}');
    }

    lines
      ..add('')
      ..add('WHERE THE LATE FIXES GO INSTEAD: every rejection reason, by')
      ..add('horizon. If a horizon that stops losing them does not raise')
      ..add('`accepted`, they were being discarded by a later gate anyway.')
      ..add('');

    for (final entry in delivered.entries) {
      lines.add(entry.key);
      for (final horizon in _horizons.take(4)) {
        final processor = TrackProcessor(bufferHorizon: horizon);
        for (final captured in entry.value) {
          processor.add(captured.fix);
        }
        final report = processor.diagnose();
        final counts = report.rejections ?? const <FixRejection, int>{};
        lines.add(
          '  ${'${horizon.inSeconds}s'.padLeft(4)} '
          'accepted ${report.accepted.toString().padLeft(5)}   '
          '${[
            for (final reason in FixRejection.values)
              if ((counts[reason] ?? 0) > 0) '${reason.name} ${counts[reason]}',
          ].join(', ')}',
        );
      }
    }

    lines
      ..add('')
      ..add('IS LATENESS A PROPERTY OF THE OTHER STREAM? Median reported')
      ..add('accuracy of the fixes that arrived late, against the rest.')
      ..add('')
      ..add('capture                 late n   late med acc   on-time med acc');
    for (final entry in delivered.entries) {
      final lateAcc = <double>[];
      final onTimeAcc = <double>[];
      DateTime? newest;
      for (final captured in entry.value) {
        final fix = captured.fix;
        final isLate = newest != null && newest.isAfter(fix.timestamp);
        (isLate ? lateAcc : onTimeAcc).add(fix.accuracyM);
        if (newest == null || fix.timestamp.isAfter(newest)) {
          newest = fix.timestamp;
        }
      }
      lateAcc.sort();
      onTimeAcc.sort();
      lines.add(
        '${entry.key.padRight(21)} ${lateAcc.length.toString().padLeft(7)} '
        '${_p(lateAcc, 0.5).padLeft(14)} ${_p(onTimeAcc, 0.5).padLeft(17)}',
      );
    }

    lines
      ..add('')
      ..add('ACCURACY (m) OF THE FIXES LOST AT 3 s')
      ..add('');
    for (final entry in lateAccuracy.entries) {
      lines.add(
        '${entry.key.padRight(21)} n=${entry.value.length.toString().padLeft(4)}  '
        'min ${_p(entry.value, 0)}  p50 ${_p(entry.value, 0.5)}  '
        'p90 ${_p(entry.value, 0.9)}  max ${_p(entry.value, 1)}',
      );
    }

    // Printing IS the deliverable here too.
    // ignore: avoid_print
    print(lines.join('\n'));
  });

  test('pace-relative stop threshold, against Strava where there is one', () {
    // **The earlier ruling — "leave it at 0.5, the evidence is decisive" —
    // is disregarded here on instruction.** It was made on two captures
    // disagreeing in opposite directions, which is noise. A third makes it a
    // trend: fast we are stricter than Strava, slow we are looser, which is
    // what a fixed threshold does against a rule that scales with the
    // activity's own pace.
    //
    //   Zurich  1.37 m/s median   ours 1:36 STRICTER
    //   forest  0.88 m/s median   ours 11:45 LOOSER
    //   shop    0.79 m/s median   ours  5:45 LOOSER
    //
    // REPORT ONLY. `minMovingSpeedMps` does not move on this.
    final median = <String, double>{};
    final shipped = <String, Duration>{};

    for (final entry in delivered.entries) {
      final processor = TrackProcessor();
      for (final captured in entry.value) {
        processor.add(captured.fix);
      }
      final report = processor.diagnose();
      median[entry.key] = report.acceptedSpeedMps!.median;
      shipped[entry.key] = report.movingTime;
    }

    final lines = <String>[
      '',
      "WHAT 0.5 m/s IS, AS A FRACTION OF EACH WALK'S OWN PACE",
      '',
      'The smoothed-speed median does not depend on the stop threshold — it',
      'is measured per accepted fix, before any moving/stopped decision — so',
      'a threshold set from it is not circular.',
      '',
      'capture                med spd   0.5 is    ours   Strava     delta',
    ];

    for (final entry in delivered.entries) {
      final strava = stravaMoving[entry.key];
      lines.add(
        '${entry.key.padRight(21)} '
        '${median[entry.key]!.toStringAsFixed(2).padLeft(7)} '
        '${'${(0.5 / median[entry.key]!).toStringAsFixed(2)}x'.padLeft(7)} '
        '${_hms(shipped[entry.key]!).padLeft(7)} '
        '${(strava == null ? '—' : _hms(strava)).padLeft(8)} '
        '${(strava == null ? '—' : _signed(shipped[entry.key]! - strava)).padLeft(9)}',
      );
    }

    lines
      ..add('')
      ..add("A PACE-RELATIVE THRESHOLD. Moving time at k x the run's own")
      ..add('median smoothed speed, and the signed error against Strava.')
      ..add('A floor stops a stationary receiver being scaled into motion:')
      ..add('at k x 0 the threshold is 0 and every wandering metre counts as')
      ..add('movement. No capture here is of a stationary receiver, so the')
      ..add('floor is swept rather than measured — and that is the gap.')
      ..add('');

    for (final floor in _floors) {
      lines
        ..add('floor ${floor.toStringAsFixed(2)} m/s')
        ..add(
          '  capture              ${[
            for (final k in _multipliers) '${k.toStringAsFixed(2)}x'.padLeft(17),
          ].join()}',
        )
        ..add(
          '                       '
          '${'  thr   moving    err' * _multipliers.length}',
        );

      for (final entry in delivered.entries) {
        final cells = <String>[];
        for (final k in _multipliers) {
          final threshold = math.max(k * median[entry.key]!, floor);
          final processor = TrackProcessor(minMovingSpeedMps: threshold);
          for (final captured in entry.value) {
            processor.add(captured.fix);
          }
          final moving = processor.diagnose().movingTime;
          final strava = stravaMoving[entry.key];
          cells
            ..add(threshold.toStringAsFixed(2).padLeft(6))
            ..add(_hms(moving).padLeft(8))
            ..add((strava == null ? '—' : _signed(moving - strava)).padLeft(7));
        }
        lines.add('  ${entry.key.padRight(21)}${cells.join()}');
      }
      lines.add('');
    }

    lines
      ..add('FOR COMPARISON: the same three, at fixed thresholds.')
      ..add('')
      ..add(
        '  capture              ${[
          for (final t in _thresholds) t.toStringAsFixed(2).padLeft(9),
        ].join()}',
      );
    for (final entry in delivered.entries) {
      final strava = stravaMoving[entry.key];
      if (strava == null) continue;
      final cells = <String>[];
      for (final threshold in _thresholds) {
        final processor = TrackProcessor(minMovingSpeedMps: threshold);
        for (final captured in entry.value) {
          processor.add(captured.fix);
        }
        cells.add(_signed(processor.diagnose().movingTime - strava).padLeft(9));
      }
      lines.add('  ${entry.key.padRight(21)}${cells.join()}');
    }

    lines
      ..add('')
      ..add('THE THRESHOLD THAT ACTUALLY MATCHES STRAVA, found by bisection,')
      ..add("and what it is as a fraction of that walk's own median. If")
      ..add('Strava scaled to pace, this last column would be a constant.')
      ..add('')
      ..add('capture                med spd   fits at   as a fraction');
    for (final entry in delivered.entries) {
      final strava = stravaMoving[entry.key];
      if (strava == null) continue;

      // Moving time falls monotonically as the threshold rises, so bisection
      // is safe. 30 halvings takes the bracket below a thousandth of a m/s,
      // far under anything the answer is read to.
      var (low, high) = (0.0, 3.0);
      for (var i = 0; i < 30; i++) {
        final mid = (low + high) / 2;
        final processor = TrackProcessor(minMovingSpeedMps: mid);
        for (final captured in entry.value) {
          processor.add(captured.fix);
        }
        if (processor.diagnose().movingTime > strava) {
          low = mid;
        } else {
          high = mid;
        }
      }
      final fits = (low + high) / 2;
      lines.add(
        '${entry.key.padRight(21)} '
        '${median[entry.key]!.toStringAsFixed(2).padLeft(7)} '
        '${fits.toStringAsFixed(2).padLeft(9)} '
        '${'${(fits / median[entry.key]!).toStringAsFixed(2)}x'.padLeft(15)}',
      );
    }

    // Printing IS the deliverable.
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}

const List<double> _thresholds = [0.30, 0.40, 0.50, 0.60, 0.75, 1];

/// Fractions of a run's own median smoothed speed. 0.25 and 0.35 were asked
/// for; the neighbours are here so a fit reads as a plateau or as a point
/// that happened to land.
const List<double> _multipliers = [0.20, 0.25, 0.30, 0.35, 0.40];

/// Floors under the scaled threshold. 0 is the no-floor case, included so
/// that what the floor is doing is visible rather than assumed.
const List<double> _floors = [0, 0.15, 0.25, 0.35];

const List<Duration> _horizons = [
  Duration.zero,
  Duration(seconds: 3),
  Duration(seconds: 5),
  Duration(seconds: 8),
  Duration(seconds: 12),
  Duration(seconds: 20),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

/// A signed mm:ss, so an error's direction reads without arithmetic.
String _signed(Duration d) => '${d.isNegative ? '-' : '+'}${_hms(d.abs())}';

String _hms(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

String _p(List<double> sorted, double q) {
  if (sorted.isEmpty) return '-';
  return sorted[((sorted.length - 1) * q).round()].toStringAsFixed(2);
}
