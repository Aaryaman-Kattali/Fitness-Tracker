import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/track_processor.dart';

/// Synthetic GPS tracks with known ground truth.
///
/// The whole point of A1a is that the processing pipeline is provable indoors.
/// These fixtures are the oracle: plain Dart data, no device, no plugin, no
/// network, no randomness that is not seeded. Every track states the distance
/// it really covers, so a test can assert against a number rather than against
/// whatever the implementation happened to produce.
///
/// Tracks run due north from [originLat]. That is not laziness — along a
/// meridian the spherical distance is exact and independent of the longitude
/// convergence factor, so `groundTruthDistanceM` is a true value rather than an
/// approximation that quietly shares an error with the code under test.

/// Bangalore. Any origin works; a real one keeps the numbers recognisable.
const double originLat = 12.9716;
const double originLon = 77.5946;

/// 6:00/km, expressed so that whole seconds land on whole metres:
/// 1000 m / 360 s. Fixtures step once per second.
const double runSpeedMps = 1000 / 360;

/// Stationary fixes at the start of every track.
///
/// The pipeline discards the first three fixes as cold-start drift. Without a
/// lead-in, that discard would silently eat three steps of genuine distance
/// (~8 m of 1000 m) and spend most of the 1% budget before the test began.
/// Real runs start with the phone already locking on while you stand there, so
/// this is the realistic shape as well as the fair one: fix 3 is the last
/// stationary fix, and accumulation starts from it at the true origin.
const leadInFixes = 4;

/// A track plus the answers the pipeline is supposed to arrive at.
class SyntheticTrack {
  const SyntheticTrack({
    required this.name,
    required this.fixes,
    required this.groundTruthDistanceM,
    this.groundTruthMovingSeconds,
    this.turnTimes = const [],
    this.stopWindows = const [],
    List<RawFix>? truth,
  }) : _truth = truth;

  final String name;
  final List<RawFix> fixes;

  /// The same track with no noise on it, for tracks that have any. Defaults to
  /// [fixes], which is correct for the noise-free fixtures.
  final List<RawFix>? _truth;

  /// Where the runner really was at [time].
  ///
  /// Pairing a processed point with the truth has to go through the timestamp,
  /// never through a list index: the pipeline rejects fixes, so the processed
  /// track is shorter than the fixture and any index-based pairing silently
  /// compares a point against a second the runner had not reached yet.
  ({double lat, double lon})? truthAt(DateTime time) {
    for (final fix in _truth ?? fixes) {
      if (fix.timestamp == time) {
        return (lat: fix.latitude, lon: fix.longitude);
      }
    }
    return null;
  }

  /// The noise-free twin, in timestamp order. [fixes] where there is none.
  ///
  /// Exposed so a fixture built by reordering another one can inherit its
  /// truth. Rebuilding the twin would mean reproducing the first fixture's
  /// noise draws, and two copies of a noise model is the failure this file
  /// already learned once.
  List<RawFix> get truthFixes => _truth ?? fixes;

  /// Distance genuinely covered from the first fix the pipeline may accept
  /// (index [leadInFixes] - 1) to the last.
  final double groundTruthDistanceM;

  /// Only set where the track has a deliberate stationary period.
  final int? groundTruthMovingSeconds;

  /// When the walker was at a corner, for the tracks that have corners.
  ///
  /// Carried so a test can measure the loss AT the turns separately from the
  /// loss along the straights. Without it, corner-cutting can only be reported
  /// as a total, and a total does not say where the metres went — which is the
  /// entire question a fixture with turns exists to answer.
  final List<DateTime> turnTimes;

  /// When the walker was standing still, for the tracks that stop on purpose.
  ///
  /// Carried for the same reason as [turnTimes], and it buys the same thing.
  /// A test can read the pipeline's own cumulative distance at both edges of a
  /// stop and subtract, which measures what the stop contributed in isolation
  /// from the walking either side of it. Without it, phantom distance can only
  /// be inferred from a total, where it is mixed in with smoothing error and
  /// cannot be given a budget of its own.
  final List<({DateTime from, DateTime to})> stopWindows;

  /// Wall-clock span from the first acceptable fix to the last.
  Duration get groundTruthElapsed =>
      fixes.last.timestamp.difference(fixes[leadInFixes - 1].timestamp);
}

/// 1 km due north at a steady 6:00/km with no noise at all.
///
/// The floor of the whole suite: if this is not within 1%, nothing built on
/// top of it means anything. It is also what catches over-smoothing — a filter
/// tuned so hard that it eats real displacement fails here while looking
/// excellent on the noisy track.
SyntheticTrack straightKm() => SyntheticTrack(
  name: 'straight 1 km, 6:00/km, no noise',
  fixes: _straightNorth(distanceM: 1000),
  groundTruthDistanceM: 1000,
);

/// Correlation time of the multipath stress fixture's error, in seconds.
///
/// **Not a property of this receiver.** It was once used by every fixture here,
/// on the reasoning that receiver error is dominated by ionospheric delay and
/// satellite geometry and therefore drifts over minutes. That reasoning is
/// sound in general and false for this device at this sampling rate: measured
/// residual autocorrelation is −0.040 at 1 s, +0.035 at 5 s and −0.007 at 30 s,
/// which is zero. See PROGRESS.md under A1c-8.
///
/// It survives for [urbanCanyonKm] alone, which models a condition this
/// receiver was never measured in rather than one it was.
const double noiseCorrelationSeconds = 300;

/// The one surviving 15 m fixture, and it earns its place on a narrow ground.
///
/// Every other correlated-error fixture is gone. They were calibrated to a
/// noise process the device does not produce, twice, and PROGRESS.md A1c-8 is
/// the record of that. Keeping them would mean keeping budgets that describe
/// nothing.
///
/// This one is kept because it is the only fixture that tests the specific
/// failure the measurement identified as *possible but unverified*: **a
/// receiver whose reported accuracy does not describe its error.** It carries
/// 15 m of correlated multipath error while reporting the same 2.5 m median the
/// device reports when it is behaving. Every filter here that reads
/// `accuracyM` — the threshold, the kinematic bound's slack, the Kalman gain —
/// is being lied to, which is exactly what a dense urban canyon does and what
/// the 23 Aug walk, on open road, could not show.
///
/// Two consequences follow from the reported accuracy being plausible, and both
/// are the point. The accuracy filter cannot save the pipeline here, because
/// nothing looks wrong. And the smoother gives each fix a small variance and
/// therefore a large gain, so it believes the drift.
///
/// **Not used for any accuracy budget.** It is asked to prove the pipeline does
/// not crash, does not produce an absurd or negative distance, and still lands
/// closer to the truth than the raw fixes did. Nothing more, because there is
/// no ground truth from a real urban canyon to calibrate a budget against, and
/// inventing one is the mistake this whole section exists to stop repeating.
SyntheticTrack urbanCanyonKm({int seed = 20260820}) => SyntheticTrack(
  name: 'straight 1 km, 15 m correlated multipath, reported as 2.5 m',
  fixes: _straightNorth(
    distanceM: 1000,
    noiseSigmaM: 15,
    noiseCorrelationSeconds: noiseCorrelationSeconds,
    accuracyM: gpsAccuracyMedianM,
    accuracyP90M: gpsAccuracyP90M,
    seed: seed,
  ),
  groundTruthDistanceM: 1000,
  // Identical timestamps, no noise: where the runner actually was.
  truth: _straightNorth(
    distanceM: 1000,
    accuracyM: gpsAccuracyMedianM,
    accuracyP90M: gpsAccuracyP90M,
  ),
);

