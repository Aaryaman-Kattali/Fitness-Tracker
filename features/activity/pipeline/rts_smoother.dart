part of 'track_processor.dart';

// WHY THIS FILE EXISTS WHEN NOTHING IN PRODUCTION CALLS IT.
//
// The backward pass is a MEASURED NEGATIVE RESULT (A1-7, PROGRESS.md A1c-14)
// and is deliberately not wired to the saved track: on both ground-truth walks
// the smoothed distance is further from the truth than the filtered one. It is
// not dead code and must not be deleted as such.
//
// **The tests are the asset and this implementation is their fixture.** That is
// the whole justification, stated plainly so nobody has to reconstruct it. What
// A1c-14 and A1c-15 record is not a sentence but a SWEEP — filter against
// smoother, seven values of `accelerationNoiseMps2`, five datasets, plus a
// coastline-decimation ratio that separates jitter removal from corner
// deletion. PROGRESS.md can carry the resulting tables. It cannot carry the
// ability to re-run them, and a number whose instrument has been deleted is
// folklore rather than evidence — which is exactly the failure A1c-13 recorded
// when a constant turned out to be defended by a measurement that never
// happened.
//
// It is also the only implementation in hand the day a coordinated-turn or IMM
// motion model is tried, which is the named next candidate: the finding here is
// that the corner problem lives in the MOTION MODEL, not in the direction of
// the pass, so the comparison this code makes possible is the baseline that
// candidate has to beat.
//
// What does NOT follow from any of that is the runtime cost. See
// [TrackProcessor.recordFilterStates]: the state tape is opt-in and off in the
// live recorder, because a phone should not carry ~0.9 MB per walk for an
// analysis that only ever runs here.

/// One axis of the filter, frozen after an update: state and covariance.
typedef _AxisState = ({
  double position,
  double speed,
  double p00,
  double p01,
  double p10,
  double p11,
});

/// Both axes after one accepted fix, plus the interval that reached it.
///
/// `dt` is the gap from the PREVIOUS accepted fix to this one, which is what
/// the backward pass needs to rebuild the prediction that was made into this
/// step. Storing it beats re-deriving it from timestamps: the forward pass
/// already computed it, and two computations of the same interval is one
/// rounding difference away from a smoother that disagrees with the filter it
/// is smoothing.
typedef _Filtered = ({_AxisState north, _AxisState east, double dt});

/// A run's track after the backward pass, with its metrics recomputed from it.
///
/// Separate from [TrackProcessor] rather than replacing its numbers, because
/// the two answer different questions and both are needed at once: the live
/// screen shows what was known at the time, and this is what is known now that
/// the run has finished. A single object holding one set of numbers would make
/// it impossible to say which.
@immutable
class SmoothedTrack {
  const SmoothedTrack({
    required this.points,
    required this.distanceM,
    required this.movingTime,
    required this.splits,
  });

  final List<TrackPoint> points;
  final double distanceM;
  final Duration movingTime;
  final List<Split> splits;

  Duration get elapsed => points.length < 2
      ? Duration.zero
      : points.last.timestamp.difference(points.first.timestamp);

  double? get averagePaceSecPerKm => distanceM <= 0
      ? null
      : movingTime.inMicroseconds / 1e6 / (distanceM / 1000);
}

/// Per-kilometre splits over an arbitrary track.
///
/// Lifted out of [TrackProcessor] when the backward pass needed the same rule
/// over a different set of points. Two copies of a boundary-interpolation rule
/// is two answers to "how long was the third kilometre", agreeing until one of
/// them is edited.
List<Split> splitsOf(List<TrackPoint> points, double distanceM) {
  if (points.length < 2 || distanceM <= 0) return const [];

  final result = <Split>[];
  var boundaryTime = points.first.timestamp;
  var km = 1;
  var index = 1;

  while (km * 1000 <= distanceM) {
    final target = km * 1000.0;
    while (index < points.length &&
        points[index].cumulativeDistanceM < target) {
      index++;
    }
    if (index >= points.length) break;

    final before = points[index - 1];
    final after = points[index];
    final span = after.cumulativeDistanceM - before.cumulativeDistanceM;
    // Where in this segment the kilometre actually fell.
    final fraction = span <= 0
        ? 0.0
        : (target - before.cumulativeDistanceM) / span;
    final segment = after.timestamp.difference(before.timestamp);
    final crossing = before.timestamp.add(
      Duration(microseconds: (segment.inMicroseconds * fraction).round()),
    );

    result.add(
      Split(
        km: km,
        duration: crossing.difference(boundaryTime),
        distanceM: 1000,
        isPartial: false,
      ),
    );
    boundaryTime = crossing;
    km++;
  }

  final remainder = distanceM - (km - 1) * 1000;
  if (remainder > 0) {
    result.add(
      Split(
        km: km,
        duration: points.last.timestamp.difference(boundaryTime),
        distanceM: remainder,
        isPartial: true,
      ),
    );
  }

  return result;
}

