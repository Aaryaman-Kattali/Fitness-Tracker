import 'dart:async';

import 'package:fitness_tracker/data/repositories/run_recorder.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:tracelet/tracelet.dart' as tl;

/// [RunRecorder] over the tracelet plugin.
///
/// The only file in the app that imports `tracelet`, the same rule
/// `HealthConnectRepository` follows for `health`. Everything above this line
/// sees [RawFix] and nothing else.
class TraceletRunRecorder implements RunRecorder {
  final _fixes = StreamController<RawFix>.broadcast();
  StreamSubscription<tl.Location>? _subscription;
  bool _ready = false;

  int _received = 0;
  int _undatable = 0;

  @override
  Stream<RawFix> get fixes => _fixes.stream;

  @override
  ({int received, int undatable}) get delivery => (
    received: _received,
    undatable: _undatable,
  );

  /// The configuration, and every line of it is a decision.
  ///
  /// tracelet ships its own accuracy threshold, implied-speed cap and Kalman
  /// smoother — which is to say, its own versions of filters (b), (c) and (d)
  /// of the A1a chain. Two filter chains with different constants is two
  /// sources of truth, and only one of them is under test here. So the
  /// plugin's are turned off or opened wide, and the pipeline decides.
  tl.Config get _config => const tl.Config(
    geo: tl.GeoConfig(
      distanceFilter: 0,
      disableElasticity: true,
      filter: tl.LocationFilter(
        // Wide open rather than removed: the pipeline's own 50 m rule is the
        // one that counts, and letting bad fixes through to it means they are
        // counted and diagnosable rather than vanishing a layer below.
        trackingAccuracyThreshold: 100000,
        maxImpliedSpeed: 100000,
        // NOT the default, which is `adjust` — "smooth / correct rejected
        // locations before recording them". That would hand the pipeline
        // positions the plugin had already moved, presented as measurements.
        policy: tl.LocationFilterPolicy.ignore,
        // Kalman smoothing is left at its default of OFF. A1a is the
        // smoother, and two Kalman filters in series is not twice as good;
        // it is one filter with unknown behaviour.
      ),
    ),
    android: tl.AndroidConfig(
      fastestLocationUpdateInterval: 1000,
      // Deliver a fix even when the position has not changed. Standing at a
      // crossing is information: it is how moving time knows to stop counting.
      allowIdenticalLocations: true,
      foregroundService: tl.ForegroundServiceConfig(
        channelId: 'run_recording',
        channelName: 'Run recording',
        notificationTitle: 'Recording run',
        notificationText: 'Tracking your route',
        notificationPriority: tl.NotificationPriority.low,
      ),
    ),
    app: tl.AppConfig(
      // A run ends when you end it, not when Android decides to reclaim the
      // app, so the service must outlive the UI. It must NOT outlive the run:
      // startOnBoot would put a tracker on the phone that nobody started.
      stopOnTerminate: false,
    ),
  );

  @override
  Future<RecorderStatus> prepare() async {
    try {
      if (!_ready) {
        await tl.Tracelet.ready(_config);
        _ready = true;
      }

      var authorization = await tl.Tracelet.getLocationAuthorization();
      if (authorization == tl.AuthorizationStatus.notDetermined ||
          authorization == tl.AuthorizationStatus.denied) {
        authorization = await tl.Tracelet.requestLocationAuthorization();
      }

      // whenInUse is accepted rather than demanded. Recording works while the
      // screen is on and the app is foregrounded, which is most of a run, and
      // refusing to start at all would be a worse answer than recording with a
      // caveat. `always` is what survives the screen going off.
      if (authorization != tl.AuthorizationStatus.always &&
          authorization != tl.AuthorizationStatus.whenInUse) {
        return RecorderStatus.blocked(
          RecorderBlocker.permission,
          detail: authorization.name,
        );
      }

      final provider = await tl.Tracelet.getProviderState();
      if (!provider.enabled) {
        return const RecorderStatus.blocked(
          RecorderBlocker.locationServicesOff,
        );
      }

      return const RecorderStatus.ready();
    } on Exception catch (error) {
      // Platform boundary: degrade visibly rather than crash, per CLAUDE.md
      // section 4. The reason travels with the status so the screen can show
      // it instead of a spinner that never resolves.
      return RecorderStatus.blocked(
        RecorderBlocker.platformError,
        detail: '$error',
      );
    }
  }