/// The second stress fixture: the measured process, six times too big.
///
/// The brief was to keep one 15 m fixture. This is a second, and it earns its
/// place by testing a different mechanism from [urbanCanyonKm] rather than a
/// different number. That one lies about its accuracy while drifting slowly;
/// this one is honest about being in bad conditions and jumps.
///
/// It is no longer "pathological" in kind, which is why it is no longer called
/// that. When it was written, independent per-fix error was believed to be
/// something no receiver produced — the whole suite modelled correlated drift.
/// The device produces exactly this process, at ~2.5 m. So this is now the
/// *same* process at six times the magnitude: a receiver under a railway
/// bridge, rather than a receiver behaving in some unphysical way.
///
/// Reported accuracy is 8 m, not the 15 m it once carried. At 15 m the accuracy
/// filter rejects every fix and the fixture silently stops testing anything
/// downstream of it, while still passing. 8 m is the worst a fix can report and
/// still be treated as GPS, which is the honest way to say "bad conditions,
/// admitted anyway".
///
/// A robustness case, never an accuracy one. It must not crash, must not return
/// a negative or absurd distance, and must land closer to the truth than the
/// raw fixes did. That is all it is asked.
SyntheticTrack severeWhiteNoiseKm({int seed = 20260820}) => SyntheticTrack(
  name: 'straight 1 km with 15 m white error, reported as 8 m',
  fixes: _straightNorth(
    distanceM: 1000,
    noiseSigmaM: 15,
    // Explicitly zero, against a default that is now 20 s. This is the one
    // fixture in the suite whose error really is redrawn every second, and it
    // is here as the contrast that proves the generator's correlation works at
    // all — not as a claim that any receiver behaves this way.
    noiseCorrelationSeconds: 0,
    accuracyM: gpsAccuracyMaxM,
    seed: seed,
  ),
  groundTruthDistanceM: 1000,
  truth: _straightNorth(distanceM: 1000, accuracyM: gpsAccuracyMaxM),
);

/// 1 km with three scattered fixes reporting 80 m accuracy.
///
/// Spread rather than consecutive, so the test proves three independent
/// rejections rather than one burst that a single off-by-one could produce.
/// Each bad fix is also physically displaced 60 m east: a fix that is rejected
/// for its accuracy but happens to be in the right place proves nothing.
SyntheticTrack kmWithInaccurateFixes() {
  const badSteps = {100, 200, 300};
  return SyntheticTrack(
    name: '1 km with 3 fixes at 80 m accuracy',
    fixes: _straightNorth(
      distanceM: 1000,
      perStep: (step, north, east) => badSteps.contains(step)
          ? (north: north, east: east + 60, accuracyM: 80.0)
          : null,
    ),
    groundTruthDistanceM: 1000,
  );
}

/// 1 km with a single fix flung 500 m up the track and back again, 1 s apart.
///
/// 500 m/s is 1800 km/h. No kinematic bound worth the name accepts it.
SyntheticTrack kmWithTeleport() => SyntheticTrack(
  name: '1 km with a 500 m teleport',
  fixes: _straightNorth(
    distanceM: 1000,
    perStep: (step, north, east) =>
        step == 180 ? (north: north + 500, east: east, accuracyM: null) : null,
  ),
  groundTruthDistanceM: 1000,
);

/// A 60 s silence, then a fix 400 m further on, then normal running.
///
/// The counterpart to [kmWithTeleport] and the reason the speed filter must be
/// a kinematic bound rather than a fixed threshold. 400 m in 60 s is 6.7 m/s —
/// fast, but a human ran it, and a receiver that loses lock under a bridge or
/// between buildings produces exactly this. A fixed per-fix cap throws the
/// distance away; a bound that scales with elapsed time keeps it.
SyntheticTrack gapThenGenuineDisplacement() {
  const beforeSteps = 200;
  const afterSteps = 100;
  const gapSeconds = 60;
  const gapDistanceM = 400.0;

  final fixes = _straightNorth(distanceM: beforeSteps * runSpeedMps);
  var north = beforeSteps * runSpeedMps;
  var time = fixes.last.timestamp;

  // The fix that reacquires, 60 s and 400 m later.
  north += gapDistanceM;
  time = time.add(const Duration(seconds: gapSeconds));
  // 8 m, not the 20 m this used to carry. A reacquiring receiver reports worse
  // accuracy than a settled one, but `maxAccuracyM` is now 9 — so a 20 m fix
  // is rejected as a network fix and the kinematic bound, which is what this
  // fixture exists to exercise, never runs on it. 8.1 m is the worst the GPS
  // stream was measured at; this sits just under it, which is the worst a fix
  // can be and still be one the pipeline should reason about.
  //
  // Worth naming as a real gap: the 23 Aug walk never lost lock, so what a
  // reacquiring fix on THIS receiver actually reports is unmeasured. If it
  // reports 20 m, the pipeline now throws away a genuine 400 m of travel.
  fixes.add(_fixAt(north: north, east: 0, time: time, accuracyM: 8));

  for (var step = 1; step <= afterSteps; step++) {
    fixes.add(
      _fixAt(
        north: north + step * runSpeedMps,
        east: 0,
        time: time.add(Duration(seconds: step)),
        accuracyM: 5,
      ),
    );
  }

  return SyntheticTrack(
    name: '60 s signal gap with a genuine 400 m displacement',
    fixes: fixes,
    groundTruthDistanceM:
        beforeSteps * runSpeedMps + gapDistanceM + afterSteps * runSpeedMps,
  );
}

/// Run 5 min, stand still 4 min, run 5 min.
///
/// The stationary stretch carries 1.5 m of jitter, because a receiver sitting
/// on a wall still wanders. Moving time must exclude those 240 s; elapsed time
/// must include them. A pipeline that measures speed on the raw track sees the
/// jitter as ~3 m/s and counts the whole stop as running.
SyntheticTrack standingStill({int seed = 41}) {
  const runSeconds = 300;
  const stillSeconds = 240;

  final fixes = _straightNorth(distanceM: runSeconds * runSpeedMps);
  const north = runSeconds * runSpeedMps;
  var time = fixes.last.timestamp;
  final rnd = math.Random(seed);

  // The same white error the walking fixtures carry, at the same measured
  // sigma. It used to be 1.5 m correlated, on the reasoning that a stationary
  // phone's error drifts rather than being re-rolled each second — which is
  // the reasoning the device falsified.
  //
  // This makes the stop fixtures markedly harder and that is correct: 2.5 m of
  // white error at 1 Hz across a four-minute stand is hundreds of metres of raw
  // path length going nowhere, and the pipeline meets exactly that. It is also
  // why the stop detector judges DISPLACEMENT over a window rather than summed
  // path — a stationary receiver under this model wanders ~3.5 m over 10 s,
  // which reads as 0.35 m/s against a 0.5 m/s threshold. That is under the
  // line, but not by much, and this fixture is where that margin is visible.
  final driftNorth = _Drift(rnd, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds);
  final driftEast = _Drift(rnd, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds);

  for (var second = 1; second <= stillSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + driftNorth.next(),
        east: driftEast.next(),
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
      ),
    );
  }
  time = fixes.last.timestamp;

  for (var second = 1; second <= runSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + second * runSpeedMps,
        east: 0,
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
      ),
    );
  }

  return SyntheticTrack(
    name: '5 min run, 4 min standing, 5 min run',
    fixes: fixes,
    // The jitter while stationary is noise around a fixed point, not travel.
    groundTruthDistanceM: 2 * runSeconds * runSpeedMps,
    groundTruthMovingSeconds: 2 * runSeconds,
  );
}

/// A clean kilometre in which two pairs of fixes arrive in the wrong order.
///
/// A1b left "does the plugin deliver monotonically" open: nothing sorts the
/// stream, and tracelet exposes a `timestampDriftMs` field, which is the author
/// acknowledging that arrivals can be late. This is the fixture for the
/// diagnostic that answers it.
///
/// The two swaps are deliberately different, and the difference is the whole
/// reason the report counts out-of-order arrivals separately from the
/// out-of-order *rejection*:
///
///   * the first pair is two ordinary fixes, so the late one is caught by the
///     clock test and filed under `FixRejection.outOfOrder`
///   * the second pair's late fix also reports 80 m accuracy, so it is thrown
///     out one filter earlier and the clock test never runs on it
///
/// A count taken from the rejections alone therefore sees one reordering where
/// two happened, and would report a receiver as well-behaved when it is not.
///
/// Deliberately NOT in [allTracks]: its timestamps do not increase, which is
/// the point, and the suite-wide monotonicity check must keep failing anything
/// else that looks like this.
SyntheticTrack outOfOrderArrivals() {
  const plainSwapStep = 100;
  const inaccurateSwapStep = 200;

  final fixes = _straightNorth(
    distanceM: 1000,
    perStep: (step, north, east) => step == inaccurateSwapStep
        ? (north: north, east: east, accuracyM: 80.0)
        : null,
  );

  for (final step in [plainSwapStep, inaccurateSwapStep]) {
    final index = leadInFixes - 1 + step;
    final earlier = fixes[index];
    fixes[index] = fixes[index + 1];
    fixes[index + 1] = earlier;
  }

  return SyntheticTrack(
    name: '1 km with two pairs of fixes delivered out of order',
    fixes: fixes,
    groundTruthDistanceM: 1000,
  );
}

