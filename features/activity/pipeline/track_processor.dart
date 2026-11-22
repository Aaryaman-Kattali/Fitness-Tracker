import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/pipeline/elevation.dart';
import 'package:fitness_tracker/features/activity/pipeline/geo.dart';
import 'package:fitness_tracker/features/activity/pipeline/noise_process.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/pipeline/stream_detector.dart';
import 'package:meta/meta.dart';

part 'rts_smoother.dart';
part 'saved_track.dart';
part 'track_diagnostics.dart';

/// Why a fix was thrown away.
///
/// Rejections are recorded rather than silently dropped: on a device the only
/// evidence of a receiver behaving badly is which filter fired and how often,
/// and a pipeline that discards that leaves nothing to diagnose from.
enum FixRejection {
  /// One of the first few fixes of a session. A receiver that has just woken
  /// up reports positions that wander tens of metres while it settles, and it
  /// reports them with a confident accuracy figure, so no accuracy test
  /// catches them.
  coldStart,

  /// Reported accuracy worse than the pipeline will accept.
  accuracy,

  /// Came from a producer other than the receiver being measured.
  ///
  /// Android's fused provider interleaves GPS with wifi and cell
  /// trilateration. [StreamDetector] decides which is which; this reason is
  /// what it fired on. Distinct from [accuracy] deliberately — a fix rejected
  /// here passed the quality bound and was still not a position from the
  /// instrument this track is made of, which is the case the 24 Aug walk found
  /// and the accuracy threshold alone could not.
  otherStream,

  /// Getting from the last accepted fix to this one would have taken a speed
  /// no runner reaches.
  implausibleSpeed,

  /// Arrived too soon after the origin for the pair to start the filter.
  ///
  /// Fires only before the smoother has a velocity, when both its opening
  /// position and its opening speed come from one pair of measurements
  /// divided by the interval between them. Never after: once the filter is
  /// running, a short interval is handled correctly and cheaply.
  tooSoonToPair,

  /// The clock did not move forward. Every `dt` downstream would be zero or
  /// negative, which is a division by zero waiting in the pace calculation.
  ///
  /// With the reorder buffer running this fires only on a genuine duplicate
  /// timestamp. A merely late fix is held and put back in sequence instead.
  outOfOrder,

  /// Delivered so late that the track had already moved past it.
  ///
  /// Distinct from [outOfOrder] on purpose: that one says the receiver's clock
  /// misbehaved, this one says the delivery path held a fix longer than the
  /// pipeline is willing to wait. They point at different components and the
  /// remedies are different — a bigger horizon fixes one and nothing fixes the
  /// other.
  arrivedTooLate,
}

/// A fix that did not make it, and what stopped it.
@immutable
class RejectedFix {
  const RejectedFix(this.fix, this.reason);

  final RawFix fix;
  final FixRejection reason;

  @override
  String toString() => 'RejectedFix(${reason.name}, $fix)';
}

/// A position on the processed track.
///
/// [latitude] and [longitude] are the filtered values; [source] is the fix
/// they came from, kept so the raw altitude, accuracy and reported speed can
/// be stored per point without the pipeline pretending to have derived them.
@immutable
class TrackPoint {
  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.cumulativeDistanceM,
  });

  final double latitude;
  final double longitude;
  final RawFix source;

  /// Distance along the smoothed track from its start to this point.
  ///
  /// Carried per point rather than recomputed, because both current pace and
  /// the kilometre splits need to ask "how far had we come at this moment"
  /// and re-walking the track for each answer is the same sum three times.
  final double cumulativeDistanceM;

  DateTime get timestamp => source.timestamp;
}

/// One kilometre of a run, or the remainder at the end of it.
@immutable
class Split {
  const Split({
    required this.km,
    required this.duration,
    required this.distanceM,
    required this.isPartial,
  });

  /// 1-based: the first kilometre of the run is `km: 1`.
  final int km;

  /// Wall-clock time within this split, stops included.
  ///
  /// Elapsed rather than moving time, because a split is a record of what the
  /// clock did over that kilometre — it is the number you compare against the
  /// same kilometre last week, and a stop at the lights genuinely made it
  /// slower.
  final Duration duration;

  /// 1000 for a whole split; whatever is left for the last one.
  final double distanceM;

  /// True for the remainder at the end of a run that did not finish on a
  /// kilometre. Marked rather than inferred, so nothing downstream has to
  /// guess whether a 500 m "kilometre" is a short split or a bad reading.
  final bool isPartial;

  /// Pace over this split, in seconds per kilometre.
  double get paceSecPerKm => duration.inMicroseconds / 1e6 / (distanceM / 1000);

  @override
  String toString() =>
      'Split($km, ${duration.inSeconds}s, '
      '${distanceM.toStringAsFixed(0)}m${isPartial ? ', partial' : ''})';
}

/// Turns a stream of raw GPS fixes into a usable track.
///
/// Pure Dart on purpose: no plugin, no platform channel, nothing that depends
/// on an API level. It is fed by a location plugin on a device and by
/// synthetic fixtures in tests, and cannot tell the difference.
///
/// The filter chain runs in a fixed order, and the order is load-bearing:
///
///   0. hold each fix for [bufferHorizon] and release them in timestamp order
///   1. discard fixes worse than [maxAccuracyM]
///   2. discard fixes from the other position stream ([StreamDetector])
///   3. discard the first [coldStartFixes] of what is left
///   4. discard fixes that imply an impossible speed
///   5. smooth what survives
///   6. accumulate distance from the *smoothed* track
///
/// Steps 5 and 6 are the ones that get transposed. Accumulating first and
/// smoothing afterwards produces a map that looks clean next to a distance
/// that integrated every metre of jitter — and on foot the jitter is larger
/// than the real displacement between fixes, so the error is not small.
///
/// **Cold start is last of the three discards, and that ordering is a measured
/// decision rather than a tidy-up.** It exists to throw away a settling
/// receiver, so its three-fix budget has to be spent on fixes from the stream
/// being kept. Both ground-truth walks OPEN with network fixes — the first
/// five delivered on 23 Aug are all network — so with cold start first the
/// entire budget went on fixes that were never the receiver settling, and the
/// settling fixes were then accepted. Putting the stream and quality gates
/// ahead of it makes it discard three GPS fixes instead, which is what it was
/// written to do. Measured on 24 Aug: 1605.2 m becomes 1608.5 m against a
/// 1610 m truth, −0.30% becomes −0.09%.
class TrackProcessor {
  TrackProcessor({
    this.coldStartFixes = 3,
    this.detectStreams = true,
    this.maxAccuracyM = 9,
    this.maxSpeedMps = 12,
    this.accelerationNoiseMps2 = 0.035,
    this.minMovingSpeedMps = 0.5,
    this.movingWindow = const Duration(seconds: 10),
    this.paceWindow = const Duration(seconds: 30),
    this.bufferHorizon = const Duration(seconds: 3),
    this.maxBufferedFixes = 64,
    this.recordFilterStates = false,
  });

