import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/data/repositories/steps_repository.dart';
import 'package:fitness_tracker/features/today/providers/today_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'steps_providers.g.dart';

/// Everything the steps ring needs to know about the platform.
///
/// Deliberately flat rather than a sealed hierarchy: the widget has to decide
/// what to draw from the combination of these, and a union type would just
/// move the same branching into the constructor.
@immutable
class StepsStatus {
  const StepsStatus({
    required this.availability,
    required this.permission,
    this.lastSync,
  });

  final HealthAvailability availability;
  final HealthPermissionStatus permission;

  /// Null when no sync was attempted, because it could not have succeeded.
  final StepsSyncOutcome? lastSync;

  bool get canRead =>
      availability.canRead && permission == HealthPermissionStatus.granted;

  /// Whether to offer the permission prompt inline.
  ///
  /// True while undetermined as well as after a refusal: Health Connect
  /// reports both as "not granted", and an app that stops offering after one
  /// ambiguous answer can never be turned back on.
  bool get needsPermission =>
      availability.canRead && permission != HealthPermissionStatus.granted;
}

/// The daily step goal the ring fills against.
///
/// A constant, not a setting: the training plan prescribes 8,000+ steps a day,
/// there is one user, and changing it is editing this line.
const stepsTarget = 8000;

/// Today's stored totals, or null when nothing has been recorded for today.
///
/// Reads the database, not the platform — so it keeps rendering the last
/// known figure when a sync fails, and updates the instant one lands.
@riverpod
Stream<DailyActivity?> todayActivity(Ref ref) =>
    ref.watch(stepsRepositoryProvider).watchDate(ref.watch(todayDateProvider));

/// Platform state for the steps ring, refreshed on demand.
///
/// [build] performs the sync, so invalidating this provider is what a resume
/// or a pull-to-refresh does. It never throws: every call underneath resolves
/// its failures to a value, because the Today screen must render whatever
/// this returns and must never be blocked by it.
@riverpod
class StepsPanel extends _$StepsPanel {
  @override
  Future<StepsStatus> build() async {
    final repository = ref.watch(stepsRepositoryProvider);
    final today = ref.watch(todayDateProvider);

    final availability = await repository.availability();
    if (!availability.canRead) {
      return StepsStatus(
        availability: availability,
        permission: HealthPermissionStatus.unknown,
      );
    }

    final permission = await repository.permissionStatus();
    if (permission != HealthPermissionStatus.granted) {
      return StepsStatus(availability: availability, permission: permission);
    }

    return StepsStatus(
      availability: availability,
      permission: permission,
      lastSync: await repository.syncToday(today: today),
    );
  }

  /// Re-reads the platform and re-syncs today. Used by resume and by
  /// pull-to-refresh.
  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }

  /// Shows the Health Connect permission sheet, then re-syncs.
  Future<void> requestPermission() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(stepsRepositoryProvider).requestPermissions();
      return build();
    });
  }

  /// Sends the user to the Play Store to install or update Health Connect.
  Future<void> openInstall() =>
      ref.read(healthRepositoryProvider).openInstall();
}
