// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_diagnostics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The debug Health Connect read-out.
///
/// Autodisposed and never kept alive: it is only ever on screen while someone
/// is looking at it, and every value in it can change outside the app.

@ProviderFor(HealthDiagnosticsPanel)
final healthDiagnosticsPanelProvider = HealthDiagnosticsPanelProvider._();

/// The debug Health Connect read-out.
///
/// Autodisposed and never kept alive: it is only ever on screen while someone
/// is looking at it, and every value in it can change outside the app.
final class HealthDiagnosticsPanelProvider
    extends $AsyncNotifierProvider<HealthDiagnosticsPanel, HealthDiagnostics> {
  /// The debug Health Connect read-out.
  ///
  /// Autodisposed and never kept alive: it is only ever on screen while someone
  /// is looking at it, and every value in it can change outside the app.
  HealthDiagnosticsPanelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthDiagnosticsPanelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthDiagnosticsPanelHash();

  @$internal
  @override
  HealthDiagnosticsPanel create() => HealthDiagnosticsPanel();
}

String _$healthDiagnosticsPanelHash() =>
    r'cb41e43e9ab091293dd3c45b5a65c81224fc8607';

/// The debug Health Connect read-out.
///
/// Autodisposed and never kept alive: it is only ever on screen while someone
/// is looking at it, and every value in it can change outside the app.

abstract class _$HealthDiagnosticsPanel
    extends $AsyncNotifier<HealthDiagnostics> {
  FutureOr<HealthDiagnostics> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<HealthDiagnostics>, HealthDiagnostics>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HealthDiagnostics>, HealthDiagnostics>,
              AsyncValue<HealthDiagnostics>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
