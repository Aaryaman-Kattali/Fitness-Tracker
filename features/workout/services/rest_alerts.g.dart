// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(restAlerts)
final restAlertsProvider = RestAlertsProvider._();

final class RestAlertsProvider
    extends $FunctionalProvider<RestAlerts, RestAlerts, RestAlerts>
    with $Provider<RestAlerts> {
  RestAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restAlertsHash();

  @$internal
  @override
  $ProviderElement<RestAlerts> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RestAlerts create(Ref ref) {
    return restAlerts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestAlerts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestAlerts>(value),
    );
  }
}

String _$restAlertsHash() => r'c0b12afc4101dfac1447999aac8aee1817fc3d52';