/// 5.5 km, for splits: five whole kilometres and a 500 m remainder.
SyntheticTrack fiveAndAHalfKm() => SyntheticTrack(
  name: '5.5 km at 6:00/km',
  fixes: _straightNorth(distanceM: 5500),
  groundTruthDistanceM: 5500,
);

// ---------------------------------------------------------------------------
// Walking
//
// Every fixture above this line is a runner at 2.78 m/s arriving at exactly
// 1 Hz. The device test that prompted these was a walk at roughly a quarter of
// that speed, delivering 0.78 fixes per second. Both of those are inputs the
// pipeline has never been measured against, and both scale things it depends
// on: displacement per fix falls by four, and every dt-scaled term — the
// kinematic bound, the Kalman prediction step, the moving-time window — is
// being asked to work at intervals it has never seen.
//
// Each fixture below changes exactly ONE thing from an existing one, so that a
// budget it misses has a single candidate cause rather than three.
// ---------------------------------------------------------------------------

/// A slow walk, in metres per second.
///
/// 1.0 m/s is 16:40/km. Kept as the pessimistic speed: the error envelope does
/// not shrink when you walk slower, so the displacement between fixes falls
/// while the noise stays put and every step's signal-to-noise ratio drops with
/// it. A filter that cannot separate motion from noise here is not broken; it
/// is being asked a question with less information in it.
const double walkSpeedMps = 1;

/// The measured walk, at whatever speed and error you ask for.
///
/// The builder behind the primary fixtures. Defaults are the measured GPS
/// model — see [gpsNoiseSigmaM] — and the noise is WHITE, which is the
/// correction that this whole rebuild exists to make. Passing a
/// `correlationSeconds` is possible and is what [urbanCanyonKm] does; nothing
/// else should.
SyntheticTrack walkingKm({
  int seed = 20260821,
  double noiseSigmaM = gpsNoiseSigmaM,
  double speedMps = walkSpeedMps,
  double accuracyM = gpsAccuracyMedianM,
  double? accuracyP90M = gpsAccuracyP90M,
  double correlationSeconds = gpsNoiseCorrelationSeconds,
}) => SyntheticTrack(
  name:
      'straight 1 km walked at ${speedMps.toStringAsFixed(1)} m/s, '
      '${_sigmaLabel(noiseSigmaM)} m GPS error over '
      '${correlationSeconds.toStringAsFixed(0)} s',
  fixes: _straightNorth(
    distanceM: 1000,
    speedMps: speedMps,
    noiseSigmaM: noiseSigmaM,
    noiseCorrelationSeconds: correlationSeconds,
    accuracyM: accuracyM,
    accuracyP90M: accuracyP90M,
    seed: seed,
  ),
  groundTruthDistanceM: 1000,
  truth: _straightNorth(
    distanceM: 1000,
    speedMps: speedMps,
    accuracyM: accuracyM,
    accuracyP90M: accuracyP90M,
  ),
);

/// [walkingKm], delivered at an irregular cadence. Nothing else differs.
///
/// Both the kinematic bound and the Kalman prediction step scale with dt, and
/// at exactly 1 Hz every power of dt is also 1 — so a term that should be dt²,
/// dt³ or dt⁴ cannot be told apart from one that is correct. This is the
/// fixture in which that would show.
///
/// Worth stating against the measurement: the device's GPS stream arrives at
/// exactly 1.000 s, p10 to p90. The irregular cadence the diagnostics showed
/// was the network stream interleaving, not the receiver wandering. So this
/// fixture now models a robustness case rather than the operating point —
/// a receiver that goes quiet under a bridge — and [measuredWalkKm] is what
/// the budgets are set against.
SyntheticTrack variableCadenceWalk({
  int seed = 20260821,
  int cadenceSeed = 8675309,
  double noiseSigmaM = gpsNoiseSigmaM,
  double speedMps = walkSpeedMps,
  double accuracyM = gpsAccuracyMedianM,
  double? accuracyP90M = gpsAccuracyP90M,
}) {
  // 1000 m at the walking speed, so the two cadence fixtures cover the same
  // ground rather than the same time and their totals are comparable.
  final durationSeconds = (1000 / speedMps).round();
  return SyntheticTrack(
    // The error size is in the name because there are now two of these at the
    // same speed and they differ only in it. A fixture whose name does not
    // distinguish it from another is a baseline waiting to be pinned twice.
    name:
        'walk at ${speedMps.toStringAsFixed(1)} m/s delivered at an '
        'irregular cadence, ${_sigmaLabel(noiseSigmaM)} m correlated GPS error',
    fixes: _irregularNorth(
      speedMps: speedMps,
      durationSeconds: durationSeconds,
      noiseSigmaM: noiseSigmaM,
      accuracyM: accuracyM,
      accuracyP90M: accuracyP90M,
      seed: seed,
      cadenceSeed: cadenceSeed,
    ),
    groundTruthDistanceM: speedMps * durationSeconds,
    truth: _irregularNorth(
      speedMps: speedMps,
      durationSeconds: durationSeconds,
      accuracyM: accuracyM,
      accuracyP90M: accuracyP90M,
      seed: seed,
      cadenceSeed: cadenceSeed,
    ),
  );
}

/// [standingStill], at walking pace and with a three-minute stop.
///
/// The controlled test of the stop detector at the speed it will actually meet.
/// `minMovingSpeedMps` is 0.5 and this walk is 1.0, so the margin between
/// walking and "stopped" is a factor of two — where for a runner it was five
/// and a half. The residual wander of a smoothed track from a stationary
/// receiver has not got any smaller.
///
/// Clean while walking and 1.5 m of correlated drift while standing, exactly as
/// [standingStill] does it, so the only variable is the pace.
SyntheticTrack walkWithStop({int seed = 41, double speedMps = walkSpeedMps}) {
  const walkSeconds = 300;
  const stillSeconds = 180;

  final fixes = _straightNorth(
    distanceM: walkSeconds * speedMps,
    speedMps: speedMps,
  );
  final north = walkSeconds * speedMps;
  var time = fixes.last.timestamp;
  final rnd = math.Random(seed);

  final driftNorth = _Drift(rnd, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds);
  final driftEast = _Drift(rnd, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds);

  for (var second = 1; second <= stillSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + driftNorth.next(),
        east: driftEast.next(),
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
      ),
    );
  }
  time = fixes.last.timestamp;

  for (var second = 1; second <= walkSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + second * speedMps,
        east: 0,
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
        speedMps: speedMps,
      ),
    );
  }

  return SyntheticTrack(
    name:
        'walk 5 min at ${speedMps.toStringAsFixed(1)} m/s, stand 3 min, '
        'walk 5 min',
    fixes: fixes,
    groundTruthDistanceM: 2 * walkSeconds * speedMps,
    groundTruthMovingSeconds: 2 * walkSeconds,
  );
}

/// Walk, stand still for three minutes, walk on — with the stop's edges
/// carried in [SyntheticTrack.stopWindows] so its cost can be measured alone.
///
/// **The A1c-J fixture.** The 7 Sep Zurich walk was the first real capture with
/// substantial stops, and it showed 475 m of its 4529 m raw accepted path
/// accumulating while the detector said stopped — ~1000 fixes at 3.79 m
/// accuracy, each adding a small positive step to a sum that never cancels.
/// This reproduces that shape indoors.
///
/// The walker's true displacement across the stop is exactly zero, so a test
/// can read cumulative distance at both edges, subtract, and get the phantom
/// distance on its own — no smoothing error from the walking mixed in, and no
/// need to reason about a total.
///
/// Under the measured noise model, not a gentler one: 2.5 m per axis correlated
/// over 20 s at 1 Hz, which is what the device actually produces and what makes
/// a stationary receiver wander convincingly enough to fool a path-length sum.
SyntheticTrack walkStandWalk({int seed = 20260907}) {
  const walkSeconds = 120;
  const stillSeconds = 180;
  const speedMps = walkSpeedMps;

  final fixes = _straightNorth(
    distanceM: walkSeconds * speedMps,
    speedMps: speedMps,
  );
  const north = walkSeconds * speedMps;

  final stopFrom = fixes.last.timestamp;
  var time = stopFrom;
  final rnd = math.Random(seed);
  final driftNorth = _Drift(rnd, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds);
  final driftEast = _Drift(rnd, gpsNoiseSigmaM, gpsNoiseCorrelationSeconds);

  for (var second = 1; second <= stillSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + driftNorth.next(),
        east: driftEast.next(),
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
      ),
    );
  }
  final stopTo = fixes.last.timestamp;
  time = stopTo;

  for (var second = 1; second <= walkSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + second * speedMps,
        east: 0,
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
        speedMps: speedMps,
      ),
    );
  }

  return SyntheticTrack(
    name: 'walk 2 min, stand 3 min, walk 2 min',
    fixes: fixes,
    groundTruthDistanceM: 2 * walkSeconds * speedMps,
    groundTruthMovingSeconds: 2 * walkSeconds,
    stopWindows: [(from: stopFrom, to: stopTo)],
  );
}