  /// How many opening fixes to discard unconditionally.
  ///
  /// Unconditional is deliberate: a cold-start fix that reports 5 m accuracy
  /// is exactly the case this exists to catch.
  final int coldStartFixes;

  /// Whether [StreamDetector] separates the position streams.
  ///
  /// False switches step 2 off and restores the chain as it behaved before the
  /// detector existed, which is what the mutation test uses to prove it is
  /// doing the work: with it off, the 4.20 m network fix of 24 Aug is accepted.
  final bool detectStreams;

  /// Worst horizontal accuracy, in metres, that still counts as a position.
  ///
  /// **PROVISIONAL, and knowingly so. 9 is a measured-but-unjustified value,
  /// kept because every alternative is justified-but-untested.**
  ///
  /// 9 was chosen to separate two sensors, not to bound quality — see the
  /// walk below. [StreamDetector] now owns that job and does it without
  /// needing a gap in the accuracy distribution to exist, so as a *stream*
  /// discriminator this number is retired. As a *quality* bound it is
  /// unjustified in the other direction: nothing measured says 9 m is where a
  /// fix stops being worth using, and the value before it was pressed into
  /// stream duty was 50.
  ///
  /// It stays at 9 anyway, and the reason changed when it was re-measured.
  /// Raising it to 50 with the detector wired in moves **nothing**: not one of
  /// the twenty fixtures, not either ground-truth capture. The granularity
  /// rule already rejects everything the ceiling used to, so the fixes only
  /// change which reason they are filed under. (The earlier note that 50
  /// pushes `burstCadenceWalk` to 32.1 m/s does not reproduce; that fixture's
  /// accuracies are all well under 9, so the ceiling cannot reach them.)
  ///
  /// What keeps it at 9 is the case the measurement cannot see. Where
  /// granularity is unavailable — a single-stream receiver, or one whose
  /// timestamps do not carry the split — the detector reports `singleStream`
  /// and this threshold is the only filter left between a 27 m fix and the
  /// track. No capture in this project is of such a receiver, so nothing here
  /// can choose the number. Revisit when one is captured; the S25 Ultra may be
  /// one.
  ///
  /// The measurement it came from, kept because it is still the evidence for
  /// what the two streams are. Android's fused provider does not deliver one
  /// stream — it interleaves two producers, and on the 1610 m ground-truth
  /// walk of 23 Aug 2026 they were separable with no overlap whatsoever:
  ///
  /// | | fixes | cadence | accuracy median | accuracy range |
  /// |---|---|---|---|---|
  /// | GPS, whole-second timestamps | 1051 | 1.000 s | 2.50 m | 2.0 – **8.10** m |
  /// | network (wifi/cell), fractional timestamps | 154 | 6.82 s | 26.82 m | **9.60** – 200.00 m |
  ///
  /// The second stream is trilateration off wifi and cell towers. Its 154
  /// fixes trace 6171 m of path length across a walk that was 1610 m — 3.8
  /// times the entire route — because each one lands tens of metres off the
  /// GPS position and the track jumps out to it and back. At the old 50 m
  /// threshold the pipeline accepted 88 of them.
  ///
  /// 9 m sits inside the 8.10–9.60 m gap between the two. **That gap was a
  /// property of one walk.** On 24 Aug the streams crossed — worst GPS 5.00 m,
  /// best network 4.20 m — and a network fix passed the threshold, which is
  /// the whole reason [StreamDetector] exists.
  final double maxAccuracyM;

  /// The physical ceiling on human running speed, in metres per second.
  ///
  /// 12 m/s is a shade under the fastest 100 m ever run, so anything above it
  /// is not a person. It is deliberately far above running pace: this filter
  /// exists to catch receivers reporting nonsense, not to second-guess how
  /// fast the run was.
  final double maxSpeedMps;

  /// How much a runner's speed is expected to change between fixes, in metres
  /// per second squared. The single tuning knob of the smoother.
  ///
  /// It sets how much the filter believes a new measurement against its own
  /// prediction. Too high and the track follows the noise, inflating distance;
  /// too low and the filter stops believing that the path bends at all.
  ///
  /// **This is not "a runner's second-to-second variation".** That was the old
  /// justification for 0.2 and it was answering the wrong question. At 1 Hz the
  /// filter's job is not to model how a person's pace varies — it is to decide
  /// how much of the metre-scale disagreement between consecutive fixes is
  /// motion and how much is measurement error. The device's GPS error is ~2.5 m
  /// per axis and uncorrelated (PROGRESS.md, A1c-8), which at a 1.6 m/s walk is
  /// larger than the real displacement between fixes. At 0.2 the filter
  /// re-derived that noise as acceleration and followed it.
  ///
  /// 0.035 is chosen from a sweep against two things that pull in opposite
  /// directions, measured 23 Aug 2026:
  ///
  /// | value | 1610 m walk | switchback, 3 hairpins | rectangle, 4 corners |
  /// |---|---|---|---|
  /// | 0.2 (old) | +6.8% | +5.08% | +0.99% |
  /// | 0.05 | +4.5% | +5.00% | +1.59% |
  /// | **0.035** | **+3.6%** | **−0.16%** | **+1.92%** |
  /// | 0.02 | +2.4% | −12.38% | +2.79% |
  /// | 0.01 | +1.6% | −26.55% | +4.35% |
  ///
  /// Lowering it monotonically improves the real walk — right down to +1.6% at
  /// 0.01, better than the +3.6% shipped here — and monotonically destroys a
  /// hairpin, because a filter that will not believe a measurement also will
  /// not believe a U-turn. An out-and-back route has a U-turn in it, so that
  /// case is not exotic.
  ///
  /// 0.035 is the value at which the two effects a turn produces cancel: the
  /// corner-cut going in and the overshoot-recovery coming out. It gives up
  /// about half the available gain on the real walk to buy a geometry that is
  /// not wrong in either direction. The remaining +3.6% against Strava's +1.2%
  /// is open work, recorded in PROGRESS.md under A1c-9.
  ///
  /// Steady motion is unaffected at any value in this range — the noise-free
  /// straight kilometre reads 0.00% from 0.2 down to 0.001. The lag that killed
  /// the position-only filter is a property of the missing velocity state, not
  /// of this constant, and lowering it does not bring that back.
  final double accelerationNoiseMps2;

