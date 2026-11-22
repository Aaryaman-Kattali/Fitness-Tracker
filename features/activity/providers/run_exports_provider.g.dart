// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_exports_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The share-sheet boundary, replaceable in tests.

@ProviderFor(fileSharer)
final fileSharerProvider = FileSharerProvider._();

/// The share-sheet boundary, replaceable in tests.

final class FileSharerProvider
    extends $FunctionalProvider<FileSharer, FileSharer, FileSharer>
    with $Provider<FileSharer> {
  /// The share-sheet boundary, replaceable in tests.
  FileSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileSharerHash();

  @$internal
  @override
  $ProviderElement<FileSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileSharer create(Ref ref) {
    return fileSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileSharer>(value),
    );
  }
}

String _$fileSharerHash() => r'e34dc47e71363dccc733afba43be3a5f1736f39b';

/// Every run that left diagnostic files behind, newest first.
///
/// Autodisposed, like the other debug panels: it is only ever read while
/// someone is looking at the screen, and it goes stale the moment a run is
/// recorded or an export deleted.

@ProviderFor(runExports)
final runExportsProvider = RunExportsProvider._();

/// Every run that left diagnostic files behind, newest first.
///
/// Autodisposed, like the other debug panels: it is only ever read while
/// someone is looking at the screen, and it goes stale the moment a run is
/// recorded or an export deleted.

final class RunExportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RunExport>>,
          List<RunExport>,
          FutureOr<List<RunExport>>
        >
    with $FutureModifier<List<RunExport>>, $FutureProvider<List<RunExport>> {
  /// Every run that left diagnostic files behind, newest first.
  ///
  /// Autodisposed, like the other debug panels: it is only ever read while
  /// someone is looking at the screen, and it goes stale the moment a run is
  /// recorded or an export deleted.
  RunExportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runExportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runExportsHash();

  @$internal
  @override
  $FutureProviderElement<List<RunExport>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RunExport>> create(Ref ref) {
    return runExports(ref);
  }
}

String _$runExportsHash() => r'01f4ac3c87faefc797b3694ee12d1342f140b79c';

/// Share one run's three files, or delete all of them.
///
/// A notifier rather than two loose functions because both actions have to
/// invalidate the listing afterwards, and a delete that leaves the screen
/// showing the file it just removed is the kind of debug-screen lie that
/// wastes an afternoon.
///
/// keepAlive, and it is load-bearing rather than tidy. Autodisposed, nothing
/// watches this — the widget only ever `read`s it — so it is collected the
/// moment the read returns, and `delete` throws UnmountedRefException when it
/// comes back from awaiting the confirmation dialog. `share` hid the problem
/// by awaiting nothing in between.

@ProviderFor(RunExportActions)
final runExportActionsProvider = RunExportActionsProvider._();

/// Share one run's three files, or delete all of them.
///
/// A notifier rather than two loose functions because both actions have to
/// invalidate the listing afterwards, and a delete that leaves the screen
/// showing the file it just removed is the kind of debug-screen lie that
/// wastes an afternoon.
///
/// keepAlive, and it is load-bearing rather than tidy. Autodisposed, nothing
/// watches this — the widget only ever `read`s it — so it is collected the
/// moment the read returns, and `delete` throws UnmountedRefException when it
/// comes back from awaiting the confirmation dialog. `share` hid the problem
/// by awaiting nothing in between.
final class RunExportActionsProvider
    extends $NotifierProvider<RunExportActions, void> {
  /// Share one run's three files, or delete all of them.
  ///
  /// A notifier rather than two loose functions because both actions have to
  /// invalidate the listing afterwards, and a delete that leaves the screen
  /// showing the file it just removed is the kind of debug-screen lie that
  /// wastes an afternoon.
  ///
  /// keepAlive, and it is load-bearing rather than tidy. Autodisposed, nothing
  /// watches this — the widget only ever `read`s it — so it is collected the
  /// moment the read returns, and `delete` throws UnmountedRefException when it
  /// comes back from awaiting the confirmation dialog. `share` hid the problem
  /// by awaiting nothing in between.
  RunExportActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runExportActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runExportActionsHash();

  @$internal
  @override
  RunExportActions create() => RunExportActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$runExportActionsHash() => r'f4aa8155ec53a9b9b7d4330216ff643dd638e4fa';

/// Share one run's three files, or delete all of them.
///
/// A notifier rather than two loose functions because both actions have to
/// invalidate the listing afterwards, and a delete that leaves the screen
/// showing the file it just removed is the kind of debug-screen lie that
/// wastes an afternoon.
///
/// keepAlive, and it is load-bearing rather than tidy. Autodisposed, nothing
/// watches this — the widget only ever `read`s it — so it is collected the
/// moment the read returns, and `delete` throws UnmountedRefException when it
/// comes back from awaiting the confirmation dialog. `share` hid the problem
/// by awaiting nothing in between.

abstract class _$RunExportActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
