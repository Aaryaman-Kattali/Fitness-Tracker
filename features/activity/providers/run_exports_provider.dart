import 'package:fitness_tracker/data/repositories/file_sharer.dart';
import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'run_exports_provider.g.dart';

/// The share-sheet boundary, replaceable in tests.
@Riverpod(keepAlive: true)
FileSharer fileSharer(Ref ref) => const SharePlusFileSharer();

/// Every run that left diagnostic files behind, newest first.
///
/// Autodisposed, like the other debug panels: it is only ever read while
/// someone is looking at the screen, and it goes stale the moment a run is
/// recorded or an export deleted.
@riverpod
Future<List<RunExport>> runExports(Ref ref) =>
    ref.watch(runDiagnosticsStoreProvider).listExports();

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
@Riverpod(keepAlive: true)
class RunExportActions extends _$RunExportActions {
  @override
  void build() {}

  /// Returns false when the user dismissed the share sheet without choosing.
  Future<bool> share(RunExport export) {
    return ref
        .read(fileSharerProvider)
        .share(
          export.sharablePaths,
          subject: 'Run diagnostics ${export.stamp}',
        );
  }

  Future<void> delete(RunExport export) async {
    await ref.read(runDiagnosticsStoreProvider).deleteExport(export.stamp);
    ref.invalidate(runExportsProvider);
  }
}
