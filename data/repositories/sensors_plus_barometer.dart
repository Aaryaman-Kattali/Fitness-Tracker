import 'dart:async';

import 'package:fitness_tracker/data/repositories/barometer.dart';
import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// [Barometer] on `sensors_plus`. The only file that imports it.
///
/// On Android the plugin asks `SensorManager.getDefaultSensor(TYPE_PRESSURE)`
/// when the stream is listened to, and errors it with `NO_SENSOR` when there
/// is none. That is a real runtime probe, so this class only translates the
/// code.
class SensorsPlusBarometer implements Barometer {
  @override
  Stream<PressureSample> readings() =>
      // One a second is plenty: gain is read over 5 s means. The platform
      // treats the period as a hint, which is why the pipeline buckets by
      // timestamp rather than by count.
      barometerEventStream(samplingPeriod: const Duration(seconds: 1))
          .map<PressureSample>(
            (event) => (at: event.timestamp.toUtc(), hPa: event.pressure),
          )
          .transform(
            StreamTransformer.fromHandlers(
              handleError: (error, stack, sink) => sink.addError(
                error is PlatformException && error.code == 'NO_SENSOR'
                    ? const BarometerAbsent()
                    : error,
                stack,
              ),
            ),
          );
}
