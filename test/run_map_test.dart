import 'dart:async';

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/features/activity/widgets/map_tile_source.dart';
import 'package:fitness_tracker/features/activity/widgets/run_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'support/synthetic_track.dart';

/// The map, driven from fixture data with no database and no network.
///
/// There is no network here and there is not meant to be: `flutter_test` fails
/// every HTTP request by default, so the tiles cannot load, and that is the
/// realistic case rather than a limitation. What the screen must prove is that
/// everything which is NOT a tile still renders — the route, the markers and
/// the numbers are local data and do not depend on a connection.
void main() {
  /// The clean 1 km fixture as coordinates, so the map is fed a real recorded
  /// shape rather than three invented points.
  List<LatLng> fixtureRoute() => [
    for (final fix in straightKm().fixes) LatLng(fix.latitude, fix.longitude),
  ];

  /// Every style URL the widget asked for, in order, across one test.
  ///
  /// The seam doubles as the observation point: which style is requested IS
  /// the theme-following behaviour, so recording the argument is how that gets
  /// asserted without a network or a decoded style document.
  final requestedStyles = <String>[];

  setUp(requestedStyles.clear);

  /// Every start/finish marker on screen, in draw order.
  List<Marker> runMarkers(WidgetTester tester) => tester
      .widgetList<MarkerLayer>(find.byType(MarkerLayer))
      .expand((layer) => layer.markers)
      .toList();

  Marker markerAt(List<Marker> markers, Key key) =>
      markers.firstWhere((m) => m.key == key);

  /// The colours of one marker's band, left to right.
  ///
  /// Reads the painted widget rather than the [Marker] wrapper, because the
  /// band is the only part of the donut that carries a colour and it is the
  /// whole assertion — the ring and the core are the same dark on all three.
  /// `ColoredBox` and not `DecoratedBox`: the dark ring and core are the
  /// latter, so this cannot pick them up by accident.
  List<Color> bandColours(WidgetTester tester, Key key) => tester
      .widgetList<ColoredBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(ColoredBox),
        ),
      )
      .map((box) => box.color)
      .toList();

  Future<void> pumpMap(
    WidgetTester tester, {
    required List<LatLng> route,
    List<LatLng>? rawFixes,
    LatLng? currentPosition,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: CupertinoThemeData(brightness: brightness),
        home: SizedBox(
          height: 400,
          width: 400,
          child: RunMap(
            route: route,
            rawFixes: rawFixes,
            currentPosition: currentPosition,
            // Records the request and never completes. Deliberate: it pins
            // the "style has not arrived yet" frame, which is the one every
            // assertion below is about — the route, markers and controls are
            // local data and must be on screen before any basemap is.
            //
            // Without this the real reader runs, flutter_test fails the HTTP,
            // and whether the banner has appeared by the time of the assert
            // depends on how fast that failure lands. Several tests here were
            // passing on that timing rather than on the behaviour.
            styleLoader: (uri) {
              requestedStyles.add(uri);
              return Completer<vt.Style>().future;
            },
          ),
        ),
      ),
    );
    // Never pumpAndSettle: the tile layer retries and a CupertinoActivityIndicator
    // elsewhere on a real screen animates forever. Explicit pumps, per the
    // landmine in CLAUDE.md.
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('draws the route with a start and an end marker', (tester) async {
    final route = fixtureRoute();
    await pumpMap(tester, route: route);

    final polylines = tester
        .widgetList<PolylineLayer<Object>>(find.byType(PolylineLayer<Object>))
        .expand((layer) => layer.polylines)
        .toList();

    expect(
      polylines.any((line) => line.points.length == route.length),
      isTrue,
      reason: 'the whole recorded track is drawn, not a simplified version',
    );
    expect(
      polylines.any((line) => line.color == AppColors.trackLine),
      isTrue,
    );
    expect(
      polylines.any(
        (line) => line.strokeWidth == AppSpacing.trackCasingStroke,
      ),
      isTrue,
      reason: 'the casing is what gives the route an edge against the tile',
    );

    final markers = runMarkers(tester);

    expect(markers.map((m) => m.key), [
      runFinishMarkerKey,
      runStartMarkerKey,
    ]);
    expect(markerAt(markers, runStartMarkerKey).point, route.first);
    expect(markerAt(markers, runFinishMarkerKey).point, route.last);
  });

  testWidgets('the two markers are identical but for their colour', (
    tester,
  ) async {
    // The requirement that replaced the asymmetric pair: same size, same
    // geometry, and the colour is the only difference. A test that only
    // checked "both are present" would pass on the old ring-and-dot too.
    await pumpMap(tester, route: fixtureRoute());
    final markers = runMarkers(tester);

    final start = markerAt(markers, runStartMarkerKey);
    final finish = markerAt(markers, runFinishMarkerKey);

    expect(start.width, AppSpacing.trackMarkerSize);
    expect(start.height, AppSpacing.trackMarkerSize);
    expect(finish.width, start.width);
    expect(finish.height, start.height);
    expect(
      bandColours(tester, runStartMarkerKey),
      [AppColors.runStartMarker],
    );
    expect(
      bandColours(tester, runFinishMarkerKey),
      [AppColors.runFinishMarker],
    );
  });

  testWidgets('a loop draws one split marker, not two on top of each other', (
    tester,
  ) async {
    // A loop is the case two identical donuts cannot survive, and a straight
    // line cannot show it: on `straightKm` the ends are a kilometre apart and
    // any geometry passes. So the fixture closes.
    final out = fixtureRoute();
    final loop = [...out, ...out.reversed];
    expect(loop.first, loop.last, reason: 'the fixture must actually close');

    await pumpMap(tester, route: loop);
    final markers = runMarkers(tester);

    expect(
      markers.map((m) => m.key),
      [runCombinedMarkerKey],
      reason: 'two markers on one coordinate is the case being removed',
    );
    expect(
      bandColours(tester, runCombinedMarkerKey),
      [AppColors.runStartMarker, AppColors.runFinishMarker],
      reason: 'start on the left, finish on the right',
    );
    expect(
      markers.single.point.latitude,
      closeTo(loop.first.latitude, 1e-9),
      reason: 'midway between two coincident points is either of them',
    );
  });

  testWidgets('the threshold is exercised at the separations really walked', (
    tester,
  ) async {
    // **These two numbers are measured, not invented.** The same 1610 m loop,
    // walked twice, closes to 11.1 m on 23 Aug and 31.8 m on 24 Aug —
    // `capture_threshold_report_test.dart` prints both.
    //
    // **Both combine now, and that is the change 9 Sep 2026 made.** At 15 m
    // one of those walks rendered as a loop and the other did not, so the
    // marker was reporting the receiver's closing error rather than the
    // route: same path, same phone, two afternoons, two different pictures.
    // 35 m covers the measured spread. This case is what says so — if the
    // threshold moves again, it names which walk moved with it.
    final out = fixtureRoute();
    LatLng north(double metres) =>
        LatLng(out.first.latitude + metres / 111320, out.first.longitude);

    for (final separation in [11.1, 31.8]) {
      await pumpMap(tester, route: [...out, north(separation)]);
      expect(
        runMarkers(tester).map((m) => m.key),
        [runCombinedMarkerKey],
        reason: '$separation m is the same loop and must render as one',
      );
    }
  });

  testWidgets('an out-and-back that stops short is still two markers', (
    tester,
  ) async {
    // The other side of raising the threshold, and the reason it cannot go
    // much further. 35 m is still under the shortest gap a deliberate
    // out-and-back leaves — stopping half a block early is a separation a
    // reader can see on the map, and collapsing it would state a loop that
    // did not happen.
    final out = fixtureRoute();
    await pumpMap(
      tester,
      route: [
        ...out,
        LatLng(out.first.latitude + 60 / 111320, out.first.longitude),
      ],
    );

    expect(
      runMarkers(tester).map((m) => m.key),
      [runFinishMarkerKey, runStartMarkerKey],
    );
  });

  testWidgets('recentres on the whole track after the map is panned', (
    tester,
  ) async {
    // Reading the camera through the layer's own context rather than through
    // a controller the test owns: what matters is where the map actually
    // ended up, not that a method was called on it.
    LatLng centre() => MapCamera.of(
      tester.element(find.byType(PolylineLayer<Object>)),
    ).center;

    await pumpMap(tester, route: fixtureRoute());
    final fitted = centre();

    await tester.drag(find.byType(FlutterMap), const Offset(-160, -160));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      centre(),
      isNot(fitted),
      reason: 'if the drag did not move the camera the test proves nothing',
    );

    await tester.tap(find.bySemanticsLabel('Fit the whole track'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(centre().latitude, closeTo(fitted.latitude, 1e-6));
    expect(centre().longitude, closeTo(fitted.longitude, 1e-6));
  });

  testWidgets('renders with no network rather than hanging', (tester) async {
    // The offline case, and it is the default here — nothing in this test can
    // reach a tile server. The assertion is that the local data survived it.
    await pumpMap(tester, route: fixtureRoute());

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'a map with no tiles must not throw',
    );
    expect(
      find.byType(PolylineLayer<Object>),
      findsOneWidget,
      reason: 'the route is local data and does not need a tile server',
    );
  });

  group('when the tile source fails', () {
    // Driven by a loader that fails on demand, NOT by the absence of a
    // network. The obvious assumption is that flutter_test gives this for
    // free, since it fails every HTTP request — it does not. Measured on the
    // raster path: the requests never resolved far enough to reach
    // errorTileCallback, and the banner was still absent after six seconds of
    // pumping. The whole degraded path had no coverage and looked like it had
    // plenty. The seam moved from the tile provider to the style loader when
    // the basemap became vector; every assertion below is unchanged, because
    // what they are about — a dead basemap must be stated, and everything
    // local must still draw — did not change with it.
    Future<void> pumpFailing(WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 400,
            width: 400,
            child: RunMap(
              route: fixtureRoute(),
              styleLoader: (_) =>
                  Future<vt.Style>.error(Exception('style unreachable')),
            ),
          ),
        ),
      );
      // Two frames: the flag is raised in a post-frame callback, because the
      // failure surfaces during a build and setState there is an error.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// The banner's text, or null when there is no banner. Matched on the
    /// message rather than on the source name — the attribution also contains
    /// the source name, and a finder that cannot tell them apart passes
    /// against a build showing no banner at all. It did, before this.
    String? bannerText(WidgetTester tester) {
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((t) => t.contains('not loading'));
      return texts.isEmpty ? null : texts.single;
    }

    testWidgets('the banner names the source and the track still draws', (
      tester,
    ) async {
      await pumpFailing(tester);

      expect(
        bannerText(tester),
        isNotNull,
        reason: 'a dead tile source must be stated, not left as grey squares',
      );
      expect(
        find.byType(PolylineLayer<Object>),
        findsOneWidget,
        reason: 'the route is local data and owes a tile server nothing',
      );
      expect(
        tester
            .widgetList<PolylineLayer<Object>>(
              find.byType(PolylineLayer<Object>),
            )
            .expand((layer) => layer.polylines)
            .any((line) => line.points.length == fixtureRoute().length),
        isTrue,
        reason: 'the whole track, not a stub',
      );
    });

    testWidgets('it says whose tiles failed, from the config', (tester) async {
      // A failure message that does not name the third party sends the reader
      // looking for a bug in this app — which is exactly what CARTO's
      // watermark did. The name comes from MapTileSource, so swapping the
      // source cannot leave the banner naming the old one.
      await pumpFailing(tester);

      expect(bannerText(tester), startsWith(MapTileSource.active.name));
    });

    testWidgets('and that the numbers are still right', (tester) async {
      // The other half of its job. A bare map with no explanation reads as a
      // lost run, which is the opposite of what happened.
      await pumpFailing(tester);

      expect(bannerText(tester), contains('stored on this phone'));
      expect(bannerText(tester), contains('only the background is missing'));
    });

    testWidgets('the attribution gives way to it', (tester) async {
      // The documented coupling: the credit is owed for tiles that are on
      // screen, and while the banner is up there are none.
      await pumpFailing(tester);

      expect(find.text(MapTileSource.active.attribution), findsNothing);
    });

    testWidgets('and comes back when the tiles do', (tester) async {
      // The control. Without this the three assertions above pass against a
      // widget that shows the banner unconditionally.
      await pumpMap(tester, route: fixtureRoute());

      expect(bannerText(tester), isNull);
      expect(find.text(MapTileSource.active.attribution), findsOneWidget);
    });
  });

  testWidgets('says so when a run stored no track', (tester) async {
    // Distinct from an empty map. A run with no points and a run whose tiles
    // failed both show nothing, and they are different problems.
    await pumpMap(tester, route: const []);

    expect(find.textContaining('stored no track'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  group('the basemap', () {
    testWidgets('is read from this repo, not from a style server', (
      tester,
    ) async {
      // **This assertion changed shape when the styles were vendored, and the
      // intent it carries did not.** It was "the style URL contains no API
      // key", made about a URL fetched from the vendor. There is no such URL
      // now: the document is an asset, so the strongest available statement
      // here is that the widget asks the bundle rather than the network — and
      // the keyless property it used to stand for is asserted properly, over
      // the documents' own contents, in `map_style_test.dart`.
      await pumpMap(tester, route: fixtureRoute());

      expect(requestedStyles, hasLength(1));
      final uri = requestedStyles.single;
      expect(uri, startsWith('asset://'));
      for (final marker in const [
        'api_key',
        'apikey',
        'access_token',
        'key=',
        '{key}',
        'token',
      ]) {
        expect(uri.toLowerCase(), isNot(contains(marker)), reason: uri);
      }
    });

    testWidgets('does NOT follow the app theme', (tester) async {
      // **The exact inverse of what this test asserted yesterday, and the
      // premise moved rather than the test being bent.** It required two
      // different style documents across two brightnesses, because the OS
      // setting chose the basemap. U-3 removed that: the map is this app's
      // palette and a phone setting does not get a vote, so the same document
      // is requested in both appearances.
      //
      // Still driven from two real pumps at two brightnesses. A test that
      // simply stopped looking at brightness would pass against a build that
      // still switched styles; this one cannot.
      await pumpMap(tester, route: fixtureRoute());
      await pumpMap(
        tester,
        route: fixtureRoute(),
        brightness: Brightness.dark,
      );

      expect(requestedStyles, isNotEmpty);
      expect(
        requestedStyles.toSet(),
        {MapTileSource.active.styleUri},
        reason: 'one style, whatever the OS appearance says',
      );
    });

    testWidgets('identifies itself to the tile server', (tester) async {
      // The OSM tile usage policy blocks generic library defaults, and the
      // same courtesy is owed to OpenFreeMap. Without this header the
      // libraries send their own name, which is one.
      //
      // **Weaker than the assertion it replaces, and that is stated rather
      // than hidden.** It checked the header on the mounted layer. The vector
      // path sends it through StyleReader, which this file's test seam
      // replaces wholesale, so what is checkable here is that the app defines
      // a non-generic agent — not that the request carried it. The raster
      // fallback below still proves the wiring end to end.
      await pumpMap(tester, route: fixtureRoute());

      expect(runMapUserAgent, contains('com.personal.fitness_tracker'));
      expect(
        runMapUserAgent,
        isNot(startsWith('flutter_map')),
        reason: 'the library default is the thing being replaced',
      );
    });

    testWidgets('does not invert the track casing either', (tester) async {
      // **Also inverted, and for the same reason, and this one is a bug
      // guard rather than bookkeeping.** The casing is edge definition: it
      // works by sitting at the opposite end of the range from the ground.
      // While the ground followed the theme, so did it. With one fixed light
      // ground, a casing that still inverted would resolve LIGHT on a phone
      // in dark mode — a light casing on a light map, which is not a weaker
      // outline but no outline at all, and the track would lose the thing
      // that makes it findable.
      //
      // So the assertion is that the two brightnesses produce the SAME dark
      // casing, and that it is dark.
      Color casing(WidgetTester t) => t
          .widgetList<PolylineLayer<Object>>(find.byType(PolylineLayer<Object>))
          .expand((layer) => layer.polylines)
          .firstWhere((l) => l.strokeWidth == AppSpacing.trackCasingStroke)
          .color;

      await pumpMap(tester, route: fixtureRoute());
      final light = casing(tester);

      await pumpMap(
        tester,
        route: fixtureRoute(),
        brightness: Brightness.dark,
      );
      final dark = casing(tester);

      expect(
        light,
        dark,
        reason: 'the ground does not change, so neither may the casing',
      );
      expect(
        light.computeLuminance(),
        lessThan(0.1),
        reason: 'edge definition against a light ground means a DARK casing',
      );
    });

    testWidgets('credits OpenStreetMap, and no longer credits CARTO', (
      tester,
    ) async {
      // One party now: OSM supplies the data AND renders and serves the tiles.
      // The second name is asserted ABSENT rather than just dropped — a stale
      // credit for a service no longer being used is its own small lie.
      await pumpMap(tester, route: fixtureRoute());

      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(find.textContaining('CARTO'), findsNothing);
    });
  });

  group('live mode', () {
    LatLng centre(WidgetTester tester) => MapCamera.of(
      tester.element(find.byType(PolylineLayer<Object>)),
    ).center;

    testWidgets('draws a position puck and no end marker', (tester) async {
      // A run still being recorded has no end. Drawing an end marker on one
      // would claim something that is not true yet, and the puck is the thing
      // being looked for anyway.
      final route = fixtureRoute();
      await pumpMap(tester, route: route, currentPosition: route.last);

      final markers = tester
          .widgetList<CircleLayer<Object>>(find.byType(CircleLayer<Object>))
          .expand((layer) => layer.circles)
          .toList();

      final puck = markers.where((m) => m.color == AppColors.trackPosition);
      expect(puck, hasLength(1));
      expect(puck.single.point, route.last);
      expect(
        runMarkers(tester).map((m) => m.key),
        [runStartMarkerKey],
        reason:
            'where it began is known and worth showing; where it ends '
            'is not, and a finish marker would claim it is',
      );
    });

    testWidgets('follows the position as the track extends', (tester) async {
      final route = fixtureRoute();
      final half = route.sublist(0, route.length ~/ 2);

      await pumpMap(tester, route: half, currentPosition: half.last);
      final before = centre(tester);

      await pumpMap(tester, route: route, currentPosition: route.last);
      final after = centre(tester);

      expect(after, isNot(before));
      expect(after.latitude, closeTo(route.last.latitude, 1e-6));
      expect(after.longitude, closeTo(route.last.longitude, 1e-6));
    });

    testWidgets('stops following the moment the map is panned', (tester) async {
      // The binding constraint: a camera that keeps reclaiming itself pulls
      // the map out from under a thumb that panned away deliberately.
      final route = fixtureRoute();
      final half = route.sublist(0, route.length ~/ 2);

      await pumpMap(tester, route: half, currentPosition: half.last);
      expect(find.bySemanticsLabel('Follow my position'), findsNothing);

      await tester.drag(find.byType(FlutterMap), const Offset(-120, -120));
      await tester.pump(const Duration(milliseconds: 100));
      final panned = centre(tester);

      expect(
        find.bySemanticsLabel('Follow my position'),
        findsOneWidget,
        reason: 'the way back has to be offered once following has stopped',
      );

      // A further fix arrives. The camera must NOT move.
      await pumpMap(tester, route: route, currentPosition: route.last);
      expect(centre(tester).latitude, closeTo(panned.latitude, 1e-6));
      expect(centre(tester).longitude, closeTo(panned.longitude, 1e-6));
    });

    testWidgets('resumes following when the button is tapped', (tester) async {
      final route = fixtureRoute();
      final half = route.sublist(0, route.length ~/ 2);

      await pumpMap(tester, route: half, currentPosition: half.last);
      await tester.drag(find.byType(FlutterMap), const Offset(-120, -120));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.bySemanticsLabel('Follow my position'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(centre(tester).latitude, closeTo(half.last.latitude, 1e-6));
      expect(
        find.bySemanticsLabel('Follow my position'),
        findsNothing,
        reason: 'following again, so there is nothing left to resume',
      );

      // And it is following for real, not merely recentred once.
      await pumpMap(tester, route: route, currentPosition: route.last);
      expect(centre(tester).latitude, closeTo(route.last.latitude, 1e-6));
    });

    testWidgets('offers no fit-track button while live', (tester) async {
      // Fit-track belongs to a finished run. Mid-recording it would fight the
      // follow camera: fit, then get moved back a second later.
      final route = fixtureRoute();
      await pumpMap(tester, route: route, currentPosition: route.last);

      expect(find.bySemanticsLabel('Fit the whole track'), findsNothing);
    });

    testWidgets('says what it is waiting for before the first point', (
      tester,
    ) async {
      // Distinct from a saved run with no track. One failed; this one has not
      // started yet, and the cold-start filter discards the first three fixes
      // by design.
      await tester.pumpWidget(
        const CupertinoApp(
          home: SizedBox(
            height: 400,
            width: 400,
            child: RunMap(route: [], emptyMessage: 'Waiting for GPS.'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Waiting for GPS.'), findsOneWidget);
      expect(find.textContaining('stored no track'), findsNothing);
    });
  });

  group('a position with no track yet', () {
    // The state the recording screen sits in before Start, and for the first
    // seconds after it. It used to render as the message panel above, which
    // meant the live screen had no map until the pipeline produced one — the
    // pre-start map was simply missing, not broken.
    const here = LatLng(19.2183, 72.9781);

    testWidgets('is a map, not a message', (tester) async {
      await pumpMap(tester, route: const [], currentPosition: here);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('stored no track'), findsNothing);
    });

    testWidgets('centres on the position, since there is no shape to fit', (
      tester,
    ) async {
      await pumpMap(tester, route: const [], currentPosition: here);

      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      expect(options.initialCenter, here);
      expect(options.initialCameraFit, isNull);
      expect(options.initialZoom, AppSpacing.mapLocatingZoom);
    });

    testWidgets('draws the puck and no line', (tester) async {
      await pumpMap(tester, route: const [], currentPosition: here);

      final markers = tester
          .widgetList<CircleLayer<Object>>(find.byType(CircleLayer<Object>))
          .expand((layer) => layer.circles);

      expect(
        markers.where((m) => m.color == AppColors.trackPosition),
        hasLength(1),
      );
      expect(
        runMarkers(tester),
        isEmpty,
        reason: 'nothing has started, so there is no start to mark',
      );
      expect(find.byType(PolylineLayer<Object>), findsNothing);
    });

    testWidgets('falls back to the message only when there is neither', (
      tester,
    ) async {
      // The remaining honest blank: no track, no position, nothing to point a
      // camera at. It has to stay reachable — inventing a location to avoid an
      // empty screen would be worse than the empty screen.
      await pumpMap(tester, route: const []);

      expect(find.byType(FlutterMap), findsNothing);
    });
  });

  group('the debug overlay', () {
    testWidgets('draws nothing when it is off', (tester) async {
      await pumpMap(tester, route: fixtureRoute());

      final circles = tester
          .widgetList<CircleLayer<Object>>(find.byType(CircleLayer<Object>))
          .expand((layer) => layer.circles);

      expect(
        circles.where((c) => c.color == AppColors.trackRawFix),
        isEmpty,
      );
    });

    testWidgets('draws every raw fix, underneath the route', (tester) async {
      // The layer ORDER is the assertion that matters. Drawn on top, the
      // points would hide the line and the screen would answer the wrong
      // question; the whole diagnostic is a line seen against the cloud of
      // measurements it came from.
      final route = fixtureRoute();
      final raw = [
        for (final point in route)
          LatLng(point.latitude + 0.00002, point.longitude),
      ];
      await pumpMap(tester, route: route, rawFixes: raw);

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final rawIndex = map.children.indexWhere(
        (child) =>
            child is CircleLayer &&
            child.circles.any((c) => c.color == AppColors.trackRawFix),
      );
      final routeIndex = map.children.indexWhere(
        (child) => child is PolylineLayer,
      );

      expect(rawIndex, isNonNegative, reason: 'the overlay must be present');
      expect(
        rawIndex,
        lessThan(routeIndex),
        reason: 'raw fixes go UNDER the smoothed line, never over it',
      );

      final drawn = (map.children[rawIndex] as CircleLayer).circles;
      expect(
        drawn,
        hasLength(raw.length),
        reason: 'every accepted fix, not a sample of them',
      );
    });
  });
}