  /// Below this speed the runner counts as stopped, in metres per second.
  ///
  /// A slow walk is about 1.1 m/s, so half a metre per second sits clearly
  /// under anything deliberate while staying above the residual wander of a
  /// smoothed track from a stationary receiver.
  final double minMovingSpeedMps;

  /// How far back the moving/stopped decision looks.
  ///
  /// Ten seconds is long enough that a runner has covered ~28 m — unmistakable
  /// against any plausible wander — and short enough that a stop is noticed
  /// while it is still happening rather than half a minute later.
  final Duration movingWindow;

  /// How far back [currentPaceSecPerKm] looks.
  final Duration paceWindow;

  /// How long a fix is held before the chain sees it, so that one delivered
  /// late can be put back in sequence.
  ///
  /// Nothing in the delivery path sorts anything, and the first device test
  /// delivered 119 arrivals out of sequence on a 48-minute walk. Without this
  /// the clock test refuses every one of them, which on that walk was 106
  /// fixes thrown away — a sixth of the evidence, discarded for a fault in the
  /// transport rather than in the measurement.
  ///
  /// Three seconds because it has to exceed the worst delivery lag and not the
  /// gap between fixes. The cost is paid entirely by the live screen, which
  /// lags by this much; the saved track does not care when it was computed.
  ///
  /// [Duration.zero] switches the buffer off entirely and restores the pipeline
  /// exactly as it behaved before this existed, which is what the mutation test
  /// uses to prove the buffer is doing the work.
  final Duration bufferHorizon;

  /// Hard cap on held fixes, so a receiver whose clock stops cannot make the
  /// buffer grow for the length of a run. Over the cap the oldest is released
  /// early — the same thing the horizon would have done had the clock moved.
  final int maxBufferedFixes;

  /// Whether to keep the filter's state after each accepted fix, so that
  /// [smoothedTrack] can run a backward pass over it.
  ///
  /// **Off by default, and the default is the point.** A Kalman filter's whole
  /// business is forgetting, so the covariance cannot be reconstructed after
  /// the fact — the tape has to be written while the run happens or not at
  /// all. That is ~128 bytes per accepted fix, about 0.9 MB held for a
  /// two-hour walk at 1 Hz, and it was being written unconditionally on every
  /// real recording to serve a method **nothing in production calls** (A1-7:
  /// the backward pass is a measured negative result and is deliberately not
  /// wired to the saved track). The phone was paying for an analysis that only
  /// ever runs on a laptop.
  ///
  /// So it is opt-in rather than opt-out: a future production call site has to
  /// ask for the cost rather than inherit it. `replay()` in the test harness
  /// and the replay paths in `rts_smoother_test` turn it on; the live recorder
  /// does not.
  ///
  /// Calling [smoothedTrack] without it throws rather than returning a track
  /// built from an empty tape — a plausible-looking wrong distance is the
  /// failure this repo keeps finding, and an empty tape would produce exactly
  /// one.
  final bool recordFilterStates;

  final List<TrackPoint> _points = [];
  final List<RejectedFix> _rejected = [];

  /// The filter's own state after each accepted fix, for [smoothedTrack].
  /// Empty unless [recordFilterStates] is set.
  final List<_Filtered> _filtered = [];

  /// Shares [maxAccuracyM] rather than carrying its own copy of 9: two
  /// thresholds with the same job is two sources of truth, and only one of
  /// them would get edited.
  late final _streams = StreamDetector(ceilingM: maxAccuracyM);

  /// What the stream detector concluded, for the report.
  StreamReport get streams => _streams.report();

  /// Counts and distributions collected as the chain runs.
  ///
  /// Observation only. Nothing in [TrackDiagnostics] feeds back into a filter,
  /// a threshold or the distance total — remove every call to it and this class
  /// produces the same track.
  final diagnostics = TrackDiagnostics();

  int _seen = 0;
  RawFix? _lastAccepted;

  // The smoother runs in a local metric frame pinned at the first accepted
  // fix, so its state, its process noise and the fixes' accuracy are all
  // plainly in metres rather than in degrees that mean different distances on
  // each axis.
  _Axis? _north;
  late _Axis _east;
  RawFix? _originFix;
  double _originLat = 0;
  double _originLon = 0;
  double _metresPerDegreeEast = 0;

  double _distanceM = 0;
  double _movingSeconds = 0;

  /// The position the next distance contribution is measured FROM (A1c-J).
  ///
  /// Normally the previous accepted point, which makes accumulation ordinary
  /// fix-to-fix. It stops advancing for as long as fixes are classified
  /// stopped, so a stop contributes the displacement across it rather than the
  /// summed wander within it.
  double _anchorLat = 0;
  double _anchorLon = 0;

  /// Distance covered, in metres, accumulated from the smoothed track.
  double get distanceM => _distanceM;

  /// The accepted, filtered track, in order.
  List<TrackPoint> get points => List.unmodifiable(_points);

  /// How many points the track holds, without copying it.
  ///
  /// [points] returns an unmodifiable COPY, so reading `points.length` once
  /// per fix — which is what the live screen was doing — is O(n) per fix and
  /// O(n²) over a run. On a two-hour walk that is ~26 million list writes to
  /// learn a number the list already knows.
  int get pointCount => _points.length;

  /// The accepted points from [start] onward, in order.
  ///
  /// The track is append-only: [_points] is written in exactly one place and
  /// only ever grows, so a caller that has already consumed the first `start`
  /// points can never need to revisit them. That is what lets the live map
  /// extend one polyline instead of rebuilding it every second.
  Iterable<TrackPoint> pointsFrom(int start) => _points.skip(start);

