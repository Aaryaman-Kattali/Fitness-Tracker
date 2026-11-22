// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's stored totals, or null when nothing has been recorded for today.
///
/// Reads the database, not the platform — so it keeps rendering the last
/// known figure when a sync fails, and updates the instant one lands.

@ProviderFor(todayActivity)
final todayActivityProvider = TodayActivityProvider._();

/// Today's stored totals, or null when nothing has been recorded for today.
///
/// Reads the database, not the platform — so it keeps rendering the last
/// known figure when a sync fails, and updates the instant one lands.

final class TodayActivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyActivity?>,
          DailyActivity?,
          Stream<DailyActivity?>
        >
    with $FutureModifier<DailyActivity?>, $StreamProvider<DailyActivity?> {
  /// Today's stored totals, or null when nothing has been recorded for today.
  ///
  /// Reads the database, not the platform — so it keeps rendering the last
  /// known figure when a sync fails, and updates the instant one lands.
  TodayActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayActivityHash();

  @$internal
  @override
  $StreamProviderElement<DailyActivity?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailyActivity?> create(Ref ref) {
    return todayActivity(ref);
  }
}

String _$todayActivityHash() => r'3aaa326682d6f31474153a0ad3b450a358d8271a';

/// Platform state for the steps ring, refreshed on demand.
///
/// [build] performs the sync, so invalidating this provider is what a resume
/// or a pull-to-refresh does. It never throws: every call underneath resolves
/// its failures to a value, because the Today screen must render whatever
/// this returns and must never be blocked by it.

@ProviderFor(StepsPanel)
final stepsPanelProvider = StepsPanelProvider._();

/// Platform state for the steps ring, refreshed on demand.
///
/// [build] performs the sync, so invalidating this provider is what a resume
/// or a pull-to-refresh does. It never throws: every call underneath resolves
/// its failures to a value, because the Today screen must render whatever
/// this returns and must never be blocked by it.
final class StepsPanelProvider
    extends $AsyncNotifierProvider<StepsPanel, StepsStatus> {
  /// Platform state for the steps ring, refreshed on demand.
  ///
  /// [build] performs the sync, so invalidating this provider is what a resume
  /// or a pull-to-refresh does. It never throws: every call underneath resolves
  /// its failures to a value, because the Today screen must render whatever
  /// this returns and must never be blocked by it.
  StepsPanelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stepsPanelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stepsPanelHash();

  @$internal
  @override
  StepsPanel create() => StepsPanel();
}

String _$stepsPanelHash() => r'c578a717a34b99efce7388c173cfda0393170268';

/// Platform state for the steps ring, refreshed on demand.
///
/// [build] performs the sync, so invalidating this provider is what a resume
/// or a pull-to-refresh does. It never throws: every call underneath resolves
/// its failures to a value, because the Today screen must render whatever
/// this returns and must never be blocked by it.

abstract class _$StepsPanel extends $AsyncNotifier<StepsStatus> {
  FutureOr<StepsStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StepsStatus>, StepsStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StepsStatus>, StepsStatus>,
              AsyncValue<StepsStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
