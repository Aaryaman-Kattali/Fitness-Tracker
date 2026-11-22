import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:fitness_tracker/features/activity/run_recording_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// The recording screen's three-stat panel, driven at real values.
///
/// **This exists because a fixed-size test at placeholder values is what let
/// the overflow ship.** The panel rendered an em dash in every column before a
/// run starts — three narrow glyphs that fit anything — and the row overflowed
/// as soon as the run produced numbers, at 44pt, on the screen being read at
/// arm's length while moving. So the rule here is that nothing is asserted
/// against a dash alone: every case below drives the strings the formatters
/// actually emit.
///
/// The second half of the rule is width. A single surface size proves nothing
/// about a layout whose failure mode IS running out of width, so every case
/// runs on a narrow phone and a large one.
void main() {
  /// The widths that bracket the handsets this app has to run on, per
  /// CLAUDE.md's one-binary rule: a small Android phone and a large modern
  /// one. The obligation is the same for layout as it is for behaviour.
  const widths = <String, double>{'narrow 320': 320, 'wide 430': 430};

  /// Every stat at its longest realistic string, together.
  ///
  /// Not a plausible single run — 100 km at 59:59/km is nobody's afternoon —
  /// and that is deliberate. Each column has to survive the widest value it
  /// can independently produce, because nothing stops a long walk from
  /// carrying a slow pace and an hours-long moving time at once.
  final worstCase = RunRecordingState(
    isRecording: true,
    startedAt: DateTime.utc(2026, 9, 8, 6),
    distanceM: 100000,
    elapsed: const Duration(hours: 10, minutes: 30),
    movingTime: const Duration(hours: 10),
    averagePaceSecPerKm: 3599,
    currentPaceSecPerKm: 3599,
    pointCount: 99999,
  );

  /// What an ordinary run looks like, which must also fit — and must fit
  /// WITHOUT being scaled down, which is asserted separately below.
  final typical = RunRecordingState(
    isRecording: true,
    startedAt: DateTime.utc(2026, 9, 8, 6),
    distanceM: 5420,
    elapsed: const Duration(minutes: 31, seconds: 20),
    movingTime: const Duration(minutes: 28, seconds: 38),
    averagePaceSecPerKm: 347,
    currentPaceSecPerKm: 347,
    pointCount: 1620,
  );

  /// The state the panel was originally checked in, kept as one case rather
  /// than as the only case.
  const preStart = RunRecordingState();

  Future<void> pumpAt(
    WidgetTester tester,
    RunRecordingState state,
    double width,
  ) async {
    tester.view
      ..physicalSize = Size(width, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.topCenter,
            child: StatsOverlay(state: state),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final cases = <String, RunRecordingState>{
    'worst case': worstCase,
    'typical run': typical,
    'before the run starts': preStart,
  };

  for (final entry in cases.entries) {
    for (final width in widths.entries) {
      testWidgets('${entry.key} does not overflow on ${width.key}', (
        tester,
      ) async {
        await pumpAt(tester, entry.value, width.value);

        // A RenderFlex overflow is reported through FlutterError during paint,
        // which flutter_test records rather than throwing. Reading it back is
        // what turns "the panel looks wrong" into a pass/fail.
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} overflows the stats row at ${width.key}',
        );
      });
    }
  }

  testWidgets('the worst case renders every value in full, never clipped', (
    tester,
  ) async {
    // The overflow could be "fixed" by dropping a column or truncating a
    // number, and both would pass the tests above. A clipped number is a WRONG
    // number, so the values are asserted present and complete.
    await pumpAt(tester, worstCase, 320);

    expect(find.text('100.00'), findsOneWidget);
    expect(find.text('10:00:00'), findsOneWidget);
    expect(find.text('59:59'), findsOneWidget);

    // And the unit still reaches the screen. It moved into the label to buy
    // the column back, rather than being deleted to save room.
    expect(find.text('Distance km'), findsOneWidget);
    expect(find.text('Pace /km'), findsOneWidget);
  });

  testWidgets('the value carries no unit, which is what buys the width', (
    tester,
  ) async {
    // **The assertion that keeps the type big**, expressed as the mechanism
    // rather than as an appearance. " km" on a 44pt value spent a quarter of
    // the widest column restating what the label already says, and removing
    // it is what lets an ordinary run render without being scaled down.
    //
    // **Not asserted as a pixel width, deliberately.** `flutter_test` renders
    // in a fixed-pitch test font whose glyphs are a full em wide — roughly
    // 1.76x SF Pro at this size — so every absolute width measured in this
    // file is far wider than the device's. That makes the overflow tests
    // above conservative, which is safe, and makes "does this scale down on a
    // real phone" unmeasurable here. It is listed as a device-only check.
    await pumpAt(tester, typical, 430);

    expect(find.text('5.42'), findsOneWidget);
    expect(
      find.text('5.42 km'),
      findsNothing,
      reason: 'the unit belongs in the label, not in a 44pt value',
    );
  });

  testWidgets('the columns are equal thirds, whatever the values say', (
    tester,
  ) async {
    // **The structural assertion, and the one that stops this recurring.**
    // Under `spaceBetween` the columns were sized by their contents, so a
    // long distance stole room from pace and the row's total was free to
    // exceed the panel — silently, because free space hits zero and the
    // columns butt together well before the overflow indicator fires. Flex
    // thirds are decided by the constraint rather than by the strings, so no
    // value can crowd another.
    await pumpAt(tester, worstCase, 430);

    // Scoped to the headline values by name. The demoted line below has three
    // columns of its own, for the same reason, and measuring all six together
    // would compare two different rows.
    final sizes = [
      for (final value in ['100.00', '10:00:00', '59:59'])
        tester
            .renderObject<RenderBox>(
              find.ancestor(
                of: find.text(value),
                matching: find.byType(FittedBox),
              ),
            )
            .size
            .width,
    ];

    expect(sizes, hasLength(3), reason: 'one value per column');
    for (final width in sizes) {
      expect(
        width,
        closeTo(sizes.first, 0.01),
        reason: 'the columns are $sizes, which is not equal thirds',
      );
    }
  });
}