  /// Every fix that was thrown away, with its reason.
  List<RejectedFix> get rejected => List.unmodifiable(_rejected);

  // Fixes held for [bufferHorizon], kept in timestamp order.
  final List<RawFix> _buffer = [];
  DateTime? _newestSeen;
  DateTime? _releasedThrough;

  /// Feed one fix in. Safe to call with anything a receiver produces.
  ///
  /// The fix is not necessarily processed here. With the buffer running it is
  /// held until the stream has moved [bufferHorizon] past it, so anything
  /// delivered late has a chance to land in the right place first. Call
  /// [flush] when the fixes stop, or the last few seconds never reach the
  /// track.
  void add(RawFix delivered) {
    // **The receiver's own speed field is bounded HERE, at the boundary, and
    // nowhere downstream.** It is Doppler rather than differenced positions,
    // nothing upstream bounds it, and the committed captures carry values up
    // to 39708 m/s on fixes whose positions are perfectly good — the
    // kinematic filter bounds a pair of POSITIONS and has never looked at
    // this field. Left alone it reaches `run_points.speedMps` through the
    // DAO, where nothing can tell it from a measurement.
    //
    // The fix itself is kept: only the annotation is wrong, and throwing away
    // a good position over a bad speed would be the more expensive error.
    // [maxSpeedMps] rather than a second constant — one physical claim, one
    // number to edit.
    final reported = delivered.speedMps;
    final implausible =
        reported != null && (reported < 0 || reported > maxSpeedMps);
    if (implausible) diagnostics.recordImplausibleReportedSpeed();
    final fix = implausible ? delivered.withoutReportedSpeed() : delivered;

    // Recorded on ARRIVAL, before the buffer touches it. This is the only
    // place that can see the order the delivery path used, and the whole
    // question of whether it reorders anything lives here — count it after
    // sorting and the answer is no, for every run, forever.
    diagnostics.recordDelivered(fix);

    if (bufferHorizon == Duration.zero) {
      _process(fix);
      return;
    }

    final released = _releasedThrough;
    if (released != null && !fix.timestamp.isAfter(released)) {
      // The track has already been built past this moment. Processing it now
      // would either walk the clock backwards or wedge a point in behind one
      // whose distance is already banked.
      _reject(fix, FixRejection.arrivedTooLate);
      return;
    }

    // Linear insert from the back. The buffer holds a handful of fixes and is
    // nearly sorted already, since most arrivals are in order — a binary
    // search would be more code for the same work.
    var at = _buffer.length;
    while (at > 0 && _buffer[at - 1].timestamp.isAfter(fix.timestamp)) {
      at--;
    }
    _buffer.insert(at, fix);

    final newest = _newestSeen;
    if (newest == null || fix.timestamp.isAfter(newest)) {
      _newestSeen = fix.timestamp;
    }

    while (_buffer.isNotEmpty &&
        (_buffer.length > maxBufferedFixes ||
            _newestSeen!.difference(_buffer.first.timestamp) >=
                bufferHorizon)) {
      _process(_buffer.removeAt(0));
    }
  }

  /// Release everything the buffer is still holding. Call after the last fix.
  ///
  /// Idempotent: a second call has nothing to release and changes nothing.
  void flush() {
    while (_buffer.isNotEmpty) {
      _process(_buffer.removeAt(0));
    }
  }

