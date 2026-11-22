// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's single database connection.
///
/// Overridden in tests with an in-memory executor.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The app's single database connection.
///
/// Overridden in tests with an in-memory executor.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The app's single database connection.
  ///
  /// Overridden in tests with an in-memory executor.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'b365a9b813ebcce079ba1acd59613771ada6cfd9';

@ProviderFor(planDao)
final planDaoProvider = PlanDaoProvider._();

final class PlanDaoProvider
    extends $FunctionalProvider<PlanDao, PlanDao, PlanDao>
    with $Provider<PlanDao> {
  PlanDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planDaoHash();

  @$internal
  @override
  $ProviderElement<PlanDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanDao create(Ref ref) {
    return planDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanDao>(value),
    );
  }
}

String _$planDaoHash() => r'3ad93b4d3e54059476939844856467950e938963';

@ProviderFor(workoutDao)
final workoutDaoProvider = WorkoutDaoProvider._();

final class WorkoutDaoProvider
    extends $FunctionalProvider<WorkoutDao, WorkoutDao, WorkoutDao>
    with $Provider<WorkoutDao> {
  WorkoutDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutDaoHash();

  @$internal
  @override
  $ProviderElement<WorkoutDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkoutDao create(Ref ref) {
    return workoutDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutDao>(value),
    );
  }
}

String _$workoutDaoHash() => r'2ef11c4c3cb393ec79909f3f6f875fdad0b51122';

@ProviderFor(planRepository)
final planRepositoryProvider = PlanRepositoryProvider._();

final class PlanRepositoryProvider
    extends $FunctionalProvider<PlanRepository, PlanRepository, PlanRepository>
    with $Provider<PlanRepository> {
  PlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlanRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanRepository create(Ref ref) {
    return planRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanRepository>(value),
    );
  }
}

String _$planRepositoryHash() => r'b9ddc9c30e49f06b982c496a9c175c03b34f41d3';

@ProviderFor(workoutRepository)
final workoutRepositoryProvider = WorkoutRepositoryProvider._();

final class WorkoutRepositoryProvider
    extends
        $FunctionalProvider<
          WorkoutRepository,
          WorkoutRepository,
          WorkoutRepository
        >
    with $Provider<WorkoutRepository> {
  WorkoutRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkoutRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkoutRepository create(Ref ref) {
    return workoutRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutRepository>(value),
    );
  }
}

String _$workoutRepositoryHash() => r'17098fd51cc46d3bd76ede817da9c0158c124dc0';

@ProviderFor(stepsDao)
final stepsDaoProvider = StepsDaoProvider._();

final class StepsDaoProvider
    extends $FunctionalProvider<StepsDao, StepsDao, StepsDao>
    with $Provider<StepsDao> {
  StepsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stepsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stepsDaoHash();

  @$internal
  @override
  $ProviderElement<StepsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StepsDao create(Ref ref) {
    return stepsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StepsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StepsDao>(value),
    );
  }
}

String _$stepsDaoHash() => r'fb5b2ad19736c6aed6631743a333f90cbb44858d';

/// The platform-health boundary.
///
/// Overridden with a fake in tests — nothing below this provider is reachable
/// off a device, which is exactly why it is a provider and not a direct
/// construction inside [stepsRepository].

@ProviderFor(healthRepository)
final healthRepositoryProvider = HealthRepositoryProvider._();

/// The platform-health boundary.
///
/// Overridden with a fake in tests — nothing below this provider is reachable
/// off a device, which is exactly why it is a provider and not a direct
/// construction inside [stepsRepository].

final class HealthRepositoryProvider
    extends
        $FunctionalProvider<
          HealthRepository,
          HealthRepository,
          HealthRepository
        >
    with $Provider<HealthRepository> {
  /// The platform-health boundary.
  ///
  /// Overridden with a fake in tests — nothing below this provider is reachable
  /// off a device, which is exactly why it is a provider and not a direct
  /// construction inside [stepsRepository].
  HealthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthRepository create(Ref ref) {
    return healthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthRepository>(value),
    );
  }
}

String _$healthRepositoryHash() => r'df7e5cd6d9af84cc7a4c32017b93e596330794b5';

@ProviderFor(stepsRepository)
final stepsRepositoryProvider = StepsRepositoryProvider._();

final class StepsRepositoryProvider
    extends
        $FunctionalProvider<StepsRepository, StepsRepository, StepsRepository>
    with $Provider<StepsRepository> {
  StepsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stepsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stepsRepositoryHash();

  @$internal
  @override
  $ProviderElement<StepsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StepsRepository create(Ref ref) {
    return stepsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StepsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StepsRepository>(value),
    );
  }
}

String _$stepsRepositoryHash() => r'd001c7d9f9ebe361f90df10c9de27dce71e02ca5';
