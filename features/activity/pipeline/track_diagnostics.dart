part of 'track_processor.dart';

/// Everything the pipeline knew about a run and then threw away.
///
/// The pipeline's job is to turn fixes into a track, and it does that by
/// discarding things. From outside, a run that was shortened by an over-eager
/// filter, a run whose receiver only reported every three seconds, and a run
/// that was genuinely that short all produce the same single number. The only
/// way to tell them apart afterwards is to have counted at the time.
///
/// This collector runs alongside the filter chain and changes nothing about it.
/// It is fed from [TrackProcessor.add] at the points where decisions are
/// already being made; if any of it were removed the track would come out
/// identical.
class TrackDiagnostics {
  TrackDiagnostics() : _live = true;

  /// A collector fed after the fact, from the points a finished run stored.
  ///
  /// Only the accepted track is persisted, so a reconstruction can see what
  /// survived and nothing about what did not. The distinction is carried here
  /// rather than patched onto the report afterwards because it changes which
  /// numbers are *meaningful*, not just which are present: the stored positions
  /// are already smoothed, so differencing them cannot produce the unsmoothed
  /// total, and reporting it would silently print the smoothed distance twice
  /// under two different labels.
  TrackDiagnostics.reconstruction() : _live = false;

  final bool _live;

  // Delivered: every fix that reached the pipeline, accepted or not.
  int _delivered = 0;
  final List<double> _deliveredAccuracyM = [];
  final List<double> _deliveredDtS = [];
  int _outOfOrderArrivals = 0;
  double _rawDeliveredDistanceM = 0;
  RawFix? _lastDelivered;

  /// Delivered fixes whose timestamp landed exactly on a second.
  ///
  /// Counted with [StreamDetector]'s own test rather than a second one, so the
  /// reported fraction is a measurement of the primary discriminator's input
  /// and not of something adjacent to it.
  int _wholeSecondDelivered = 0;

  // Accepted: what survived the chain.
  int _accepted = 0;
  DateTime? _firstAccepted;
  DateTime? _lastAccepted;
  final List<double> _acceptedAccuracyM = [];
  final List<double> _acceptedDtS = [];
  final List<double> _acceptedSpeedMps = [];
  final List<double> _reportedSpeedMps = [];
  double _rawAcceptedDistanceM = 0;

  double _largestStepM = 0;
  double _largestStepDtS = 0;
  DateTime? _largestStepAt;

  /// Raw accepted positions, for the structure function.
  ///
  /// Live capture only. A reconstruction's "raw" positions are the smoothed
  /// ones read back out of the database, and measuring the receiver's noise
  /// off them would measure the smoother instead — silently, and with a
  /// plausible-looking answer.
  ///
  /// Three doubles and a [DateTime] per accepted fix, so about 48 bytes. A
  /// two-hour run at 1 Hz is under 0.4 MB, against the ~0.9 MB the backward
  /// pass already holds for the same run.
  final List<NoiseSample> _acceptedPositions = [];

  final Map<FixRejection, int> _rejections = {};

  /// Reported accuracy of the fixes rejected [FixRejection.arrivedTooLate].
  ///
  /// Kept because the count on its own is the frightening half of a benign
  /// measurement. Late arrival is a property of the *other* producer — a
  /// network position is computed asynchronously and handed over whenever it
  /// resolves — and this median is what says so on the run in hand rather
  /// than by reference to a note in another file.
  final List<double> _lateArrivalAccuracyM = [];

  /// Fixes whose reported speed was refused at the boundary.
  ///
  /// Counted because dropping bad values makes the printed distribution look
  /// healthy, and a healthy distribution is indistinguishable from a receiver
  /// that was healthy. Without this line the report would silently improve.
  int _implausibleReportedSpeeds = 0;

  /// Moving/stopped per accepted point, in order, for segmenting the stops.
  ///
  /// `from` is the previous accepted fix's timestamp, so each entry carries
  /// the whole interval it is responsible for rather than just its own
  /// instant. That is what lets [stopSegments] use the same accounting
  /// `movingTime` uses; without it the two answers diverge across a gap in
  /// the accepted stream, which is exactly what they did.
  final List<({DateTime from, DateTime at, bool moving})> _moving = [];

  /// Called for every fix handed to the pipeline, before any filter runs.
  void recordDelivered(RawFix fix) {
    _delivered++;
    _deliveredAccuracyM.add(fix.accuracyM);
    if (fix.timestamp.millisecond == 0) _wholeSecondDelivered++;

    final previous = _lastDelivered;
    if (previous != null) {
      final dt =
          fix.timestamp.difference(previous.timestamp).inMicroseconds / 1e6;
      _deliveredDtS.add(dt);

      // Counted here rather than from FixRejection.outOfOrder, and the
      // difference is the whole point of the question. That rejection only
      // fires after cold-start and accuracy have passed, and only against the
      // last *accepted* fix — so a fix that arrived out of order and was also
      // inaccurate is filed under accuracy, and the count is silently low.
      // This one is over arrivals, which is what "did the plugin reorder them"
      // actually asks.
      if (dt <= 0) _outOfOrderArrivals++;

      _rawDeliveredDistanceM += haversineMetres(
        previous.latitude,
        previous.longitude,
        fix.latitude,
        fix.longitude,
      );
    }
    _lastDelivered = fix;
  }

