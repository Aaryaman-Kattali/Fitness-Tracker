// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The date the Today screen is rendering.
///
/// Goes through the effective clock so a debug date override moves the whole
/// screen — the session, the date line and any workout started from here — in
/// one step. Overridden in tests to pin a weekday.

@ProviderFor(todayDate)
final todayDateProvider = TodayDateProvider._();

/// The date the Today screen is rendering.
///
/// Goes through the effective clock so a debug date override moves the whole
/// screen — the session, the date line and any workout started from here — in
/// one step. Overridden in tests to pin a weekday.

final class TodayDateProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// The date the Today screen is rendering.
  ///
  /// Goes through the effective clock so a debug date override moves the whole
  /// screen — the session, the date line and any workout started from here — in
  /// one step. Overridden in tests to pin a weekday.
  TodayDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayDateHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return todayDate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$todayDateHash() => r'ea82244ef31ea78fbb61b6de45183451814ca00c';

/// Today's lifting session, or null on cardio/rest days.

@ProviderFor(todaySession)
final todaySessionProvider = TodaySessionProvider._();

/// Today's lifting session, or null on cardio/rest days.

final class TodaySessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionPlan?>,
          SessionPlan?,
          FutureOr<SessionPlan?>
        >
    with $FutureModifier<SessionPlan?>, $FutureProvider<SessionPlan?> {
  /// Today's lifting session, or null on cardio/rest days.
  TodaySessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaySessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaySessionHash();

  @$internal
  @override
  $FutureProviderElement<SessionPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionPlan?> create(Ref ref) {
    return todaySession(ref);
  }
}

String _$todaySessionHash() => r'dc8761f129d46589855daec5d4567615eb2ba326';

/// Label for a day with no lifting session.

@ProviderFor(todayRestLabel)
final todayRestLabelProvider = TodayRestLabelProvider._();

/// Label for a day with no lifting session.

final class TodayRestLabelProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Label for a day with no lifting session.
  TodayRestLabelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayRestLabelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayRestLabelHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return todayRestLabel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$todayRestLabelHash() => r'532bc098ca2804991f6d8f4e7722eed27ad087aa';

/// Every plan day, for the "start another session" picker.

@ProviderFor(allPlanDays)
final allPlanDaysProvider = AllPlanDaysProvider._();

/// Every plan day, for the "start another session" picker.

final class AllPlanDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({PlanDayKey dayKey, int id, String name})>>,
          List<({PlanDayKey dayKey, int id, String name})>,
          FutureOr<List<({PlanDayKey dayKey, int id, String name})>>
        >
    with
        $FutureModifier<List<({PlanDayKey dayKey, int id, String name})>>,
        $FutureProvider<List<({PlanDayKey dayKey, int id, String name})>> {
  /// Every plan day, for the "start another session" picker.
  AllPlanDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPlanDaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPlanDaysHash();

  @$internal
  @override
  $FutureProviderElement<List<({PlanDayKey dayKey, int id, String name})>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<({PlanDayKey dayKey, int id, String name})>> create(Ref ref) {
    return allPlanDays(ref);
  }
}

String _$allPlanDaysHash() => r'4dab886da85ec3057607d5d82177406a927dc6f4';

/// The workout already in progress for today's session, if any.
///
/// Read-only on purpose — merely rendering the Today screen must not create a
/// workout row. Autodisposed so that returning from a session re-runs it and
/// the button label stays honest.

@ProviderFor(openSessionId)
final openSessionIdProvider = OpenSessionIdFamily._();

/// The workout already in progress for today's session, if any.
///
/// Read-only on purpose — merely rendering the Today screen must not create a
/// workout row. Autodisposed so that returning from a session re-runs it and
/// the button label stays honest.

final class OpenSessionIdProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// The workout already in progress for today's session, if any.
  ///
  /// Read-only on purpose — merely rendering the Today screen must not create a
  /// workout row. Autodisposed so that returning from a session re-runs it and
  /// the button label stays honest.
  OpenSessionIdProvider._({
    required OpenSessionIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'openSessionIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openSessionIdHash();

  @override
  String toString() {
    return r'openSessionIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as int;
    return openSessionId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OpenSessionIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openSessionIdHash() => r'891930594a60331e3e0aa184474ddfe852641793';

/// The workout already in progress for today's session, if any.
///
/// Read-only on purpose — merely rendering the Today screen must not create a
/// workout row. Autodisposed so that returning from a session re-runs it and
/// the button label stays honest.

final class OpenSessionIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, int> {
  OpenSessionIdFamily._()
    : super(
        retry: null,
        name: r'openSessionIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The workout already in progress for today's session, if any.
  ///
  /// Read-only on purpose — merely rendering the Today screen must not create a
  /// workout row. Autodisposed so that returning from a session re-runs it and
  /// the button label stays honest.

  OpenSessionIdProvider call(int planDayId) =>
      OpenSessionIdProvider._(argument: planDayId, from: this);

  @override
  String toString() => r'openSessionIdProvider';
}