/// Genuine movement slow enough that the stop detector calls it stationary.
///
/// **The regression the A1c-J design exists to prevent, and the reason the fix
/// is a frozen anchor rather than skipping accumulation during stops.** The
/// detector judges displacement over a 10 s window against 0.5 m/s. A shuffle
/// at 0.3 m/s clears neither, so every window inside the slow stretch reads as
/// stopped — and a pipeline that simply excluded stopped fixes would throw away
/// 54 m the walker really covered.
///
/// Deliberately noise-free, unlike [walkStandWalk]. The premise has to be
/// airtight: at 0.3 m/s the displacement over any 10 s window is exactly 3 m,
/// so the misclassification is certain rather than probable. Adding the
/// measured error would make some windows cross the threshold and the fixture
/// would be testing a mixture instead of the case it is named for. Realism
/// under noise is the other fixture's job.
SyntheticTrack slowWalkMisreadAsStopped() {
  const briskSeconds = 60;
  const slowSeconds = 180;
  const slowSpeedMps = 0.3;
  const speedMps = walkSpeedMps;

  final fixes = _straightNorth(
    distanceM: briskSeconds * speedMps,
    speedMps: speedMps,
  );
  var north = briskSeconds * speedMps;
  var time = fixes.last.timestamp;

  for (var second = 1; second <= slowSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + second * slowSpeedMps,
        east: 0,
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
        speedMps: slowSpeedMps,
      ),
    );
  }
  north += slowSeconds * slowSpeedMps;
  time = fixes.last.timestamp;

  for (var second = 1; second <= briskSeconds; second++) {
    fixes.add(
      _fixAt(
        north: north + second * speedMps,
        east: 0,
        time: time.add(Duration(seconds: second)),
        accuracyM: 5,
        speedMps: speedMps,
      ),
    );
  }

  return SyntheticTrack(
    name: 'walk 1 min, shuffle 3 min at 0.3 m/s, walk 1 min',
    fixes: fixes,
    groundTruthDistanceM:
        2 * briskSeconds * speedMps + slowSeconds * slowSpeedMps,
  );
}

// ---------------------------------------------------------------------------
// The measured operating point
//
// Everything below is derived from `captures/2026-08-23_1610m.ndjson`, a walk
// of a route whose length was measured on the ground. Nothing below is chosen.
//
// The suite has been calibrated twice against invented noise models — 15 m
// correlated, then 2.5 m correlated — and the device produced neither. What it
// produces is written down in PROGRESS.md under A1c-7 and A1c-8, and the short
// version is: two interleaved streams, and the GPS one carries ~2.5 m per-axis
// UNCORRELATED error at exactly 1.000 s.
//
// The rule this section exists to enforce: a fixture parameter here is a
// measurement with a line number in PROGRESS.md, or it does not belong here.
// ---------------------------------------------------------------------------

/// Median horizontal accuracy the GPS stream reports, in metres.
///
/// Measured over the 1051 whole-second fixes of the 23 Aug capture.
const double gpsAccuracyMedianM = 2.5;

/// p90 of the same, in metres. Median and p90 together pin the log-normal that
/// [_ReportedAccuracy] draws from.
const double gpsAccuracyP90M = 3.4;

/// Worst accuracy the GPS stream ever reported, in metres.
///
/// The lower edge of the gap that `TrackProcessor.maxAccuracyM` sits in. The
/// network stream's best fix was 9.60 m, so nothing in between exists.
const double gpsAccuracyMaxM = 8.1;

/// True per-axis positional error of the GPS stream, in metres.
///
/// The old version of this constant carried an ASSUMPTION tag: that the
/// receiver's reported accuracy was honest, checkable only against a route of
/// known length. That route has now been walked and the magnitude survives —
/// but the *shape* does not. Within the GPS stream, reported accuracy barely
/// predicts per-fix error at all (Spearman +0.338; the 2.0–2.5 m bin has a p90
/// residual of 5.13 m). [urbanCanyonKm] is what keeps that failure mode tested.
const double gpsNoiseSigmaM = 2.5;

/// Correlation time of the GPS error, in seconds. **~20 s, and this number has
/// been wrong twice.**
///
/// It was 300 s, guessed from ionospheric physics. It was then briefly reported
/// as ZERO, and that reading was an artefact of how it was measured, twice over:
/// the leave-one-out estimator fits a quadratic over ±5 s and subtracts it, so
/// it removes slowly-varying error by construction and can only ever call the
/// remainder white; and the decimation test that appeared to confirm it was run
/// over the accepted set, which was 88 network fixes at the time and dominated
/// by them.
///
/// Measured properly, on the GPS stream alone, with a structure function —
/// E[|p(t+τ) − p(t)|²] = (v·τ)² + D(τ), which needs no truth and no fitted
/// baseline, so neither blind spot applies:
///
/// | lag | 1 s | 2 s | 3 s | 5 s | 8 s |
/// |---|---|---|---|---|---|
/// | D(τ), m² | 1.18 | 2.96 | 4.96 | 8.69 | 12.27 |
///
/// D rising from near zero is exactly what white error does not do; white error
/// is flat at 4σ² from the first lag. Beyond ~12 s the walk's own loop geometry
/// makes (v·τ)² an overestimate of real displacement and D goes negative, so
/// only the short lags are usable — which is enough, because the 1 s value is
/// what drives accumulated path length.
///
/// σ = 2.5 m with τ₀ = 20 s predicts an rms inter-fix step of 1.89 m against a
/// measured 1.88 m, and a raw path length of ~1766 m against a measured 1766 m.
/// A white σ = 2.5 m model predicts 5491 m, or +241%, on a walk where the GPS
/// stream actually produced +9.7%.
///
/// The error is therefore strongly correlated at the sampling rate — ρ ≈ 0.95
/// between consecutive fixes — and the +205% raw over-report that started all
/// of this was the network stream, not the GPS one.
const double gpsNoiseCorrelationSeconds = 20;

/// **The primary distance fixture.** A brisk walk under the measured GPS model.
///
/// 1.6 m/s, exactly 1.000 s between fixes, 2.5 m per-axis error correlated
/// over 20 s, reported accuracy log-normal about a 2.5 m median. This is what
/// the pipeline is asked to be accurate on.
SyntheticTrack measuredWalkKm({int seed = 20260822}) =>
    // correlationSeconds is left at its default, which IS the measured value:
    // gpsNoiseCorrelationSeconds, 20 s. Passing it here would be redundant
    // rather than emphatic.
    //
    // Both lines above said "white" and "i.e. zero" until 1 Sep 2026. That was
    // the reading A1c-8 retracted — an estimator that fitted a quadratic over
    // ±5 s and subtracted it could only ever call the remainder white — and
    // the constant has been 20 since the rebuild. The comment simply did not
    // follow. `noise_process_test` now recovers 2.5 m and 20 s back out of
    // this fixture, so the claim is checked rather than asserted.
    walkingKm(seed: seed, speedMps: briskWalkSpeedMps);

/// The measured model at an irregular cadence.
///
/// A robustness case rather than the operating point — see the note on
/// [variableCadenceWalk]. The device's GPS stream is metronomic; what looked
/// irregular in the first diagnostics was the network stream interleaving.
SyntheticTrack measuredVariableCadenceWalk({int seed = 20260822}) =>
    variableCadenceWalk(seed: seed, speedMps: briskWalkSpeedMps);

// ---------------------------------------------------------------------------
// The second stream
//
// No fixture modelled this and it is the single largest thing the device does
// that the suite could not see. Android's fused provider interleaves wifi/cell
// trilateration with GPS: 154 fixes of 1205 on the 23 Aug walk, at ~6.8 s,
// reporting a 26.82 m median accuracy, tracing 6171 m across a 1610 m route.
// ---------------------------------------------------------------------------

/// Median accuracy the network stream reports, in metres.
const double networkAccuracyMedianM = 27;

