import 'dart:io';

import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/repositories/health_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// [HealthRepository] backed by Google Health Connect via the `health` plugin.
///
/// This is the only file in the app allowed to import `health`.
///
/// Every plugin call is wrapped. The plugin throws [UnsupportedError] from its
/// own availability check when no Health Connect provider is installed, and
/// the method channel throws `MissingPluginException` when the app is not
/// running on a device at all — a widget test, or a desktop debug run. Both
/// are ordinary conditions here, not bugs, so they resolve to a value.
class HealthConnectRepository implements HealthRepository {
  HealthConnectRepository({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  /// The types the app reads. Read-only: this app is not a source of truth
  /// for step data and never writes back.
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const List<HealthDataAccess> _access = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<HealthAvailability> availability() async {
    // Android-only app; anything else is a development environment.
    if (!Platform.isAndroid) return HealthAvailability.unsupported;

    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      return switch (status) {
        HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          HealthAvailability.needsUpdate,
        HealthConnectSdkStatus.sdkUnavailable =>
          HealthAvailability.notInstalled,
        // The plugin returns null on iOS and when the status call itself
        // failed; on Android the second is the only way to get here.
        null => HealthAvailability.unsupported,
      };
    } on Object catch (error) {
      _log('availability', error);
      return HealthAvailability.unsupported;
    }
  }

  @override
  Future<HealthPermissionStatus> permissionStatus() async {
    try {
      await _ensureConfigured();
      final granted = await _health.hasPermissions(
        _types,
        permissions: _access,
      );
      return switch (granted) {
        true => HealthPermissionStatus.granted,
        false => HealthPermissionStatus.denied,
        // Health Connect cannot always tell "never asked" from "asked and
        // refused"; both surface as null.
        null => HealthPermissionStatus.unknown,
      };
    } on Object catch (error) {
      _log('permissionStatus', error);
      return HealthPermissionStatus.unknown;
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _access,
      );
      return granted
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.denied;
    } on Object catch (error) {
      _log('requestPermissions', error);
      return HealthPermissionStatus.denied;
    }
  }

  @override
  Future<List<DailyActivity>> dailyTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      await _ensureConfigured();
      return await _readTotals(from: from, to: to);
    } on Object catch (error) {
      _log('dailyTotals', error);
      return const [];
    }
  }

  Future<List<DailyActivity>> _readTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    final firstDay = _midnight(from);
    final lastDay = _midnight(to);
    if (lastDay.isBefore(firstDay)) return const [];

    // One query for energy across the whole window, bucketed locally, rather
    // than one per day: the step aggregate below already costs a call per day
    // and the energy records are small.
    final energyByDay = await _activeEnergyByDay(
      from: firstDay,
      to: _endOfDay(lastDay),
    );

    final results = <DailyActivity>[];
    for (var day = firstDay; !day.isAfter(lastDay); day = _nextDay(day)) {
      final steps = await _health.getTotalStepsInInterval(day, _endOfDay(day));
      final kcal = energyByDay[day];

      // Nothing at all for this day: leave it absent rather than writing a
      // zero row that would read as "you did not move".
      if (steps == null && kcal == null) continue;

      results.add(
        DailyActivity(
          date: day,
          steps: steps ?? 0,
          activeKcal: kcal ?? 0,
          source: ActivitySource.healthConnect,
        ),
      );
    }
    return results;
  }

  /// Active energy summed per local calendar day, keyed on midnight.
  Future<Map<DateTime, double>> _activeEnergyByDay({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: from,
      endTime: to,
    );

    final totals = <DateTime, double>{};
    for (final point in points) {
      final value = point.value;
      if (value is! NumericHealthValue) continue;
      // A record is attributed to the day it started on. Records spanning
      // midnight are rare and short; splitting them would cost a second pass
      // for no visible difference in a daily total.
      final day = _midnight(point.dateFrom);
      totals[day] = (totals[day] ?? 0) + value.numericValue.toDouble();
    }
    return totals;
  }

  @override
  Future<HealthDiagnostics> diagnose({required DateTime now}) async {
    final todayFrom = _midnight(now);
    final todayTo = _endOfDay(todayFrom);
    // 48 h back from *midnight*, not from now: it has to cover the whole of
    // yesterday, or a record written once per day would be cut in half and
    // look like a partial write.
    final rawFrom = todayFrom.subtract(const Duration(hours: 48));

    var rawSdkStatus = 'not read';
    int? aggregate;
    String? fatal;

    try {
      await _ensureConfigured();
      rawSdkStatus =
          (await _health.getHealthConnectSdkStatus())?.name ?? 'null';
      aggregate = await _health.getTotalStepsInInterval(todayFrom, todayTo);
    } on Object catch (error) {
      fatal = '$error';
    }

    return HealthDiagnostics(
      availability: await availability(),
      rawSdkStatus: rawSdkStatus,
      rawWindowFrom: rawFrom,
      rawWindowTo: todayTo,
      todayWindowFrom: todayFrom,
      todayWindowTo: todayTo,
      todayStepsAggregate: aggregate,
      types: [
        for (final type in _types)
          await _diagnoseType(type, from: rawFrom, to: todayTo),
      ],
      error: fatal,
    );
  }

  Future<HealthTypeDiagnostic> _diagnoseType(
    HealthDataType type, {
    required DateTime from,
    required DateTime to,
  }) async {
    bool? granted;
    try {
      granted = await _health.hasPermissions(
        [type],
        permissions: const [HealthDataAccess.READ],
      );
    } on Object catch (error) {
      return HealthTypeDiagnostic(
        type: type.name,
        isGranted: null,
        records: const [],
        error: '$error',
      );
    }

    try {
      final points = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: from,
        endTime: to,
      );
      return HealthTypeDiagnostic(
        type: type.name,
        isGranted: granted,
        records: [
          for (final point in points)
            HealthRecordSample(
              start: point.dateFrom,
              end: point.dateTo,
              value: '${point.value}',
              unit: point.unitString,
              sourcePackage: point.sourceName,
              recordingMethod: point.recordingMethod.name,
            ),
        ],
      );
    } on Object catch (error) {
      return HealthTypeDiagnostic(
        type: type.name,
        isGranted: granted,
        records: const [],
        error: '$error',
      );
    }
  }

  @override
  Future<void> openInstall() async {
    try {
      await _health.installHealthConnect();
    } on Object catch (error) {
      _log('openInstall', error);
    }
  }

  static DateTime _midnight(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// The last instant of [day], as an exclusive-feeling but inclusive bound.
  static DateTime _endOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

  /// Adds a day by calendar arithmetic rather than `Duration(days: 1)`, so a
  /// daylight-saving boundary does not land the loop at 23:00 the same day.
  static DateTime _nextDay(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);

  static void _log(String call, Object error) =>
      debugPrint('HealthConnectRepository.$call failed: $error');
}
