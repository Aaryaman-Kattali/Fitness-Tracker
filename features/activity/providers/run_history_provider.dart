import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'run_history_provider.g.dart';

/// Neither type below carries a drift row, and that is not only layering.
///
/// `riverpod_generator` cannot emit a provider whose return type is a drift
/// row class. Those are declared inside `app_database.g.dart`, which is a
/// `part` of its library, and the generator fails with `InvalidTypeException:
/// The type is invalid and cannot be converted to code` — a message that says
/// nothing about which type or why. Verified by reduction: swapping the return
/// type for `int` builds, swapping it back to `List<Run>` fails.
///
/// Every other provider in the app happened to satisfy this already, by
/// returning ints, hand-written models or nothing. It is written down here
/// rather than left to be rediscovered.

/// One row of the run list. Only what the row draws.
@immutable
class RunSummary {
  const RunSummary({
    required this.id,
    required this.startedAt,
    required this.distanceM,
    required this.movingS,
    required this.avgPaceSPerKm,
  });

  final int id;
  final DateTime startedAt;
  final double distanceM;
  final int movingS;
  final double avgPaceSPerKm;
}

/// Every recorded run, newest first, as a live query.
///
/// Watched rather than fetched so that finishing a run puts it in the list
/// without anyone having to know to refresh.
@riverpod
Stream<List<RunSummary>> runHistory(Ref ref) => ref
    .watch(runDaoProvider)
    .watchRecentRuns()
    .map(
      (runs) => [
        for (final run in runs)
          RunSummary(
            id: run.id,
            startedAt: run.startedAt,
            distanceM: run.distanceM,
            movingS: run.movingS,
            avgPaceSPerKm: run.avgPaceSPerKm,
          ),
      ],
    );

/// One run, with everything the detail screen draws.
@immutable
class RunDetail {
  const RunDetail({
    required this.distanceM,
    required this.movingS,
    required this.elapsedS,
    required this.avgPaceSPerKm,
    required this.route,
    required this.rawFixes,
    this.elevGainM,
  });

  final double distanceM;
  final int movingS;
  final int elapsedS;
  final double avgPaceSPerKm;

  /// Barometric climb, or null when nothing measured it: no barometer, a
  /// failed one, or a run saved before A6. The screen says "not measured"
  /// rather than showing a zero, which would claim a flat route.
  final double? elevGainM;

  /// The smoothed track, in order.
  final List<LatLng> route;

  /// The accepted fixes before smoothing, or null when they are not available
  /// for this run.
  ///
  /// Null is the normal case, not an error: only the most recent run's raw
  /// positions are kept, and no run recorded before the debug capture existed
  /// has them at all. The screen has to say which it is rather than showing an
  /// empty overlay, because "no raw fixes stored" and "the smoothed line sits
  /// exactly on the raw fixes" look identical when both draw nothing.
  final List<LatLng>? rawFixes;

  bool get hasRawFixes => rawFixes != null && rawFixes!.isNotEmpty;
}

@riverpod
Future<RunDetail> runDetail(Ref ref, int runId) async {
  final dao = ref.watch(runDaoProvider);

  final run = await dao.runById(runId);
  if (run == null) throw StateError('Run $runId is not in the database.');

  final points = await dao.pointsFor(runId);
  final raw = await ref.read(runDiagnosticsStoreProvider).rawTrackFor(runId);

  return RunDetail(
    distanceM: run.distanceM,
    movingS: run.movingS,
    elapsedS: run.elapsedS,
    avgPaceSPerKm: run.avgPaceSPerKm,
    elevGainM: run.elevGainM,
    route: [for (final point in points) LatLng(point.lat, point.lon)],
    rawFixes: raw == null
        ? null
        : [for (final point in raw) LatLng(point.lat, point.lon)],
  );
}
