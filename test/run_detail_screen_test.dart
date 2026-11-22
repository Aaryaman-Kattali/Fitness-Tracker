import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/features/activity/providers/run_history_provider.dart';
import 'package:fitness_tracker/features/activity/run_detail_screen.dart';
import 'package:fitness_tracker/features/activity/widgets/run_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'support/synthetic_track.dart';

/// The detail screen's layout: a full-bleed map with the numbers in a sheet
/// over it.
///
/// Driven from a fixture through a provider override, so there is no database
/// and no network here — the same rule the map widget follows.
void main() {
  const runId = 7;

  RunDetail fixtureDetail() => RunDetail(
    distanceM: 5500,
    movingS: 1830,
    elapsedS: 1920,
    avgPaceSPerKm: 332.7,
    route: [
      for (final fix in straightKm().fixes) LatLng(fix.latitude, fix.longitude),
    ],
    rawFixes: null,
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runDetailProvider(runId).overrideWith((ref) async => fixtureDetail()),
        ],
        child: const CupertinoApp(home: RunDetailScreen(runId: runId)),
      ),
    );
    // Explicit pumps rather than pumpAndSettle: the sheet and the tile layer
    // both animate, per the landmine in CLAUDE.md.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the map fills the screen rather than sitting in a box', (
    tester,
  ) async {
    await pumpScreen(tester);

    final screen = tester.getSize(find.byType(RunDetailScreen));
    final map = tester.getSize(find.byType(RunMap));

    expect(
      map.height,
      screen.height,
      reason:
          'a map inset below a navigation bar is not full-bleed; the '
          'translucent bar is what lets the track run under it',
    );
    expect(map.width, screen.width);
  });

  testWidgets('fits the track into the part of the map the sheet leaves', (
    tester,
  ) async {
    // Symmetric padding would frame the track into the whole rectangle, and
    // the bottom fifth of that rectangle is behind the sheet — so the end of
    // every run would be hidden by the numbers describing it.
    await pumpScreen(tester);

    final padding = tester.widget<RunMap>(find.byType(RunMap)).fitPadding;

    expect(
      padding.bottom,
      greaterThan(padding.top),
      reason: 'the sheet covers the bottom of the map and nothing else',
    );
    expect(
      padding.bottom,
      greaterThan(
        tester.getSize(find.byType(RunDetailScreen)).height *
            AppSpacing.sheetCollapsedFraction,
      ),
      reason: 'at minimum, clear of the collapsed sheet',
    );
    expect(padding.left, padding.right);
  });

  group('elevation gain (A6-1)', () {
    Future<void> pumpWithGain(WidgetTester tester, double? gain) async {
      final base = fixtureDetail();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runDetailProvider(runId).overrideWith(
              (ref) async => RunDetail(
                distanceM: base.distanceM,
                movingS: base.movingS,
                elapsedS: base.elapsedS,
                avgPaceSPerKm: base.avgPaceSPerKm,
                route: base.route,
                rawFixes: null,
                elevGainM: gain,
              ),
            ),
          ],
          child: const CupertinoApp(home: RunDetailScreen(runId: runId)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('a run with no barometric gain says so, not zero', (
      tester,
    ) async {
      await pumpWithGain(tester, null);

      expect(find.text('Not measured'), findsOneWidget);
      expect(find.text('0 m'), findsNothing);
    });

    testWidgets('a measured gain is shown in whole metres', (tester) async {
      await pumpWithGain(tester, 42.4);

      expect(find.text('42 m'), findsOneWidget);
    });
  });

  group('the stats sheet', () {
    /// Where the sheet's top edge sits. The sheet IS the list view — the
    /// grabber and the summary line are inside it, so that a thumb landing on
    /// the row that is visible drags the thing it looks like it should.
    double sheetTop(WidgetTester tester) =>
        tester.getTopLeft(find.byType(ListView)).dy;

    double screenHeight(WidgetTester tester) =>
        tester.getSize(find.byType(RunDetailScreen)).height;

    /// Drag the sheet by a point that is actually on it.
    ///
    /// Not by `find.byType(DraggableScrollableSheet)`: that widget fills the
    /// screen and only paints its child at the bottom, so a drag aimed at its
    /// centre lands on the map and pans it. Silently — the sheet just does not
    /// move, which is a passing test away from being an invisible bug.
    Future<void> dragSheet(WidgetTester tester, double dy) async {
      await tester.drag(find.byType(ListView), Offset(0, dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('shows the summary line while collapsed', (tester) async {
      await pumpScreen(tester);

      // 'Pace /km' belongs to the summary line alone; 'Distance' and the
      // formatted values appear in both it and the full list below.
      final summary = find.text('Pace /km');
      expect(summary, findsOneWidget);
      expect(
        tester.getBottomLeft(summary).dy,
        lessThan(screenHeight(tester)),
        reason: 'the collapsed sheet has to be readable without a drag',
      );
      expect(find.text('5.50 km'), findsWidgets);
    });

    testWidgets('keeps the full list out of the way until dragged', (
      tester,
    ) async {
      // The claim that makes this a sheet rather than a short list: collapsed,
      // it is not showing everything.
      //
      // Asserted by POSITION, not by findsNothing. A ListView builds children
      // past the bottom of its viewport — 250 px of cache extent by default —
      // so every row here exists in the tree whether or not a human can see
      // it. findsNothing passed for a while and was measuring the cache
      // extent, not the layout.
      await pumpScreen(tester);
      expect(
        tester.getTopLeft(find.text('Elapsed')).dy,
        greaterThan(screenHeight(tester)),
        reason: 'built, but laid out below the bottom of the screen',
      );

      await dragSheet(tester, -400);

      expect(
        tester.getTopLeft(find.text('Elapsed')).dy,
        lessThan(screenHeight(tester)),
      );
      expect(find.text('Average pace'), findsOneWidget);
    });

    testWidgets('leaves the map visible when fully expanded', (tester) async {
      // A sheet dragged to the top of the screen has become a page, and the
      // map is the reason this screen is laid out this way at all.
      await pumpScreen(tester);
      final collapsed = sheetTop(tester);

      await dragSheet(tester, -2000);
      expect(
        sheetTop(tester),
        lessThan(collapsed),
        reason: 'if the drag did not move the sheet the test proves nothing',
      );
      expect(
        sheetTop(tester),
        closeTo(
          screenHeight(tester) * (1 - AppSpacing.sheetExpandedFraction),
          screenHeight(tester) * 0.02,
        ),
      );
    });
  });
}
