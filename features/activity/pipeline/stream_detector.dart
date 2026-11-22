import 'dart:math' as math;

import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:meta/meta.dart';

/// Which rule is currently separating the position streams.
enum StreamDiscriminator {
  /// Only one timestamp granularity seen so far, and it is too early to say
  /// whether that is the whole story.
  ///
  /// Behaves exactly like [granularity]: whole-second fixes in, fractional
  /// fixes out. That asymmetry is the point. A whole-second fix is a candidate
  /// from the stream being measured, so admitting it costs nothing if this
  /// turns out to be a single-stream device. A fractional fix is either the
  /// other producer or a receiver that does not round — and admitting it on
  /// the chance that it is the latter is exactly how the 4.20 m network fix of
  /// 24 Aug reached the cold-start rule instead of being stopped for what it
  /// was.
  ///
  /// The cost lands only on a receiver whose own timestamps are fractional:
  /// its first [StreamDetector.probeFixes] fixes are dropped before the
  /// fallback engages. No device measured here behaves that way.
  undecided,

  /// Timestamp granularity. GPS lands on whole seconds, network does not.
  ///
  /// The robust signal, and the primary one. It separated both captures
  /// perfectly, including the walk where reported accuracy no longer did.
  granularity,

  /// A gap in the accuracy distribution, wherever it happens to be.
  ///
  /// The fallback for a receiver whose timestamps do not carry the split.
  /// Nothing measured has needed it; it exists because the primary
  /// discriminator rests on a delivery detail nobody promised us.
  accuracyGap,

  /// One stream. No cut beyond the physical ceiling.
  ///
  /// Not a failure to detect anything — a receiver delivering GPS alone is the
  /// case the whole mechanism is trying to reach, and it must not invent a
  /// second stream to have something to reject.
  singleStream,
}

/// What the detector concluded, for the diagnostics report.
@immutable
class StreamReport {
  const StreamReport({
    required this.discriminator,
    required this.primaryCount,
    required this.otherCount,
    required this.primaryAccuracyMedianM,
    required this.otherAccuracyMedianM,
    required this.cutM,
    required this.granularityAvailable,
  });

  final StreamDiscriminator discriminator;

  /// Fixes attributed to the receiver's own stream, and to everything else.
  final int primaryCount;
  final int otherCount;

  /// Median reported accuracy of each side of the split, in metres. Null for a
  /// side that took no fixes, or whose fixes reported no accuracy at all.
  ///
  /// The two medians are what say whether the split found two instruments or
  /// cut one in half: 2.50 m against 26.82 m on 23 Aug is a factor of ten, and
  /// two sides reading the same number is a split that separated nothing.
  final double? primaryAccuracyMedianM;
  final double? otherAccuracyMedianM;

  /// How many position streams the detector concluded were present.
  ///
  /// Null while [StreamDiscriminator.undecided] — never resolving is a third
  /// outcome, and reporting it as 1 would claim a finding the detector did not
  /// make.
  int? get streamsDetected => switch (discriminator) {
    StreamDiscriminator.undecided => null,
    StreamDiscriminator.singleStream => 1,
    StreamDiscriminator.granularity || StreamDiscriminator.accuracyGap => 2,
  };

  /// Where the accuracy cut landed, when one was used. Null otherwise.
  final double? cutM;

  /// Whether both timestamp granularities were ever seen.
  ///
  /// **The dependency to watch.** The whole primary discriminator rests on
  /// `tracelet` passing the platform's timestamp through unrounded. If it ever
  /// normalises them, every fix arrives on a whole second, this reads false,
  /// and the split disappears — silently, because a stream that is never
  /// detected produces no rejections to notice. It is reported on every run
  /// for that reason.
  final bool granularityAvailable;
}