  /// The filter chain proper, on one fix, in timestamp order.
  void _process(RawFix fix) {
    _releasedThrough = fix.timestamp;

    // Every fix, before any gate, because the detector learns the receiver's
    // accuracy distribution from what arrives and a sample filtered by the
    // thing it is meant to calibrate is not a sample. Its own tally of the
    // split is therefore independent of which reason each rejection is filed
    // under below.
    final inStream = !detectStreams || _streams.admits(fix);

    // Quality first, so a fix too vague to use is filed as what it is rather
    // than as a verdict on which instrument produced it. The detector's
    // ceiling is the same number and would otherwise take the credit for
    // every rejection on this line.
    if (fix.accuracyM > maxAccuracyM) {
      _reject(fix, FixRejection.accuracy);
      return;
    }

    if (!inStream) {
      _reject(fix, FixRejection.otherStream);
      return;
    }

    // Only now. See the note on the class: cold start's budget is for the
    // stream being kept.
    _seen++;
    if (_seen <= coldStartFixes) {
      _reject(fix, FixRejection.coldStart);
      return;
    }

    final previous = _lastAccepted;
    if (previous != null) {
      if (!fix.timestamp.isAfter(previous.timestamp)) {
        _reject(fix, FixRejection.outOfOrder);
        return;
      }
      if (!_isReachable(from: previous, to: fix)) {
        _reject(fix, FixRejection.implausibleSpeed);
        return;
      }
    }

    final elapsed = previous == null
        ? 0.0
        : fix.timestamp.difference(previous.timestamp).inMicroseconds / 1e6;

    // Before the filter has a velocity, both the position and the speed it
    // starts from come straight off this pair of measurements, and both
    // estimates divide by the interval between them. A fix arriving a few tens
    // of milliseconds after the origin cannot establish either: the
    // displacement between them is measurement noise, and noise over a near
    // zero interval is an arbitrary speed. Measured on a standing start whose
    // true displacement is zero — 0.9 m of noise reads 1.8 m/s at a 500 ms
    // gap, 30 m/s at 30 ms and 89.9 m/s at 10 ms.
    //
    // The test is whether the pair's own error bar is narrower than the range
    // of speeds a person has. `maxSpeedMps` is the pipeline's existing
    // statement of that range, so it is the comparison rather than a new
    // constant. Failing it, the fix is dropped and the origin is kept, so the
    // next fix pairs against the origin over a longer and usable interval.
    //
    // Only before initialisation. Afterwards a short interval is harmless: the
    // Kalman gain pulls a 30 ms measurement almost entirely onto the
    // prediction, which is exactly what A1c-4 measured.
    if (previous != null && _originFix != null && _north == null) {
      final pairSigma =
          math.sqrt(
            _originFix!.accuracyM * _originFix!.accuracyM +
                fix.accuracyM * fix.accuracyM,
          ) /
          elapsed;
      if (pairSigma > maxSpeedMps) {
        _reject(fix, FixRejection.tooSoonToPair);
        return;
      }
    }

    _lastAccepted = fix;

    final smoothed = _smooth(fix, secondsSincePrevious: elapsed);
    final last = _points.isEmpty ? null : _points.last;

    // Moving time. A run has stops in it — traffic lights, a gate, tying a
    // lace — and counting them as running makes every pace derived from it a
    // lie.
    //
    // Judged on straight-line displacement over [movingWindow], not on the
    // length of one segment. Two reasons, and both matter. Displacement is a
    // difference of two positions rather than a sum of many, so it does not
    // accumulate jitter the way path length does: a receiver wandering on a
    // wall goes nowhere and reads as nowhere. And a single segment is far too
    // short a lever — at 1 Hz it is under three metres, so the decision would
    // ride on noise either way.
    //
    // Decided BEFORE the point is appended, because the distance it carries
    // now depends on the answer. See [displacementSpeedForCandidate].
    final displacementSpeed = last == null
        ? 0.0
        : displacementSpeedForCandidate(
            _points,
            _points.length - 1,
            smoothed.lat,
            smoothed.lon,
            fix.timestamp,
            movingWindow,
          );

    // Null is "no basis to judge" — the window held no earlier point, which is
    // what a low-cadence receiver produces. Treated as not-moving for moving
    // TIME, which is exactly what happened before A1c-J, and as accumulate for
    // DISTANCE, because a displacement the rule could not classify is not the
    // same as one it classified as a stop.
    final moving = (displacementSpeed ?? 0) >= minMovingSpeedMps;
    final judged = displacementSpeed != null;

    // Reported per fix, and deliberately still the plain fix-to-fix step even
    // when that step is not accumulated. Diagnostics describe what the
    // receiver did; the distance total describes what the walker did, and
    // A1c-J is precisely the discovery that those are different questions
    // while standing still.
    final step = last == null
        ? 0.0
        : haversineMetres(
            last.latitude,
            last.longitude,
            smoothed.lat,
            smoothed.lon,
          );

    // Step (e), and it reads from the smoothed position, never from the raw
    // fix. Smoothing has to happen before this line rather than after it.
    //
    // **A1c-J: the anchor freezes while stopped.** Accumulating fix to fix
    // regardless of the moving flag put 475 m of phantom distance into the
    // 7 Sep Zurich walk — 11% of its raw accepted path — because ~1000 fixes
    // at 3.79 m accuracy each add a small positive step while the walker
    // stands still, and a sum of positive steps never cancels.
    //
    // The anchor is simply the last position distance was accumulated TO. A
    // stopped fix contributes nothing and leaves it alone, so when movement
    // resumes the contribution is the displacement from wherever the walker
    // actually was when the stop began. While moving, the anchor IS the
    // previous point, so this reduces to fix-to-fix and a continuous walk is
    // unaffected.
    //
    // **Not plain exclusion, and that is the whole design.** Skipping
    // accumulation during stops would drop genuinely slow movement that the
    // 10 s / 0.5 m/s detector misread as stationary — the under-reporting
    // failure that ruled out the displacement gate originally. Freezing gives
    // drift nothing, because drift returns to where it started, while real
    // movement still lands as displacement on resume.
    if (moving || !judged) {
      _distanceM += haversineMetres(
        _anchorLat,
        _anchorLon,
        smoothed.lat,
        smoothed.lon,
      );
      _anchorLat = smoothed.lat;
      _anchorLon = smoothed.lon;
    } else if (last == null) {
      // The first accepted point is where accumulation starts from.
      _anchorLat = smoothed.lat;
      _anchorLon = smoothed.lon;
    }

    if (moving) _movingSeconds += elapsed;

    _points.add(
      TrackPoint(
        latitude: smoothed.lat,
        longitude: smoothed.lon,
        source: fix,
        cumulativeDistanceM: _distanceM,
      ),
    );

    diagnostics.recordAccepted(
      fix: fix,
      previousAccepted: previous,
      smoothedStepM: step,
      dtS: elapsed,
      moving: moving,
    );
  }

  /// Per-kilometre splits, plus the partial remainder if the run did not end
  /// on a whole kilometre.
  ///
  /// Each boundary is interpolated *within* the segment that crosses it rather
  /// than snapped to whichever fix happened to land nearest. At 1 Hz that
  /// distinction is worth about a second; at the 10–30 s cadence a phone falls
  /// back to when it is saving battery, it is worth ten or twenty, which is
  /// the difference between a split time you can compare week to week and one
  /// you cannot.
  List<Split> get splits => splitsOf(_points, _distanceM);