  /// Called when [TrackProcessor.add] refuses a fix's reported speed. The fix
  /// itself is not rejected — only the annotation is dropped.
  void recordImplausibleReportedSpeed() => _implausibleReportedSpeeds++;

  void recordRejected(RawFix fix, FixRejection reason) {
    _rejections[reason] = (_rejections[reason] ?? 0) + 1;
    if (reason == FixRejection.arrivedTooLate && !fix.accuracyM.isNaN) {
      _lateArrivalAccuracyM.add(fix.accuracyM);
    }
  }

  /// Called for every fix that made it onto the track.
  ///
  /// [previousAccepted] is the raw fix before this one, which is what the
  /// unsmoothed accumulation differences against — not the previous *delivered*
  /// fix, so this total is the pipeline's own filtering with the smoother taken
  /// out, and nothing else.
  void recordAccepted({
    required RawFix fix,
    required RawFix? previousAccepted,
    required double smoothedStepM,
    required double dtS,
    required bool moving,
  }) {
    _accepted++;
    _firstAccepted ??= fix.timestamp;
    _lastAccepted = fix.timestamp;

    // NaN is how a reconstruction says "this point stored no accuracy". It is
    // left out of the sample rather than substituted, because any substitute
    // is a value that moves the median this line exists to report; the printed
    // `n` is what makes the omission visible.
    if (!fix.accuracyM.isNaN) _acceptedAccuracyM.add(fix.accuracyM);
    if (fix.speedMps != null) _reportedSpeedMps.add(fix.speedMps!);
    if (_live) {
      _acceptedPositions.add((
        at: fix.timestamp,
        latitude: fix.latitude,
        longitude: fix.longitude,
      ));
    }

    if (previousAccepted == null) {
      // The first accepted fix is neither moving nor stopped: there is nothing
      // behind it to have moved from, and the pipeline does not count it as
      // either. Recording a flag for it would open a phantom stop segment at
      // the head of every run, one fix long, which is an artefact of the
      // bookkeeping and not something the receiver did.
      return;
    }

    _moving.add((
      from: previousAccepted.timestamp,
      at: fix.timestamp,
      moving: moving,
    ));
    _acceptedDtS.add(dtS);
    _rawAcceptedDistanceM += haversineMetres(
      previousAccepted.latitude,
      previousAccepted.longitude,
      fix.latitude,
      fix.longitude,
    );

    if (dtS > 0) _acceptedSpeedMps.add(smoothedStepM / dtS);
    if (smoothedStepM > _largestStepM) {
      _largestStepM = smoothedStepM;
      _largestStepDtS = dtS;
      _largestStepAt = fix.timestamp;
    }
  }

  /// Freeze what has been collected into a report.
  ///
  /// [deliveredByPlugin] and [undatableDropped] come from the recorder, above
  /// this layer: a fix the plugin emitted with an unparseable timestamp never
  /// reaches the pipeline at all, so counting only what arrives here would
  /// report a clean delivery record for a receiver that was losing fixes.
  RunDiagnosticsReport report({
    required double smoothedDistanceM,
    required Duration elapsed,
    required Duration movingTime,
    required double minMovingSpeedMps,
    required double maxSpeedMps,
    required Duration movingWindow,
    StreamReport? streams,
    SavedTrack? saved,
    ElevationReport? elevation,
    int? deliveredByPlugin,
    int? undatableDropped,
  }) {
    return RunDiagnosticsReport(
      streams: streams,
      saved: saved,
      elevation: elevation,
      wholeSecondDelivered: _live ? _wholeSecondDelivered : null,
      noise: _live ? measureNoiseProcess(_acceptedPositions) : null,
      source: _live
          ? DiagnosticsSource.liveCapture
          : DiagnosticsSource.reconstructed,
      startedAt: _firstAccepted,
      endedAt: _lastAccepted,
      deliveredByPlugin: deliveredByPlugin,
      undatableDropped: undatableDropped,
      reachedPipeline: _live ? _delivered : null,
      accepted: _accepted,
      rejections: _live ? Map.unmodifiable(_rejections) : null,
      outOfOrderArrivals: _live ? _outOfOrderArrivals : null,
      lateArrivalAccuracyM: Distribution.maybe(_lateArrivalAccuracyM),
      implausibleReportedSpeeds: _live ? _implausibleReportedSpeeds : null,
      deliveredAccuracyM: Distribution.maybe(_deliveredAccuracyM),
      acceptedAccuracyM: Distribution.maybe(_acceptedAccuracyM),
      deliveredDtS: Distribution.maybe(_deliveredDtS),
      acceptedDtS: Distribution.maybe(_acceptedDtS),
      deliveredDtOver3s: _live
          ? _deliveredDtS.where((dt) => dt > 3).length
          : null,
      acceptedDtOver3s: _acceptedDtS.where((dt) => dt > 3).length,
      acceptedSpeedMps: Distribution.maybe(_acceptedSpeedMps),
      reportedSpeedMps: Distribution.maybe(_reportedSpeedMps),
      largestStepM: _largestStepAt == null ? null : _largestStepM,
      largestStepDtS: _largestStepAt == null ? null : _largestStepDtS,
      largestStepAt: _largestStepAt,
      // Both are unknowable after the fact: the raw positions are not stored,
      // only the smoothed ones, and differencing those would report the
      // pipeline's own total back as if it were the unsmoothed one.
      rawDeliveredDistanceM: _live ? _rawDeliveredDistanceM : null,
      rawAcceptedDistanceM: _live ? _rawAcceptedDistanceM : null,
      smoothedDistanceM: smoothedDistanceM,
      stops: stopSegments(),
      elapsed: elapsed,
      movingTime: movingTime,
      minMovingSpeedMps: minMovingSpeedMps,
      maxSpeedMps: maxSpeedMps,
      movingWindow: movingWindow,
    );
  }