/// p90 of the same. The tail is enormous and the fixture must have it: the
/// capture's worst network fix reported exactly 200.00 m.
const double networkAccuracyP90M = 98;

/// True per-axis error of a network fix, in metres.
///
/// From the measured residuals of the fixes reporting 10–50 m accuracy: median
/// 2D residual 18.45 m, which is ~16 m per axis. Deliberately SMALLER than the
/// 27 m those fixes report, because that mismatch is real and is half of why
/// the accuracy field works as a stream label while failing as an error
/// estimate.
const double networkNoiseSigmaM = 16;

/// Seconds between network fixes. Measured median 6.82 s.
const double networkIntervalSeconds = 6.8;

/// The measured walk with the network stream interleaved into it.
///
/// The fixture that would have caught the over-report in one run. The GPS
/// fixes are [measuredWalkKm]'s, untouched — same timestamps, same positions,
/// same ground truth — and the network fixes are added between them, on
/// deliberately FRACTIONAL timestamps, because that is the discriminator the
/// real streams differ by and the pipeline's behaviour must not depend on it.
///
/// Ground truth is unchanged at 1000 m. Every metre the network stream adds is
/// a metre the pipeline invented, which is what makes this fixture scoreable:
/// a run that comes out long here has accepted fixes it should have rejected,
/// and no other explanation is available.
SyntheticTrack walkWithNetworkStream({
  int seed = 20260822,
  int netSeed = 5150,
}) {
  final gps = measuredWalkKm(seed: seed);
  final rnd = math.Random(netSeed);
  final driftNorth = _Drift(rnd, networkNoiseSigmaM, 0);
  final driftEast = _Drift(rnd, networkNoiseSigmaM, 0);
  final reported = _ReportedAccuracy(
    networkAccuracyMedianM,
    networkAccuracyP90M,
    netSeed,
  );

  final start = gps.fixes.first.timestamp;
  final spanSeconds =
      gps.fixes.last.timestamp.difference(start).inMilliseconds / 1000;

  final network = <RawFix>[];
  // Offset off the whole second on purpose, and never ON one: a network fix
  // landing at .000 would be indistinguishable from a GPS fix by the only
  // field that separates them on the device.
  for (
    var t = networkIntervalSeconds;
    t < spanSeconds;
    t += networkIntervalSeconds
  ) {
    final atMs = (t * 1000).round();
    if (atMs % 1000 == 0) continue;
    network.add(
      _fixAt(
        north: briskWalkSpeedMps * t + driftNorth.next(),
        east: driftEast.next(),
        time: start.add(Duration(milliseconds: atMs)),
        accuracyM: reported.next(),
        // The device's network fixes report a Doppler speed of 0.0 far more
        // often than not — the no-Doppler sentinel. 111 of them on the walk.
        speedMps: 0,
      ),
    );
  }

  final merged = [...gps.fixes, ...network]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  return SyntheticTrack(
    name:
        'measured walk with ${network.length} interleaved network fixes '
        'at ${networkAccuracyMedianM.toStringAsFixed(0)} m',
    fixes: merged,
    groundTruthDistanceM: gps.groundTruthDistanceM,
    truth: gps.truthFixes,
  );
}

/// How long a delayed fix waits before it is delivered, in seconds.
///
/// Under the 3 s buffer horizon on purpose: these are the fixes a reorder
/// buffer is supposed to recover, and a fixture whose delays straddled the
/// horizon could not say whether a survivor was recovered or merely lucky.
const double lateArrivalSeconds = 2.5;

/// How long the few hopeless ones wait.
///
/// Twelve seconds, not five. Five is not reliably hopeless: the release rule
/// compares against the newest TIMESTAMP delivered, not against wall-clock
/// arrival, so if the fixes either side of the gap were themselves running
/// late the buffer has not yet moved past a five-second-old one and quietly
/// recovers it. Measured: two of four survived. A fixture whose planted defect
/// is only usually a defect cannot support an exact count.
const double hopelessArrivalSeconds = 12;

/// The realistic walk, delivered out of order.
///
/// The mechanism the device showed and no fixture modelled: 119 arrivals out
/// of sequence on a 48-minute walk, 106 of them discarded outright. Nothing in
/// the delivery path sorts anything, and tracelet exposes a `timestampDriftMs`
/// field, which is the author acknowledging that arrivals run late.
///
/// Modelled as delivery latency rather than as a shuffle, because that is what
/// actually happens: a fix is *held somewhere* and handed over late. One in
/// five waits [lateArrivalSeconds]; [hopelessLateFixes] of them wait
/// [hopelessArrivalSeconds] and are beyond saving.
///
/// **The ground truth is untouched.** Exactly the same fixes, at exactly the
/// same timestamps, covering exactly the same 1000 m — only the order they are
/// handed over in changes. That is what makes any difference in the measured
/// distance attributable to the ordering and to nothing else.
///
/// Deliberately NOT in [allTracks]: its timestamps do not increase, which is
/// the entire point, and the suite-wide monotonicity check must keep failing
/// anything else that looks like this.
SyntheticTrack shuffledArrivalWalk({
  int seed = 20260822,
  int arrivalSeed = 31337,
}) {
  final ordered = measuredVariableCadenceWalk(seed: seed);
  final rnd = math.Random(arrivalSeed);

  // Which fixes are hopeless, chosen up front so the count is exact rather
  // than a property of how the draws happened to fall.
  final hopeless = <int>{};
  while (hopeless.length < hopelessLateFixes) {
    // Away from the ends: a hopeless fix among the cold-start lead-in would be
    // discarded for being a cold-start fix and would prove nothing about the
    // horizon.
    hopeless.add(leadInFixes + 20 + rnd.nextInt(ordered.fixes.length - 60));
  }

  // Arrival time per fix: its own timestamp plus however long it was held.
  final held = <({double at, int index})>[];
  for (var i = 0; i < ordered.fixes.length; i++) {
    final delay = hopeless.contains(i)
        ? hopelessArrivalSeconds
        : (rnd.nextDouble() < 0.2 ? lateArrivalSeconds : 0.0);
    held.add((
      at:
          ordered.fixes[i].timestamp
                  .difference(ordered.fixes.first.timestamp)
                  .inMilliseconds /
              1000 +
          delay,
      index: i,
    ));
  }

  // Stable in the ties, so two fixes handed over in the same millisecond keep
  // the order the receiver produced them in.
  held.sort((a, b) {
    final byArrival = a.at.compareTo(b.at);
    return byArrival != 0 ? byArrival : a.index.compareTo(b.index);
  });

  return SyntheticTrack(
    name: 'realistic walk delivered out of order, up to 2.5 s late',
    fixes: [for (final entry in held) ordered.fixes[entry.index]],
    groundTruthDistanceM: ordered.groundTruthDistanceM,
    truth: ordered.truthFixes,
  );
}

/// How many fixes in [shuffledArrivalWalk] arrive too late to be saved.
const int hopelessLateFixes = 4;

/// How many extra fixes a burst adds after the one that triggered it.
const int burstExtraFixes = 2;

/// The realistic walk, with bursts of fixes arriving milliseconds apart.
///
/// Isolates one mechanism and nothing else. The device's accepted intervals
/// reach a minimum of 0.03 s against a delivered p10 of 0.28 s, and a smoothed
/// step of noise size over near-zero elapsed time is what produces a 13.63 m/s
/// reading on a 1.46 m/s walk. Every step of that is arithmetic; none of it has
/// ever been given to the pipeline.
///
/// The true path is unchanged: position comes from elapsed time, so a burst
/// samples the same walk more densely and covers no extra ground. Ground truth
/// stays 1000 m, which is what makes any excess attributable to the cadence.
///
/// Deliberately NOT modelling out-of-order arrival. This fixture asks the
/// narrower question — what does a sub-second interval cost by itself — so that
/// the reorder buffer is measured against a known baseline rather than against
/// two changes at once.
SyntheticTrack burstCadenceWalk({
  int seed = 20260822,
  int cadenceSeed = 8675309,
}) {
  const durationSeconds = 625; // 1000 m at 1.6 m/s.
  return SyntheticTrack(
    name: 'brisk walk with sub-100 ms fix bursts, 2.5 m correlated GPS error',
    fixes: _irregularNorth(
      speedMps: briskWalkSpeedMps,
      durationSeconds: durationSeconds,
      noiseSigmaM: gpsNoiseSigmaM,
      accuracyM: gpsAccuracyMedianM,
      accuracyP90M: gpsAccuracyP90M,
      seed: seed,
      cadenceSeed: cadenceSeed,
      cadenceMs: _burstCadence(),
    ),
    groundTruthDistanceM: briskWalkSpeedMps * durationSeconds,
    truth: _irregularNorth(
      speedMps: briskWalkSpeedMps,
      durationSeconds: durationSeconds,
      accuracyM: gpsAccuracyMedianM,
      seed: seed,
      cadenceSeed: cadenceSeed,
      // A fresh closure, so the burst state starts where the noisy track's did.
      // Same seed and same starting state means the same interval sequence,
      // which is what puts the twin on identical timestamps.
      cadenceMs: _burstCadence(),
    ),
  );
}

