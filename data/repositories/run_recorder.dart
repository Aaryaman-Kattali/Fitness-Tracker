import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:meta/meta.dart';

/// Why recording cannot start.
///
/// Every one of these has to reach the screen. A run that silently fails to
/// record is worse than one that refuses to start, because you find out an
/// hour later with nothing to show for it.
enum RecorderBlocker {
  /// The user has not granted location access, or granted only a level that
  /// will not survive the screen going off.
  permission,

  /// Location services are switched off device-wide.
  locationServicesOff,

  /// The plugin failed to initialise. Nothing here is recoverable in-app.
  platformError,
}

/// Whether a recording can start, and what is stopping it if not.
@immutable
class RecorderStatus {
  const RecorderStatus.ready() : blocker = null, detail = null;
  const RecorderStatus.blocked(this.blocker, {this.detail});

  final RecorderBlocker? blocker;

  /// Platform text, where there is any worth showing. Diagnostic, not a
  /// user-facing string.
  final String? detail;

  bool get canRecord => blocker == null;
}

/// A manufacturer whose power management is known to kill background services.
///
/// Samsung's One UI is the reason this exists: a foreground service with a
/// persistent notification is necessary but not sufficient there, and the
/// remaining gap can only be closed by the user in a settings screen this app
/// cannot change on their behalf.
@immutable
class OemPowerWarning {
  const OemPowerWarning({
    required this.manufacturer,
    required this.model,
    required this.aggressionRating,
    required this.isExemptFromBatteryOptimisation,
  });

  final String manufacturer;
  final String model;

  /// 0–5, per dontkillmyapp.com.
  final int aggressionRating;

  /// Whether the user has already granted this app an exemption.
  final bool isExemptFromBatteryOptimisation;

  /// Worth interrupting the user for: an aggressive OEM that has *not* already
  /// been told to leave this app alone.
  bool get needsAttention => !isExemptFromBatteryOptimisation;
}

/// Records a run, as a stream of raw GPS fixes.
///
/// The interface is deliberately narrow and deliberately speaks [RawFix],
/// which is the A1a pipeline's own input type and knows nothing about any
/// plugin. That is what lets the same pipeline run against a real receiver on
/// a phone and against a synthetic track in a test, without either side
/// knowing which it is.
abstract class RunRecorder {
  /// Check permissions and device state, asking the user if needed.
  ///
  /// Call before [start]. Safe to call repeatedly.
  Future<RecorderStatus> prepare();

  /// Fixes as they arrive, unmodified.
  ///
  /// No filtering, no smoothing, no reordering. Everything that decides what
  /// is a real position happens in the pipeline downstream, where it is under
  /// test. A repository that quietly cleaned this stream would be a second
  /// opinion nobody could see.
  Stream<RawFix> get fixes;

  /// How many positions the platform handed over since the last [start], and
  /// how many of those could not be turned into a [RawFix].
  ///
  /// Diagnostic only. It lives here rather than in the pipeline because the
  /// pipeline cannot see it: a fix dropped for an unparseable timestamp never
  /// arrives downstream, so counting arrivals below this line would report a
  /// perfect delivery record for a receiver that was losing fixes.
  ({int received, int undatable}) get delivery;

  /// Where the phone is now, so the map can be framed before a run starts.
  ///
  /// **Not part of recording, and deliberately not on the same path.** Nothing
  /// this returns reaches the pipeline: it exists so the screen has something
  /// to point a camera at in the seconds before [fixes] produces anything, and
  /// a position good enough to frame a map is nowhere near good enough to be a
  /// point in a run.
  ///
  /// Null when there is no position to be had — nothing cached, no fix in
  /// time, permission refused, platform error. The screen says it is locating;
  /// nothing crashes and no position is invented.
  Future<RawFix?> currentPosition();

  Future<void> start();
  Future<void> stop();

  /// Null when the manufacturer is not known to kill background work.
  Future<OemPowerWarning?> oemPowerWarning();

  /// Open the manufacturer's own power-management screen.
  ///
  /// Returns false when this device has no such screen, which is the good
  /// case: there is nothing for the user to fix.
  Future<bool> openPowerManagerSettings();

  Future<void> dispose();
}
