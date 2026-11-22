import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:meta/meta.dart';

/// A position the pipeline accepted, reduced to what the estimator needs.
/// Deliberately not the pipeline's own fix type: nothing here reads accuracy
/// or speed, and a narrower input is one that cannot accidentally start doing
/// so.
typedef NoiseSample = ({DateTime at, double latitude, double longitude});

/// One lag of the second-difference structure function.
@immutable
class StructureLag {
  const StructureLag({
    required this.lagS,
    required this.triples,
    required this.secondDifferenceM2,
    required this.noiseConsistent,
  });

  final double lagS;

  /// How many fix triples `(t-T, t, t+T)` landed within tolerance of this lag.
  final int triples;

  /// `S(T) = E[|p(t+T) - 2p(t) + p(t-T)|^2]`, in m^2.
  ///
  /// **Zero for constant velocity, identically.** That is the whole reason
  /// this replaced the first-difference form: no motion term is subtracted, so
  /// there is nothing to over-subtract on a route that turns. See
  /// [measureNoiseProcess] for what it is not blind to.
  final double secondDifferenceM2;

  /// Whether `S(T)/T` had not yet risen by this lag — that is, whether this
  /// row is still consistent with a bounded stationary error process rather
  /// than with the route.
  ///
  /// See [measureNoiseProcess] for the rule. Marked per row so a lag that is
  /// measuring the walk is visible as such, rather than being read as a
  /// property of the receiver. Nothing is computed from it: the report reads
  /// the shortest lag and only the shortest lag.
  final bool noiseConsistent;

  /// `D(T)` is not identified by `S(T)` alone. `S(T) = 4.D(T) - D(2T)`, so the
  /// two limiting error processes bracket it: white error has `D(2T) = D(T)`
  /// and gives `S = 3D`; a random walk has `D(2T) = 2D(T)` and gives `S = 2D`.
  /// Every real process sits between them, and one walk cannot say where.
  double get errorLowM2 => secondDifferenceM2 / 3;
  double get errorHighM2 => secondDifferenceM2 / 2;
}

/// What the estimator measured, and what a recalibration would read.
///
/// **Report only.** Nothing here feeds a filter, a threshold or a constant.
@immutable
class NoiseProcessReport {
  const NoiseProcessReport({required this.lags, required this.medianDtS});

  final List<StructureLag> lags;

  /// Median interval between accepted fixes, in seconds. The cadence the lags
  /// are built from and the `T` the derived constant is scaled to.
  final double medianDtS;

  /// The error's own rms displacement between consecutive fixes, in metres,
  /// as the bracket `S(T)` actually identifies.
  ///
  /// The quantity PROGRESS.md A1c-8 identified as the one that governs
  /// accumulated path length — a white sigma = 2.5 m model, which has no
  /// correlation to carry, over-predicted the 23 Aug walk's raw GPS path by
  /// 241%.
  ///
  /// **Read at the shortest lag only.** `D(T) = 2.sigma_step^2`, so this needs
  /// no sigma, tau0 split — which is as well, because there is no longer a fit
  /// to supply one. The shortest lag is also the only one where the
  /// acceleration blindness in [measureNoiseProcess] has not yet taken over.
  ({double lowM, double highM})? get interFixNoise {
    if (lags.isEmpty) return null;
    final shortest = lags.first;
    if (shortest.secondDifferenceM2 <= 0) return null;
    return (
      lowM: math.sqrt(shortest.errorLowM2 / 2),
      highM: math.sqrt(shortest.errorHighM2 / 2),
    );
  }

  /// What `accelerationNoiseMps2` would be if the shipped tuning were carried
  /// across to this receiver unchanged in the only dimensionless way
  /// available.
  ///
  /// **Reported for comparison, and it is not a recommendation.** 0.035 came
  /// from a sweep against ground-truth geometries, not from a formula, so
  /// there is no exact rule to re-run. What can be held fixed is the
  /// dimensionless tracking index of a constant-velocity filter, a.T^2/sigma,
  /// with sigma taken as the noise that shows up between consecutive fixes
  /// rather than the per-axis magnitude — see [interFixNoise].
  ///
  /// **Measured to under-predict by about 2x, 1 Sep 2026.** On the S26 this
  /// reads 0.0126 to 0.0155 where the sweep's optimum is 0.02 and
  /// raw-accepted beats both. It says nothing about corner-cutting, which is what the sweep
  /// scores and is not visible in a noise measurement at all. The sweep is the
  /// stronger instrument; this decides whether a walk on the reference loop is
  /// worth taking.
  ({double low, double high})? get derivedAccelerationNoiseMps2 {
    final step = interFixNoise;
    if (step == null || medianDtS <= 0) return null;
    return (
      low: _trackingIndex * step.lowM / (medianDtS * medianDtS),
      high: _trackingIndex * step.highM / (medianDtS * medianDtS),
    );
  }
}

