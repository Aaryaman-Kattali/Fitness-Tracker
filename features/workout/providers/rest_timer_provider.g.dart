// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The rest timer, started automatically whenever a set is saved.
///
/// Kept alive above the screen so navigating between exercises — or back to
/// the session list — does not reset a rest that is already running.

@ProviderFor(RestTimer)
final restTimerProvider = RestTimerProvider._();

/// The rest timer, started automatically whenever a set is saved.
///
/// Kept alive above the screen so navigating between exercises — or back to
/// the session list — does not reset a rest that is already running.
final class RestTimerProvider
    extends $NotifierProvider<RestTimer, RestTimerState> {
  /// The rest timer, started automatically whenever a set is saved.
  ///
  /// Kept alive above the screen so navigating between exercises — or back to
  /// the session list — does not reset a rest that is already running.
  RestTimerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restTimerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restTimerHash();

  @$internal
  @override
  RestTimer create() => RestTimer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestTimerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestTimerState>(value),
    );
  }
}

String _$restTimerHash() => r'cd35d6f8a7ba6615d04fdbe2ee821c9414e3e27f';

/// The rest timer, started automatically whenever a set is saved.
///
/// Kept alive above the screen so navigating between exercises — or back to
/// the session list — does not reset a rest that is already running.

abstract class _$RestTimer extends $Notifier<RestTimerState> {
  RestTimerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RestTimerState, RestTimerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RestTimerState, RestTimerState>,
              RestTimerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
