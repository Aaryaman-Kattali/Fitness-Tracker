import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';

/// A [RunDiagnosticsStore] that keeps the report in a field.
///
/// The real one goes through `path_provider`, which is a method channel and
/// therefore unavailable in a plain unit test. Substituting it here also makes
/// the written report assertable, which a file in the app's documents
/// directory would not be.
class FakeRunDiagnosticsStore implements RunDiagnosticsStore {
  String? written;

  /// The last raw track handed over, with the run it belongs to.
  int? rawTrackRunId;
  List<({double lat, double lon})>? rawTrack;

  /// The `runStart` each writer was handed. A real store turns these into
  /// filenames; here they are kept so a test can assert all three files of a
  /// run are named for the same moment.
  final stamps = <DateTime>[];

  @override
  Future<void> save(String report, {required DateTime runStart}) async {
    stamps.add(runStart);
    written = report;
  }

  @override
  Future<String?> latest() async => written;

  @override
  Future<void> saveRawTrack(
    int runId,
    List<({double lat, double lon})> positions, {
    required DateTime runStart,
  }) async {
    stamps.add(runStart);
    rawTrackRunId = runId;
    rawTrack = positions;
  }

  /// Matches the real store's contract, including the part that matters: a
  /// stored track belongs to one run and is not offered for any other.
  @override
  Future<List<({double lat, double lon})>?> rawTrackFor(int runId) async =>
      runId == rawTrackRunId ? rawTrack : null;

  /// The last NDJSON capture handed over, and the count that came with it.
  String? fixCapture;
  int? fixCaptureCount;

  @override
  Future<void> saveFixCapture(
    String ndjson, {
    required DateTime runStart,
    required int fixCount,
  }) async {
    stamps.add(runStart);
    fixCapture = ndjson;
    fixCaptureCount = fixCount;
  }

  @override
  Future<String?> latestFixCapture() async => fixCapture;

  /// What the export screen lists. Set by a test that wants rows; empty
  /// otherwise, which is the right answer for a fake with no filesystem.
  List<RunExport> exports = const [];

  /// Stamps passed to [deleteExport], so a test can assert a delete asked for
  /// the run it was pointed at and not the newest one.
  final deleted = <String>[];

  @override
  Future<List<RunExport>> listExports() async => exports;

  @override
  Future<void> deleteExport(String stamp) async {
    deleted.add(stamp);
    exports = [
      for (final export in exports)
        if (export.stamp != stamp) export,
    ];
  }
}