/// Decides which fixes came from the receiver and which came from somewhere
/// else, without assuming the two are separable by accuracy.
///
/// **Why this exists.** Android's fused provider interleaves GPS with wifi and
/// cell trilateration. The 23 Aug 2026 ground-truth walk separated them
/// perfectly on reported accuracy — worst GPS 8.10 m, best network 9.60 m —
/// and `maxAccuracyM: 9` was set in that gap. The 24 Aug walk crossed it:
/// worst GPS 5.00 m, best network **4.20 m**. One network fix passed the
/// threshold and was removed by the cold-start rule, because it happened to
/// arrive second. At any other position in the sequence it would have been
/// accepted, and a 4.2 m network fix sits tens of metres off the GPS position.
///
/// So the gap was a property of one walk, not of the hardware, and a threshold
/// placed in it is a threshold that works until it does not. This class
/// replaces it with something that does not need a gap to exist.
///
/// **Causal by construction.** Live stats read the same decisions the saved
/// track does. Every rule here is evaluated from what has arrived so far, so
/// there is no second pass and no way for the map to disagree with the
/// database about which fixes were real.
class StreamDetector {
  StreamDetector({
    this.ceilingM = 9,
    this.probeFixes = 20,
    this.minClassSamples = 3,
    this.minMedianRatio = 2,
    this.minGapM = 1,
    this.minGapRatio = 3,
    this.minModeShare = 0.1,
  });

  /// The quality backstop, and now only a backstop.
  ///
  /// **Deliberately still 9, the value `maxAccuracyM` carried, and this is one
  /// change deferred rather than one made.** 9 was chosen to sit inside a gap
  /// that no longer exists, so as a *stream* discriminator it is retired and
  /// [StreamDetector] does that job instead. As a *quality* bound it is now
  /// unjustified in the other direction: nothing measured says 9 m is where a
  /// fix stops being worth using, and the original value before it was pressed
  /// into stream duty was 50.
  ///
  /// Moving it is a second, independent change with its own evidence
  /// requirement, and letting it ride along here would have made this commit
  /// two experiments at once. Raising it to 50 was tried and measured: it
  /// admits fixes the fixtures were built to have excluded and pushes
  /// `burstCadenceWalk`'s max smoothed speed from 5.78 m/s to 32.1 m/s. That
  /// is a real degradation on a single-stream receiver, and no capture in this
  /// project is of one — so the right number is unknown and stays unchanged
  /// until something measures it.
  final double ceilingM;

  /// How many fixes to watch before giving up on granularity.
  ///
  /// Reached on a receiver whose GPS timestamps are fractional, or whose two
  /// granularity classes turn out to be the same producer. Both captures
  /// resolve well inside it.
  final int probeFixes;

  /// How many fixes of each granularity class before the split is judged.
  final int minClassSamples;

  /// How far apart the two classes' median accuracies must be for the
  /// granularity split to mean two producers.
  ///
  /// **This guard is the difference between a discriminator and a
  /// coincidence.** A fractional timestamp is not evidence of wifi
  /// trilateration; it is evidence that a fix did not land on a whole second.
  /// On the A32's fused provider those coincide, because GPS ticks on the
  /// second and network positioning does not. On a receiver that simply
  /// reports sub-second times — or in `burstCadenceWalk`, where the pipeline's
  /// own fixture delivers bursts of GPS fixes 30–100 ms apart — they do not,
  /// and a rule that trusts granularity alone throws away the receiver.
  ///
  /// So granularity is accepted as a stream discriminator only when the two
  /// classes look like different instruments: median accuracy 2.50 m against
  /// 26.82 m on 23 Aug, 2.5 m against 29.79 m on 24 Aug — factors of ten. Two
  /// classes with the same accuracy profile are one producer with untidy
  /// timestamps, and are treated as such.
  final double minMedianRatio;

  /// What makes a gap in the accuracy distribution a real one: at least this
  /// many metres wide, at least this many times the typical spacing between
  /// neighbouring samples, and with at least this share of the samples on each
  /// side. All three, because any one alone finds a gap in noise.
  ///
  /// 1 m, and it was 2 until it was measured. The only real stream boundary
  /// in accuracy space that this project has ever recorded — 8.10 to 9.60 m on
  /// 23 Aug — is 1.50 m wide, so a 2 m floor excluded the single case the
  /// fallback exists to handle. The ratio test is the primary guard and this
  /// is a backstop against promoting a 0.1 m quantisation step; on the 24 Aug
  /// accuracies a 0.30 m step clears the ratio test and is stopped here.
  final double minGapM;
  final double minGapRatio;
  final double minModeShare;

