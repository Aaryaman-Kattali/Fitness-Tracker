// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The debug-only date override.
///
/// Testing a Saturday session by changing the phone's date is miserable and
/// drags every other app's notion of time with it, so the override lives here
/// instead. [setDate] is inert outside a debug build, which — together with
/// the `kDebugMode` guard on the Settings UI — is what keeps it from shipping.

@ProviderFor(DateOverride)
final dateOverrideProvider = DateOverrideProvider._();

/// The debug-only date override.
///
/// Testing a Saturday session by changing the phone's date is miserable and
/// drags every other app's notion of time with it, so the override lives here
/// instead. [setDate] is inert outside a debug build, which — together with
/// the `kDebugMode` guard on the Settings UI — is what keeps it from shipping.
final class DateOverrideProvider
    extends $NotifierProvider<DateOverride, DateTime?> {
  /// The debug-only date override.
  ///
  /// Testing a Saturday session by changing the phone's date is miserable and
  /// drags every other app's notion of time with it, so the override lives here
  /// instead. [setDate] is inert outside a debug build, which — together with
  /// the `kDebugMode` guard on the Settings UI — is what keeps it from shipping.
  DateOverrideProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dateOverrideProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dateOverrideHash();

  @$internal
  @override
  DateOverride create() => DateOverride();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$dateOverrideHash() => r'2afbf85af5573a6d5a7587d9a449c95c3e8a5eea';

/// The debug-only date override.
///
/// Testing a Saturday session by changing the phone's date is miserable and
/// drags every other app's notion of time with it, so the override lives here
/// instead. [setDate] is inert outside a debug build, which — together with
/// the `kDebugMode` guard on the Settings UI — is what keeps it from shipping.

abstract class _$DateOverride extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(effectiveClock)
final effectiveClockProvider = EffectiveClockProvider._();

final class EffectiveClockProvider
    extends $FunctionalProvider<EffectiveClock, EffectiveClock, EffectiveClock>
    with $Provider<EffectiveClock> {
  EffectiveClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveClockHash();

  @$internal
  @override
  $ProviderElement<EffectiveClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EffectiveClock create(Ref ref) {
    return effectiveClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EffectiveClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EffectiveClock>(value),
    );
  }
}

String _$effectiveClockHash() => r'f2775416db1f5ece22698d1928753f02508c5a95';
