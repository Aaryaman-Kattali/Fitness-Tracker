import 'package:fitness_tracker/features/activity/diagnostics/run_diagnostics_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bug this file exists for cost a walk.
///
/// Three diagnostic files were written to three fixed names, so recording a run
/// destroyed the previous run's evidence — including the capture of the first
/// ground-truth walk, which cannot be regenerated because the walk is over.
/// Nothing failed, nothing warned; the second walk simply arrived and the first
/// one's file was gone.
///
/// What is tested here is the naming and the ordering, which are the two
/// answers that can be silently *wrong*. The file writing itself is not:
/// `getApplicationDocumentsDirectory` resolves to the real Windows Documents
/// folder under `flutter test`, so exercising it here would scatter files
/// through the user's own directory. That leaves the directory listing as a
/// device-only check, which is the honest place for it — a listing that fails
/// is loud, an ordering that quietly returns the second-newest capture is not.
void main() {
  group('fileStamp', () {
    test('two runs a second apart cannot collide', () {
      final first = fileStamp(DateTime.utc(2026, 8, 23, 15, 20, 2));
      final second = fileStamp(DateTime.utc(2026, 8, 23, 15, 20, 3));

      expect(first, '20260823-152002');
      expect(second, '20260823-152003');
      expect(first, isNot(second));
    });

    test('every field is zero-padded, so text order is time order', () {
      // January the 2nd at 03:04:05 is the case that catches an unpadded
      // formatter: `202612-345` sorts before `20260823-152002` and would make
      // a newer capture look older than one from four months earlier.
      expect(fileStamp(DateTime.utc(2026, 1, 2, 3, 4, 5)), '20260102-030405');
    });

    test('normalises to UTC, so a local time cannot reorder two runs', () {
      final local = DateTime.utc(
        2026,
        8,
        23,
        15,
        20,
        2,
      ).toLocal();

      expect(fileStamp(local), '20260823-152002');
    });
  });

  group('stampedNewestFirst', () {
    const prefix = 'run_fixes_';
    const suffix = '.ndjson';

    test('orders by the stamp, newest run first', () {
      final ordered = stampedNewestFirst(
        [
          '/data/run_fixes_20260823-152002.ndjson',
          '/data/run_fixes_20260825-090000.ndjson',
          '/data/run_fixes_20260102-030405.ndjson',
        ],
        prefix: prefix,
        suffix: suffix,
      );

      expect(ordered, [
        '/data/run_fixes_20260825-090000.ndjson',
        '/data/run_fixes_20260823-152002.ndjson',
        '/data/run_fixes_20260102-030405.ndjson',
      ]);
    });

    test('keeps the other two file kinds out of each other', () {
      final paths = [
        '/data/run_fixes_20260823-152002.ndjson',
        '/data/run_diagnostics_20260825-090000.txt',
        '/data/run_raw_track_20260825-090000.csv',
      ];

      expect(
        stampedNewestFirst(paths, prefix: prefix, suffix: suffix),
        ['/data/run_fixes_20260823-152002.ndjson'],
      );
      expect(
        stampedNewestFirst(
          paths,
          prefix: 'run_raw_track_',
          suffix: '.csv',
        ),
        ['/data/run_raw_track_20260825-090000.csv'],
      );
    });

    test('ignores anything else in the documents directory', () {
      // Real neighbours: the drift database, and the fixed-name files written
      // by the version of the store that overwrote them.
      final ordered = stampedNewestFirst(
        [
          '/data/db.sqlite',
          '/data/run_fixes_latest.ndjson',
          '/data/run_fixes_20260823-152002.ndjson',
        ],
        prefix: prefix,
        suffix: suffix,
      );

      // `run_fixes_latest.ndjson` matches the prefix and the suffix and would
      // sort above every stamp, because 'l' is above '2'. It is excluded by
      // being neither — it has no stamp — and this is the assertion that says
      // so, because an old file winning the ordering forever is exactly the
      // failure that would look like "the capture never updates".
      expect(ordered, ['/data/run_fixes_20260823-152002.ndjson']);
    });

    test('a Windows path separator does not defeat the prefix test', () {
      // listSync returns backslashes on the machine the suite runs on, and the
      // prefix is matched against the last segment, not the whole path.
      expect(
        stampedNewestFirst(
          [r'C:\Users\x\Documents\run_fixes_20260823-152002.ndjson'],
          prefix: prefix,
          suffix: suffix,
        ),
        [r'C:\Users\x\Documents\run_fixes_20260823-152002.ndjson'],
      );
    });

    test('nothing recorded yet is an empty list, not a throw', () {
      expect(
        stampedNewestFirst(const [], prefix: prefix, suffix: suffix),
        isEmpty,
      );
    });
  });
}