/// How far the single bad fix is thrown, in metres.
///
/// Modelled on the spur in the reference track from the device test: a long
/// straight out-and-back down a road that was never walked. One fix is all it
/// takes, and the length gets counted twice — out and back — so a 250 m spur
/// adds 500 m to a walk that was 3.5 km.
const double spurLengthM = 250;

// ---------------------------------------------------------------------------
// Turns
//
// Every fixture above this line is a straight line due north. Not one contains
// a corner. That was not carelessness — along a meridian the spherical
// distance is exact, which is what makes `groundTruthDistanceM` a true value
// rather than an approximation sharing an error with the code under test — but
// it means a Kalman smoother's corner-cutting, the one mechanism that could
// SHORTEN a recorded track, was untested by the entire suite while every bias
// the suite could measure ran long.
//
// The ground truth here is a sum of leg lengths in the local metric frame. It
// is still verified independently, against summed great-circle distances along
// the noise-free twin, in `synthetic_track_test.dart`.
// ---------------------------------------------------------------------------

/// A brisk walk, in metres per second.
///
/// 1.6 m/s is 10:25/km. Taken from the device test rather than guessed: 3.46 km
/// over 35:41 of moving time is 1.62 m/s. The earlier 1.0 m/s figure came from
/// a pace chart that included stopped time, which is a different quantity.
const double briskWalkSpeedMps = 1.6;

/// A 728 m rectangular circuit: four 90-degree turns at walking pace.
///
/// 200 m north, 150 m east, 200 m south, 150 m west, then 28 m north again so
/// the fourth corner is a corner rather than the end of the track. A smoother
/// that lags through a turn cuts the diagonal, and four right angles is enough
/// for the loss to be measurable without being so many that it cannot be
/// attributed.
///
/// Noise-free by default, and that is the decisive form. Corner-cutting is a
/// property of the filter, not of the receiver: on a clean track every metre
/// missing from the total was removed by the smoother and by nothing else.
SyntheticTrack rectangleCircuit({
  double noiseSigmaM = 0,
  int seed = 20260822,
}) {
  const waypoints = [
    (north: 0.0, east: 0.0),
    (north: 200.0, east: 0.0),
    (north: 200.0, east: 150.0),
    (north: 0.0, east: 150.0),
    (north: 0.0, east: 0.0),
    (north: 28.0, east: 0.0),
  ];

  return _pathTrack(
    name: noiseSigmaM == 0
        ? '728 m rectangular circuit, four 90-degree turns, no noise'
        : '728 m rectangular circuit, four 90-degree turns, '
              '${noiseSigmaM.toStringAsFixed(0)} m correlated error',
    waypoints: waypoints,
    speedMps: briskWalkSpeedMps,
    noiseSigmaM: noiseSigmaM,
    seed: seed,
  );
}

/// The control for the turning fixtures: the same walk with no turns in it.
///
/// 728 m straight, at the same speed, the same accuracy, through the same
/// builder as [rectangleCircuit] — differing in one thing only, whether the
/// path bends. Without it, any error measured on the circuit could be the
/// speed, the reported accuracy, the builder's interpolation or the turns, and
/// there would be no way to say which.
SyntheticTrack straightControlWalk({
  double noiseSigmaM = 0,
  int seed = 20260822,
}) => _pathTrack(
  name: '728 m straight at 1.6 m/s, no turns (control)',
  waypoints: const [
    (north: 0.0, east: 0.0),
    (north: 728.0, east: 0.0),
  ],
  speedMps: briskWalkSpeedMps,
  noiseSigmaM: noiseSigmaM,
  seed: seed,
);

/// A 272 m switchback: three hairpins, six turns, in quick succession.
///
/// The harder case, and deliberately harsher than a street corner. Each pair
/// of 90-degree turns is separated by a 10 m jog, so the walker reverses
/// direction inside about six seconds — less than the smoother's own settling
/// time. A filter carrying a velocity state predicts straight ahead through
/// exactly this and has to be dragged back by the measurements.
SyntheticTrack switchbackWalk({double noiseSigmaM = 0, int seed = 20260822}) {
  const waypoints = [
    (north: 0.0, east: 0.0),
    (north: 60.0, east: 0.0),
    (north: 60.0, east: 10.0),
    (north: 0.0, east: 10.0),
    (north: 0.0, east: 20.0),
    (north: 60.0, east: 20.0),
    (north: 60.0, east: 30.0),
    (north: -2.0, east: 30.0),
  ];

  return _pathTrack(
    name: noiseSigmaM == 0
        ? '272 m switchback, three hairpins, no noise'
        : '272 m switchback, three hairpins, '
              '${noiseSigmaM.toStringAsFixed(0)} m correlated error',
    waypoints: waypoints,
    speedMps: briskWalkSpeedMps,
    noiseSigmaM: noiseSigmaM,
    seed: seed,
  );
}

/// A 600 m walk with one fix flung [spurLengthM] to the east and back.
///
/// [kmWithTeleport] at walking pace, and deliberately far more plausible than
/// that fixture is. The teleport is 500 m in one second reporting a normal
/// accuracy, which nothing could mistake for a person. This one reports 8 m —
/// inside `maxAccuracyM`, so the accuracy filter cannot help — and is the shape
/// a real receiver produces when it briefly takes a reflected signal off a
/// building.
///
/// It reported 30 m before `maxAccuracyM` fell to 9. At 30 m the accuracy
/// filter would now catch it first and this fixture would silently stop testing
/// the kinematic bound while still passing, which is the worst way for a test
/// to rot.
///
/// The kinematic bound is what has to catch it, and the arithmetic is worth
/// stating: 250 m in 1 s is 250 m/s against a ceiling of 12, so it is caught by
/// a factor of twenty. That margin is large because the spur is large. It is
/// not evidence that a smaller spur would be caught.
SyntheticTrack walkWithSpurSpike() => SyntheticTrack(
  name: '600 m walk with a single ${spurLengthM.toInt()} m spur fix',
  fixes: _straightNorth(
    distanceM: 600,
    speedMps: walkSpeedMps,
    perStep: (step, north, east) => step == 300
        ? (north: north, east: east + spurLengthM, accuracyM: gpsAccuracyMaxM)
        : null,
  ),
  groundTruthDistanceM: 600,
);

/// Feed a whole track through a processor, the way a location stream would.
///
/// The pipeline is fed one fix at a time on a device, so tests feed it one fix
/// at a time too — a helper that handed it the whole list would be exercising
/// an API that does not exist in the app.
/// `recordFilterStates` is on for the processor this builds, because this is
/// the harness and A1c-14's backward pass is one of the things it has to be
/// able to run. The live recorder leaves it off — see [
/// TrackProcessor.recordFilterStates]. A caller passing its own `into` decides
/// for itself, and must ask for the tape if it intends to call
/// `smoothedTrack()`.
TrackProcessor replay(SyntheticTrack track, {TrackProcessor? into}) {
  final processor = into ?? TrackProcessor(recordFilterStates: true);
  track.fixes.forEach(processor.add);
  // The stream has ended, so the reorder buffer has nothing left to wait for.
  // A replay that skipped this would measure every fixture three seconds
  // short, which on a walk is a few metres and looks exactly like drift.
  processor.flush();
  return processor;
}

