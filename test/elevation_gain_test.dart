import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A6-2: barometric gain with a hysteresis, so noise is not integrated as
/// climb.
///
/// **Every noise parameter below is ASSUMED, not measured.** No committed
/// capture carries pressure yet (A6-3 is what starts recording it), so these
/// fixtures are stress cases in the A1c-D sense, not the measured operating
/// point: a white sensor floor of 0.1 m, which is phone-barometer datasheet
/// class, plus a 0.3 m error correlated over 10 s for pocket, body and wind,
/// plus a weather drift of 0.3 hPa an hour. The first walk recorded with
/// pressure replaces them.
///
/// The flat route is the one that matters, and it is built so that a naive
/// integrator FAILS it: 22 minutes at 1 Hz, the length of the 18 Sep walk, on
/// which Strava read 3 m.
void main() {
  const seconds = 22 * 60;
  final start = DateTime.utc(2026, 9, 18, 16, 32);

  /// Pressure at [altitudeM] in the standard atmosphere: the inverse of what
  /// the code under test applies, so a noise-free fixture round-trips exactly.
  double pressureAt(double altitudeM) =>
      1013.25 * math.pow(1 - altitudeM / 44330, 5.255).toDouble();

  /// One sample per second along [profile], with the assumed noise on it.
  /// Seeded: a fixture that fails one run in twenty trains people to re-run.
  List<PressureSample> walk(
    double Function(int second) profile, {
    int seed = 20260919,
  }) {
    final random = math.Random(seed);
    double gaussian() =>
        math.sqrt(-2 * math.log(1 - random.nextDouble())) *
        math.cos(2 * math.pi * random.nextDouble());

    const whiteM = 0.1;
    const correlatedM = 0.3;
    const correlationS = 10.0;
    const driftHpaPerHour = -0.3;
    final rho = math.exp(-1 / correlationS);

    var correlated = 0.0;
    return [
      for (var s = 0; s < seconds; s++)
        () {
          correlated =
              rho * correlated +
              math.sqrt(1 - rho * rho) * correlatedM * gaussian();
          final altitude = profile(s) + correlated + whiteM * gaussian();
          return (
            at: start.add(Duration(seconds: s)),
            hPa: pressureAt(altitude) + driftHpaPerHour * s / 3600,
          );
        }(),
    ];
  }

  /// Every rise, summed. What the hysteresis exists to not be.
  double naiveGainM(List<PressureSample> samples) {
    var gain = 0.0;
    for (var i = 1; i < samples.length; i++) {
      final step =
          altitudeFromPressureM(samples[i].hPa) -
          altitudeFromPressureM(samples[i - 1].hPa);
      if (step > 0) gain += step;
    }
    return gain;
  }

  test('a flat route reads as flat, where a naive integrator reads tens of '
      'metres', () {
    final flat = walk((_) => 408);

    expect(
      naiveGainM(flat),
      greaterThan(20),
      reason:
          'the fixture must be able to fail: noise alone has to look '
          'like climb to an integrator with no threshold',
    );
    // The 5 s averaging is load-bearing here by 6 cm: with it removed this
    // reads 2.06 m against the 2 m budget. That margin is under ASSUMED
    // noise, datasheet class rather than measured, so a real sensor may move
    // it either way, and the deadband is provisional until measured on
    // hardware.
    expect(elevationGainM(flat), lessThan(2));
  });

  test('a real climb is counted', () {
    // Up 30 m over three minutes, a plateau, and back down: a gain of 30.
    double hill(int s) => switch (s) {
      < 300 => 400,
      < 480 => 400 + 30 * (s - 300) / 180,
      < 900 => 430,
      < 1080 => 430 - 30 * (s - 900) / 180,
      _ => 400,
    };

    expect(elevationGainM(walk(hill)), closeTo(30, 2.5));
  });

  test('a small climb is still counted, so the threshold is not a wall', () {
    // 6 m, the scale of a bridge approach. A threshold large enough to eat
    // this would make the number useless on an ordinary city walk.
    double ramp(int s) =>
        s < 600 ? 400 : (s < 660 ? 400 + (s - 600) / 10 : 406);

    expect(elevationGainM(walk(ramp)), closeTo(6, 2));
  });

  /// One sample per second along [profile], with no noise at all.
  List<PressureSample> clean(double Function(int second) profile) => [
    for (var s = 0; s < seconds; s++)
      (at: start.add(Duration(seconds: s)), hPa: pressureAt(profile(s))),
  ];

  test(
    'undulations under the threshold are not counted, which is the cost',
    () {
      // Stated as a test so the price of the threshold is on record rather than
      // discovered: twenty 1.5 m bumps are 30 m of real climbing that reads as
      // 0. Noise-free, because that isolates the cost; with the assumed noise
      // on top, some bumps clear the deadband and are counted, so the reading
      // there sits somewhere between 0 and the truth.
      double bumps(int s) => 400 + 1.5 * math.sin(math.pi * s / 66).abs();

      expect(elevationGainM(clean(bumps)), 0);
    },
  );

  test('no samples is no measurement, not zero', () {
    expect(elevationGainM(const []), isNull);
  });

  test('a noise-free climb round-trips through pressure exactly', () {
    // Flat either side of the ramp, so the 5 s means at both ends are the
    // true endpoints and the only thing tested is the pressure conversion.
    double ramp(int s) =>
        s < 100 ? 400 : (s < 200 ? 400 + (s - 100) / 10 : 410);

    expect(elevationGainM(clean(ramp)), closeTo(10, 1e-6));
  });
}
