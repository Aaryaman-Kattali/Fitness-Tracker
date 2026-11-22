import 'package:fitness_tracker/features/activity/diagnostics/reconstruct_diagnostics.dart';
import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';
import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'run_diagnostics_provider.g.dart';

@Riverpod(keepAlive: true)
RunDiagnosticsStore runDiagnosticsStore(Ref ref) => const RunDiagnosticsStore();

/// The debug read-out for the most recent run, as text.
///
/// Two sources, in order of how much they can tell you. A live capture written
/// when the run was saved is complete. Failing that, the accepted points still
/// in the database are re-read and what can be recovered from them is
/// recovered — which is everything about the fixes that survived and nothing
/// about the ones that did not.
///
/// Autodisposed, like the Health Connect panel: it is only ever on screen while
/// someone is looking at it.
@riverpod
Future<String> runDiagnosticsReport(Ref ref) async {
  final captured = await ref.read(runDiagnosticsStoreProvider).latest();
  if (captured != null) return captured;

  final dao = ref.read(runDaoProvider);
  final runs = await dao.recentRuns(limit: 1);
  if (runs.isEmpty) {
    return 'No run has been recorded yet.\n\n'
        'Record one and the full capture — delivery counts, rejections by '
        'reason, arrival order — is written when you finish it.';
  }

  final run = runs.single;
  final rows = await dao.pointsFor(run.id);
  if (rows.length < 2) {
    return 'The last run stored ${rows.length} point(s). '
        'There is nothing to reconstruct from.';
  }

  // The stop detector's own settings, taken from the pipeline rather than
  // restated here. A reconstruction that segmented stops against a remembered
  // threshold would answer a question nobody asked.
  final defaults = TrackProcessor();

  var cumulative = 0.0;
  final points = <TrackPoint>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (i > 0) {
      cumulative += haversineMetres(
        rows[i - 1].lat,
        rows[i - 1].lon,
        row.lat,
        row.lon,
      );
    }
    points.add(
      TrackPoint(
        latitude: row.lat,
        longitude: row.lon,
        cumulativeDistanceM: cumulative,
        // Reassembled from the columns that rode along unprocessed. This is
        // the raw fix's own accuracy and Doppler speed, not a reconstruction
        // of them — the one part of the original input that did survive.
        source: RawFix(
          latitude: row.lat,
          longitude: row.lon,
          timestamp: row.timestamp,
          // A stored null means the receiver reported no accuracy. It cannot
          // become a small number here: that would move the median of the
          // distribution this report exists to show.
          accuracyM: row.accuracyM ?? double.nan,
          altitudeM: row.elevM,
          speedMps: row.speedMps,
        ),
      ),
    );
  }

  return reconstructDiagnostics(
    points: points,
    smoothedDistanceM: run.distanceM,
    elapsed: Duration(seconds: run.elapsedS),
    movingTime: Duration(seconds: run.movingS),
    minMovingSpeedMps: defaults.minMovingSpeedMps,
    maxSpeedMps: defaults.maxSpeedMps,
    movingWindow: defaults.movingWindow,
  ).plainText();
}