/// Every fixture, for suite-wide invariants.
List<SyntheticTrack> allTracks() => [
  straightKm(),
  urbanCanyonKm(),
  severeWhiteNoiseKm(),
  kmWithInaccurateFixes(),
  kmWithTeleport(),
  gapThenGenuineDisplacement(),
  standingStill(),
  fiveAndAHalfKm(),
  walkingKm(),
  variableCadenceWalk(),
  // variableCadenceWalk(speedMps: briskWalkSpeedMps) used to sit here. After
  // the rebuild it differs from measuredVariableCadenceWalk() only by seed, and
  // the two produce the same NAME — which is the collision this file warns
  // about two hundred lines up, and it duly pinned one baseline twice.
  measuredWalkKm(),
  measuredVariableCadenceWalk(),
  walkWithNetworkStream(),
  burstCadenceWalk(),
  walkWithStop(),
  walkWithStop(speedMps: briskWalkSpeedMps),
  walkWithSpurSpike(),
  rectangleCircuit(),
  switchbackWalk(),
  straightControlWalk(),
];

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

/// [leadInFixes] stationary fixes at the origin, then one fix per second
/// travelling due north at [speedMps] until [distanceM] is covered.
///
/// `perStep` plants a defect at a chosen fix: return a replacement position
/// and accuracy for that step, or null to leave it alone.
List<RawFix> _straightNorth({
  required double distanceM,
  double speedMps = runSpeedMps,
  double noiseSigmaM = 0,
  double noiseCorrelationSeconds = gpsNoiseCorrelationSeconds,
  double accuracyM = 5,
  double? accuracyP90M,
  int accuracySeed = 424242,
  int seed = 7,
  ({double north, double east, double? accuracyM})? Function(
    int step,
    double north,
    double east,
  )?
  perStep,
}) {
  final rnd = math.Random(seed);
  final steps = (distanceM / speedMps).round();
  final start = DateTime.utc(2026, 8, 20, 6);
  final fixes = <RawFix>[];

  // One error process per axis. They must be independent streams, not two
  // draws from one, or north and east would drift in lockstep.
  final driftNorth = _Drift(rnd, noiseSigmaM, noiseCorrelationSeconds);
  final driftEast = _Drift(rnd, noiseSigmaM, noiseCorrelationSeconds);
  final reported = _ReportedAccuracy.maybe(
    accuracyM,
    accuracyP90M,
    accuracySeed,
  );

  // Standing at the trailhead while the receiver settles.
  for (var i = 0; i < leadInFixes; i++) {
    fixes.add(
      _fixAt(
        north: driftNorth.next(),
        east: driftEast.next(),
        time: start.add(Duration(seconds: i)),
        accuracyM: reported?.next() ?? accuracyM,
        speedMps: 0,
      ),
    );
  }

  for (var step = 1; step <= steps; step++) {
    var north = step * speedMps + driftNorth.next();
    var east = driftEast.next();
    // Drawn before any override, so planting a defect does not shift every
    // later fix's accuracy onto a different draw.
    var stepAccuracy = reported?.next() ?? accuracyM;

    final override = perStep?.call(step, north, east);
    if (override != null) {
      north = override.north;
      east = override.east;
      stepAccuracy = override.accuracyM ?? accuracyM;
    }

    fixes.add(
      _fixAt(
        north: north,
        east: east,
        time: start.add(Duration(seconds: leadInFixes - 1 + step)),
        accuracyM: stepAccuracy,
        speedMps: speedMps,
      ),
    );
  }

  return fixes;
}

/// The same walk, delivered at intervals that are not one second.
///
/// Separate from [_straightNorth] rather than an option on it. Those two want
/// different primary arguments — a distance and a step count against a duration
/// and an interval stream — and folding both into one builder would mean every
/// existing fixture ran through a code path with a variable it does not use.
/// The eight fixtures above are the oracle for the whole milestone; they do not
/// get to change shape while a diagnosis is running.
///
/// The cadence has its own [cadenceSeed] and its own generator, deliberately.
/// Drawing intervals and noise from one stream would make the interval sequence
/// depend on whether noise was switched on — and the noise-free twin built for
/// [SyntheticTrack.truthAt] would land on different timestamps from the track
/// it is the truth for, which silently breaks every positional comparison.
List<RawFix> _irregularNorth({
  required double speedMps,
  required int durationSeconds,
  double noiseSigmaM = 0,
  double noiseCorrelationSeconds = gpsNoiseCorrelationSeconds,
  double accuracyM = 5,
  double? accuracyP90M,
  int accuracySeed = 424242,
  int seed = 7,
  int cadenceSeed = 8675309,
  int Function(math.Random rnd)? cadenceMs,
}) {
  final rnd = math.Random(seed);
  final cadence = math.Random(cadenceSeed);
  final interval = cadenceMs ?? _cadenceMs;
  final start = DateTime.utc(2026, 8, 20, 6);
  final fixes = <RawFix>[];

  final driftNorth = _Drift(rnd, noiseSigmaM, noiseCorrelationSeconds);
  final driftEast = _Drift(rnd, noiseSigmaM, noiseCorrelationSeconds);
  // Its own generator, for the same reason the cadence has one: drawing
  // accuracy from the noise stream would make the interval sequence and the
  // positions depend on whether accuracy varies, and the noise-free twin would
  // land on different timestamps from the track it is the truth for.
  final reported = _ReportedAccuracy.maybe(
    accuracyM,
    accuracyP90M,
    accuracySeed,
  );

  for (var i = 0; i < leadInFixes; i++) {
    fixes.add(
      _fixAt(
        north: driftNorth.next(),
        east: driftEast.next(),
        time: start.add(Duration(seconds: i)),
        accuracyM: reported?.next() ?? accuracyM,
        speedMps: 0,
      ),
    );
  }

  // Milliseconds as an int, never a float accumulation: a track of a thousand
  // fixes summing a fractional dt would drift off the ground truth by an amount
  // that grows with length, which is indistinguishable from the pipeline
  // drifting and would be blamed on it.
  const startMs = leadInFixes - 1;
  var elapsedMs = 0;
  final totalMs = durationSeconds * 1000;

  while (elapsedMs < totalMs) {
    final dtMs = math.min(interval(cadence), totalMs - elapsedMs);
    elapsedMs += dtMs;
    final seconds = elapsedMs / 1000;

    fixes.add(
      _fixAt(
        north: speedMps * seconds + driftNorth.next(dtSeconds: dtMs / 1000),
        east: driftEast.next(dtSeconds: dtMs / 1000),
        time: start.add(Duration(milliseconds: startMs * 1000 + elapsedMs)),
        accuracyM: reported?.next() ?? accuracyM,
        speedMps: speedMps,
      ),
    );
  }

  return fixes;
}

/// Walk a polyline through [waypoints] at [speedMps], one fix per second.
///
/// The primitive behind every fixture with a corner in it. Position comes from
/// distance travelled along the path, interpolated *within* the leg the walker
/// is on rather than snapped to a waypoint — so a turn happens at the moment
/// the geometry says it does, which is almost never on a whole second.
///
/// The turn times it records are exact for the same reason, and they are what
/// lets a test separate the metres lost at the corners from the metres lost
/// along the straights.
SyntheticTrack _pathTrack({
  required String name,
  required List<({double north, double east})> waypoints,
  required double speedMps,
  double noiseSigmaM = 0,
  double accuracyM = 8,
  int seed = 7,
}) {
  // Cumulative distance to each waypoint, and the total.
  final legStart = <double>[0];
  for (var i = 1; i < waypoints.length; i++) {
    final dNorth = waypoints[i].north - waypoints[i - 1].north;
    final dEast = waypoints[i].east - waypoints[i - 1].east;
    legStart.add(legStart.last + math.sqrt(dNorth * dNorth + dEast * dEast));
  }
  final total = legStart.last;

  final start = DateTime.utc(2026, 8, 20, 6);
  final rnd = math.Random(seed);
  final driftNorth = _Drift(rnd, noiseSigmaM, noiseCorrelationSeconds);
  final driftEast = _Drift(rnd, noiseSigmaM, noiseCorrelationSeconds);

  final fixes = <RawFix>[];
  final clean = <RawFix>[];

  void emit({
    required double north,
    required double east,
    required DateTime time,
    required double? reportedSpeed,
  }) {
    fixes.add(
      _fixAt(
        north: north + driftNorth.next(),
        east: east + driftEast.next(),
        time: time,
        accuracyM: accuracyM,
        speedMps: reportedSpeed,
      ),
    );
    // The noise-free twin, on identical timestamps. Built alongside rather
    // than by a second pass, because a second pass would have to reproduce the
    // same interpolation and the two could drift apart silently.
    clean.add(
      _fixAt(
        north: north,
        east: east,
        time: time,
        accuracyM: accuracyM,
        speedMps: reportedSpeed,
      ),
    );
  }

  // Standing at the start while the receiver settles.
  for (var i = 0; i < leadInFixes; i++) {
    emit(
      north: waypoints.first.north,
      east: waypoints.first.east,
      time: start.add(Duration(seconds: i)),
      reportedSpeed: 0,
    );
  }

  // Ceil, not round, and the difference is not cosmetic. 730 m at 1.6 m/s is
  // 456.25 steps; rounding to 456 stops the walker 0.4 m short of the final
  // waypoint, so the track quietly covers less than the perimeter it claims
  // and every measurement against that perimeter inherits the gap. Ceiling
  // plus the clamp below lands the last fix exactly on the endpoint, at the
  // cost of one final step that is shorter than a full second's travel —
  // which is what arriving somewhere looks like.
  final steps = (total / speedMps).ceil();
  for (var step = 1; step <= steps; step++) {
    final travelled = math.min(step * speedMps, total);

    // The leg the walker is on at this distance.
    var leg = 1;
    while (leg < legStart.length - 1 && legStart[leg] < travelled) {
      leg++;
    }
    final from = waypoints[leg - 1];
    final to = waypoints[leg];
    final legLength = legStart[leg] - legStart[leg - 1];
    final fraction = legLength <= 0
        ? 0.0
        : (travelled - legStart[leg - 1]) / legLength;

    emit(
      north: from.north + (to.north - from.north) * fraction,
      east: from.east + (to.east - from.east) * fraction,
      time: start.add(Duration(seconds: leadInFixes - 1 + step)),
      reportedSpeed: speedMps,
    );
  }

  return SyntheticTrack(
    name: name,
    fixes: fixes,
    groundTruthDistanceM: total,
    truth: clean,
    // Interior waypoints only: the first and last are the ends of the walk,
    // and nobody turns at them.
    turnTimes: [
      for (var i = 1; i < waypoints.length - 1; i++)
        start.add(
          Duration(
            microseconds: ((leadInFixes - 1 + legStart[i] / speedMps) * 1e6)
                .round(),
          ),
        ),
    ],
  );
}

