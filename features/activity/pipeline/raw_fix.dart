import 'package:meta/meta.dart';

/// One position report, exactly as a location plugin hands it over.
///
/// This is the pipeline's input boundary and deliberately knows nothing about
/// any plugin: A1a is provable indoors against synthetic tracks, and a type
/// that imported a plugin would drag a device dependency into every test.
///
/// [altitudeM] and [speedMps] are nullable because a real fix genuinely
/// arrives without them — a first lock often has no speed, and altitude is
/// absent whenever the fix is horizontal-only. The precedent is
/// `SetLogs.weightKg`: inventing a zero is worse than recording nothing, since
/// zero is a value something downstream will average.
@immutable
class RawFix {
  const RawFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracyM,
    this.altitudeM,
    this.speedMps,
  });

  final double latitude;
  final double longitude;

  /// Wall-clock time of the fix. The pipeline requires these to be strictly
  /// increasing and drops any fix that is not.
  final DateTime timestamp;

  /// Horizontal accuracy in metres, as a radius. Larger is worse.
  final double accuracyM;

  /// Raw GPS altitude. Stored, never used to compute climb: it is ±10–15 m,
  /// which fabricates elevation gain on flat ground.
  final double? altitudeM;

  /// Speed the receiver reports, from Doppler rather than from differencing
  /// positions. The pipeline does not trust it for distance; it is kept for
  /// the record and for A7.
  final double? speedMps;

  /// The same fix with [speedMps] dropped.
  ///
  /// For a reported speed no one on foot could produce. **Dropped rather than
  /// clamped**: this field is stored per point and read later by things that
  /// cannot tell a measurement from a repair, so a clamped value would be a
  /// wrong number wearing the shape of a right one. Absent is the honest form,
  /// and the precedent is `SetLogs.weightKg` — null for unloaded work, never
  /// zero, because zero is a value something downstream will average.
  RawFix withoutReportedSpeed() => RawFix(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    accuracyM: accuracyM,
    altitudeM: altitudeM,
  );

  @override
  String toString() =>
      'RawFix(${latitude.toStringAsFixed(6)}, '
      '${longitude.toStringAsFixed(6)}, '
      '${timestamp.toIso8601String()}, ±${accuracyM}m)';
}
