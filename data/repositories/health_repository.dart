import 'package:fitness_tracker/data/models/health_models.dart';

/// The whole platform-health boundary.
///
/// Everything that touches Health Connect goes through this interface, so the
/// rest of the app never imports the `health` plugin and never has to be run
/// on a device to be tested. `FakeHealthRepository` in `test/support` is the
/// other implementation.
///
/// No method on this interface throws. The platform's failure modes — no
/// provider installed, permission refused, permission revoked between two
/// calls, an emulator with no Health Connect at all — are all values, because
/// a thrown exception here would have to be caught in the widget layer and
/// the Today screen must never depend on any of this working.
abstract interface class HealthRepository {
  /// Whether the platform can serve health data at all.
  Future<HealthAvailability> availability();

  /// Whether the app currently holds the read permissions it needs.
  ///
  /// Worth re-reading before every sync: Health Connect lets the user revoke
  /// a grant at any time, and the app is not told when they do.
  Future<HealthPermissionStatus> permissionStatus();

  /// Shows the Health Connect permission sheet and reports the outcome.
  Future<HealthPermissionStatus> requestPermissions();

  /// Daily totals for each local calendar day from [from] to [to] inclusive.
  ///
  /// Days the platform has nothing for are omitted rather than returned as
  /// zero — a day with no data and a day spent sitting still are different
  /// things, and only the second one is a real zero.
  ///
  /// Returns an empty list rather than throwing if the read fails.
  Future<List<DailyActivity>> dailyTotals({
    required DateTime from,
    required DateTime to,
  });

  /// Sends the user to the Play Store listing for Health Connect.
  Future<void> openInstall();

  /// Everything the platform will say about itself, for the debug screen.
  ///
  /// [now] anchors both the raw dump window and the today window, so the
  /// debug date override moves them together.
  ///
  /// Unlike every other method here, this one keeps the platform's errors as
  /// strings instead of resolving them to a value: the whole reason it exists
  /// is that a swallowed error and an empty result are indistinguishable.
  Future<HealthDiagnostics> diagnose({required DateTime now});
}