/// One inter-fix interval, in milliseconds.
///
/// Roughly one in twelve is a 3–5 s gap; the rest are 0.8–1.7 s. The mixture
/// has a median near 1.3 s, which is the shape the device test showed: a
/// receiver asked for 1 Hz that mostly delivers a little slower and
/// occasionally goes quiet for several seconds.
int _cadenceMs(math.Random rnd) =>
    rnd.nextDouble() < 0.08 ? 3000 + rnd.nextInt(2001) : 800 + rnd.nextInt(901);

/// A cadence in which roughly one interval in ten opens a burst.
///
/// Stateful, so it is a closure rather than a function: a burst is a run of
/// [burstExtraFixes] further fixes at 30-100 ms, and "am I inside one" cannot be
/// answered from the random stream alone. The state is a counter and nothing
/// else, so two closures built from the same seed produce the same sequence,
/// which is what keeps a track and its noise-free twin on identical timestamps.
int Function(math.Random) _burstCadence() {
  var remaining = 0;
  return (rnd) {
    if (remaining > 0) {
      remaining--;
      return _burstIntervalMs(rnd);
    }
    if (rnd.nextDouble() < 0.10) {
      remaining = burstExtraFixes;
      return _burstIntervalMs(rnd);
    }
    return 800 + rnd.nextInt(901);
  };
}

int _burstIntervalMs(math.Random rnd) => 30 + rnd.nextInt(71);

RawFix _fixAt({
  required double north,
  required double east,
  required DateTime time,
  required double accuracyM,
  double? speedMps,
}) {
  final position = offsetMetres(north: north, east: east);
  return RawFix(
    latitude: position.lat,
    longitude: position.lon,
    timestamp: time,
    accuracyM: accuracyM,
    // A plausible flat-ground altitude. Nothing computes climb from it; it is
    // here so the column has realistic contents to store.
    altitudeM: 920,
    speedMps: speedMps,
  );
}

/// Displace the origin by metres, under the same spherical model
/// [haversineMetres] assumes, so ground truth and measurement agree exactly.
({double lat, double lon}) offsetMetres({
  required double north,
  required double east,
}) {
  final lat = originLat + _degrees(north / earthRadiusM);
  final lon =
      originLon +
      _degrees(east / (earthRadiusM * math.cos(lat * math.pi / 180)));
  return (lat: lat, lon: lon);
}

/// One axis of GPS error, as a first-order Gauss–Markov process.
///
/// `n[k] = ρ·n[k−1] + √(1−ρ²)·σ·w[k]`, with `ρ = exp(−dt/τ)`. The `√(1−ρ²)`
/// term is what keeps the standing deviation at σ regardless of τ, so changing
/// the correlation time changes how the error *moves* without widening the
/// ±15 m envelope it moves within.
///
/// τ = 0 collapses to independent per-fix noise, which is the pathological
/// fixture. The state starts from a stationary draw rather than from zero: a
/// real receiver is already somewhere in its error envelope when you press
/// start, and beginning at exactly zero would hand the pipeline a first fix
/// that is perfect.
class _Drift {
  _Drift(this._rnd, this._sigma, double correlationSeconds)
    : _correlationSeconds = correlationSeconds,
      _rho = correlationSeconds <= 0 ? 0 : math.exp(-1 / correlationSeconds) {
    _value = _sigma == 0 ? 0 : _gaussian(_rnd) * _sigma;
  }

  final math.Random _rnd;
  final double _sigma;
  final double _correlationSeconds;
  final double _rho;
  late double _value;

  /// Advance the error by [dtSeconds].
  ///
  /// The default of one second is the 1 Hz case every fixture but the
  /// irregular-cadence one uses, and takes the precomputed [_rho] unchanged so
  /// those tracks stay byte-identical. At any other interval rho has to be
  /// recomputed, because the correlation between two samples is a property of
  /// the time between them and not of their being adjacent — a 4 s gap treated
  /// as 1 s would leave the error more correlated across the gap than physics
  /// allows, which understates exactly the jumps this fixture exists to create.
  double next({double dtSeconds = 1}) {
    if (_sigma == 0) return 0;
    final rho = dtSeconds == 1
        ? _rho
        : (_correlationSeconds <= 0
              ? 0.0
              : math.exp(-dtSeconds / _correlationSeconds));
    return _value =
        rho * _value + math.sqrt(1 - rho * rho) * _gaussian(_rnd) * _sigma;
  }
}

/// Box–Muller. `dart:math` gives uniforms only, and the seeded [math.Random]
/// keeps every fixture byte-identical between runs.
double _gaussian(math.Random rnd) {
  final u1 = 1 - rnd.nextDouble(); // (0, 1]: log(0) is not a sample.
  final u2 = rnd.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

double _degrees(double radians) => radians * 180 / math.pi;

/// The accuracy a receiver *claims*, drawn per fix.
///
/// Every fixture built before this one reports one constant accuracy for every
/// fix, which no receiver does. That matters more than it looks: the Kalman
/// gain is computed from this number, so a constant accuracy means a constant
/// measurement variance and the filter never has to decide that one fix
/// deserves more belief than its neighbour.
///
/// Log-normal, because accuracy is positive and right-skewed, and because two
/// order statistics pin it exactly: `sigma = ln(p90/median) / z90`. The
/// constructor therefore takes a median and a p90 rather than a mean and a
/// spread, so the fixture is parameterised by the two numbers the device
/// actually reported instead of by a fitted guess.
class _ReportedAccuracy {
  _ReportedAccuracy(this._medianM, double p90M, int seed)
    : _sigmaLn = math.log(p90M / _medianM) / _z90,
      _rnd = math.Random(seed);

  /// Null when no p90 is given, which leaves every fixture that predates this
  /// on its constant accuracy and byte-identical to before.
  static _ReportedAccuracy? maybe(double medianM, double? p90M, int seed) =>
      p90M == null ? null : _ReportedAccuracy(medianM, p90M, seed);

  final double _medianM;
  final double _sigmaLn;
  final math.Random _rnd;

  double next() => _medianM * math.exp(_sigmaLn * _gaussian(_rnd));

  /// The standard normal's 90th percentile.
  static const _z90 = 1.2815515655446004;
}

/// 15.0 prints as "15" and 2.5 as "2.5", so fixture names built from a sigma
/// keep the spellings they had before this file learned about fractional noise.
String _sigmaLabel(double sigmaM) => sigmaM == sigmaM.roundToDouble()
    ? sigmaM.toStringAsFixed(0)
    : sigmaM.toStringAsFixed(1);