/// The cadence and the constant the 23 Aug sweep produced.
const double referenceDtS = 1;
const double referenceAccelerationNoiseMps2 = 0.035;

/// What **this estimator** reads for the A32's inter-fix error, in metres, at
/// the white end of the bracket, on the two committed captures of the same
/// 1610 m loop.
///
/// Hardcoded from a replay and pinned by `noise_process_test`. The white end
/// rather than the midpoint, so that one convention is used everywhere a ratio
/// is taken; the bracket's width is reported beside it and is not averaged away.
///
/// **These replace the first-difference estimator's 0.551 m and 0.675 m and do
/// not agree with them.** The new form reads about 25% lower on both walks.
/// Neither number is a receiver constant to be reconciled — they are two
/// instruments, and the older one subtracted a motion term this one does not
/// have. What matters is that every ratio in the report is now taken between
/// readings from the same instrument.
///
/// **The two walks disagree by 17% and are carried side by side rather than
/// averaged.** One receiver, one loop, two days. That spread is the floor on
/// what a single walk can decide about a constant, and it is stated in the
/// report where the ratio is read so no S26 number is over-interpreted. It was
/// 22% under the first-difference form, which is the one hint that the new
/// estimator is also the steadier one — on two walks, which is not evidence.
const double referenceInterFixNoiseM = 0.405;
const double referenceInterFixNoiseSecondWalkM = 0.475;

const double _trackingIndex =
    referenceAccelerationNoiseMps2 *
    referenceDtS *
    referenceDtS /
    referenceInterFixNoiseM;

/// Lags to evaluate, as multiples of the receiver's own median cadence.
///
/// Multiples rather than fixed seconds: the same five points of the curve on a
/// receiver delivering at 1 Hz and on one delivering at 5 Hz. The A32's lags
/// were 1, 2, 3, 5 and 8 s at 1.000 s cadence, which these reproduce exactly.
const _lagMultiples = [1.0, 2.0, 3.0, 5.0, 8.0];

/// Below this many triples a lag is not reported: a mean square over a handful
/// of samples is not a measurement of anything.
const _minTriples = 20;

