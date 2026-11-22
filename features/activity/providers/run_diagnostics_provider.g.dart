// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_diagnostics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(runDiagnosticsStore)
final runDiagnosticsStoreProvider = RunDiagnosticsStoreProvider._();

final class RunDiagnosticsStoreProvider
    extends
        $FunctionalProvider<
          RunDiagnosticsStore,
          RunDiagnosticsStore,
          RunDiagnosticsStore
        >
    with $Provider<RunDiagnosticsStore> {
  RunDiagnosticsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runDiagnosticsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runDiagnosticsStoreHash();

  @$internal
  @override
  $ProviderElement<RunDiagnosticsStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RunDiagnosticsStore create(Ref ref) {
    return runDiagnosticsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunDiagnosticsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunDiagnosticsStore>(value),
    );
  }
}

String _$runDiagnosticsStoreHash() =>
    r'5d26b96057d32a75a45e7ea3dbbc4ebb80157987';

/// The debug read-out for the most recent run, as text.
///
/// Two sources, in order of how much they can tell you. A live capture written
/// when the run was saved is complete. Failing that, the accepted points still
/// in the database are re-read and what can be recovered from them is
/// recovered — which is everything about the fixes that survived and nothing
/// about the ones that did not.
///
/// Autodisposed, like the Health Connect panel: it is only ever on screen while
/// someone is looking at it.

@ProviderFor(runDiagnosticsReport)
final runDiagnosticsReportProvider = RunDiagnosticsReportProvider._();

/// The debug read-out for the most recent run, as text.
///
/// Two sources, in order of how much they can tell you. A live capture written
/// when the run was saved is complete. Failing that, the accepted points still
/// in the database are re-read and what can be recovered from them is
/// recovered — which is everything about the fixes that survived and nothing
/// about the ones that did not.
///
/// Autodisposed, like the Health Connect panel: it is only ever on screen while
/// someone is looking at it.

final class RunDiagnosticsReportProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The debug read-out for the most recent run, as text.
  ///
  /// Two sources, in order of how much they can tell you. A live capture written
  /// when the run was saved is complete. Failing that, the accepted points still
  /// in the database are re-read and what can be recovered from them is
  /// recovered — which is everything about the fixes that survived and nothing
  /// about the ones that did not.
  ///
  /// Autodisposed, like the Health Connect panel: it is only ever on screen while
  /// someone is looking at it.
  RunDiagnosticsReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runDiagnosticsReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runDiagnosticsReportHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return runDiagnosticsReport(ref);
  }
}

String _$runDiagnosticsReportHash() =>
    r'7751a9294970b651c313e11315584b1db7fd34c0';
