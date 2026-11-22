import 'package:fitness_tracker/data/repositories/barometer.dart';
import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';

/// A [Barometer] that replays readings, or behaves like a phone without one.
///
/// [FakeBarometer.absent] is what every test that is not about elevation uses:
/// it is the real `SensorsPlusBarometer`'s answer on a phone with no sensor,
/// so those tests run the path the A32 runs.
class FakeBarometer implements Barometer {
  FakeBarometer(this.samples, {this.thenError});

  FakeBarometer.absent()
    : samples = const [],
      thenError = const BarometerAbsent();

  final List<PressureSample> samples;

  /// Raised after [samples] have been delivered, when set.
  final Object? thenError;

  @override
  Stream<PressureSample> readings() async* {
    yield* Stream.fromIterable(samples);
    final error = thenError;
    if (error != null) yield* Stream.error(error);
  }
}
