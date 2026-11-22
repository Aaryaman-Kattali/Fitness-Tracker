import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grouping a directory of diagnostic files back into the runs that made them.
///
/// Pure, so no `dart:io` here and none needed. The question this answers is
/// the one with a wrong answer available: a grouping that pairs one walk's
/// capture with another walk's report produces an export that looks complete
/// and describes two different runs, and nothing downstream could tell.
void main() {
  /// One run's worth of files, in the layout the store writes.
  List<String> filesFor(String stamp, {bool index = true}) => [
    '/docs/run_diagnostics_$stamp.txt',
    '/docs/run_raw_track_$stamp.csv',
    '/docs/run_fixes_$stamp.ndjson',
    if (index) '/docs/run_index_$stamp.txt',
  ];

  test("groups a run's files together and keeps runs apart", () {
    // Two runs, interleaved in the listing the way a real directory returns
    // them. A grouping keyed on anything but the stamp would mix them.
    final groups = groupExportsByStamp(
      [
        ...filesFor('20260823-152002'),
        ...filesFor('20260824-081500'),
      ]..shuffle(),
    );

    expect(groups, hasLength(2));

    for (final group in groups) {
      expect(group.allPaths, hasLength(4));
      for (final path in group.allPaths) {
        expect(
          path,
          contains(group.stamp),
          reason: "every file in a group belongs to that group's run",
        );
      }
    }
  });

  test('orders newest run first', () {
    final groups = groupExportsByStamp([
      ...filesFor('20260101-000000'),
      ...filesFor('20260824-081500'),
      ...filesFor('20260823-152002'),
    ]);

    expect(
      [for (final group in groups) group.stamp],
      ['20260824-081500', '20260823-152002', '20260101-000000'],
    );
  });

  test('a share sends the evidence and not the derived index', () {
    // The index is a cached line count. Sending it with a capture invites
    // someone to trust it as a record of the walk, and it is a record of a
    // convenience.
    final group = groupExportsByStamp(filesFor('20260823-152002')).single;

    expect(group.sharablePaths, hasLength(3));
    expect(
      group.sharablePaths.any((path) => path.contains('run_index_')),
      isFalse,
    );
    expect(
      group.allPaths.any((path) => path.contains('run_index_')),
      isTrue,
      reason: 'a delete still has to take it, or it outlives its capture',
    );
  });

  test('a run missing files still groups', () {
    // The 1610 m walk predates the index, and a run that accepted nothing
    // writes a capture with no raw track. Neither is an error.
    final group = groupExportsByStamp([
      '/docs/run_diagnostics_20260823-152002.txt',
      '/docs/run_fixes_20260823-152002.ndjson',
    ]).single;

    expect(group.sharablePaths, hasLength(2));
    expect(group.paths[ExportKind.rawTrack], isNull);
  });

  test('ignores the retired fixed-name capture', () {
    // `run_fixes_latest.ndjson` is what the store wrote before C-7-1, and it
    // passes a prefix-and-suffix test. Grouped, it would appear as a run
    // stamped "latest" that sorts above every real one forever — the same
    // trap stampedNewestFirst documents.
    final groups = groupExportsByStamp([
      '/docs/run_fixes_latest.ndjson',
      '/docs/run_diagnostics_latest.txt',
      ...filesFor('20260823-152002'),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.stamp, '20260823-152002');
  });

  test('ignores files that are not ours', () {
    final groups = groupExportsByStamp([
      '/docs/some_other_app.txt',
      '/docs/db.sqlite',
      '/docs/run_fixes_.ndjson',
      '/docs/run_fixes_2026-08-23.ndjson',
      ...filesFor('20260823-152002'),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.allPaths, hasLength(4));
  });

  test('handles a Windows listing, because the tests run on one', () {
    // listSync returns backslashes on Windows and the paths the store builds
    // use forward slashes. Both reach this function.
    final groups = groupExportsByStamp([
      r'C:\docs\run_fixes_20260823-152002.ndjson',
      r'C:\docs\run_diagnostics_20260823-152002.txt',
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.sharablePaths, hasLength(2));
  });

  group('the stamp is a time', () {
    test('reads back as the UTC instant it was written from', () {
      final start = DateTime.utc(2026, 8, 23, 15, 20, 2);
      expect(parseFileStamp(fileStamp(start)), start);
    });

    test('survives a local time that is not UTC', () {
      // fileStamp converts to UTC. Parsing has to agree, or a capture recorded
      // at 20:50 IST would be listed as having been recorded at 15:20 local.
      final start = DateTime.utc(2026, 8, 23, 15, 20, 2).toLocal();
      expect(parseFileStamp(fileStamp(start)), start.toUtc());
    });
  });
}
