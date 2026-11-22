// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The prescribed session behind a plan day.

@ProviderFor(sessionPlan)
final sessionPlanProvider = SessionPlanFamily._();

/// The prescribed session behind a plan day.

final class SessionPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionPlan?>,
          SessionPlan?,
          FutureOr<SessionPlan?>
        >
    with $FutureModifier<SessionPlan?>, $FutureProvider<SessionPlan?> {
  /// The prescribed session behind a plan day.
  SessionPlanProvider._({
    required SessionPlanFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionPlanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionPlanHash();

  @override
  String toString() {
    return r'sessionPlanProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SessionPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionPlan?> create(Ref ref) {
    final argument = this.argument as int;
    return sessionPlan(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionPlanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionPlanHash() => r'b2324d8fc064f5cae7bcc752322ddbdc06197e06';

/// The prescribed session behind a plan day.

final class SessionPlanFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SessionPlan?>, int> {
  SessionPlanFamily._()
    : super(
        retry: null,
        name: r'sessionPlanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The prescribed session behind a plan day.

  SessionPlanProvider call(int planDayId) =>
      SessionPlanProvider._(argument: planDayId, from: this);

  @override
  String toString() => r'sessionPlanProvider';
}

/// The workout being logged into for [planDayId].
///
/// Kept alive so that moving between exercises does not re-run the lookup, and
/// idempotent regardless: an unfinished workout from the same day is reused
/// rather than replaced.

@ProviderFor(activeWorkoutId)
final activeWorkoutIdProvider = ActiveWorkoutIdFamily._();

/// The workout being logged into for [planDayId].
///
/// Kept alive so that moving between exercises does not re-run the lookup, and
/// idempotent regardless: an unfinished workout from the same day is reused
/// rather than replaced.

final class ActiveWorkoutIdProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// The workout being logged into for [planDayId].
  ///
  /// Kept alive so that moving between exercises does not re-run the lookup, and
  /// idempotent regardless: an unfinished workout from the same day is reused
  /// rather than replaced.
  ActiveWorkoutIdProvider._({
    required ActiveWorkoutIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'activeWorkoutIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutIdHash();

  @override
  String toString() {
    return r'activeWorkoutIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as int;
    return activeWorkoutId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveWorkoutIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeWorkoutIdHash() => r'8ca7d1cab0a68faf0861107138092d184cdbcc54';

/// The workout being logged into for [planDayId].
///
/// Kept alive so that moving between exercises does not re-run the lookup, and
/// idempotent regardless: an unfinished workout from the same day is reused
/// rather than replaced.

final class ActiveWorkoutIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, int> {
  ActiveWorkoutIdFamily._()
    : super(
        retry: null,
        name: r'activeWorkoutIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The workout being logged into for [planDayId].
  ///
  /// Kept alive so that moving between exercises does not re-run the lookup, and
  /// idempotent regardless: an unfinished workout from the same day is reused
  /// rather than replaced.

  ActiveWorkoutIdProvider call(int planDayId) =>
      ActiveWorkoutIdProvider._(argument: planDayId, from: this);

  @override
  String toString() => r'activeWorkoutIdProvider';
}

/// The warm-up lines already ticked in [workoutId].

@ProviderFor(warmupChecks)
final warmupChecksProvider = WarmupChecksFamily._();

/// The warm-up lines already ticked in [workoutId].

final class WarmupChecksProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<WarmupCheckKey>>,
          Set<WarmupCheckKey>,
          Stream<Set<WarmupCheckKey>>
        >
    with
        $FutureModifier<Set<WarmupCheckKey>>,
        $StreamProvider<Set<WarmupCheckKey>> {
  /// The warm-up lines already ticked in [workoutId].
  WarmupChecksProvider._({
    required WarmupChecksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'warmupChecksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$warmupChecksHash();

  @override
  String toString() {
    return r'warmupChecksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<WarmupCheckKey>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<WarmupCheckKey>> create(Ref ref) {
    final argument = this.argument as int;
    return warmupChecks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WarmupChecksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$warmupChecksHash() => r'2f7a8f3017249621b6acd03db9970760aea2035b';

/// The warm-up lines already ticked in [workoutId].

final class WarmupChecksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<WarmupCheckKey>>, int> {
  WarmupChecksFamily._()
    : super(
        retry: null,
        name: r'warmupChecksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The warm-up lines already ticked in [workoutId].

  WarmupChecksProvider call(int workoutId) =>
      WarmupChecksProvider._(argument: workoutId, from: this);

  @override
  String toString() => r'warmupChecksProvider';
}

/// Every set logged so far in [workoutId].

@ProviderFor(workoutSets)
final workoutSetsProvider = WorkoutSetsFamily._();

/// Every set logged so far in [workoutId].

final class WorkoutSetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoggedSet>>,
          List<LoggedSet>,
          Stream<List<LoggedSet>>
        >
    with $FutureModifier<List<LoggedSet>>, $StreamProvider<List<LoggedSet>> {
  /// Every set logged so far in [workoutId].
  WorkoutSetsProvider._({
    required WorkoutSetsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'workoutSetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutSetsHash();

  @override
  String toString() {
    return r'workoutSetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LoggedSet>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LoggedSet>> create(Ref ref) {
    final argument = this.argument as int;
    return workoutSets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutSetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutSetsHash() => r'b1ba63ff46debb111343585f1b646655b0fac733';

/// Every set logged so far in [workoutId].

final class WorkoutSetsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LoggedSet>>, int> {
  WorkoutSetsFamily._()
    : super(
        retry: null,
        name: r'workoutSetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every set logged so far in [workoutId].

  WorkoutSetsProvider call(int workoutId) =>
      WorkoutSetsProvider._(argument: workoutId, from: this);

  @override
  String toString() => r'workoutSetsProvider';
}

/// The sets logged for one exercise in the session in progress.

@ProviderFor(exerciseSets)
final exerciseSetsProvider = ExerciseSetsFamily._();

/// The sets logged for one exercise in the session in progress.

final class ExerciseSetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoggedSet>>,
          List<LoggedSet>,
          Stream<List<LoggedSet>>
        >
    with $FutureModifier<List<LoggedSet>>, $StreamProvider<List<LoggedSet>> {
  /// The sets logged for one exercise in the session in progress.
  ExerciseSetsProvider._({
    required ExerciseSetsFamily super.from,
    required ({int workoutId, int exerciseId}) super.argument,
  }) : super(
         retry: null,
         name: r'exerciseSetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseSetsHash();

  @override
  String toString() {
    return r'exerciseSetsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<LoggedSet>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LoggedSet>> create(Ref ref) {
    final argument = this.argument as ({int workoutId, int exerciseId});
    return exerciseSets(
      ref,
      workoutId: argument.workoutId,
      exerciseId: argument.exerciseId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseSetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseSetsHash() => r'7e8d6702b3009d7df8796e34508a7992a0cc5b75';

/// The sets logged for one exercise in the session in progress.

final class ExerciseSetsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<LoggedSet>>,
          ({int workoutId, int exerciseId})
        > {
  ExerciseSetsFamily._()
    : super(
        retry: null,
        name: r'exerciseSetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The sets logged for one exercise in the session in progress.

  ExerciseSetsProvider call({
    required int workoutId,
    required int exerciseId,
  }) => ExerciseSetsProvider._(
    argument: (workoutId: workoutId, exerciseId: exerciseId),
    from: this,
  );

  @override
  String toString() => r'exerciseSetsProvider';
}

/// Last session's numbers for an exercise, excluding the one in progress.

@ProviderFor(lastExerciseSession)
final lastExerciseSessionProvider = LastExerciseSessionFamily._();

/// Last session's numbers for an exercise, excluding the one in progress.

final class LastExerciseSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseSession?>,
          ExerciseSession?,
          FutureOr<ExerciseSession?>
        >
    with $FutureModifier<ExerciseSession?>, $FutureProvider<ExerciseSession?> {
  /// Last session's numbers for an exercise, excluding the one in progress.
  LastExerciseSessionProvider._({
    required LastExerciseSessionFamily super.from,
    required ({int exerciseId, int? excludingWorkoutId}) super.argument,
  }) : super(
         retry: null,
         name: r'lastExerciseSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lastExerciseSessionHash();

  @override
  String toString() {
    return r'lastExerciseSessionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ExerciseSession?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExerciseSession?> create(Ref ref) {
    final argument =
        this.argument as ({int exerciseId, int? excludingWorkoutId});
    return lastExerciseSession(
      ref,
      exerciseId: argument.exerciseId,
      excludingWorkoutId: argument.excludingWorkoutId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LastExerciseSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lastExerciseSessionHash() =>
    r'0e4ee7bed7bc79174268deb00f3844856c33bef5';

/// Last session's numbers for an exercise, excluding the one in progress.

final class LastExerciseSessionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ExerciseSession?>,
          ({int exerciseId, int? excludingWorkoutId})
        > {
  LastExerciseSessionFamily._()
    : super(
        retry: null,
        name: r'lastExerciseSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Last session's numbers for an exercise, excluding the one in progress.

  LastExerciseSessionProvider call({
    required int exerciseId,
    int? excludingWorkoutId,
  }) => LastExerciseSessionProvider._(
    argument: (exerciseId: exerciseId, excludingWorkoutId: excludingWorkoutId),
    from: this,
  );

  @override
  String toString() => r'lastExerciseSessionProvider';
}

/// The workout history list.

@ProviderFor(workoutHistory)
final workoutHistoryProvider = WorkoutHistoryProvider._();

/// The workout history list.

final class WorkoutHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkoutSummary>>,
          List<WorkoutSummary>,
          Stream<List<WorkoutSummary>>
        >
    with
        $FutureModifier<List<WorkoutSummary>>,
        $StreamProvider<List<WorkoutSummary>> {
  /// The workout history list.
  WorkoutHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<WorkoutSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkoutSummary>> create(Ref ref) {
    return workoutHistory(ref);
  }
}

String _$workoutHistoryHash() => r'd4d94f1c56365bf26b5712dede4285d9ba3edb2b';

/// Exercises trained in a past workout.

@ProviderFor(workoutExercises)
final workoutExercisesProvider = WorkoutExercisesFamily._();

/// Exercises trained in a past workout.

final class WorkoutExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({int exerciseId, bool isUnilateral, String name})>>,
          List<({int exerciseId, bool isUnilateral, String name})>,
          FutureOr<List<({int exerciseId, bool isUnilateral, String name})>>
        >
    with
        $FutureModifier<
          List<({int exerciseId, bool isUnilateral, String name})>
        >,
        $FutureProvider<
          List<({int exerciseId, bool isUnilateral, String name})>
        > {
  /// Exercises trained in a past workout.
  WorkoutExercisesProvider._({
    required WorkoutExercisesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'workoutExercisesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutExercisesHash();

  @override
  String toString() {
    return r'workoutExercisesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<
    List<({int exerciseId, bool isUnilateral, String name})>
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<({int exerciseId, bool isUnilateral, String name})>> create(
    Ref ref,
  ) {
    final argument = this.argument as int;
    return workoutExercises(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutExercisesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutExercisesHash() => r'26ff9b1c26d4d9ab91dfa471371696af635b47f1';

/// Exercises trained in a past workout.

final class WorkoutExercisesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<({int exerciseId, bool isUnilateral, String name})>>,
          int
        > {
  WorkoutExercisesFamily._()
    : super(
        retry: null,
        name: r'workoutExercisesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Exercises trained in a past workout.

  WorkoutExercisesProvider call(int workoutId) =>
      WorkoutExercisesProvider._(argument: workoutId, from: this);

  @override
  String toString() => r'workoutExercisesProvider';
}