/// The Rauch-Tung-Striebel backward pass over one axis.
///
/// Walks the filtered states from the end to the start, and at each step
/// corrects the estimate with what the filter went on to learn. The correction
/// gain is
///
///     C_k = P_k · Fᵀ · (P⁻_{k+1})⁻¹
///
/// where `P⁻_{k+1}` is the prediction the forward pass made from k into k+1.
/// That prediction is rebuilt here rather than stored, because it is a
/// deterministic function of the filtered state and the interval, and storing
/// it would double the per-fix memory to carry a value that cannot disagree.
///
/// **Why this is the structural fix for corner-cutting.** The forward filter
/// arriving at a bend has seen nothing past it, so its prediction still points
/// along the old heading and the estimate cuts the inside of the turn — and
/// then overshoots on the way out as the measurements drag it back. The
/// backward pass is standing after the turn looking at it. It does not have to
/// guess which way the path went; it already knows.
///
/// Returns the smoothed positions, in order, one per input state.
List<double> _rtsPositions(
  List<_AxisState> states,
  List<double> dts,
  double q,
) {
  final n = states.length;
  if (n == 0) return const [];

  final positions = List<double>.filled(n, 0);
  // The last filtered estimate is already the smoothed one: there is nothing
  // after it to learn from. This is the recursion's boundary condition, not a
  // shortcut.
  var pos = states[n - 1].position;
  var vel = states[n - 1].speed;
  var s00 = states[n - 1].p00;
  var s01 = states[n - 1].p01;
  var s10 = states[n - 1].p10;
  var s11 = states[n - 1].p11;
  positions[n - 1] = pos;

  for (var k = n - 2; k >= 0; k--) {
    final state = states[k];
    // The interval the forward pass used to get from k to k+1.
    final dt = dts[k + 1];

    // P⁻ = F·P·Fᵀ + Q, with F = [[1, dt], [0, 1]] — the same arithmetic
    // _Axis.predict runs, and it has to stay the same arithmetic.
    final f00 = state.p00 + dt * (state.p10 + state.p01) + dt * dt * state.p11;
    final f01 = state.p01 + dt * state.p11;
    final f10 = state.p10 + dt * state.p11;
    final dt2 = dt * dt;
    final p00 = f00 + q * dt2 * dt2 / 4;
    final p01 = f01 + q * dt2 * dt / 2;
    final p10 = f10 + q * dt2 * dt / 2;
    final p11 = state.p11 + q * dt2;

    // C = P·Fᵀ·(P⁻)⁻¹, with Fᵀ = [[1, 0], [dt, 1]].
    final a00 = state.p00 + state.p01 * dt;
    final a01 = state.p01;
    final a10 = state.p10 + state.p11 * dt;
    final a11 = state.p11;

    final det = p00 * p11 - p01 * p10;
    // A covariance with process noise added is positive definite, so this
    // cannot be zero for any input a receiver can produce. Asserted rather
    // than guarded: a zero here means the forward pass is broken, and a
    // fallback would hide that behind a track that still looks plausible.
    assert(det != 0, 'singular predicted covariance in the backward pass');

    final c00 = (a00 * p11 - a01 * p10) / det;
    final c01 = (-a00 * p01 + a01 * p00) / det;
    final c10 = (a10 * p11 - a11 * p10) / det;
    final c11 = (-a10 * p01 + a11 * p00) / det;

    // The innovation the backward pass carries: how far the smoothed future
    // ended up from where the forward pass predicted it would be.
    final dPos = pos - (state.position + state.speed * dt);
    final dVel = vel - state.speed;

    pos = state.position + c00 * dPos + c01 * dVel;
    vel = state.speed + c10 * dPos + c11 * dVel;

    // Pˢ = P + C·(Pˢ_{k+1} − P⁻)·Cᵀ.
    final e00 = s00 - p00;
    final e01 = s01 - p01;
    final e10 = s10 - p10;
    final e11 = s11 - p11;

    final ce00 = c00 * e00 + c01 * e10;
    final ce01 = c00 * e01 + c01 * e11;
    final ce10 = c10 * e00 + c11 * e10;
    final ce11 = c10 * e01 + c11 * e11;

    final n00 = state.p00 + ce00 * c00 + ce01 * c01;
    final n01 = state.p01 + ce00 * c10 + ce01 * c11;
    final n10 = state.p10 + ce10 * c00 + ce11 * c01;
    final n11 = state.p11 + ce10 * c10 + ce11 * c11;

    s00 = n00;
    s01 = n01;
    s10 = n10;
    s11 = n11;

    positions[k] = pos;
  }

  return positions;
}
