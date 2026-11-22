import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/features/activity/widgets/map_tile_source.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// The vendored basemap style document.
///
/// **It is ours now.** It was fetched from OpenFreeMap on 7 Sep 2026, has
/// since been recoloured to this app's palette, and nothing upstream will fix
/// it again — which is the whole reason this file exists. A hosted style that
/// broke was the vendor's problem and arrived pre-tested; a vendored one that
/// breaks is ours and arrives on a phone, outdoors, mid-run.
///
/// **One document, not two.** There was a light/dark pair here until 8 Sep
/// 2026. U-3 removed the choice: a palette is an identity, and one decided by
/// a phone's appearance setting is not one. `dark.json` was vendored on 7 Sep
/// and dropped on 8 Sep rather than left unreferenced — NOTES.md says why.
///
/// So the invariants that vendoring puts at risk are pinned here rather than
/// discovered later: that the document still parses, that nothing inside it
/// needs a key, and — the one that vendoring specifically endangers — that
/// every URL it contains is absolute. A relative sprite or tile URL resolves
/// against the style's own location, and that location is now `asset://`, so
/// a relative URL would resolve to an asset this repo does not contain and
/// fail silently as a missing basemap.
///
/// Read off disk rather than through `rootBundle`: `flutter test` runs with
/// the package root as its working directory, and reading the file is reading
/// the thing that actually gets shipped.
void main() {
  final document = File('assets/map_style/positron.json');

  Map<String, Object?> read() =>
      (jsonDecode(document.readAsStringSync()) as Map).cast<String, Object?>();

  /// Every string anywhere in the document that looks like a URL.
  ///
  /// Walked rather than read from the three fields that are supposed to hold
  /// them: a style is a nested document and the point of the check is to catch
  /// a URL somewhere nobody thought to look.
  List<String> urlsIn(Object? node) {
    final found = <String>[];
    void walk(Object? n) {
      switch (n) {
        case final String s when s.contains('://') || s.startsWith('//'):
          found.add(s);
        case Map():
          n.values.forEach(walk);
        case List():
          n.forEach(walk);
      }
    }

    walk(node);
    return found;
  }

  group('the vendored style', () {
    test('is present and parses as a MapLibre style', () {
      expect(
        document.existsSync(),
        isTrue,
        reason: 'the app reads this path at run time',
      );
      final style = read();
      expect(style['version'], 8);
      expect(style['sources'], isA<Map<String, Object?>>());
      expect((style['layers']! as List).isNotEmpty, isTrue);
    });

    test('every URL in it is absolute', () {
      // The invariant vendoring endangers. `StyleReader._resolve` returns
      // http(s) and asset URLs untouched and resolves everything else against
      // the style's own URI — which is now an asset path, so a relative URL
      // would silently point into this bundle.
      for (final url in urlsIn(read())) {
        expect(
          url.startsWith('https://'),
          isTrue,
          reason:
              '"$url" is not absolute https, so it would resolve against '
              'asset://assets/map_style/ and never load',
        );
      }
    });

    test('needs no key, account or token', () {
      // The property A2-7 turns on, and it now has to hold about the
      // document's contents rather than about the URL it was fetched from. A
      // vendored style could carry a keyed tile source and nothing outside
      // this test would notice until the free tier ended.
      for (final url in urlsIn(read())) {
        for (final marker in const [
          'api_key',
          'apikey',
          'access_token',
          'key=',
          '{key}',
          'token',
        ]) {
          expect(
            url.toLowerCase(),
            isNot(contains(marker)),
            reason: '"$url" looks keyed',
          );
        }
      }
    });
  });

  test('the active source points at the vendored document', () {
    // The one line that changes the basemap, asserted so that a swap back to
    // the hosted style is a deliberate edit rather than something that happens
    // while nobody is reading.
    expect(MapTileSource.active.isVector, isTrue);
    expect(MapTileSource.active.styleUri, startsWith('asset://'));

    // And that the asset URI names a file this repo actually contains — the
    // failure mode being guarded is a typo in a path that no compiler checks
    // and that only shows up as a basemap that never draws.
    final uri = MapTileSource.active.styleUri!;
    expect(
      File(uri.substring('asset://'.length)).existsSync(),
      isTrue,
      reason: '$uri does not exist',
    );
  });

  test('the dropped dark document is gone, not merely unreferenced', () {
    // U-3 removed the second style. Leaving the file in `assets/` would be
    // dead weight that still ships inside the bundle and still reads as a
    // choice someone might wire back up, so the deletion is pinned rather
    // than left to a reviewer noticing.
    expect(File('assets/map_style/dark.json').existsSync(), isFalse);
  });

  test('the hosted source is kept as the way back', () {
    // Not dead code: it is what `active` was before vendoring, so abandoning
    // local edits is one line rather than a deletion and a re-fetch.
    expect(MapTileSource.openFreeMapHosted.styleUri, startsWith('https://'));
  });

  /// The palette, measured against the document that actually renders.
  ///
  /// **These assertions live here rather than in `app_colors_contrast_test`
  /// because the ground is in the JSON.** The overlay tokens are Dart and the
  /// basemap is an asset, and the numbers that matter are relationships
  /// between the two; restating the land colour as a hex in the Dart library
  /// would create the second source of truth every measurement then depends on.
  ///
  /// Everything is measured as the COMPOSITE that renders, never the nominal
  /// hex. Buildings are a low-opacity fill over land and the track is a core
  /// inside a translucent casing, so a solid-vs-solid comparison compares two
  /// things that never share a screen.
  ///
  /// **The ground inverted on 8 Sep 2026 and five assertions here inverted
  /// with it.** They were not wrong; they encoded a LIGHT ground, and each was
  /// a floor that only means anything while the map is brighter than the
  /// things drawn on it. What replaced each is recorded at the case.
  group('the palette', () {
    Map<String, Object?> layer(String id) {
      final found = (read()['layers']! as List)
          .cast<Map<String, Object?>>()
          .where((l) => l['id'] == id);
      expect(found, hasLength(1), reason: 'no layer "$id"');
      return found.single;
    }

    Object? paint(String id, String property) =>
        (layer(id)['paint']! as Map)[property];

    /// A paint colour, required to be a plain `#RRGGBB` hex.
    ///
    /// The strictness is the point. Upstream mixes `rgb()`, `hsl()` and
    /// `hsla()` forms, and a parser that quietly accepted them all would
    /// happily read a value it had misunderstood.
    Color colorOf(String id, String property) {
      final raw = paint(id, property);
      expect(
        raw,
        matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
        reason:
            '$id.$property is $raw, which the recolour should have set '
            'to a plain hex',
      );
      return Color(int.parse('FF${(raw! as String).substring(1)}', radix: 16));
    }

    Color over(Color fg, Color bg, double alpha) => Color.from(
      alpha: 1,
      red: fg.r * alpha + bg.r * (1 - alpha),
      green: fg.g * alpha + bg.g * (1 - alpha),
      blue: fg.b * alpha + bg.b * (1 - alpha),
    );

    double luminance(Color c) {
      double channel(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    double contrast(Color a, Color b) {
      final (x, y) = (luminance(a), luminance(b));
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    Color land() => colorOf('background', 'background-color');
    Color water() => colorOf('water', 'fill-color');

    /// Every ground the basemap paints, as the composite that renders.
    Map<String, Color> surfaces() {
      final ground = land();
      return {
        'land': ground,
        'water': water(),
        'path': colorOf('highway_path', 'line-color'),
        'minor road': colorOf('highway_minor', 'line-color'),
        'major casing': colorOf('highway_major_casing', 'line-color'),
        'major inner': colorOf('highway_major_inner', 'line-color'),
        'motorway casing': colorOf('highway_motorway_casing', 'line-color'),
        'park': over(
          colorOf('park', 'fill-color'),
          ground,
          paint('park', 'fill-opacity')! as double,
        ),
        'building': over(
          colorOf('building', 'fill-color'),
          ground,
          paint('building', 'fill-opacity')! as double,
        ),
      };
    }

    test('the ground is dark, and the roads are the light thing on it', () {
      // **The principle of the whole palette, asserted as a relationship.**
      // The previous map failed by putting land, parks, buildings and roads
      // all at mid luminance: they differed in hue and barely in value, so
      // nothing receded and nothing advanced, and it read as a topographic
      // survey. The fix is value separation, and its direction is dark
      // ground, light roads.
      final ground = land();
      expect(
        luminance(ground),
        lessThan(0.02),
        reason: 'the ground must recede',
      );
      for (final road in ['highway_minor', 'highway_major_inner']) {
        expect(
          luminance(colorOf(road, 'line-color')),
          greaterThan(luminance(ground)),
          reason: '$road must advance off the ground',
        );
      }
    });

    test('roads vs ground is the LARGEST separation on the map', () {
      // The route is read against the roads while moving, so no background
      // class may separate from the ground by more than the roads do. That is
      // what stops parks or water growing back into the mid-tone mush this
      // palette replaced.
      final ground = land();
      final roads = contrast(colorOf('highway_minor', 'line-color'), ground);
      final backgrounds = {
        'water': contrast(water(), ground),
        'park': contrast(surfaces()['park']!, ground),
        'building': contrast(surfaces()['building']!, ground),
      };
      for (final b in backgrounds.entries) {
        expect(
          b.value,
          lessThan(roads),
          reason: '${b.key} separates from the ground more than roads do',
        );
      }
    });

    test('the road hierarchy is a monotone, separated ramp', () {
      // **Inverted 8 Sep 2026.** This asserted each class was DARKER than the
      // one below, which was right while the ground was near-white. On a dark
      // ground the ramp climbs: minor, major, motorway, each lighter than and
      // clear of the step below.
      //
      // Measured on the INNER colours now rather than the casings. On a light
      // map the casing was a road's visible edge; on a dark one the road
      // surface itself carries the hierarchy.
      final ground = land();
      final ramp = {
        'minor': colorOf('highway_minor', 'line-color'),
        'major': colorOf('highway_major_inner', 'line-color'),
        'motorway': const Color(0xFFF2F5FA),
      };

      var previous = ground;
      for (final step in ramp.entries) {
        expect(
          luminance(step.value),
          greaterThan(luminance(previous)),
          reason: '${step.key} must be lighter than the step below it',
        );
        expect(
          contrast(step.value, previous),
          greaterThanOrEqualTo(1.25),
          reason: '${step.key} is too close to the step below it',
        );
        previous = step.value;
      }
    });

    test('paths are legible, and distinct from the roads beside them', () {
      // Priority of the original recolour and still the thing most worth
      // seeing while moving. The road comparison is deliberately a WEAK bar:
      // a light path and a light road cannot be separated by value without
      // pushing one of them off the ramp, so hue and stroke weight carry that
      // distinction and this only guarantees they are not the same colour.
      //
      // **The major-road half of this moved out on 9 Sep 2026** — see the
      // case below. That pair turned out to be the one road pair a colour
      // vision simulation collapses, and a bar this weak could not say so.
      final path = colorOf('highway_path', 'line-color');
      expect(contrast(path, land()), greaterThanOrEqualTo(3));
      expect(
        contrast(path, colorOf('highway_minor', 'line-color')),
        greaterThanOrEqualTo(1.5),
      );
    });

    test('the path separates from the major road by VALUE, not by hue', () {
      // **U-8, and it is a colour vision finding.** Path `#8FBFB5` against
      // major road `#C8CEDA` measured ΔE2000 18.9 in normal vision and 8.1
      // under a Machado severity-1.0 deuteranope simulation: the path's teal
      // desaturates to a grey of nearly the same value, and the pair was
      // separating by hue with only 1.29:1 of value underneath it. Paths are
      // what is looked at while running.
      //
      // **1.5:1 both sides is the whole window, not a comfortable floor.**
      // The path sits between minor and major, so this bar and the one above
      // pull in opposite directions: lightening the major road instead is not
      // available — it is one step below motorway `#F2F5FA` at 1.45:1 and the
      // ramp case needs 1.25:1, leaving no headroom above it. `#7DA89F` is
      // the point where both sides read the same, 1.64:1 and 1.67:1.
      expect(
        contrast(
          colorOf('highway_path', 'line-color'),
          colorOf('highway_major_inner', 'line-color'),
        ),
        greaterThanOrEqualTo(1.5),
        reason: 'the pair is left separating by hue, which a simulation eats',
      );
    });

    test('a halo width with no halo colour paints nothing, so none exists', () {
      // The MapLibre spec's default `text-halo-color` is `rgba(0,0,0,0)` and
      // `theme_reader.dart:165` implements exactly that, so a layer setting a
      // width and no colour has a fully transparent halo. It reads as
      // configured and draws nothing, which is the failure this pins: upstream
      // Positron shipped two such layers and got away with it, because `#666`
      // on a near-white ground is legible with no halo at all.
      for (final layer
          in (read()['layers']! as List).cast<Map<String, Object?>>()) {
        if (layer['type'] != 'symbol') continue;
        final paint = (layer['paint'] as Map?)?.cast<String, Object?>() ?? {};
        if (!paint.containsKey('text-halo-width')) continue;
        expect(
          paint['text-halo-color'],
          isNotNull,
          reason:
              '${layer['id']} sets a halo width and no colour, so its halo '
              'is transparent and the width is decoration',
        );
      }
    });

    test('a street label is carried by its halo on the road it names', () {
      // **The recolour inverted the ground under these labels and not the
      // labels.** A street name runs along the road it names for most of its
      // length, and `#9DA1AC` on the light road ribbons is 1.64 to 1.67:1 —
      // so it was legible only where it crossed open ground, and with no halo
      // there was nothing separating one label from the next either. That
      // reads as merged text even where the placement is correct, which is
      // what sent the first diagnosis at the renderer.
      //
      // Same max(ink, halo) rule the route and the raw-fix cloud live by: on
      // the ground the ink carries it, on every road the halo does, and
      // neither has to work everywhere.
      for (final id in ['highway-name-minor', 'highway-name-major']) {
        final label = colorOf(id, 'text-color');
        final halo = colorOf(id, 'text-halo-color');
        expect(
          contrast(label, halo),
          greaterThanOrEqualTo(4.5),
          reason: '$id: the halo has to separate from the ink it surrounds',
        );
        for (final surface in surfaces().entries) {
          expect(
            math.max(
              contrast(label, surface.value),
              contrast(halo, surface.value),
            ),
            greaterThanOrEqualTo(3),
            reason: '$id disappears on ${surface.key}',
          );
        }
      }
    });

    test('water reads as a different surface from the land', () {
      // **Relaxed from 3:1 on 8 Sep 2026, and the reason is structural.** On
      // the light map water was the one dark fill and cleared 12:1 trivially.
      // A dark ground compresses every background class into the bottom of
      // the luminance range — there is nowhere below #14151B to go — so the
      // background classes separate at 1.2 to 1.8 and the whole upper range
      // is spent on roads and the route. That is the design rather than a
      // concession: see the roads-are-the-largest-separation case above.
      expect(
        contrast(water(), land()),
        greaterThanOrEqualTo(1.5),
        reason: 'water has to read as water',
      );
      expect(water(), isNot(AppColors.accentPrimary));
    });

    test('buildings read as mass rather than detail', () {
      // **The 0.35 opacity ceiling is gone, replaced by what it protected.**
      // On the light map an opaque-ish building fill dropped the raw-fix cloud
      // to 1.79:1, so the opacity WAS the safeguard and the ceiling stood in
      // for it. The cloud has a white border now and the ground is dark, so
      // the quantity that matters is asserted directly rather than proxied by
      // a number a later palette would have to guess the meaning of.
      final ground = land();
      final building = over(
        colorOf('building', 'fill-color'),
        ground,
        paint('building', 'fill-opacity')! as double,
      );
      expect(
        contrast(building, ground),
        lessThan(2),
        reason: 'buildings must stay mass, not detail',
      );
    });

    test('the route is findable on every ground, by core or by casing', () {
      // **Replaces a bare casing floor, which the inversion broke.** The old
      // case demanded the casing clear 3:1 everywhere; on a dark ground it
      // composites to 1.06 and does nothing at all.
      //
      // That is not a defect. The casing and the core cover complementary
      // halves of the range: the dark casing carries the route across the
      // light roads, the magenta core carries it across the dark ground, and
      // neither has to work everywhere. Asserting either alone would fail a
      // route that is perfectly visible.
      for (final surface in surfaces().entries) {
        final casing = over(
          AppColors.trackLineCasing,
          surface.value,
          AppColors.trackLineCasing.a,
        );
        final best = math.max(
          contrast(AppColors.trackLine, surface.value),
          contrast(casing, surface.value),
        );
        expect(
          best,
          greaterThanOrEqualTo(3),
          reason: 'the route disappears on ${surface.key}',
        );
      }
    });

    test('the run markers separate from every ground AND from the route', () {
      // They sit ON the magenta line, so clearing the ground is only half of
      // what they need. The dark ring does the other half — the ink is lime
      // and cyan, both light, and the route is light too.
      final ring = AppColors.trackLineCasing.withValues(alpha: 1);
      for (final marker in {
        'start': AppColors.runStartMarker,
        'finish': AppColors.runFinishMarker,
      }.entries) {
        for (final surface in surfaces().entries) {
          final best = math.max(
            contrast(marker.value, surface.value),
            contrast(ring, surface.value),
          );
          expect(
            best,
            greaterThanOrEqualTo(3),
            reason: '${marker.key} marker vanishes on ${surface.key}',
          );
        }
      }
      expect(
        contrast(ring, AppColors.trackLine),
        greaterThanOrEqualTo(3),
        reason: 'the markers must separate from the route they sit on',
      );
    });

    test('start and finish are told apart by hue, so geometry must differ', () {
      // **1.53:1 — they do NOT separate by value**, which is exactly why
      // `run_map.dart` draws them as a ring and a dot rather than a matched
      // pair. On a loop the two coordinates coincide; identical geometry there
      // means one hides the other, and only hue would be left to say which
      // survived. Pinned so anyone proposing a symmetric pair meets this
      // number first — it has been proposed once already.
      expect(
        contrast(AppColors.runStartMarker, AppColors.runFinishMarker),
        lessThan(2),
      );
    });

    test('the raw-fix cloud is findable on every ground, water included', () {
      // **Replaces the fill-only baseline, which the inversion broke.** The
      // old case asserted the accent fill alone cleared 2.9:1 against the
      // ground — true on a near-white map, and 1.53:1 on this one.
      //
      // The criterion is the one the route lives by: findable if EITHER part
      // separates. 2.1 is the achievable ceiling rather than a comfortable
      // margin, and the binding ground is a mid-luminance surface where the
      // FILL already carries it and no border colour improves on it.
      for (final surface in surfaces().entries) {
        final fill = over(
          AppColors.trackRawFix,
          surface.value,
          AppColors.trackRawFix.a,
        );
        final best = math.max(
          contrast(fill, surface.value),
          contrast(AppColors.trackRawFixBorder, surface.value),
        );
        expect(
          best,
          greaterThanOrEqualTo(2.1),
          reason: 'the raw-fix cloud vanishes on ${surface.key}',
        );
      }
    });

    test('the cloud stays readable on the route drawn over it', () {
      // New, and specific to the route becoming magenta. The overlay used to
      // be derived from the accent; if it still were, it would now be the same
      // hue as the line it exists to be compared against.
      expect(
        math.max(
          contrast(
            over(
              AppColors.trackRawFix,
              AppColors.trackLine,
              AppColors.trackRawFix.a,
            ),
            AppColors.trackLine,
          ),
          contrast(AppColors.trackRawFixBorder, AppColors.trackLine),
        ),
        greaterThanOrEqualTo(3),
        reason: 'the cloud must read against the route drawn over it',
      );
    });
  });
}
