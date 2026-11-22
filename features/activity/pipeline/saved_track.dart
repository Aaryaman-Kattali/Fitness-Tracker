part of 'track_processor.dart';

/// Inter-fix error, in metres at the HIGH end of the bracket, below which the
/// saved distance comes from the raw accepted positions (A1c-Q).
///
/// The filter's benefit is device-dependent in SIGN (PROGRESS.md A1c-15): on
/// the S26 raw accepted beats every value of `accelerationNoiseMps2`, on the
/// A32 the filter is load-bearing. Replayed on the seven committed captures the
/// S26 reads 0.151–0.225 m and the A32 0.496–0.582 m, so 0.30 sits in a clean
/// gap. Compared against the HIGH end of the bracket on purpose: that is the
/// noisier reading, so a borderline receiver keeps the smoother, which is the
/// side already shipped and validated.
const double bypassBelowInterFixNoiseM = 0.30;

/// Where a saved run's distance and splits came from.
enum DistanceSource {
  /// The causal filter's track, exactly as the live screen showed it.
  smoothed,

  /// The raw accepted positions, with stops still decided on the smoothed
  /// track. See [bypassBelowInterFixNoiseM].
  rawAccepted,
}

/// The run as it is stored: which track the distance came from, and the
/// numbers that follow from that choice.
@immutable
class SavedTrack {
  const SavedTrack({
    required this.points,
    required this.distanceM,
    required this.movingTime,
    required this.splits,
    required this.source,
    required this.interFixNoiseHighM,
  });

  /// The smoothed positions on both sides — what `run_points` stores never
  /// changes — carrying the cumulative distance of whichever [source] won, so
  /// the splits are cut from the same total the run row holds.
  final List<TrackPoint> points;
  final double distanceM;
  final Duration movingTime;
  final List<Split> splits;
  final DistanceSource source;

  /// What decided [source]. Null when the run was too short to measure, which
  /// keeps the smoother.
  final double? interFixNoiseHighM;

  double? get averagePaceSecPerKm => distanceM <= 0
      ? null
      : movingTime.inMicroseconds / 1e6 / (distanceM / 1000);
}

SavedTrack _savedTrackOf(TrackProcessor processor) {
  final points = processor._points;
  // The same sample the diagnostics report measures: the accepted fixes' own
  // positions. So the number printed in the report is the number that decided.
  final noise = measureNoiseProcess([
    for (final point in points)
      (
        at: point.timestamp,
        latitude: point.source.latitude,
        longitude: point.source.longitude,
      ),
  ])?.interFixNoise?.highM;

  if (noise == null || noise >= bypassBelowInterFixNoiseM) {
    return SavedTrack(
      points: List.unmodifiable(points),
      distanceM: processor.distanceM,
      movingTime: processor.movingTime,
      splits: processor.splits,
      source: DistanceSource.smoothed,
      interFixNoiseHighM: noise,
    );
  }

  // HYBRID, not a plain bypass. Moving/stopped is decided exactly as the
  // forward pass decided it — the same rule, on the same smoothed history,
  // against the same smoothed candidate — and only the metres accumulated come
  // from the raw fix. Deciding stops on raw positions instead lets standing
  // jitter read as moving, which is A1c-J returning: +311 m and +3:43 on the
  // 7 Sep Zurich capture.
  //
  // Moving time is re-derived here rather than copied from the processor, so
  // that `saved_track_test` comparing the two is a check on this loop and not
  // a tautology.
  final saved = <TrackPoint>[];
  var cumulative = 0.0;
  var movingSeconds = 0.0;
  var anchorLat = 0.0;
  var anchorLon = 0.0;

  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    final raw = point.source;

    if (i == 0) {
      anchorLat = raw.latitude;
      anchorLon = raw.longitude;
    } else {
      final speed = displacementSpeedForCandidate(
        points,
        i - 1,
        point.latitude,
        point.longitude,
        point.timestamp,
        processor.movingWindow,
      );
      final moving = (speed ?? 0) >= processor.minMovingSpeedMps;

      // Same two-way reading of null as the forward pass: not-moving for time,
      // accumulate for distance.
      if (moving || speed == null) {
        cumulative += haversineMetres(
          anchorLat,
          anchorLon,
          raw.latitude,
          raw.longitude,
        );
        anchorLat = raw.latitude;
        anchorLon = raw.longitude;
      }
      if (moving) {
        movingSeconds +=
            point.timestamp.difference(points[i - 1].timestamp).inMicroseconds /
            1e6;
      }
    }

    saved.add(
      TrackPoint(
        latitude: point.latitude,
        longitude: point.longitude,
        source: raw,
        cumulativeDistanceM: cumulative,
      ),
    );
  }

  return SavedTrack(
    points: List.unmodifiable(saved),
    distanceM: cumulative,
    movingTime: Duration(milliseconds: (movingSeconds * 1000).round()),
    splits: splitsOf(saved, cumulative),
    source: DistanceSource.rawAccepted,
    interFixNoiseHighM: noise,
  );
}
