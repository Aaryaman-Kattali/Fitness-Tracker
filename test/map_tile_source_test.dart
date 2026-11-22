import 'dart:convert';
import 'dart:io';

import 'package:fitness_tracker/features/activity/widgets/map_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapTileSource', () {
    test('the active source is keyless', () {
      // The one property the choice turns on, and the one that stopped being
      // true under CARTO without anything failing.
      expect(MapTileSource.active.keyless, isTrue);
    });

    test('the active source is vector, and has exactly one style', () {
      // **This assertion is the inverse of the one it replaces, deliberately.**
      // It used to require a light/dark PAIR and a different document for each
      // brightness, on the reasoning that a dark map rendered from the light
      // style was the bug being fixed. U-3 removed the premise: a palette
      // decided by an OS setting is not a palette, so there is one document
      // and the appearance setting does not reach the map at all.
      const source = MapTileSource.active;
      expect(source.isVector, isTrue);
      expect(source.styleUri, isNotNull);
      expect(source.urlTemplate, isNull);
    });

    test('the raster fallback is still raster, and still keyless', () {
      expect(MapTileSource.openStreetMap.isVector, isFalse);
      expect(MapTileSource.openStreetMap.urlTemplate, isNotNull);
      expect(MapTileSource.openStreetMap.keyless, isTrue);
    });

    test('the raster fallback does not ask for retina tiles it cannot get', () {
      // Moved here from run_map_test.dart when the active basemap became
      // vector. Retina is a raster concept — there is no '{r}' in a style
      // document — so the assertion cannot be made about what the app now
      // renders. It is kept, pointed at the fallback, because the fallback is
      // one line from being live again and this is the trap it falls into.
      //
      // Reason unchanged: CARTO took '{r}' and served true @2x. OSM does not,
      // and with no '{r}' flutter_map resolves retinaMode to SIMULATION, which
      // drops a zoom level and upscales — worse than 1x at the zoom where
      // corners get inspected.
      const fallback = MapTileSource.openStreetMap;
      expect(fallback.serverRetina, isFalse);
      expect(fallback.urlTemplate, isNot(contains('{r}')));
      expect(
        fallback.maxNativeZoom,
        19,
        reason: 'simulation would silently make this 18',
      );
    });

    test('a source cannot be both raster and vector, or neither', () {
      expect(
        () => MapTileSource(
          name: 'Both',
          urlTemplate: 'https://example.invalid/{z}/{x}/{y}.png',
          styleUri: 'https://example.invalid/style',
          attribution: 'nobody',
          keyless: true,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MapTileSource(
          name: 'Neither',
          attribution: 'nobody',
          keyless: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('attribution against the live source', () {
    // The credit is a constant, so it can go stale the moment OpenFreeMap
    // changes who it asks to be credited — and a stale attribution is a
    // licence problem that nothing on screen would ever reveal. This asks the
    // server. Offline it SKIPS rather than fails: a red build on a plane
    // teaches people to ignore red builds, which costs more than this catches.
    setUp(() {
      // flutter_test installs an HttpClient that fails every request, which
      // would make this skip forever and look like it was passing.
      HttpOverrides.global = null;
    });

    test('names every party the served TileJSON credits', () async {
      final Map<String, dynamic> tileJson;
      try {
        tileJson = await _getJson('https://tiles.openfreemap.org/planet');
      } on Object catch (error) {
        markTestSkipped(
          'OpenFreeMap unreachable, attribution unverified: '
          '$error',
        );
        return;
      }

      final credit = (tileJson['attribution'] as String? ?? '').toLowerCase();
      expect(credit, isNotEmpty, reason: 'no attribution to check against');

      final ours = MapTileSource.active.attribution.toLowerCase();
      for (final party in const [
        'openfreemap',
        'openmaptiles',
        'openstreetmap',
      ]) {
        if (!credit.contains(party)) continue;
        expect(
          ours,
          contains(party),
          reason:
              'the served TileJSON credits "$party" and '
              'MapTileSource.active.attribution does not',
        );
      }
    });
  });
}

Future<Map<String, dynamic>> _getJson(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}
