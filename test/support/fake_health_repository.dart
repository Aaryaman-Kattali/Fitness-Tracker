import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/repositories/health_repository.dart';

/// An in-memory [HealthRepository].
///
/// Health Connect cannot be driven from a test — there is no device, no
/// provider app and no permission sheet — so every degraded state the UI has
/// to handle is reachable only through this. Each platform answer is a plain
/// mutable field so a test can change it between calls, which is how
/// revocation partway through a session is reproduced.
class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({
    this.availabilityResult = HealthAvailability.available,
    this.permissionResult = HealthPermissionStatus.granted,
    this.grantOnRequest = true,
    Map<DateTime, DailyActivity>? days,
  }) : days = days ?? {};

  HealthAvailability availabilityResult;
  HealthPermissionStatus permissionResult;

  /// What the permission sheet will answer next.
  bool grantOnRequest;

  /// The platform's data, keyed on midnight of the day it belongs to.
  final Map<DateTime, DailyActivity> days;

  int permissionRequests = 0;
  int installPrompts = 0;

  @override
  Future<HealthAvailability> availability() async => availabilityResult;

  @override
  Future<HealthPermissionStatus> permissionStatus() async => permissionResult;

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    permissionRequests++;
    return permissionResult = grantOnRequest
        ? HealthPermissionStatus.granted
        : HealthPermissionStatus.denied;
  }

  @override
  Future<List<DailyActivity>> dailyTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    final first = _midnight(from);
    final last = _midnight(to);
    return days.entries
        .where((e) => !e.key.isBefore(first) && !e.key.isAfter(last))
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> openInstall() async => installPrompts++;

  /// Records the diagnostic screen will show. Empty unless a test sets it.
  List<HealthRecordSample> stepRecords = const [];

  @override
  Future<HealthDiagnostics> diagnose({required DateTime now}) async {
    final todayFrom = _midnight(now);
    final todayTo = DateTime(
      todayFrom.year,
      todayFrom.month,
      todayFrom.day,
      23,
      59,
      59,
      999,
    );

    return HealthDiagnostics(
      availability: availabilityResult,
      rawSdkStatus: availabilityResult.name,
      rawWindowFrom: todayFrom.subtract(const Duration(hours: 48)),
      rawWindowTo: todayTo,
      todayWindowFrom: todayFrom,
      todayWindowTo: todayTo,
      todayStepsAggregate: days[todayFrom]?.steps,
      types: [
        HealthTypeDiagnostic(
          type: 'STEPS',
          isGranted: permissionResult == HealthPermissionStatus.granted,
          records: stepRecords,
        ),
        HealthTypeDiagnostic(
          type: 'ACTIVE_ENERGY_BURNED',
          isGranted: permissionResult == HealthPermissionStatus.granted,
          records: const [],
        ),
      ],
    );
  }

  /// Seeds one day of platform data.
  void setDay(DateTime date, {required int steps, double activeKcal = 0}) {
    final day = _midnight(date);
    days[day] = DailyActivity(
      date: day,
      steps: steps,
      activeKcal: activeKcal,
      source: ActivitySource.healthConnect,
    );
  }

  static DateTime _midnight(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