/// Measure the receiver's error process from the accepted track.
///
/// `S(T) = E[|p(t+T) - 2p(t) + p(t-T)|^2]`, evaluated on the RAW accepted
/// positions. **No motion term is subtracted and no baseline is fitted.** A
/// second difference annihilates constant velocity by construction, which is
/// what the previous first-difference form could not do: it subtracted one
/// constant speed as `(v.T)^2`, and on any route that turns that over-subtracts
/// through every bend. On the S26's 1 Sep loop it drove all five lags negative
/// and the estimator returned nothing at all.
///
/// The two alternatives were rejected on their merits. Subtracting a
/// per-segment heading, or any locally-fitted motion, removes slowly-varying
/// error *by construction* — that is exactly how PROGRESS.md A1c-8 came to
/// measure the A32's error as white. Restricting the lags to straight sections
/// needs a straightness threshold nobody has evidence for and discards most of
/// a loop.
///
/// **The limitation, which is real and is not the old one.** A second
/// difference is blind to constant velocity, NOT to acceleration: a genuine
/// turn enters as `(a.T^2)^2`. Measured 1 Sep 2026, `S(T)` grows faster than
/// `T^3` on all three captures, which no bounded stationary error process can
/// do — for an exponentially-correlated error `S` is linear in T at short lags
/// and saturates. So above about 2 s these lags are measuring the route. The
/// leading run over which `S(T)/T` does not rise is marked, and everything the
/// report depends on is read at the shortest lag.
///
/// **There is deliberately no sigma, tau0 fit.** The previous form had one and
/// it cannot survive here. On all three captures only the shortest lag is
/// noise-consistent, which is one point and two parameters; on the one fixture
/// where three lags survive they all sit in the linear regime, where the model
/// constrains `sigma^2/tau0` and neither term alone — measured 1 Sep 2026, the
/// ratio comes back within 3% of the generated 2.5 m / 20 s while the split
/// reads 1.25 m / 4.9 s. Printing that pair would report a receiver property
/// nobody measured. The bracket at the shortest lag is what the data supports,
/// so it is all that is offered.
///
/// Null when there is not enough track to say anything.
NoiseProcessReport? measureNoiseProcess(List<NoiseSample> fixes) {
  if (fixes.length < 30) return null;

  final seconds = [
    for (final fix in fixes)
      fix.at.difference(fixes.first.at).inMicroseconds / 1e6,
  ];

  final gaps = [
    for (var i = 1; i < seconds.length; i++)
      if (seconds[i] > seconds[i - 1]) seconds[i] - seconds[i - 1],
  ];
  if (gaps.length < 10) return null;
  final medianDtS = _median(gaps);
  if (medianDtS <= 0) return null;

  // One local tangent plane for the whole track, anchored on the first fix.
  // The estimator differences positions metres apart over a walk kilometres
  // long, so the projection's scale error is common to all three terms of a
  // triple and cancels; what it must not do is vary between them.
  const metresPerDegreeNorth = earthRadiusM * math.pi / 180;
  final metresPerDegreeEast =
      metresPerDegreeNorth * math.cos(fixes.first.latitude * math.pi / 180);
  final north = [
    for (final fix in fixes)
      (fix.latitude - fixes.first.latitude) * metresPerDegreeNorth,
  ];
  final east = [
    for (final fix in fixes)
      (fix.longitude - fixes.first.longitude) * metresPerDegreeEast,
  ];

  final measured = <({double lagS, int triples, double s})>[];
  for (final multiple in _lagMultiples) {
    final lagS = multiple * medianDtS;
    final squares = _secondDifferences(
      seconds,
      north,
      east,
      lagS,
      medianDtS / 2,
    );
    if (squares.length < _minTriples) continue;

    measured.add((
      lagS: lagS,
      triples: squares.length,
      s: squares.reduce((a, b) => a + b) / squares.length,
    ));
  }

  // The leading run over which S(T)/T does not rise.
  //
  // For an exponentially-correlated error, D(T) is about 4.sigma^2.T/tau0 at
  // short lags and saturates, so S(T) = 4D(T) - D(2T) is linear in T and then
  // flattens: S/T can only fall. A rising S/T is the (a.T^2)^2 term — real
  // turning — so every lag past the break is measuring the route.
  var consistent = 0;
  for (final lag in measured) {
    if (lag.s <= 0) break;
    if (consistent > 0 &&
        lag.s / lag.lagS >
            measured[consistent - 1].s / measured[consistent - 1].lagS) {
      break;
    }
    consistent++;
  }

  return NoiseProcessReport(
    medianDtS: medianDtS,
    lags: [
      for (var i = 0; i < measured.length; i++)
        StructureLag(
          lagS: measured[i].lagS,
          triples: measured[i].triples,
          secondDifferenceM2: measured[i].s,
          noiseConsistent: i < consistent,
        ),
    ],
  );
}

/// Squared second differences over every triple whose two intervals are each
/// within [toleranceS] of [lagS]. Overlapping triples are included: each fix is
/// the centre of one and an endpoint of others.
List<double> _secondDifferences(
  List<double> seconds,
  List<double> north,
  List<double> east,
  double lagS,
  double toleranceS,
) {
  final squares = <double>[];
  for (var i = 0; i < seconds.length; i++) {
    final before = _nearest(seconds, i, seconds[i] - lagS, toleranceS);
    final after = _nearest(seconds, i, seconds[i] + lagS, toleranceS);
    if (before == null || after == null) continue;

    final dn = north[after] - 2 * north[i] + north[before];
    final de = east[after] - 2 * east[i] + east[before];
    squares.add(dn * dn + de * de);
  }
  return squares;
}

/// Index of the fix closest to [targetS], or null if the closest is further
/// than [toleranceS] from it, or is [centre] itself.
///
/// A binary search rather than the old two-pointer walk: the partner now moves
/// backwards as well as forwards, so a monotone scan no longer applies.
int? _nearest(
  List<double> seconds,
  int centre,
  double targetS,
  double toleranceS,
) {
  var low = 0;
  var high = seconds.length;
  while (low < high) {
    final mid = (low + high) ~/ 2;
    if (seconds[mid] < targetS) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }

  int? best;
  for (final candidate in [low - 1, low]) {
    if (candidate < 0 || candidate >= seconds.length) continue;
    if (candidate == centre) continue;
    if (best == null ||
        (seconds[candidate] - targetS).abs() <
            (seconds[best] - targetS).abs()) {
      best = candidate;
    }
  }

  if (best == null) return null;
  return (seconds[best] - targetS).abs() > toleranceS ? null : best;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}
