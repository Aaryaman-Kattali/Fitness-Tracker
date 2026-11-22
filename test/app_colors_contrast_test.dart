import 'dart:math' as math;

import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// The palette, measured rather than eyeballed.
///
/// **Single theme, so this file no longer loops over `Brightness`.** Every
/// token is one colour; there is no variant to resolve and no second ground to
/// check. That halves the cases and doubles what each one means.
///
/// **It now covers FILL pairings, which is the gap that made it worth
/// rewriting.** The old oracle measured one accent as TEXT on the surfaces it
/// tinted, and that was the whole truth while the accent was never a fill.
/// `accentPrimary` is the primary button's background now, so the pairing that
/// matters most — dark label ON a saturated fill — was invisible to the check
/// that existed. An oracle that does not cover the loudest element on the
/// screen is measuring the easy half.
///
/// The bars are WCAG AA: 4.5:1 for normal text, 3:1 for large text and UI
/// components. Labels in this app render at `caption2` 11pt, so the 3:1
/// allowance does not reach them — which is exactly what forced `textLabel`
/// off #6E7280.
void main() {
  const aaNormalText = 4.5;
  const aaLargeText = 3.0;

  /// The three grounds anything can land on. `surfaceControl` is the strictest
  /// and is therefore the one that sets every floor below.
  const surfaces = <String, Color>{
    'surfacePage': AppColors.surfacePage,
    'surfaceCard': AppColors.surfaceCard,
    'surfaceControl': AppColors.surfaceControl,
  };

  group('text on every surface', () {
    const stops = <String, Color>{
      'textPrimary': AppColors.textPrimary,
      'textSecondary': AppColors.textSecondary,
      'textLabel': AppColors.textLabel,
    };

    for (final stop in stops.entries) {
      for (final surface in surfaces.entries) {
        test('${stop.key} on ${surface.key}', () {
          final ratio = _contrast(stop.value, surface.value);
          expect(
            ratio,
            greaterThanOrEqualTo(aaNormalText),
            reason:
                '${stop.key} ${_hex(stop.value)} on ${surface.key} '
                '${_hex(surface.value)} is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    }

    test(
      'textLabel is usable at label size, which is why it is not #6E7280',
      () {
        // **The measurement that changed a specified value.** #6E7280 was the
        // original spec and scored 3.97 / 3.59 / 3.19 — large-text only, on a
        // stop whose entire job is small muted labels. Pinned as the ratio
        // rather than the hex so that darkening it back toward the original has
        // to fail here rather than merely differ.
        expect(
          _contrast(AppColors.textLabel, AppColors.surfaceControl),
          greaterThanOrEqualTo(aaNormalText),
        );
        expect(AppColors.textLabel, isNot(const Color(0xFF6E7280)));
      },
    );

    test('the muted stops are separated by weight, not by contrast', () {
      // textLabel had to move up to clear AA, which compressed it against
      // textSecondary to about 1.27:1. That is recorded as an accepted cost
      // rather than a defect: the hierarchy is carried by font weight and
      // size. This asserts the compression is REAL, so that a future attempt
      // to restore the visual gap by darkening textLabel collides with the AA
      // test above rather than quietly passing here.
      final gap = _contrast(AppColors.textSecondary, AppColors.textLabel);
      expect(gap, lessThan(1.5));
    });
  });

  group('accents as values', () {
    // "Labels stay muted; VALUES get colour" — so every accent is read as a
    // number on a card, which is normal-text weight and takes the 4.5 bar.
    const accents = <String, Color>{
      'accentPrimary': AppColors.accentPrimary,
      'accentSuccess': AppColors.accentSuccess,
      'accentSecondary': AppColors.accentSecondary,
      'danger': AppColors.danger,
      'warning': AppColors.warning,
      'plyo': AppColors.plyo,
      'warmup': AppColors.warmup,
    };

    for (final accent in accents.entries) {
      for (final surface in surfaces.entries) {
        test('${accent.key} on ${surface.key}', () {
          final ratio = _contrast(accent.value, surface.value);
          expect(
            ratio,
            greaterThanOrEqualTo(aaNormalText),
            reason:
                '${accent.key} ${_hex(accent.value)} on ${surface.key} is '
                '${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    }
  });

  group('the FILL pairings, which the old oracle could not see', () {
    // A filled button is a label ON the accent, not the accent on a surface.
    // This is the inverse of every case above and it was uncovered until the
    // primary button existed.
    const label = AppColors.surfacePage;
    const fills = <String, Color>{
      'accentPrimary': AppColors.accentPrimary,
      'accentSuccess': AppColors.accentSuccess,
      'accentSecondary': AppColors.accentSecondary,
    };

    for (final fill in fills.entries) {
      test('surfacePage label on a ${fill.key} fill', () {
        final ratio = _contrast(label, fill.value);
        expect(
          ratio,
          greaterThanOrEqualTo(aaNormalText),
          reason:
              'a ${fill.key} button needs a legible label; '
              '${ratio.toStringAsFixed(2)}:1',
        );
      });
    }

    test('white is NOT a legible label on these fills', () {
      // The reason the label is a dark surface token rather than white. All
      // three accents are light, so white-on-accent is the instinctive choice
      // and the wrong one — measured at 3.29, 1.18 and 1.81. Asserted so the
      // instinct has to argue with a number.
      for (final fill in [
        AppColors.accentPrimary,
        AppColors.accentSuccess,
        AppColors.accentSecondary,
      ]) {
        expect(
          _contrast(const Color(0xFFFFFFFF), fill),
          lessThan(aaNormalText),
        );
      }
    });
  });

  group('the palette is single-theme, and that is deliberate', () {
    test('text is never pure white', () {
      // The tell of a default dark theme rather than a designed one.
      expect(AppColors.textPrimary, isNot(const Color(0xFFFFFFFF)));
    });

    test('the surfaces are a real ramp, darkest first', () {
      final page = _luminance(AppColors.surfacePage);
      final card = _luminance(AppColors.surfaceCard);
      final control = _luminance(AppColors.surfaceControl);
      expect(page, lessThan(card));
      expect(card, lessThan(control));
    });

    test('the run markers are the success and secondary accents', () {
      // Pinned so the map and the app cannot drift into two greens.
      expect(AppColors.runStartMarker, AppColors.accentSuccess);
      expect(AppColors.runFinishMarker, AppColors.accentSecondary);
    });

    test('the track line IS the primary accent now', () {
      // The inverse of what this file used to assert. Orange existed because
      // the route had to hold against a near-white AND a near-black basemap;
      // there is one dark ground now, so the constraint is gone and the route
      // wears the app's own colour. See AppColors.trackLine for the numbers.
      expect(AppColors.trackLine, AppColors.accentPrimary);
    });

    test('the casing stays dark, because the one ground is dark', () {
      // Counterintuitive and load-bearing: on a dark map the casing does
      // nothing, and it is kept because the ROADS are light. Core and casing
      // cover complementary halves of the ground range.
      expect(_luminance(AppColors.trackLineCasing), lessThan(0.05));
    });

    test('the raw-fix cloud is no longer derived from the accent', () {
      // Deliberately broken derivation: the accent is the same magenta as the
      // route now, and a magenta cloud under a magenta line erases the one
      // thing the overlay exists to show.
      expect(
        AppColors.trackRawFix.r,
        isNot(closeTo(AppColors.trackLine.r, 0.05)),
      );
      expect(AppColors.trackRawFix.a, lessThan(1));
    });

    test('the cloud is distinguishable from the finish marker', () {
      // Both are in the cyan family, and the overlay is read while the finish
      // marker is on screen.
      expect(
        _contrast(
          AppColors.trackRawFix.withValues(alpha: 1),
          AppColors.runFinishMarker,
        ),
        greaterThanOrEqualTo(aaLargeText),
      );
    });
  });
}

/// Composite a translucent colour onto an opaque ground.
Color _over(Color fg, Color bg) {
  double mix(double f, double b) => f * fg.a + b * (1 - fg.a);
  return Color.from(
    alpha: 1,
    red: mix(fg.r, bg.r),
    green: mix(fg.g, bg.g),
    blue: mix(fg.b, bg.b),
  );
}

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color fg, Color bg) {
  final a = _luminance(_over(fg, bg));
  final b = _luminance(bg);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
