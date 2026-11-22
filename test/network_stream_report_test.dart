@Tags(['report', 'no-oracle'])
library;

import 'dart:io';

import 'package:fitness_tracker/features/activity/diagnostics/fix_capture.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Is the indoor case separable from the fiction case by any rule?
///
/// **A reporting harness, not a budget**, and REPORT ONLY: nothing here is
/// wired into the pipeline and no constant moves on it. Same contract as
/// `capture_distance_report_test.dart` — it asserts only that each capture
/// still replays, and prints numbers for a person to read.
///
/// The question comes from the 8 Sep shop walk. Indoors, the receiver lost
/// lock for 21.6 and 18.0 minutes; during the first of those the plugin
/// delivered 218 fixes, of which 3 were GPS at 14–21 m and rejected on
/// accuracy, and the other 215 were network positioning. ~500–750 m was
/// walked inside the shop and the pipeline recorded ~56 m of it.
///
/// The network stream is normally the fiction: 154 network fixes traced
/// 6171 m on the 1610 m walk of 23 Aug, 3.8x the whole route. What makes the
/// shop capture worth asking about is that its network median is **15.5 m**
/// against 200 m in the forest and 500 m outdoors in Zurich — indoors, the
/// stream the pipeline exists to reject is an order of magnitude better than
/// the one it accepts elsewhere, because a phone surrounded by wifi is a
/// phone trilaterating off known access points.
///
/// So: does any admission rule let the shop's network fixes in while keeping
/// the outdoor captures' out, and how much fiction does the best such rule
/// buy on the routes where the answer is known?
void main() {
  const captures = <String, String>{
    '23 Aug A32 1610 m': 'captures/2026-08-23_1610m.ndjson',
    '24 Aug A32 1610 m': 'captures/2026-08-24_1610m.ndjson',
    '01 Sep S26 1930 m': 'captures/2026-09-01_1930m.ndjson',
    '07 Sep Zurich': 'captures/2026-09-07_zurich_4310m.ndjson',
    '08 Sep forest': 'captures/run_fixes_20260908-102553.ndjson',
    '08 Sep shop, indoors': 'captures/run_fixes_20260908-162309.ndjson',
  };

  /// Ground truth where it exists, in metres. Zurich, the forest and the shop
  /// have none — see NOTES.md, "Ground truth: there is none for this route".
  const groundTruthM = <String, double>{
    '23 Aug A32 1610 m': 1610,
    '24 Aug A32 1610 m': 1610,
    '01 Sep S26 1930 m': 1930,
  };

  const outdoor = [
    '23 Aug A32 1610 m',
    '24 Aug A32 1610 m',
    '01 Sep S26 1930 m',
    '07 Sep Zurich',
  ];

  final delivered = {
    for (final entry in captures.entries)
      entry.key: parseCapture(File(entry.value).readAsStringSync()),
  };

  /// The receiver's own fixes, by the rule the pipeline itself uses.
  ///
  /// `StreamDetector`'s primary discriminator is timestamp granularity: GPS
  /// ticks on the whole second and network positioning resolves whenever it
  /// resolves. It fired on every capture here, so classifying by granularity
  /// is classifying the way the shipped pipeline classified, and not by a
  /// second rule invented for this report.
  bool isNetwork(RawFix fix) => fix.timestamp.millisecond != 0;

  /// The accepted track, plus every delivered fix, per capture.
  ({List<TrackPoint> track, TrackProcessor processor}) replay(String name) {
    final processor = TrackProcessor();
    for (final captured in delivered[name]!) {
      processor.add(captured.fix);
    }
    processor.diagnose();
    return (track: processor.points, processor: processor);
  }

  final tracks = {for (final name in captures.keys) name: replay(name)};

  test('the network stream is a different instrument in every environment', () {
    final lines = <String>[
      '',
      'NETWORK STREAM ACCURACY (m), fractional-timestamp fixes only',
      '',
      'capture                    n      min      p10      p25      med      p75      p90      max',
    ];

    for (final entry in delivered.entries) {
      final accuracy = [
        for (final captured in entry.value)
          if (isNetwork(captured.fix)) captured.fix.accuracyM,
      ]..sort();
      lines.add(
        '${entry.key.padRight(21)} ${accuracy.length.toString().padLeft(6)} '
        '${[
          for (final q in [0.0, 0.10, 0.25, 0.50, 0.75, 0.90, 1.0]) _p(accuracy, q).padLeft(8),
        ].join(' ')}',
      );

      expect(tracks[entry.key]!.track, isNotEmpty);
    }

    lines
      ..add('')
      ..add('WHAT A CEILING ADMITS. Percentage of the network stream in')
      ..add('each capture at or under the threshold. A separating rule reads')
      ..add('high on the shop row and ~0 on every other.')
      ..add('')
      ..add(
        'capture               ${[
          for (final t in _ceilings) '${t.toStringAsFixed(0)}m'.padLeft(8),
        ].join()}',
      );

    for (final entry in delivered.entries) {
      final accuracy = [
        for (final captured in entry.value)
          if (isNetwork(captured.fix)) captured.fix.accuracyM,
      ];
      final cells = [
        for (final ceiling in _ceilings)
          '${(100 * accuracy.where((a) => a <= ceiling).length / accuracy.length).toStringAsFixed(1)}%'
              .padLeft(8),
      ];
      lines.add('${entry.key.padRight(21)} ${cells.join()}');
    }

    // Printing IS the deliverable: there is no assertion that could stand in
    // for reading these side by side.
    // ignore: avoid_print
    print(lines.join('\n'));
  });

  test('what a network-admitted reconstruction adds, and where', () {
    final lines = <String>[
      '',
      'GAPS IN THE ACCEPTED STREAM, over 2 minutes',
      '',
      'For each gap: the chord the pipeline draws across it, and what the',
      'network fixes inside it trace when chained in timestamp order at each',
      'ceiling. "chained" is raw haversine with no smoothing, which is the',
      'upper bound on what admitting them could produce.',
      '',
      'capture                  gap    chord m   n(net)${[for (final t in _ceilings) '${t.toStringAsFixed(0)}m'.padLeft(10)].join()}',
    ];

    for (final entry in captures.entries) {
      for (final gap in _gaps(tracks[entry.key]!.track, _longGap)) {
        final inside = [
          for (final captured in delivered[entry.key]!)
            if (isNetwork(captured.fix) &&
                captured.fix.timestamp.isAfter(gap.from) &&
                captured.fix.timestamp.isBefore(gap.to))
              captured.fix,
        ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        lines.add(
          '${entry.key.padRight(21)} ${_hms(gap.to.difference(gap.from)).padLeft(7)} '
          '${gap.chordM.toStringAsFixed(1).padLeft(9)} '
          '${inside.length.toString().padLeft(7)}'
          '${[
            for (final ceiling in _ceilings) _chained(inside.where((f) => f.accuracyM <= ceiling).toList()).toStringAsFixed(0).padLeft(10),
          ].join()}',
        );
      }
    }

    lines
      ..add('')
      ..add('THE FICTION THIS BUYS ON A ROUTE WHOSE LENGTH IS KNOWN.')
      ..add('')
      ..add('The same rule applied everywhere: every gap over the horizon is')
      ..add('reconstructed from network fixes under the ceiling, and the')
      ..add('chained length replaces the chord. Ground truth where it exists.')
      ..add('')
      ..add(
        'capture                shipped     truth${[
          for (final t in _ceilings) '${t.toStringAsFixed(0)}m'.padLeft(10),
        ].join()}',
      );

    for (final entry in captures.entries) {
      final shipped = tracks[entry.key]!.processor.distanceM;
      final truth = groundTruthM[entry.key];
      final cells = <String>[];
      for (final ceiling in _ceilings) {
        var total = shipped;
        for (final gap in _gaps(tracks[entry.key]!.track, _longGap)) {
          final inside = [
            for (final captured in delivered[entry.key]!)
              if (isNetwork(captured.fix) &&
                  captured.fix.accuracyM <= ceiling &&
                  captured.fix.timestamp.isAfter(gap.from) &&
                  captured.fix.timestamp.isBefore(gap.to))
                captured.fix,
          ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final chained = _chained(inside);
          if (chained > gap.chordM) total += chained - gap.chordM;
        }
        cells.add(
          truth == null
              ? total.toStringAsFixed(0).padLeft(10)
              : '${(100 * (total - truth) / truth).toStringAsFixed(1)}%'
                    .padLeft(10),
        );
      }
      lines.add(
        '${entry.key.padRight(21)} ${shipped.toStringAsFixed(0).padLeft(7)} '
        '${(truth?.toStringAsFixed(0) ?? '—').padLeft(9)}${cells.join()}',
      );
    }

    lines
      ..add('')
      ..add('Outdoor captures, for the summary: ${outdoor.join(', ')}.')
      ..add('');

    // Printing IS the deliverable, as in every report harness here.
    // ignore: avoid_print
    print(lines.join('\n'));
  });

  test('is "GPS absent for over N minutes" a usable gate', () {
    final lines = <String>[
      '',
      'HOW MANY GAPS QUALIFY, and how much they carry, at each horizon',
      '',
      'A gate that only fires when the receiver has been gone for N minutes',
      'is only useful if the outdoor captures produce no qualifying gaps at',
      'all — a rule that fires rarely on a route with ground truth is still a',
      'rule that fabricates when it fires.',
      '',
      'capture              ${[for (final n in _horizonsMin) '${n}min'.padLeft(16)].join()}',
      '                     ${'  gaps   chord m' * _horizonsMin.length}',
    ];

    for (final entry in captures.entries) {
      final cells = <String>[];
      for (final minutes in _horizonsMin) {
        final gaps = _gaps(
          tracks[entry.key]!.track,
          Duration(minutes: minutes),
        );
        cells
          ..add(gaps.length.toString().padLeft(6))
          ..add(
            gaps
                .fold<double>(0, (sum, gap) => sum + gap.chordM)
                .toStringAsFixed(0)
                .padLeft(10),
          );
      }
      lines.add('${entry.key.padRight(21)}${cells.join()}');
    }

    // Printing IS the deliverable, as in every report harness here.
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}

/// Ceilings swept over the network stream. 9 is what the pipeline ships as
/// `maxAccuracyM`; 15.5 is the shop capture's own network median.
const List<double> _ceilings = [9, 15.5, 20, 25, 30, 50];

/// Gap horizons for the "GPS has been absent" gate.
const List<int> _horizonsMin = [1, 2, 5, 10];

/// The candidate gate, and the shortest horizon at which no outdoor capture
/// produces a qualifying gap at all. The forest walk has one gap over a
/// minute — 13 m of chord under canopy — and none over two.
const Duration _longGap = Duration(minutes: 2);

typedef _Gap = ({DateTime from, DateTime to, double chordM});

/// Every stretch of [track] with no accepted point for longer than [minimum].
List<_Gap> _gaps(List<TrackPoint> track, Duration minimum) {
  final found = <_Gap>[];
  for (var i = 1; i < track.length; i++) {
    final (before, after) = (track[i - 1], track[i]);
    if (after.timestamp.difference(before.timestamp) < minimum) continue;
    found.add((
      from: before.timestamp,
      to: after.timestamp,
      chordM: haversineMetres(
        before.latitude,
        before.longitude,
        after.latitude,
        after.longitude,
      ),
    ));
  }
  return found;
}

/// Raw fix-to-fix length of a sequence, unsmoothed.
double _chained(List<RawFix> fixes) {
  var total = 0.0;
  for (var i = 1; i < fixes.length; i++) {
    total += haversineMetres(
      fixes[i - 1].latitude,
      fixes[i - 1].longitude,
      fixes[i].latitude,
      fixes[i].longitude,
    );
  }
  return total;
}

String _hms(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

String _p(List<double> sorted, double q) {
  if (sorted.isEmpty) return '-';
  return sorted[((sorted.length - 1) * q).round()].toStringAsFixed(2);
}