  @override
  Future<RawFix?> currentPosition() async {
    try {
      if (!_ready) {
        await tl.Tracelet.ready(_config);
        _ready = true;
      }

      final location = await tl.Tracelet.getCurrentPosition(
        // A cached fix is accepted if it is recent enough, and on a phone that
        // has been used in the last few minutes that is the usual answer: the
        // map opens immediately and the receiver is never woken. Older than
        // that and it acquires, because a stale fix frames the wrong place and
        // a map of somewhere you are not is worse than a map that is loading.
        maximumAge: _framingMaxAgeMs,
        timeout: _framingTimeoutS,
        // The run comes off the stream. A one-shot written into the plugin's
        // own database would be a position nothing in this app ever reads.
        persist: false,
      );
      return _toRawFix(location);
    } on Exception {
      // Timed out, refused, or the platform failed. Whatever the receiver
      // already had is still better than an empty screen, and asking for it
      // never turns anything on — so it answers at once or not at all.
      return _lastKnown();
    }
  }

  Future<RawFix?> _lastKnown() async {
    try {
      final location = await tl.Tracelet.getLastKnownLocation();
      return location == null ? null : _toRawFix(location);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> start() async {
    // Reset here rather than in stop(): the counts have to outlive the stop so
    // the run being saved can report them.
    _received = 0;
    _undatable = 0;
    _subscription ??= tl.Tracelet.onLocation(_emit);
    await tl.Tracelet.start();
  }

  @override
  Future<void> stop() async {
    await tl.Tracelet.stop();
    await _subscription?.cancel();
    _subscription = null;
  }

  void _emit(tl.Location location) {
    _received++;
    final fix = _toRawFix(location);
    if (fix == null) {
      _undatable++;
      return;
    }
    _fixes.add(fix);
  }

  @override
  Future<OemPowerWarning?> oemPowerWarning() async {
    try {
      final health = await tl.Tracelet.getSettingsHealth();
      if (health['isAggressiveOem'] != true) return null;

      return OemPowerWarning(
        manufacturer: health['manufacturer'] as String? ?? 'unknown',
        model: health['model'] as String? ?? 'unknown',
        aggressionRating: health['aggressionRating'] as int? ?? 0,
        isExemptFromBatteryOptimisation:
            health['isIgnoringBatteryOptimizations'] == true,
      );
    } on Exception {
      // A missing diagnostic is not worth blocking a run over.
      return null;
    }
  }

  @override
  Future<bool> openPowerManagerSettings() async {
    try {
      return await tl.Tracelet.showPowerManager();
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _fixes.close();
  }
}

/// Translate a plugin location into the pipeline's input type.
///
/// Returns null for a fix that cannot be placed in time, which is the one
/// thing the pipeline cannot work around.
RawFix? _toRawFix(tl.Location location) {
  final timestamp = DateTime.tryParse(location.timestamp);
  if (timestamp == null) return null;

  final coords = location.coords;

  return RawFix(
    latitude: coords.latitude,
    longitude: coords.longitude,
    timestamp: timestamp.toUtc(),
    // Android reports a negative accuracy when it does not have one. Passing
    // that through would make an unknown-quality fix look like a perfect one,
    // so it becomes a number the pipeline will certainly reject instead.
    accuracyM: coords.accuracy < 0 ? _unusableAccuracyM : coords.accuracy,
    // Both are `double` on the plugin side with a negative sentinel for
    // "not available", and both are nullable in RawFix for exactly that case.
    // Zero would be a claim — sea level, standing still — rather than a gap.
    altitudeM: coords.altitude == 0 ? null : coords.altitude,
    speedMps: coords.speed < 0 ? null : coords.speed,
  );
}

/// Worse than any threshold the pipeline accepts.
const _unusableAccuracyM = 100000.0;

/// How stale a cached fix may be and still frame the map. Five minutes: long
/// enough to cover walking out of the door with the app already open, short
/// enough that it cannot point at the last place the phone was used.
const int _framingMaxAgeMs = 5 * 60 * 1000;

/// How long to wait for a framing fix before giving up on it. Ten seconds
/// rather than the plugin's default thirty — this is a camera position, and
/// half a minute of nothing is the blank screen it exists to prevent.
const _framingTimeoutS = 10;
