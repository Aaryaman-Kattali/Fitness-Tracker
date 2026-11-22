import 'package:drift/native.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/activity/pipeline/raw_fix.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:fitness_tracker/features/activity/run_recording_screen.dart';
import 'package:fitness_tracker/features/activity/widgets/run_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'support/fake_barometer.dart';
import 'support/fake_diagnostics_store.dart';
import 'support/fake_run_recorder.dart';
import 'support/synthetic_track.dart';

/// The recording screen: a live track over a map, driven from fixture data.
///
/// No plugin and no network. The recorder is the fake replaying a synthetic
/// track, so what is under test is the wiring — pipeline to state to polyline
/// — and not the receiver.
///
/// Every state this screen has is reachable from here: pre-start with a
/// position and without one, locating, recording, and a basemap that never
/// loads. That list is the point. The pre-start state had no test at all
/// before this, which is how it went a fortnight rendering a grey panel where
/// the map was supposed to be.
void main() {
  late AppDatabase db;

  /// A position for the map to open on, standing in for the one-shot fix.
  ///
  /// Deliberately nowhere near [straightKm]'s track: if the pre-start camera
  /// and the recorded track were near each other, a screen that ignored this
  /// value entirely would still look right.
  final framingFix = RawFix(
    latitude: 19.2183,
    longitude: 72.9781,
    timestamp: DateTime.utc(2026, 9, 7, 6, 30),
    accuracyM: 12,
  );

  Future<void> pumpScreen(WidgetTester tester, FakeRunRecorder recorder) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    addTearDown(recorder.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          runRecorderProvider.overrideWithValue(recorder),
          barometerProvider.overrideWithValue(FakeBarometer.absent()),
          runDiagnosticsStoreProvider.overrideWithValue(
            FakeRunDiagnosticsStore(),
          ),
        ],
        child: const CupertinoApp(home: RunRecordingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> startRun(WidgetTester tester) async {
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  List<LatLng> drawnRoute(WidgetTester tester) => tester
      .widgetList<PolylineLayer<Object>>(find.byType(PolylineLayer<Object>))
      .expand((layer) => layer.polylines)
      .first
      .points;

  Iterable<CircleMarker<Object>> circles(WidgetTester tester) => tester
      .widgetList<CircleLayer<Object>>(find.byType(CircleLayer<Object>))
      .expand((layer) => layer.circles);

  /// The puck, found by the colour it is drawn in.
  ///
  /// Compared straight to the token, with no resolution against the element
  /// tree. It was a [CupertinoDynamicColor] until U-3 and had to be resolved;
  /// the map no longer follows the appearance setting, so the token is one
  /// concrete colour and resolving it would only re-derive itself. Same
  /// assertion as before — this is the live-position marker.
  Iterable<CircleMarker<Object>> pucks(WidgetTester tester) =>
      circles(tester).where((c) => c.color == AppColors.trackPosition);

  group('before Start', () {
    testWidgets('opens on a map of where the phone is, not on a blank', (
      tester,
    ) async {
      // The bug this whole change exists for. There is no track yet and there
      // will not be one until a run starts, and that must not be the same
      // thing as having nothing to show.
      await pumpScreen(
        tester,
        FakeRunRecorder(straightKm(), framingFix: framingFix),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.byType(PolylineLayer<Object>),
        findsNothing,
        reason: 'a map, but no track — nothing has been recorded yet',
      );

      final puck = pucks(tester);
      expect(puck, hasLength(1));
      expect(
        puck.single.point,
        LatLng(framingFix.latitude, framingFix.longitude),
        reason: 'the marker is where the phone said it was',
      );
    });

    testWidgets('frames the camera on that position', (tester) async {
      await pumpScreen(
        tester,
        FakeRunRecorder(straightKm(), framingFix: framingFix),
      );

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(
        map.options.initialCenter,
        LatLng(framingFix.latitude, framingFix.longitude),
      );
      expect(
        map.options.initialCameraFit,
        isNull,
        reason: 'nothing to fit: a fit would need a track',
      );
    });

    testWidgets('draws no start dot before there is a run to have started', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FakeRunRecorder(straightKm(), framingFix: framingFix),
      );

      expect(
        circles(tester).where((c) => c.color == AppColors.runStartMarker),
        isEmpty,
        reason: 'where the phone is standing is not where a run began',
      );
    });

    testWidgets('shows dashes, never zeros', (tester) async {
      // 0.00 km is a measurement. A run that has not started has none, and
      // saying it covered a flat zero is a different and false claim.
      await pumpScreen(
        tester,
        FakeRunRecorder(straightKm(), framingFix: framingFix),
      );

      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('0.00 km'), findsNothing);
      expect(find.text('0:00'), findsNothing);
    });

    testWidgets('offers Start, and no Finish', (tester) async {
      await pumpScreen(
        tester,
        FakeRunRecorder(straightKm(), framingFix: framingFix),
      );

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Finish'), findsNothing);
    });
  });

  group('with no position at all', () {
    testWidgets('says so, and still lets the run start', (tester) async {
      // A phone that has never had a fix. The screen has genuinely nothing to
      // point a camera at, so it says that rather than inventing a location —
      // and Start is unaffected, because framing was never on that path.
      await pumpScreen(tester, FakeRunRecorder(straightKm()));

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.textContaining('No position yet'), findsOneWidget);
      expect(find.textContaining('Start works without it'), findsOneWidget);

      await startRun(tester);
      expect(drawnRoute(tester), isNotEmpty);
    });
  });

  group('while recording', () {
    testWidgets('draws the track as it is recorded, with a position puck', (
      tester,
    ) async {
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      // Against the fixture's own length rather than a round number. The
      // pipeline discards the first three fixes at cold start and nothing else
      // on a clean track, so "almost all of them" is the checkable claim.
      final delivered = straightKm().fixes.length;
      final route = drawnRoute(tester);
      expect(
        route.length,
        greaterThan(delivered - 10),
        reason: 'the whole accepted track, not a sample of it',
      );
      expect(route.length, lessThan(delivered));

      final puck = pucks(tester);
      expect(puck, hasLength(1));
      expect(
        puck.single.point,
        route.last,
        reason: 'the puck is the head of the track, not a separate estimate',
      );
    });

    testWidgets('the framing position stops being used once a track exists', (
      tester,
    ) async {
      // Otherwise the puck would sit at the phone's opening position for the
      // length of the run while the line drew somewhere else.
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      expect(
        pucks(tester).single.point,
        isNot(LatLng(framingFix.latitude, framingFix.longitude)),
      );
    });

    testWidgets('the live line is the track the numbers come from', (
      tester,
    ) async {
      // Not a separate estimate drawn alongside. If the map ever showed one
      // track while the distance was accumulated from another, a disagreement
      // between them would be invisible and unfalsifiable.
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RunRecordingScreen)),
      );
      final state = container.read(runRecordingProvider);

      expect(drawnRoute(tester), hasLength(state.pointCount));
      expect(find.text('${state.pointCount} pts'), findsOneWidget);
    });

    testWidgets('the button becomes Finish', (tester) async {
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('the map fills the screen and the numbers sit over it', (
      tester,
    ) async {
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      final screen = tester.getSize(find.byType(RunRecordingScreen));
      expect(tester.getSize(find.byType(RunMap)).height, screen.height);

      // Over it, not below it: the stats card's rect has to overlap the map's.
      final card = tester.getRect(find.text('Distance km'));
      final map = tester.getRect(find.byType(RunMap));
      expect(map.overlaps(card), isTrue);
    });

    testWidgets('the numbers stay on screen with the map, not instead of it', (
      tester,
    ) async {
      // Both, always. The layout must never make anyone choose between seeing
      // where they are and seeing how far they have gone.
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      expect(find.byType(FlutterMap), findsOneWidget);
      for (final label in ['Distance km', 'Moving', 'Pace /km']) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('locating', () {
    testWidgets('says what it is waiting for between Start and the first fix', (
      tester,
    ) async {
      // A recording with no line and no numbers is indistinguishable from one
      // that has silently failed. This is the only thing that separates them,
      // and it is the window a runner watches to decide whether to trust it.
      //
      // An empty fixture is the whole point: Start is pressed, nothing is
      // delivered, and the screen has to hold that state honestly.
      final recorder = FakeRunRecorder(
        const SyntheticTrack(
          name: 'no fixes delivered',
          fixes: [],
          groundTruthDistanceM: 0,
        ),
        framingFix: framingFix,
      );
      await pumpScreen(tester, recorder);
      await startRun(tester);

      expect(find.textContaining('Locating'), findsOneWidget);
      expect(find.textContaining('receiver settles'), findsOneWidget);
      expect(
        find.byType(FlutterMap),
        findsOneWidget,
        reason: 'the locating state is ON the map, not instead of it',
      );
      expect(pucks(tester), hasLength(1));
    });
  });

  group('with no tiles at all', () {
    testWidgets('keeps drawing the track', (tester) async {
      // The offline case, and it is the default here — nothing in this test
      // can reach a tile server. A run recorded in a basement still has to
      // draw, and the map must never be able to cost anyone a run.
      final recorder = FakeRunRecorder(straightKm(), framingFix: framingFix);
      await pumpScreen(tester, recorder);
      await startRun(tester);

      expect(tester.takeException(), isNull);
      expect(drawnRoute(tester), isNotEmpty);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('and still frames the pre-start map', (tester) async {
      await pumpScreen(
        tester,
        FakeRunRecorder(straightKm(), framingFix: framingFix),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(pucks(tester), hasLength(1));
    });
  });
}