  /// Stretches the pipeline called stopped, in the order they happened.
  ///
  /// **These segments ARE stopped time — they partition it exactly.**
  ///
  /// A stopped fix owns the interval that ends at it, `[previous fix, this
  /// fix]`, which is precisely the interval `movingTime` declines to count.
  /// Consecutive stopped fixes therefore merge into one segment running from
  /// the last moving fix to the fix that resumed, and the segments sum to
  /// `elapsed - movingTime` with nothing left over. `stopped_time_test`
  /// asserts that on every fixture and every committed capture.
  ///
  /// **It used to be the other rule and the two disagreed by half an hour.**
  /// A segment ran from the first stopped fix to the next moving one, which
  /// omits the interval before the stop and includes the one after it. At 1 Hz
  /// that is a second either way; across a 1298 s hole in the accepted stream
  /// it put 21:38 of an indoor stop into the header's stopped total and
  /// printed the segment itself as `0:01`. The rule that loses is the one
  /// `movingTime` was not already using — pace divides by moving time, so the
  /// list has to follow it rather than the reverse.
  ///
  /// Durations are wall-clock between real fixes rather than a count of flags,
  /// which still matters at an irregular cadence.
  List<StopSegment> stopSegments() {
    final segments = <StopSegment>[];
    DateTime? start;
    DateTime? end;

    void close() {
      if (start != null && end != null) {
        segments.add(
          StopSegment(startedAt: start!, duration: end!.difference(start!)),
        );
      }
      start = null;
      end = null;
    }

    for (final entry in _moving) {
      if (entry.moving) {
        close();
      } else {
        start ??= entry.from;
        end = entry.at;
      }
    }
    close();
    return segments;
  }
}

/// Where a report's numbers came from, because the two sources can answer
/// different subsets of the same questions and a reader must not have to guess
/// which one they are holding.
enum DiagnosticsSource {
  /// Collected by the pipeline while the run was recording. Complete.
  liveCapture,

  /// Rebuilt afterwards from the accepted points stored in the database.
  /// Anything about a fix that was rejected is unrecoverable.
  reconstructed,
}

/// A stretch of a run the pipeline judged to be stopped.
@immutable
class StopSegment {
  const StopSegment({required this.startedAt, required this.duration});

  final DateTime startedAt;
  final Duration duration;
}

/// The shape of a sample, as five order statistics.
///
/// Order statistics rather than mean and standard deviation because every
/// quantity here is expected to be skewed — one 100 km accuracy sentinel or one
/// 60 s gap moves a mean a long way and a median not at all, and the question
/// being asked is always "what is the bulk of this doing, and how bad is the
/// tail".
@immutable
class Distribution {
  const Distribution({
    required this.n,
    required this.min,
    required this.p10,
    required this.median,
    required this.p90,
    required this.max,
  });

  factory Distribution.of(List<double> values) {
    final sorted = [...values]..sort();
    return Distribution(
      n: sorted.length,
      min: sorted.first,
      p10: _percentile(sorted, 0.10),
      median: _percentile(sorted, 0.50),
      p90: _percentile(sorted, 0.90),
      max: sorted.last,
    );
  }

  /// Null for an empty sample. A distribution of nothing is not zero, and
  /// printing zeroes would read as a measurement.
  static Distribution? maybe(List<double> values) =>
      values.isEmpty ? null : Distribution.of(values);

  final int n;
  final double min;
  final double p10;
  final double median;
  final double p90;
  final double max;

  static double _percentile(List<double> sorted, double fraction) =>
      sorted[((sorted.length - 1) * fraction).round()];
}

