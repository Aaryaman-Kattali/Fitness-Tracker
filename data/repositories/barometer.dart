import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';

/// The phone has no pressure sensor.
///
/// A type of its own rather than a platform error code, so nothing above the
/// repository has to know which plugin's vocabulary "no sensor" arrives in.
class BarometerAbsent implements Exception {
  const BarometerAbsent();

  @override
  String toString() => 'BarometerAbsent: this phone has no pressure sensor';
}

/// Air pressure, for elevation gain (A6-1).
///
/// Separate from `RunRecorder` so that each platform plugin sits behind its
/// own seam: the GPS and the barometer are different sensors with different
/// failure modes, and a phone with one and not the other is the ordinary case.
///
/// One member, and a class anyway rather than a function type: CLAUDE.md puts
/// every plugin behind a repository interface, and this is that interface.
// ignore: one_member_abstracts
abstract class Barometer {
  /// Readings from the moment of listening until cancelled.
  ///
  /// **Listening is the runtime probe.** A phone without the sensor errors the
  /// stream with [BarometerAbsent]; any other error is a sensor that exists
  /// and failed. Never decided from the Android version or the device model.
  Stream<PressureSample> readings();
}