  final _wholeSecondAccuracies = <double>[];
  final _fractionalAccuracies = <double>[];
  final _accuracies = <double>[];

  int get _wholeSecond => _wholeSecondAccuracies.length;
  int get _fractional => _fractionalAccuracies.length;

  StreamDiscriminator _discriminator = StreamDiscriminator.undecided;
  double? _cutM;

  /// Set when both granularity classes were present but looked like the same
  /// instrument. Reported, because "granularity was unavailable" and
  /// "granularity was available and meaningless" are different findings about
  /// a receiver and the second one is the more surprising.
  bool _granularityRejected = false;

  var _primary = 0;
  var _other = 0;

  /// Reported accuracies of each side, for the report's per-stream medians.
  ///
  /// Kept separately from [_wholeSecondAccuracies] and [_fractionalAccuracies]
  /// on purpose: those are classed by timestamp, these by the decision the
  /// detector actually made, and on a receiver where granularity is not the
  /// discriminator those are different partitions of the same fixes.
  final _primaryAccuracies = <double>[];
  final _otherAccuracies = <double>[];

  /// True once both timestamp granularities have been seen.
  bool get granularityAvailable => _wholeSecond > 0 && _fractional > 0;

  StreamDiscriminator get discriminator => _discriminator;

  /// Whether [fix] belongs to the stream this pipeline is measuring.
  ///
  /// Call once per delivered fix, in order. Updates the detector's state.
  bool admits(RawFix fix) {
    final whole = fix.timestamp.millisecond == 0;
    if (!fix.accuracyM.isNaN) {
      _accuracies.add(fix.accuracyM);
      (whole ? _wholeSecondAccuracies : _fractionalAccuracies).add(
        fix.accuracyM,
      );
    }

    _decide();

    final admitted = switch (_discriminator) {
      // Granularity settled it. A fractional timestamp is a fix from the other
      // producer regardless of how good it claims to be — which is the whole
      // point, and the 4.20 m fix of 24 Aug is the case in hand.
      StreamDiscriminator.granularity => whole && fix.accuracyM <= ceilingM,

      // A gap was found in the accuracy distribution and the cut sits in it.
      StreamDiscriminator.accuracyGap =>
        fix.accuracyM <= _cutM! && fix.accuracyM <= ceilingM,

      // One stream. The physical ceiling and nothing else — rejecting more
      // than that here would be inventing a second stream to have something
      // to exclude.
      StreamDiscriminator.singleStream => fix.accuracyM <= ceilingM,

      // Same rule as granularity, deliberately. See the note on the enum
      // value: a whole-second fix costs nothing to admit early, a fractional
      // one is the case that has already gone wrong once.
      StreamDiscriminator.undecided => whole && fix.accuracyM <= ceilingM,
    };

    if (admitted) {
      _primary++;
      if (!fix.accuracyM.isNaN) _primaryAccuracies.add(fix.accuracyM);
    } else {
      _other++;
      if (!fix.accuracyM.isNaN) _otherAccuracies.add(fix.accuracyM);
    }
    return admitted;
  }

  void _decide() {
    if (_discriminator == StreamDiscriminator.granularity) return;

    // Granularity, but only once there is enough of each class to compare and
    // only if the comparison says they are different instruments. Both
    // captures clear this within a handful of fixes; a receiver with untidy
    // timestamps never does, which is the point.
    if (_wholeSecond >= minClassSamples && _fractional >= minClassSamples) {
      final whole = _median(_wholeSecondAccuracies);
      final fractional = _median(_fractionalAccuracies);
      final ratio = whole <= 0 ? double.infinity : fractional / whole;

      if (ratio >= minMedianRatio) {
        _discriminator = StreamDiscriminator.granularity;
        _cutM = null;
        return;
      }
      // Two classes, one instrument. Granularity is noise here and must not be
      // used; fall through to the distribution, which will almost always say
      // singleStream.
      _granularityRejected = true;
    }

    // Below the probe budget there is nothing else to conclude. Staying
    // undecided keeps fractional fixes out, which is the conservative side on
    // a device that does interleave and the only cost on one that does not.
    if (_accuracies.length < probeFixes) return;

    // Recomputed as the sample grows rather than frozen at the probe
    // threshold: a second stream that starts halfway through a run — walking
    // out of open sky into a building's wifi — would otherwise never be seen.
    final gap = findAccuracyGap(
      _accuracies,
      minGapM: minGapM,
      minGapRatio: minGapRatio,
      minModeShare: minModeShare,
    );
    if (gap == null) {
      _discriminator = StreamDiscriminator.singleStream;
      _cutM = null;
    } else {
      _discriminator = StreamDiscriminator.accuracyGap;
      _cutM = gap;
    }
  }