/// One run's diagnostics, ready to be read or copied.
///
/// Every field that a reconstruction cannot know is nullable, and the formatter
/// prints those as "unknown" rather than omitting them — a missing line reads
/// as an oversight, where an explicit unknown reads as the limit of the data.
@immutable
class RunDiagnosticsReport {
  const RunDiagnosticsReport({
    required this.source,
    required this.startedAt,
    required this.endedAt,
    required this.accepted,
    required this.smoothedDistanceM,
    required this.stops,
    required this.elapsed,
    required this.movingTime,
    required this.minMovingSpeedMps,
    required this.maxSpeedMps,
    required this.movingWindow,
    this.deliveredByPlugin,
    this.undatableDropped,
    this.reachedPipeline,
    this.rejections,
    this.lateArrivalAccuracyM,
    this.implausibleReportedSpeeds,
    this.outOfOrderArrivals,
    this.deliveredAccuracyM,
    this.acceptedAccuracyM,
    this.deliveredDtS,
    this.acceptedDtS,
    this.deliveredDtOver3s,
    this.acceptedDtOver3s,
    this.acceptedSpeedMps,
    this.reportedSpeedMps,
    this.largestStepM,
    this.largestStepDtS,
    this.largestStepAt,
    this.rawDeliveredDistanceM,
    this.rawAcceptedDistanceM,
    this.streams,
    this.saved,
    this.elevation,
    this.wholeSecondDelivered,
    this.noise,
  });

  final DiagnosticsSource source;
  final DateTime? startedAt;
  final DateTime? endedAt;

  final int? deliveredByPlugin;
  final int? undatableDropped;
  final int? reachedPipeline;
  final int accepted;
  final Map<FixRejection, int>? rejections;
  final int? outOfOrderArrivals;

  /// Reported accuracy of the fixes rejected `arrivedTooLate`, or null when
  /// none were. Null and empty mean the same thing here and the report prints
  /// neither: a run with no late arrivals has nothing to explain.
  final Distribution? lateArrivalAccuracyM;

  /// How many delivered fixes had their reported speed dropped at the
  /// boundary. Null for a reconstruction, which never saw a delivery — and
  /// whose stored points may predate the boundary rule entirely.
  final int? implausibleReportedSpeeds;

  final Distribution? deliveredAccuracyM;
  final Distribution? acceptedAccuracyM;
  final Distribution? deliveredDtS;
  final Distribution? acceptedDtS;
  final int? deliveredDtOver3s;
  final int? acceptedDtOver3s;

  final Distribution? acceptedSpeedMps;
  final Distribution? reportedSpeedMps;

  final double? largestStepM;
  final double? largestStepDtS;
  final DateTime? largestStepAt;

  final double? rawDeliveredDistanceM;
  final double? rawAcceptedDistanceM;

  /// The causal filter's total on a live capture. On a reconstruction it is
  /// the stored run row, which since A1c-Q may be either side, and the report
  /// labels it that way rather than as smoothed.
  final double smoothedDistanceM;

  /// What was stored and why (A1c-Q). Null for a reconstruction, which cannot
  /// re-measure the noise off positions that are already smoothed.
  final SavedTrack? saved;

  /// The barometer's run. Null when the report was not made by the recorder:
  /// a replay or a reconstruction has no barometer to ask.
  final ElevationReport? elevation;

  /// Which rule separated the position streams, and what it found. Null for a
  /// reconstruction, which sees only fixes that already survived the split.
  final StreamReport? streams;

  /// How many delivered fixes carried a timestamp on an exact second, against
  /// [reachedPipeline]. Null for a reconstruction, which never saw a delivery.
  final int? wholeSecondDelivered;

  /// The receiver's error process, measured off the accepted raw positions.
  /// Null for a reconstruction, and null when the run was too short to fit.
  final NoiseProcessReport? noise;

  final List<StopSegment> stops;
  final Duration elapsed;
  final Duration movingTime;

  /// The stop detector's settings, printed with its output so a reading of the
  /// stop segments never has to be made against a remembered threshold.
  final double minMovingSpeedMps;

  /// The bound the reported speed is refused against, carried for the same
  /// reason as [minMovingSpeedMps]: a reader must not have to remember which
  /// value produced the numbers in front of them.
  final double maxSpeedMps;
  final Duration movingWindow;

  Duration get totalStopped =>
      stops.fold(Duration.zero, (sum, stop) => sum + stop.duration);