  /// The track after the backward pass, with its metrics recomputed from it.
  ///
  /// **The forward filter is untouched.** Everything above this line — the
  /// live distance, the live pace, the polyline the recording screen draws —
  /// is the causal estimate and stays that way. This is a second reading of
  /// the same run, taken once the run has finished, and it is the one worth
  /// saving: a smoother that has seen the whole track is not guessing at any
  /// point of it.
  ///
  /// Call after [flush]. Cheap to call twice; nothing here mutates.
  ///
  /// **Memory.** One [_Filtered] per accepted fix: thirteen doubles, so about
  /// 128 bytes on the heap once the record's own header is counted. A
  /// two-hour run at 1 Hz is 7200 fixes, or roughly 0.9 MB held for the length
  /// of the recording and released with the processor. That is the price of
  /// being able to smooth backwards at all — the covariance cannot be
  /// reconstructed after the fact, because a Kalman filter's whole business is
  /// forgetting.
  SmoothedTrack smoothedTrack() {
    if (!recordFilterStates) {
      throw StateError(
        'smoothedTrack() needs the filter-state tape, which this processor '
        'was not built to keep. Construct it with recordFilterStates: true. '
        'The tape cannot be reconstructed after the fact — a Kalman filter '
        'forgets by design — so this throws rather than smoothing an empty '
        'tape into a plausible wrong distance.',
      );
    }

    // Nothing to smooth: one point has no neighbour to learn from, and zero
    // points has nothing at all.
    if (_points.length < 2) {
      return SmoothedTrack(
        points: List.unmodifiable(_points),
        distanceM: _distanceM,
        movingTime: movingTime,
        splits: splits,
      );
    }

    final dts = [for (final entry in _filtered) entry.dt];
    final north = _rtsPositions(
      [for (final entry in _filtered) entry.north],
      dts,
      accelerationNoiseMps2 * accelerationNoiseMps2,
    );
    final east = _rtsPositions(
      [for (final entry in _filtered) entry.east],
      dts,
      accelerationNoiseMps2 * accelerationNoiseMps2,
    );

    // Moving time and distance are re-decided over the smoothed positions
    // rather than carried across from the forward pass, and they have to be:
    // both rules read displacement between two points, and these are different
    // points.
    //
    // One loop rather than two, because A1c-J ties them together — whether a
    // point is moving now decides whether it contributes distance, so the
    // answer cannot be computed after the totals it feeds. The anchor rule is
    // the same one the forward pass applies; see `_accept`.
    final points = <TrackPoint>[];
    var cumulative = 0.0;
    var movingSeconds = 0.0;
    var anchorLat = 0.0;
    var anchorLon = 0.0;

    for (var i = 0; i < _points.length; i++) {
      // The first accepted fix is the origin of the local frame and the filter
      // never held a state for it — there was nothing to smooth it against.
      // It stays where the receiver put it, which is one point of one track.
      final lat = i == 0
          ? _points[i].latitude
          : _originLat + north[i - 1] / _metresPerDegreeNorth;
      final lon = i == 0
          ? _points[i].longitude
          : _originLon + east[i - 1] / _metresPerDegreeEast;
      final at = _points[i].timestamp;

      if (i == 0) {
        anchorLat = lat;
        anchorLon = lon;
      } else {
        // Same two-way reading of null as the forward pass: not-moving for
        // moving time, accumulate for distance. See `_accept`.
        final speed = displacementSpeedForCandidate(
          points,
          points.length - 1,
          lat,
          lon,
          at,
          movingWindow,
        );
        final moving = (speed ?? 0) >= minMovingSpeedMps;

        if (moving || speed == null) {
          cumulative += haversineMetres(anchorLat, anchorLon, lat, lon);
          anchorLat = lat;
          anchorLon = lon;
        }
        if (moving) {
          movingSeconds +=
              at.difference(points.last.timestamp).inMicroseconds / 1e6;
        }
      }

      points.add(
        TrackPoint(
          latitude: lat,
          longitude: lon,
          source: _points[i].source,
          cumulativeDistanceM: cumulative,
        ),
      );
    }

    return SmoothedTrack(
      points: List.unmodifiable(points),
      distanceM: cumulative,
      movingTime: Duration(milliseconds: (movingSeconds * 1000).round()),
      splits: splitsOf(points, cumulative),
    );
  }

  /// The run as it is stored, decided once at save (A1c-Q).
  ///
  /// On a quiet receiver the distance and splits come from the raw accepted
  /// positions; otherwise this is the forward pass unchanged. Either way the
  /// stored positions are the smoothed ones and moving time is this
  /// processor's. The live getters above are never touched: the recording
  /// screen and the live map stay on the causal filter.
  ///
  /// Call after [flush].
  SavedTrack savedTrack() => _savedTrackOf(this);

  /// Wall-clock time from the first accepted fix to the last: the time the run
  /// took, stops included.
  Duration get elapsed => _points.length < 2
      ? Duration.zero
      : _points.last.timestamp.difference(_points.first.timestamp);

  /// Time spent actually moving, with stopped stretches excluded.
  Duration get movingTime =>
      Duration(milliseconds: (_movingSeconds * 1000).round());

  /// Average pace in seconds per kilometre, over the moving time.
  ///
  /// Moving time rather than elapsed, because that is the number a runner
  /// means by "pace" and what every watch shows: a four-minute wait at a
  /// crossing is not part of how fast you ran.
  ///
  /// Null until there is distance to divide by.
  double? get averagePaceSecPerKm =>
      _distanceM <= 0 ? null : _movingSeconds / (_distanceM / 1000);

  /// Pace over the last [paceWindow] of the track, in seconds per kilometre.
  ///
  /// A window rather than the last pair of fixes: at 1 Hz a runner covers
  /// under three metres between fixes, so an instantaneous pace is almost
  /// entirely noise and would flicker uselessly on a screen.
  ///
  /// Null before the window has filled, or while stopped — a pace of infinity
  /// is not a number to show anyone.
  double? get currentPaceSecPerKm {
    if (_points.length < 2) return null;

    final last = _points.last;
    final cutoff = last.timestamp.subtract(paceWindow);

    // The earliest point still inside the window, walking back from the end.
    var index = _points.length - 1;
    while (index > 0 && _points[index - 1].timestamp.isAfter(cutoff)) {
      index--;
    }
    if (index == _points.length - 1) return null;

    final first = _points[index];
    final seconds =
        last.timestamp.difference(first.timestamp).inMicroseconds / 1e6;
    final metres = last.cumulativeDistanceM - first.cumulativeDistanceM;
    if (seconds <= 0 || metres <= 0) return null;

    return seconds / (metres / 1000);
  }

