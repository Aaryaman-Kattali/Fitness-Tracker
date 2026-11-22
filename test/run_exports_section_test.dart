import 'package:fitness_tracker/data/repositories/file_sharer.dart';
import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/features/activity/providers/run_exports_provider.dart';
import 'package:fitness_tracker/features/settings/widgets/run_exports_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_diagnostics_store.dart';

/// The export section, driven with no filesystem and no share sheet.
class _FakeSharer implements FileSharer {
  final shared = <List<String>>[];
  String? subject;
  bool result = true;

  @override
  Future<bool> share(List<String> paths, {required String subject}) async {
    shared.add(paths);
    this.subject = subject;
    return result;
  }
}

void main() {
  late FakeRunDiagnosticsStore store;
  late _FakeSharer sharer;

  RunExport export(String stamp, {int? fixCount = 1205, int bytes = 300000}) =>
      RunExport(
        stamp: stamp,
        startedAt: parseFileStamp(stamp),
        sharablePaths: [
          '/docs/run_diagnostics_$stamp.txt',
          '/docs/run_raw_track_$stamp.csv',
          '/docs/run_fixes_$stamp.ndjson',
        ],
        allPaths: [
          '/docs/run_diagnostics_$stamp.txt',
          '/docs/run_raw_track_$stamp.csv',
          '/docs/run_fixes_$stamp.ndjson',
          '/docs/run_index_$stamp.txt',
        ],
        bytes: bytes,
        fixCount: fixCount,
      );

  Future<void> pumpSection(WidgetTester tester) async {
    store = FakeRunDiagnosticsStore();
    sharer = _FakeSharer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runDiagnosticsStoreProvider.overrideWithValue(store),
          fileSharerProvider.overrideWithValue(sharer),
        ],
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(child: RunExportsSection()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpWith(WidgetTester tester, List<RunExport> exports) async {
    await pumpSection(tester);
    store.exports = exports;
    // The provider read the empty list on the first frame, so the fake's rows
    // have to be installed and then re-read. Doing it this way round rather
    // than seeding the fake first keeps the loading state exercised too.
    ProviderScope.containerOf(
      tester.element(find.byType(RunExportsSection)),
    ).invalidate(runExportsProvider);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('says so when nothing has been recorded', (tester) async {
    await pumpSection(tester);
    await tester.pump();

    expect(find.textContaining('No run has written diagnostics'), findsOne);
  });

  testWidgets('lists a run with its fix count and size', (tester) async {
    await pumpWith(tester, [export('20260823-152002')]);

    expect(find.textContaining('1205 fixes'), findsOne);
    expect(find.textContaining('293 kB'), findsOne);
    expect(find.textContaining('3 files'), findsOne);
  });

  testWidgets('says unknown, not zero, when the count is missing', (
    tester,
  ) async {
    // A run recorded before the index existed, including the 1610 m walk. A
    // capture whose count could not be read and one that genuinely holds no
    // fixes are different runs and must not print the same thing.
    await pumpWith(tester, [export('20260823-152002', fixCount: null)]);

    expect(find.textContaining('fix count unknown'), findsOne);
    expect(find.textContaining('0 fixes'), findsNothing);
  });

  testWidgets('shares the three files of the row that was tapped', (
    tester,
  ) async {
    // Two rows, and the older one is tapped. A share wired to the newest
    // export — the easy mistake, since that is what every other reader here
    // takes — would pass a single-row test.
    await pumpWith(tester, [
      export('20260824-081500'),
      export('20260823-152002'),
    ]);

    await tester.tap(find.text('Share').last);
    await tester.pump();

    expect(sharer.shared, hasLength(1));
    expect(sharer.subject, contains('20260823-152002'));
    for (final path in sharer.shared.single) {
      expect(path, contains('20260823-152002'));
    }
    expect(
      sharer.shared.single.any((path) => path.contains('run_index_')),
      isFalse,
      reason: 'the cached count is not evidence and is not shared',
    );
  });

  group('delete', () {
    testWidgets('asks first, and does nothing when cancelled', (tester) async {
      await pumpWith(tester, [export('20260823-152002')]);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(find.textContaining('cannot be regenerated'), findsOne);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(store.deleted, isEmpty);
      expect(find.textContaining('1205 fixes'), findsOne);
    });

    testWidgets('removes the run once confirmed', (tester) async {
      await pumpWith(tester, [
        export('20260824-081500'),
        export('20260823-152002'),
      ]);

      await tester.tap(find.text('Delete').last);
      await tester.pump();

      // The dialog's action, addressed by its type. Both rows also say
      // "Delete", so `.last` on the text finds a row and quietly reopens the
      // dialog instead of confirming it — which is how this test first passed
      // its tap and deleted nothing.
      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        store.deleted,
        ['20260823-152002'],
        reason: 'the row that was tapped, not the newest one',
      );
      expect(find.text('Share'), findsOne, reason: 'one row left');
    });
  });
}