  /// The whole report as text, so the screen and the clipboard cannot disagree.
  ///
  /// The same reasoning as the Health Connect read-out: this exists to be sent
  /// to someone, and a screen that renders one thing while the copy button
  /// yields another is a bug that only shows up in the answer you get back.
  String plainText() {
    final out = StringBuffer()
      ..writeln('RUN DIAGNOSTICS')
      ..writeln(
        'source     ${switch (source) {
          DiagnosticsSource.liveCapture => 'live capture during recording',
          DiagnosticsSource.reconstructed => 'REBUILT from stored points — accepted fixes only',
        }}',
      );

    if (source == DiagnosticsSource.reconstructed) {
      out
        ..writeln()
        ..writeln(
          'Everything about a REJECTED fix is gone: only accepted points are',
        )
        ..writeln(
          'stored. Delivery counts, rejection reasons, out-of-order arrivals',
        )
        ..writeln(
          'and the raw delivered distance below read "unknown" and cannot be',
        )
        ..writeln('recovered for this run. Record another to capture them.');
    }

    out
      ..writeln()
      ..writeln('from       ${_stamp(startedAt)}')
      ..writeln('to         ${_stamp(endedAt)}')
      ..writeln('elapsed    ${_clock(elapsed)}    moving ${_clock(movingTime)}')
      ..writeln()
      ..writeln('FIXES')
      ..writeln('  delivered by plugin   ${_count(deliveredByPlugin)}')
      ..writeln('  undatable, dropped    ${_count(undatableDropped)}')
      ..writeln('  reached pipeline      ${_count(reachedPipeline)}')
      ..writeln('  accepted              ${_pad(accepted)}${_share()}')
      ..writeln('  out-of-order arrivals ${_count(outOfOrderArrivals)}');

    final reasons = rejections;
    if (reasons == null) {
      out.writeln('  rejected              unknown');
    } else {
      final total = reasons.values.fold(0, (a, b) => a + b);
      out.writeln('  rejected              ${_pad(total)}');
      // Every reason, including the ones that fired zero times. A missing line
      // is indistinguishable from a filter that was never reached.
      for (final reason in FixRejection.values) {
        final late = reason == FixRejection.arrivedTooLate
            ? lateArrivalAccuracyM
            : null;
        out.writeln(
          '    ${_label(reason).padRight(20)}${_pad(reasons[reason] ?? 0)}'
          '${late == null ? '' : '   median accuracy ${_num(late.median)} m'}',
        );
      }
    }

    // The two sentences that stop a correct report reading as a fault.
    //
    // Both numbers above are alarming and neither is a defect, and the only
    // defence against misreading them was having read NOTES.md — which is not
    // a defence at all six months from now, on a phone, looking at a shared
    // text file. Prose is cheap here; the alternatives were not. The late
    // count could have been made small by a longer buffer horizon, at five
    // seconds of live-stats lag on every run, to relabel rejections that the
    // accuracy gate throws out one step later regardless.
    if ((rejections?[FixRejection.arrivedTooLate] ?? 0) > 0) {
      out.writeln(
        '  "past the buffer" is not data loss. Late arrival is the\n'
        '  signature of the other producer on every capture measured: a\n'
        '  network position is computed asynchronously and handed over\n'
        '  whenever it resolves, and the accuracy gate rejects it one step\n'
        '  later anyway. Replayed at 0, 3, 5 and 8 s horizons the accepted\n'
        '  count and the distance do not move. The horizon stays at 3 s.',
      );
    }
    out.writeln(
      '  A LOW ACCEPTANCE RATE beside a healthy accepted median below is\n'
      '  an ENVIRONMENT signal, not a pipeline fault: it counts what the\n'
      '  other producer supplied while the receiver had no sky. The lowest\n'
      '  recorded here is 68.5%, walking inside a shop.',
    );

    final split = streams;
    out
      ..writeln()
      ..writeln('STREAM DETECTION');
    if (split == null) {
      out.writeln('  unknown');
    } else {
      out
        ..writeln(
          '  streams detected  ${split.streamsDetected ?? 'NOT RESOLVED'}',
        )
        ..writeln(
          '  discriminator     ${switch (split.discriminator) {
            StreamDiscriminator.undecided => 'UNDECIDED — never resolved, fractional fixes refused throughout',
            StreamDiscriminator.granularity => 'timestamp granularity',
            StreamDiscriminator.accuracyGap => 'gap in the accuracy distribution',
            StreamDiscriminator.singleStream => 'one stream, no cut beyond the ceiling',
          }}',
        )
        ..writeln(
          '  cut at            ${split.cutM == null ? 'n/a — no accuracy cut was used' : '${split.cutM!.toStringAsFixed(2)} m'}',
        )
        // The dependency to watch: the primary discriminator rests on the
        // plugin passing platform timestamps through unrounded. If this ever
        // reads false on a device that does interleave, the split has gone
        // silent rather than gone away.
        ..writeln(
          '  granularity       ${split.granularityAvailable ? 'both classes present and distinct' : 'unavailable or meaningless'}',
        )
        ..writeln(
          '  kept, receiver    ${_pad(split.primaryCount)} fixes   median accuracy ${_metresOrDash(split.primaryAccuracyMedianM)}',
        )
        ..writeln(
          '  other producer    ${_pad(split.otherCount)} fixes   median accuracy ${_metresOrDash(split.otherAccuracyMedianM)}',
        )
        ..writeln(
          '  effect on this run  ${switch (rejections?[FixRejection.otherStream] ?? 0) {
            0 => 'NONE. It rejected nothing the accuracy\n'
                '                      gate had not already taken, so this run\n'
                '                      would be identical with the detector off.\n'
                '                      maxAccuracyM is separating the producers\n'
                '                      on its own and the detector is a backstop.',
            final int n => '$n fix(es) rejected that PASSED the\n'
                '                      accuracy gate. The detector changed this run.',
          }}',
        )
        // Corrected 9 Sep 2026: this said "every delivered fix", and it is
        // wrong for exactly the fixes the reorder buffer drops. The detector
        // sits after the buffer, so `kept + other` falls short of `reached
        // pipeline` by the arrivedTooLate count and the sum looked broken.
        ..writeln(
          '  the detector sees every fix that SURVIVES the reorder buffer,\n'
          '  before the quality gate. So a fix counted as kept here may still\n'
          '  be rejected above, and a fix rejected "past the buffer" is in\n'
          '  neither class here — kept + other falls short of reached\n'
          '  pipeline by exactly that count.',
        );
    }

    out
      ..writeln()
      ..writeln('TIMESTAMP GRANULARITY');
    final whole = wholeSecondDelivered;
    final delivered = reachedPipeline;
    if (whole == null || delivered == null || delivered == 0) {
      out.writeln('  unknown');
    } else {
      final share = 100 * whole / delivered;
      out
        ..writeln(
          '  on a whole second ${_pad(whole)} of $delivered   ${share.toStringAsFixed(1)}%',
        )
        ..writeln('  fractional        ${_pad(delivered - whole)}')
        ..writeln(
          '  ${switch (share) {
            >= 100 => 'EVERY fix is on a whole second: one class only, so granularity\n  cannot split anything and the fallback carries the whole job',
            <= 0 => 'NO fix is on a whole second: the primary discriminator is DEAD on\n  this receiver and every split rests on the accuracy fallback',
            _ => 'both classes present, which is what the granularity rule needs',
          }}',
        );
    }

    out
      ..writeln()
      ..writeln('ACCURACY (m)')
      ..writeln('  all delivered   ${_dist(deliveredAccuracyM)}')
      ..writeln('  accepted        ${_dist(acceptedAccuracyM)}')
      ..writeln()
      ..writeln('INTER-FIX INTERVAL (s)')
      ..writeln('  all delivered   ${_dist(deliveredDtS)}')
      ..writeln('    over 3 s      ${_count(deliveredDtOver3s)}')
      ..writeln('  accepted        ${_dist(acceptedDtS)}')
      ..writeln('    over 3 s      ${_count(acceptedDtOver3s)}')
      ..writeln()
      ..writeln('SPEED (m/s)')
      ..writeln('  smoothed track  ${_dist(acceptedSpeedMps)}')
      ..writeln('  receiver says   ${_dist(reportedSpeedMps)}')
      ..writeln(
        '    dropped as implausible ${_count(implausibleReportedSpeeds)}'
        '${implausibleReportedSpeeds == null ? '' : '   over $maxSpeedMps m/s or negative'}',
      )
      ..writeln(
        '  the receiver speed is Doppler and nothing upstream bounds it, so\n'
        '  it is refused at the boundary and stored as null rather than\n'
        '  clamped. The distribution above is what SURVIVED that and the\n'
        '  count is what did not. Runs recorded before 9 Sep 2026 hold\n'
        '  unbounded values in run_points.speedMps; see NOTES.md.',
      )
      ..writeln()
      ..writeln('DISTANCE (m)')
      ..writeln(
        '  raw, all delivered fixes   ${_metres(rawDeliveredDistanceM)}',
      )
      ..writeln(
        '  raw, accepted fixes        ${_metres(rawAcceptedDistanceM)}',
      );
    _writeSaved(out);
    _writeElevation(out);
    out
      ..writeln()
      ..writeln('LARGEST ACCEPTED STEP');

    if (largestStepM == null || largestStepDtS == null) {
      out.writeln('  none');
    } else {
      final dt = largestStepDtS!;
      out.writeln(
        '  ${largestStepM!.toStringAsFixed(1)} m over '
        '${dt.toStringAsFixed(1)} s'
        '${dt > 0 ? ' = ${(largestStepM! / dt).toStringAsFixed(2)} m/s' : ''}'
        ' at ${_stamp(largestStepAt)}',
      );
    }

    _writeNoise(out);

    out
      ..writeln()
      ..writeln(
        'STOPS  (under ${minMovingSpeedMps.toStringAsFixed(1)} m/s of '
        'displacement over ${movingWindow.inSeconds} s)',
      )
      ..writeln(
        '  ${stops.length} segment(s), ${_clock(totalStopped)} stopped in total',
      )
      ..writeln(
        '  these segments partition the stopped time above exactly: each\n'
        '  stopped fix owns the interval ending at it, which is the interval\n'
        '  moving time declines to count. So they sum to elapsed minus\n'
        '  moving, and a stop spanning a hole in the accepted stream is as\n'
        '  long as the hole.',
      )
      ..writeln(
        '  what the ${movingWindow.inSeconds} s window costs is the EDGES:\n'
        '  a stop is noticed only once a window of displacement falls under\n'
        '  the threshold, so each boundary can be late by up to that much.\n'
        '  It says nothing about the total of a segment, which is wall-clock\n'
        '  between two real fixes.',
      );

    final byLength = [...stops]
      ..sort((a, b) => b.duration.compareTo(a.duration));
    for (final stop in byLength.take(_maxStopsListed)) {
      out.writeln(
        '  ${_clock(stop.duration).padLeft(7)}  from ${_stamp(stop.startedAt)}',
      );
    }
    if (byLength.length > _maxStopsListed) {
      final rest = byLength.skip(_maxStopsListed);
      final restTotal = rest.fold(Duration.zero, (sum, s) => sum + s.duration);
      out.writeln(
        '  ... and ${rest.length} shorter, ${_clock(restTotal)} between them',
      );
    }

    return out.toString();
  }

  /// Which total was stored, and the number that decided it, so a wrong call on
  /// a new receiver is visible in the one file that travels with the run.
  void _writeSaved(StringBuffer out) {
    final stored = saved;
    if (stored == null) {
      // A reconstruction prints the run row's own number, and cannot say which
      // side produced it: deciding needs the raw positions, and only the
      // smoothed ones were stored.
      out
        ..writeln('  saved, from the run row    ${_metres(smoothedDistanceM)}')
        ..writeln(
          '    raw or smoothed (A1c-Q) is unknown here: the decision needs the\n'
          '    raw positions, and only the smoothed ones were stored',
        );
      return;
    }

    final noise = stored.interFixNoiseHighM;
    final threshold = bypassBelowInterFixNoiseM.toStringAsFixed(2);
    out
      ..writeln('  pipeline, smoothed         ${_metres(smoothedDistanceM)}')
      ..writeln(
        '  SAVED                      ${_metres(stored.distanceM)}   '
        '${switch (stored.source) {
          DistanceSource.smoothed => 'smoothed',
          DistanceSource.rawAccepted => 'raw accepted, stops from smoothed',
        }}',
      )
      ..writeln(switch ((stored.source, noise)) {
        (_, null) =>
          '    inter-fix error unmeasured, too few accepted fixes: the\n'
              '    smoother is kept, which is the conservative side (A1c-Q)',
        (DistanceSource.rawAccepted, final double n) =>
          '    inter-fix error ${n.toStringAsFixed(3)} m at the high end, under '
              '$threshold m:\n'
              '    quiet enough that smoothing costs length rather than removing\n'
              '    noise, so distance and splits are raw (A1c-Q). Moving time\n'
              "    and stops are the smoothed track's either way",
        (DistanceSource.smoothed, final double n) =>
          '    inter-fix error ${n.toStringAsFixed(3)} m at the high end, not '
              'under $threshold m:\n'
              '    the smoother is load-bearing on this receiver and is kept '
              '(A1c-Q)',
      });
  }

  /// The barometer's outcome, stated whichever way it went: an absent sensor is
  /// the ordinary case on some phones and must read as that, not as a blank.
  void _writeElevation(StringBuffer out) {
    out
      ..writeln()
      ..writeln(
        'ELEVATION  (barometric only; GPS altitude stored, never used)',
      );

    final reading = elevation;
    if (reading == null) {
      out.writeln('  unknown — this report was not made by the recorder');
      return;
    }

    final gain = reading.gainM;
    out.writeln(switch (reading.outcome) {
      BarometerOutcome.absent =>
        '  NO BAROMETER on this phone. Elevation gain is not recorded, and\n'
            '  the run stores none rather than a number from GPS altitude',
      BarometerOutcome.failed =>
        '  BAROMETER FAILED after ${reading.sampleCount} reading(s): '
            '${reading.detail}\n'
            '  the run stores no gain rather than a partial one',
      BarometerOutcome.recorded when gain == null =>
        '  barometer present, 0 readings delivered: no gain stored',
      BarometerOutcome.recorded =>
        '  gain ${gain!.toStringAsFixed(1)} m from ${reading.sampleCount} '
            'readings\n'
            '  ${elevationHysteresisM.toStringAsFixed(0)} m deadband over 5 s '
            'means, PROVISIONAL until a capture\n'
            '  with pressure has been checked against a known route (A6-2)',
    });
  }

  /// The receiver's own error process, and what a recalibration would read off
  /// it. **Nothing here changes a constant.** The comparison line exists so the
  /// shipped value and the measured one are seen together rather than one being
  /// remembered while the other is read.
  void _writeNoise(StringBuffer out) {
    out
      ..writeln()
      ..writeln('MEASURED NOISE PROCESS  (accepted stream, report only)');

    final measured = noise;
    if (measured == null) {
      out.writeln(
        source == DiagnosticsSource.reconstructed
            ? '  unavailable — stored positions are smoothed, so this would\n'
                  '  measure the filter rather than the receiver'
            : '  unavailable — too few accepted fixes to measure',
      );
      return;
    }

    out
      ..writeln(
        '  S(T) = E[|p(t+T) - 2p(t) + p(t-T)|^2], which is identically zero',
      )
      ..writeln(
        '  for constant velocity. No motion term subtracted, no baseline\n'
        '  fitted, no ground truth. Blind to constant velocity, NOT to\n'
        '  acceleration: a real turn enters as (a.T^2)^2, so S/T rising is\n'
        '  the route, not the receiver.',
      )
      ..writeln('       lag   triples       S(T)      D low     D high');

    for (final lag in measured.lags) {
      out.writeln(
        '  ${_num(lag.lagS)}s  ${_pad(lag.triples)}  '
        '${_num(lag.secondDifferenceM2)}  ${_num(lag.errorLowM2)}  '
        '${_num(lag.errorHighM2)}'
        '${lag.noiseConsistent ? '' : '   S/T rose, this is the route'}',
      );
    }

    final step = measured.interFixNoise;
    final derived = measured.derivedAccelerationNoiseMps2;
    if (step != null && derived != null) {
      out
        ..writeln(
          '  inter-fix error sqrt(D(T)/2) = ${step.lowM.toStringAsFixed(3)} to '
          '${step.highM.toStringAsFixed(3)} m at '
          'T = ${measured.medianDtS.toStringAsFixed(3)} s',
        )
        ..writeln(
          '  a BRACKET, not a point: S(T) = 4.D(T) - D(2T) identifies D only\n'
          '  between the white (S=3D) and random-walk (S=2D) limits. Read at\n'
          '  the shortest lag, where the acceleration term has not taken over.',
        )
        ..writeln(
          '  A32, same estimator, white end: '
          '${referenceInterFixNoiseM.toStringAsFixed(3)} m on 23 Aug, '
          '${referenceInterFixNoiseSecondWalkM.toStringAsFixed(3)} m on 24 Aug\n'
          '  — one receiver, one loop, two days. That spread is the floor on\n'
          '  what a single walk can decide about a constant.',
        )
        ..writeln(
          '  derived accelerationNoiseMps2 ${derived.low.toStringAsFixed(4)} to '
          '${derived.high.toStringAsFixed(4)}   '
          'shipped ${referenceAccelerationNoiseMps2.toStringAsFixed(3)}',
        )
        ..writeln(
          '  derived by holding a.T^2 / inter-fix error fixed at the A32\n'
          '  point. A scaling, not the sweep 0.035 came from, and measured to\n'
          '  under-predict it by about 2x on the S26: it says nothing about\n'
          '  corner-cutting, which is what the sweep scores. REPORT ONLY.',
        );
    }

    out.writeln(
      '  no sigma, tau0 split is offered. One noise-consistent lag is one\n'
      '  point and two parameters, and lags that all sit in the linear regime\n'
      '  constrain sigma^2/tau0 and neither term alone.',
    );
  }

  /// Long enough to show every stop worth calling a stop, short enough that the
  /// report stays readable when a jittery receiver flickers the detector.
  static const _maxStopsListed = 20;

  String _share() {
    final delivered = reachedPipeline;
    if (delivered == null || delivered == 0) return '';
    return '  ${(100 * accepted / delivered).toStringAsFixed(1)}% of delivered';
  }
}