  /// Step (d) of the chain: blend this fix with the running estimate.
  ///
  /// A constant-velocity Kalman filter — two states per axis, position and
  /// speed — run as two independent one-dimensional filters rather than one
  /// four-state matrix. North and east are uncorrelated under this model, so
  /// the matrix version would spend half its arithmetic on zeroes.
  ///
  /// The gain comes from each fix's own reported accuracy, which is why this
  /// beats a moving average: a fix arrives carrying a statement of how much it
  /// deserves to be believed, and a filter that spends that lets a tight fix
  /// pull hard while a loose one barely moves the estimate.
  ///
  /// **The velocity state is the point.** A position-only filter was built
  /// here first and could not meet both distance budgets at any tuning,
  /// because a random-walk position model does not know the target is going
  /// anywhere: its estimate trails a runner holding a steady pace by a fixed
  /// distance, which comes straight off the total. Carrying speed as a state
  /// means steady motion is predicted rather than lagged, so the filter can
  /// smooth hard without shortening the run. See PROGRESS.md under A1a-5.
  ({double lat, double lon}) _smooth(
    RawFix fix, {
    required double secondsSincePrevious,
  }) {
    final variance = fix.accuracyM * fix.accuracyM;

    final origin = _originFix;
    if (origin == null) {
      // Pin the local frame here. There is nothing yet to smooth this fix
      // against, and feeding it in as a measurement of the origin it defines
      // would use one observation twice and leave the filter twice as
      // confident in it as the evidence supports.
      _originFix = fix;
      _originLat = fix.latitude;
      _originLon = fix.longitude;
      _metresPerDegreeEast =
          _metresPerDegreeNorth * math.cos(fix.latitude * math.pi / 180);
      return (lat: fix.latitude, lon: fix.longitude);
    }

    final north = (fix.latitude - _originLat) * _metresPerDegreeNorth;
    final east = (fix.longitude - _originLon) * _metresPerDegreeEast;

    if (_north == null) {
      // Two-point initialisation: the first pair of fixes sets both position
      // and speed, with the covariance that pairing actually implies. Starting
      // instead from "speed is zero, and here is a variance I picked" tells
      // the filter something false about a runner already moving, and it
      // spends the opening fixes arguing its way out of that while the noise
      // pushes it around — which lands straight in the distance total.
      final originVariance = origin.accuracyM * origin.accuracyM;
      _north = _Axis.fromPair(
        position: north,
        variance: variance,
        originVariance: originVariance,
        dt: secondsSincePrevious,
      );
      _east = _Axis.fromPair(
        position: east,
        variance: variance,
        originVariance: originVariance,
        dt: secondsSincePrevious,
      );
    } else {
      _north!
        ..predict(secondsSincePrevious, accelerationNoiseMps2)
        ..update(north, variance);
      _east
        ..predict(secondsSincePrevious, accelerationNoiseMps2)
        ..update(east, variance);
    }

    // Kept for the backward pass, one record per accepted fix after the
    // origin. See [recordFilterStates] for why this is opt-in and what it
    // costs when it is on.
    if (recordFilterStates) {
      _filtered.add((
        north: _north!.snapshot,
        east: _east.snapshot,
        dt: secondsSincePrevious,
      ));
    }

    return (
      lat: _originLat + _north!.position / _metresPerDegreeNorth,
      lon: _originLon + _east.position / _metresPerDegreeEast,
    );
  }

  static const double _metresPerDegreeNorth = earthRadiusM * math.pi / 180;