  StreamReport report() => StreamReport(
    discriminator: _discriminator,
    primaryCount: _primary,
    otherCount: _other,
    primaryAccuracyMedianM: _primaryAccuracies.isEmpty
        ? null
        : _median(_primaryAccuracies),
    otherAccuracyMedianM: _otherAccuracies.isEmpty
        ? null
        : _median(_otherAccuracies),
    cutM: _cutM,
    granularityAvailable: granularityAvailable && !_granularityRejected,
  );
}

/// The midpoint of a bimodal split in [accuracies], or null if there is one
/// mode and therefore one stream.
///
/// Pure, so it can be tested on a list of numbers without a pipeline, a
/// receiver or a walk. Deliberately not a clustering algorithm: two producers
/// with different physics leave a *gap*, and the largest gap subject to three
/// sanity conditions finds it without anyone choosing a number of clusters in
/// advance.
///
/// **Measured in log space.** The two producers differ multiplicatively — 2.5 m
/// median against 27 m — so a fixed metre-space gap means something different
/// at each end of the range. On the 23 Aug walk the stream boundary is 1.5 m
/// wide (8.10 to 9.60) while the ordinary spacing *within* the network stream
/// at its low end is comparable, so in metres the true boundary is not the
/// largest gap and a largest-gap search finds the wrong one. As a ratio it is
/// unambiguous: 1.19x at the boundary against ~1.05x inside the stream.
///
/// The three conditions all have to hold, because each alone finds a gap in
/// pure noise — a wide gap between two outliers, a proportionally large gap
/// among tightly clustered values, a gap with one sample on one side of it.
double? findAccuracyGap(
  List<double> accuracies, {
  double minGapM = 1,
  double minGapRatio = 3,
  double minModeShare = 0.1,
}) {
  if (accuracies.length < 20) return null;

  // Non-positive accuracies have no logarithm and no physical meaning. A
  // receiver reporting 0 m is not making a claim about precision.
  final sorted = [
    for (final value in accuracies)
      if (value > 0) value,
  ]..sort();
  if (sorted.length < 20) return null;

  final logs = [for (final value in sorted) math.log(value)];

  // The typical spacing, from the NON-ZERO spacings only.
  //
  // Reported accuracy is quantised — 98% of the device's GPS values land on a
  // 0.1 m grid — so most neighbouring pairs in a sorted sample are identical
  // and a plain median spacing is exactly zero. Every ratio test against it
  // then either divides by zero or trivially passes. This cost the first
  // version of this function both of its real-data cases.
  final spacings = [
    for (var i = 1; i < logs.length; i++)
      if (logs[i] - logs[i - 1] > 0) logs[i] - logs[i - 1],
  ];
  if (spacings.length < 5) return null;
  final typical = _median(spacings);
  if (typical <= 0) return null;

  // Only gaps with real mass on both sides. Three outliers are a tail, not a
  // second stream.
  final lowest = (sorted.length * minModeShare).ceil();
  final highest = sorted.length - lowest;

  var bestGap = 0.0;
  var bestIndex = -1;
  for (var i = lowest; i < highest; i++) {
    final gap = logs[i] - logs[i - 1];
    if (gap > bestGap) {
      bestGap = gap;
      bestIndex = i;
    }
  }

  if (bestIndex < 0) return null;
  if (bestGap < minGapRatio * typical) return null;
  // And an absolute floor in metres, so a 1.05x step between two very precise
  // values cannot be promoted to a stream boundary by ratio alone.
  if (sorted[bestIndex] - sorted[bestIndex - 1] < minGapM) return null;

  return (sorted[bestIndex] + sorted[bestIndex - 1]) / 2;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}
