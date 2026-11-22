import 'package:meta/meta.dart';

/// Where a day's totals came from.
///
/// Stored in `daily_steps.source` so a row can be attributed later, once
/// there is more than one possible provider.
abstract final class ActivitySource {
  /// Google Health Connect, via the `health` plugin.
  static const healthConnect = 'health_connect';
}

/// Whether the platform can serve health data at all.
///
/// Distinct from permission: the app can hold every permission it asked for
/// and still be on a device with no Health Connect provider installed, which
/// is the normal case on an emulator.
enum HealthAvailability {
  /// Health Connect is present and usable.
  available,

  /// Android, but no Health Connect provider is installed.
  notInstalled,

  /// Installed, but too old for the client this app builds against.
  needsUpdate,

  /// Not Android, or the plugin is not registered in this binary — an
  /// emulator, a widget test, or a desktop debug run.
  unsupported
  ;

  bool get canRead => this == HealthAvailability.available;

  /// Whether sending the user to the Play Store is a sensible offer.
  bool get isResolvableByInstall =>
      this == HealthAvailability.notInstalled ||
      this == HealthAvailability.needsUpdate;
}

/// Whether the app may read the types it needs.
enum HealthPermissionStatus {
  granted,

  /// Asked and refused, or granted once and revoked in Health Connect since.
  denied,

  /// Not yet determined — Health Connect cannot always distinguish "never
  /// asked" from "asked and denied", so this is only used before the first ask.
  unknown,
}

/// One raw record as the platform handed it over.
///
/// Deliberately stringly-typed: this exists to be read by a human in the
/// debug Settings screen, not computed on. Nothing in the app branches on it.
@immutable
class HealthRecordSample {
  const HealthRecordSample({
    required this.start,
    required this.end,
    required this.value,
    required this.unit,
    required this.sourcePackage,
    required this.recordingMethod,
  });

  final DateTime start;
  final DateTime end;
  final String value;
  final String unit;

  /// The writing app's package name. On Android the plugin puts this in
  /// `sourceName`; its `sourceId` is empty for ordinary records.
  final String sourcePackage;
  final String recordingMethod;
}

/// What one data type looks like right now: granted, and what it returns.
@immutable
class HealthTypeDiagnostic {
  const HealthTypeDiagnostic({
    required this.type,
    required this.isGranted,
    required this.records,
    this.error,
  });

  final String type;

  /// Null when Health Connect will not say — it cannot always tell "never
  /// asked" from "asked and refused".
  final bool? isGranted;
  final List<HealthRecordSample> records;

  /// The read's own failure, kept rather than swallowed. A read that throws
  /// and a read that returns nothing look identical in the Today screen.
  final String? error;
}

/// Everything the app can see of Health Connect, for the debug screen.
///
/// The point of this type is that steps reading zero has several causes that
/// are indistinguishable from the Today screen — no provider, a refused
/// permission, an empty store, a query window off by a timezone — and only
/// showing all of them at once separates them.
@immutable
class HealthDiagnostics {
  const HealthDiagnostics({
    required this.availability,
    required this.rawSdkStatus,
    required this.rawWindowFrom,
    required this.rawWindowTo,
    required this.todayWindowFrom,
    required this.todayWindowTo,
    required this.todayStepsAggregate,
    required this.types,
    this.error,
  });

  final HealthAvailability availability;

  /// The plugin's own enum name, unmapped, so a status this app does not model
  /// is still visible.
  final String rawSdkStatus;

  /// The window the raw record dump used.
  final DateTime rawWindowFrom;
  final DateTime rawWindowTo;

  /// The window `dailyTotals` uses for today — the one that actually feeds the
  /// ring. Shown next to the raw dump because a midnight or timezone mismatch
  /// only shows up in the comparison.
  final DateTime todayWindowFrom;
  final DateTime todayWindowTo;

  /// `getTotalStepsInInterval` over the today window. Null means the platform
  /// returned nothing, which is what the ring is currently seeing.
  final int? todayStepsAggregate;

  final List<HealthTypeDiagnostic> types;
  final String? error;
}

/// One calendar day of movement.
@immutable
class DailyActivity {
  const DailyActivity({
    required this.date,
    required this.steps,
    required this.activeKcal,
    required this.source,
  });

  /// Midnight on the local calendar day these totals cover.
  final DateTime date;
  final int steps;
  final double activeKcal;
  final String source;

  /// Progress towards [target], clamped to 0..1 so an over-target day fills
  /// the ring exactly once rather than wrapping.
  double progressTowards(int target) {
    if (target <= 0) return 0;
    return (steps / target).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is DailyActivity &&
      other.date == date &&
      other.steps == steps &&
      other.activeKcal == activeKcal &&
      other.source == source;

  @override
  int get hashCode => Object.hash(date, steps, activeKcal, source);

  @override
  String toString() =>
      'DailyActivity($date, steps: $steps, kcal: $activeKcal, $source)';
}