String _label(FixRejection reason) => switch (reason) {
  FixRejection.coldStart => 'cold start',
  FixRejection.accuracy => 'accuracy',
  FixRejection.otherStream => 'other stream',
  FixRejection.implausibleSpeed => 'implied speed',
  FixRejection.tooSoonToPair => 'too soon to pair',
  FixRejection.outOfOrder => 'non-monotonic clock',
  FixRejection.arrivedTooLate => 'past the buffer',
};

String _pad(int value) => value.toString().padLeft(6);

String _count(int? value) => value == null ? 'unknown' : _pad(value);

String _metresOrDash(double? value) =>
    value == null ? '     —  ' : '${_num(value)} m';

String _metres(double? value) =>
    value == null ? 'unknown' : value.toStringAsFixed(0).padLeft(8);

String _dist(Distribution? d) => d == null
    ? 'unknown'
    : 'min ${_num(d.min)}  p10 ${_num(d.p10)}  med ${_num(d.median)}  '
          'p90 ${_num(d.p90)}  max ${_num(d.max)}   n=${d.n}';

/// Two decimals up to a point, then none. A 100000 m accuracy sentinel printed
/// to two places is six characters of noise in a column.
String _num(double value) =>
    (value.abs() >= 1000 ? value.toStringAsFixed(0) : value.toStringAsFixed(2))
        .padLeft(8);

String _stamp(DateTime? value) => value == null
    ? '—'
    : '${value.toUtc().toIso8601String().substring(0, 19).replaceFirst('T', ' ')} UTC';

String _clock(Duration value) {
  final seconds = value.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