  /// Could a person actually have got from [from] to [to] in the time between?
  ///
  /// The bound scales with elapsed time rather than being a fixed per-fix
  /// distance, and that distinction is the whole point. A receiver that loses
  /// lock for a minute under a bridge comes back with a genuine 400 m of
  /// travel to report; a fixed cap throws that away and silently shortens the
  /// run, while a 500 m jump between two fixes a second apart has to go. Both
  /// are large jumps. Only the elapsed time tells them apart.
  ///
  /// Both fixes' uncertainty is allowed as slack, because positional
  /// uncertainty is not motion: two fixes 30 m apart that each claim ±20 m may
  /// describe someone standing still.
  ///
  /// The slack is combined **in quadrature**, not by addition. Two independent
  /// errors of σ each are σ√2 apart on average, not 2σ, so adding them
  /// overstates the excusable displacement by ~41% and the overstatement is
  /// worst exactly where it does most damage — a large accuracy figure buys
  /// its own fix a large licence.
  ///
  /// Measured on the 1610 m walk: the additive form handed a 25 m network fix
  /// 25 m of slack, which at dt = 0.13 s made the bound ~29 m and admitted a
  /// 6 m step implying 46 m/s. Quadrature narrows that, and rejecting the
  /// network stream outright (see [maxAccuracyM]) removes the fixes that were
  /// claiming the slack in the first place. Both were needed: quadrature alone
  /// still admits most of that stream, and the accuracy threshold alone leaves
  /// the arithmetic wrong for whatever the next receiver does.
  ///
  /// Note the slack does not shrink with dt and must not. At small dt a pair of
  /// fixes carries almost no information about speed, and a bound that ignored
  /// their uncertainty there would reject ordinary noise as teleportation.
  bool _isReachable({required RawFix from, required RawFix to}) {
    final seconds =
        to.timestamp.difference(from.timestamp).inMicroseconds / 1e6;
    final travelled = haversineMetres(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    final slack = math.sqrt(
      from.accuracyM * from.accuracyM + to.accuracyM * to.accuracyM,
    );
    return travelled <= maxSpeedMps * seconds + slack;
  }

  void _reject(RawFix fix, FixRejection reason) {
    _rejected.add(RejectedFix(fix, reason));
    diagnostics.recordRejected(fix, reason);
  }

  /// Freeze the run's diagnostics. Call after the last fix.
  ///
  /// Flushes first. A report taken over a track that was still three seconds
  /// short of its own last fix would be a report of a different run from the
  /// one that got saved, and the difference would be small enough to go
  /// unnoticed and permanent.
  ///
  /// [elevation] comes from the recorder, like the delivery counts: the
  /// barometer is not a pipeline input, and a replay from a capture that
  /// predates A6-3 has none to give.
  RunDiagnosticsReport diagnose({
    int? deliveredByPlugin,
    int? undatableDropped,
    ElevationReport? elevation,
  }) {
    flush();
    return _report(
      deliveredByPlugin: deliveredByPlugin,
      undatableDropped: undatableDropped,
      elevation: elevation,
    );
  }

  RunDiagnosticsReport _report({
    int? deliveredByPlugin,
    int? undatableDropped,
    ElevationReport? elevation,
  }) => diagnostics.report(
    streams: detectStreams ? _streams.report() : null,
    saved: savedTrack(),
    elevation: elevation,
    smoothedDistanceM: _distanceM,
    elapsed: elapsed,
    movingTime: movingTime,
    minMovingSpeedMps: minMovingSpeedMps,
    maxSpeedMps: maxSpeedMps,
    movingWindow: movingWindow,
    deliveredByPlugin: deliveredByPlugin,
    undatableDropped: undatableDropped,
  );

  /// How many fixes were rejected for [reason].
  int rejectedFor(FixRejection reason) =>
      _rejected.where((entry) => entry.reason == reason).length;
}

/// How fast the track has actually got somewhere over the last [window],
/// ending at [endIndex], as the crow flies.
///
/// Top-level and not a method because two callers need exactly this rule and
/// only this rule: the live pipeline, deciding moving from stopped as each fix
/// arrives, and the diagnostics reconstruction, re-deciding it afterwards from
/// the points a finished run stored. Written twice it would be two thresholds
/// that agree until one of them is edited.
///
/// Displacement over the window, not the summed path: a difference of two
/// positions does not accumulate jitter, so a receiver wandering on a wall
/// reads as going nowhere, which is what it is doing.
double displacementSpeedMps(
  List<TrackPoint> points,
  int endIndex,
  Duration window,
) =>
    displacementSpeedForCandidate(
      points,
      endIndex - 1,
      points[endIndex].latitude,
      points[endIndex].longitude,
      points[endIndex].timestamp,
      window,
    ) ??
    0;

/// The same rule, for a position that is not in [points] yet — and **null when
/// the rule cannot be applied at all.**
///
/// The live pipeline has to know whether a fix is moving *before* it can know
/// how far to accumulate, and it cannot append the point first: the accumulated
/// total is stored on the point, and `_points` is append-only so that the live
/// map can extend one polyline instead of rebuilding it. So the decision is
/// made against the candidate position, with [historyEnd] the last index of the
/// track behind it.
///
/// **Null means "no basis to judge", which is not the same as "stopped", and
/// conflating the two is a bug that A1c-J would otherwise have shipped.** The
/// rule needs a point inside the window to measure displacement against. When
/// the previous fix is older than [window] — a receiver dropped to a 20 or 30 s
/// cadence to save battery, which is a normal thing for a phone to do — there
/// is no such point.
///
/// That case used to be invisible: the in-list form returned 0 through a
/// division-by-zero guard, the fix was called stopped, and moving time quietly
/// under-counted while distance accumulated anyway. Once distance depends on
/// the answer, treating it as stopped is fatal rather than untidy — at a 20 s
/// cadence EVERY fix reads stopped, nothing ever resumes, and the run reports
/// zero metres. Callers must decide deliberately, and they do: moving time
/// treats null as not-moving, preserving the old behaviour exactly, while
/// distance accumulates through it rather than discarding a displacement it
/// merely failed to classify.
///
/// Shares one body with [displacementSpeedMps] rather than restating the walk
/// back through the window — two copies of this rule is two thresholds that
/// agree until one of them is edited, which is the mistake the top-level
/// function was extracted to prevent in the first place.
double? displacementSpeedForCandidate(
  List<TrackPoint> points,
  int historyEnd,
  double lat,
  double lon,
  DateTime at,
  Duration window,
) {
  // Nothing behind it: a first point has not moved from anywhere. Genuinely
  // not moving rather than unjudgeable, so zero rather than null.
  if (historyEnd < 0) return 0;

  final cutoff = at.subtract(window);

  // Nothing inside the window to measure against. See the note above.
  if (!points[historyEnd].timestamp.isAfter(cutoff)) return null;

  var index = historyEnd;
  while (index > 0 && points[index - 1].timestamp.isAfter(cutoff)) {
    index--;
  }

  final first = points[index];
  final seconds = at.difference(first.timestamp).inMicroseconds / 1e6;
  if (seconds <= 0) return null;

  return haversineMetres(first.latitude, first.longitude, lat, lon) / seconds;
}

/// One axis of the constant-velocity filter: position and speed, in metres and
/// metres per second, with the 2×2 covariance kept as four scalars.
///
/// Written out rather than run through a matrix library because at this size
/// the matrix code is longer than the arithmetic it replaces, and a dependency
/// for eight multiplications is not a trade worth making.
class _Axis {
  /// Build the state from the first two fixes.
  ///
  /// Position comes from the second; speed from the baseline between them.
  /// The covariance is the one that pairing implies rather than a guess: the
  /// speed estimate inherits both fixes' error over the time between them,
  /// and it is *correlated* with the position estimate, which is the part an
  /// invented initial covariance always gets wrong.
  /// Both estimates divide by [dt], so both are unbounded as it goes to zero.
  /// The pipeline guarantees a usable [dt] here by refusing to pair on one
  /// that is too short — see `FixRejection.tooSoonToPair`.
  _Axis.fromPair({
    required double position,
    required double variance,
    required double originVariance,
    required double dt,
  }) : _position = position,
       _speed = position / dt,
       _p00 = variance,
       _p01 = variance / dt,
       _p10 = variance / dt,
       _p11 = (originVariance + variance) / (dt * dt);

  double _position;
  double _speed;

  // Covariance: _p01 and _p10 stay equal by construction but are both carried,
  // because the update writes them from different rows and collapsing them
  // would only hide that.
  double _p00;
  double _p01;
  double _p10;
  double _p11;

  double get position => _position;

  /// State and covariance, frozen for the backward pass.
  _AxisState get snapshot => (
    position: _position,
    speed: _speed,
    p00: _p00,
    p01: _p01,
    p10: _p10,
    p11: _p11,
  );

  /// Advance the estimate over [dt] seconds, assuming speed holds.
  void predict(double dt, double accelerationNoise) {
    _position += _speed * dt;

    // P = F·P·Fᵀ with F = [[1, dt], [0, 1]].
    final p00 = _p00 + dt * (_p10 + _p01) + dt * dt * _p11;
    final p01 = _p01 + dt * _p11;
    final p10 = _p10 + dt * _p11;

    // Q for white-noise acceleration of the given size.
    final q = accelerationNoise * accelerationNoise;
    final dt2 = dt * dt;
    _p00 = p00 + q * dt2 * dt2 / 4;
    _p01 = p01 + q * dt2 * dt / 2;
    _p10 = p10 + q * dt2 * dt / 2;
    _p11 = _p11 + q * dt2;
  }

  /// Fold in a measured position of the stated variance.
  void update(double measurement, double variance) {
    final innovation = measurement - _position;
    final s = _p00 + variance;
    final k0 = _p00 / s;
    final k1 = _p10 / s;

    _position += k0 * innovation;
    _speed += k1 * innovation;

    final p00 = _p00;
    final p01 = _p01;
    _p00 = p00 - k0 * p00;
    _p01 = p01 - k0 * p01;
    _p10 = _p10 - k1 * p00;
    _p11 = _p11 - k1 * p01;
  }
}
