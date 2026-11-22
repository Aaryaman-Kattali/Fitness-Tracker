import 'dart:math' as math;

import 'package:meta/meta.dart';

/// What the barometer did over a run, as the run's report and row need it.
enum BarometerOutcome {
  /// Listened to for the whole run.
  recorded,

  /// The phone has no pressure sensor. Learned by listening, not by asking
  /// what the phone is (A6-1).
  absent,

  /// There is a sensor and it failed. The run keeps no gain rather than a
  /// partial one, because a partial climb looks exactly like a complete one.
  failed,
}

/// A run's elevation, and why it is what it is.
@immutable
class ElevationReport {
  ElevationReport({
    required this.outcome,
    required List<PressureSample> samples,
    this.detail,
  }) : sampleCount = samples.length,
       gainM = outcome == BarometerOutcome.recorded
           ? elevationGainM(samples)
           : null;

  final BarometerOutcome outcome;
  final int sampleCount;

  /// Null unless the barometer [BarometerOutcome.recorded] at least one
  /// reading. This is what `runs.elevGainM` stores.
  final double? gainM;

  /// Platform text for a failure. Diagnostic, not user-facing.
  final String? detail;
}

/// One barometer reading. Pure Dart, like the rest of the pipeline: the
/// plugin's own event type stops at `SensorsPlusBarometer`.
typedef PressureSample = ({DateTime at, double hPa});

/// How far altitude has to move before a change of direction is believed, in
/// metres (A6-2).
///
/// **PROVISIONAL.** It has to sit clear of the barometer's short-term noise and
/// below the smallest climb worth reporting, and neither is measured here: no
/// capture carries pressure yet. Phone barometers quote relative accuracy of
/// about ±0.1 hPa, ±0.8 m, which is datasheet class rather than a measurement,
/// and pocket and wind transients sit on top of that. The cost is on record in
/// `elevation_gain_test`: undulations smaller than this between reversals are
/// not counted. Revisit against the first walk recorded with pressure.
const double elevationHysteresisM = 2;

/// Altitude from pressure in the standard atmosphere, in metres.
///
/// Only differences are ever used, so the sea-level reference cancels and
/// today's weather does not need to be known. What does not cancel is weather
/// CHANGING during a run, which is indistinguishable from climbing; at a
/// typical 0.3 hPa an hour that is under a metre on a 22 minute walk.
double altitudeFromPressureM(double hPa) =>
    44330 * (1 - math.pow(hPa / 1013.25, 1 / 5.255).toDouble());

/// Total climb over a run, in metres, or null when there are no readings.
///
/// Null rather than zero: no barometer is not a flat route, and `runs.elevGainM`
/// stores the difference.
///
/// Counted peak to valley with a deadband of [elevationHysteresisM]. While
/// descending, the lowest point is tracked, and a climb starts only once the
/// altitude is that far above it — at which point the WHOLE rise from the
/// valley counts, so a real 6 m climb reads 6 and not 4. While climbing, every
/// new high adds, until a fall of the same size ends the climb. A naive sum of
/// every positive step integrates the noise instead: on the flat-route fixture
/// it reads tens of metres.
double? elevationGainM(List<PressureSample> samples) {
  if (samples.isEmpty) return null;

  final altitudes = _bucketMeans(samples).map(altitudeFromPressureM);
  var gain = 0.0;
  var reference = altitudes.first;
  var climbing = false;

  for (final altitude in altitudes.skip(1)) {
    if (climbing) {
      if (altitude > reference) {
        gain += altitude - reference;
        reference = altitude;
      } else if (altitude < reference - elevationHysteresisM) {
        climbing = false;
        reference = altitude;
      }
    } else {
      if (altitude < reference) {
        reference = altitude;
      } else if (altitude > reference + elevationHysteresisM) {
        gain += altitude - reference;
        reference = altitude;
        climbing = true;
      }
    }
  }
  return gain;
}

/// Readings are averaged over this long before the deadband sees them, so
/// that the sensor's white floor is not what decides a reversal.
const _bucket = Duration(seconds: 5);

/// Mean pressure per [_bucket], in time order, starting from the first sample.
///
/// Buckets by the sample's own timestamp rather than by count: the platform
/// treats the requested rate as a hint, so a count would mean a different
/// length of time on every phone.
List<double> _bucketMeans(List<PressureSample> samples) {
  final start = samples.first.at;
  final sums = <int, ({double total, int n})>{};
  for (final sample in samples) {
    final key =
        sample.at.difference(start).inMicroseconds ~/ _bucket.inMicroseconds;
    final previous = sums[key] ?? (total: 0.0, n: 0);
    sums[key] = (total: previous.total + sample.hPa, n: previous.n + 1);
  }
  final keys = sums.keys.toList()..sort();
  return [for (final key in keys) sums[key]!.total / sums[key]!.n];
}
