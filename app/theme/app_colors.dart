import 'package:flutter/cupertino.dart';

/// The app's palette. One role per colour, single theme, dark.
///
/// **Tokens are named by ROLE and never by hue.** `accentPrimary`, not
/// `magenta`. A hue-named token is a promise that the hue will not change, and
/// this file has now changed hue twice — iOS system blue to midnight green to
/// magenta — while the roles stayed exactly where they were. Renaming 170 call
/// sites each time is the cost of having named them wrong.
///
/// **Single theme, and that is the identity rather than a shortcut.** There is
/// no light variant and `CupertinoDynamicColor` is deliberately gone from
/// these tokens: a palette decided by a phone's appearance setting is not a
/// palette, it is two. The map reached this conclusion first (U-3, 8 Sep 2026)
/// and the app has now followed it. The consequence is that nothing here needs
/// resolving against a `BuildContext`, which is why `.resolveFrom(context)`
/// disappeared from every call site in the same change.
///
/// Two rules that keep this considered rather than loud. They are enforced by
/// review rather than by the type system, so they are written down here:
///
/// - **Labels stay muted; VALUES get colour.** A screen where the word
///   "Protein" is as loud as the number beside it has spent its colour budget
///   on the half nobody reads twice.
/// - **One magenta element per screen region.** Two primary buttons in view
///   and neither of them reads as primary.
///
/// Never pure white for text. `textPrimary` is #F2F3F7, and the 13 points it
/// gives up are the difference between a designed dark theme and a default
/// one.
///
/// Every pairing in here is measured by `app_colors_contrast_test.dart`,
/// including the FILL pairings — text ON a filled accent — which the oracle
/// was blind to until the primary button made them load-bearing.
abstract final class AppColors {
  // ---------- Surfaces ----------

  /// The page behind everything.
  static const surfacePage = Color(0xFF0F1014);

  /// A card sitting on [surfacePage].
  static const surfaceCard = Color(0xFF191B21);

  /// Controls, dividers, and a card nested one level deeper. One step above
  /// [surfaceCard] and the strictest ground in the app for text — every
  /// contrast floor in the oracle is set here rather than on the page.
  static const surfaceControl = Color(0xFF23252D);

  // ---------- Text ----------

  static const textPrimary = Color(0xFFF2F3F7);
  static const textSecondary = Color(0xFF9DA1AC);

  /// The muted stop, for labels under values.
  ///
  /// **#8A8E9B rather than the #6E7280 originally specified, and the reason is
  /// AA.** #6E7280 measured 3.97 / 3.59 / 3.19 against the three surfaces —
  /// short of 4.5:1 on all of them, and labels render at `caption2` 11pt where
  /// the large-text 3:1 allowance does not apply. A muted stop that cannot be
  /// used at label size is not a muted label stop.
  ///
  /// The cost is a compressed hierarchy: this sits only 1.27:1 from
  /// [textSecondary]. **Separate them with weight or size, never by darkening
  /// this back down** — 500-weight secondary against 400-weight label buys the
  /// hierarchy without spending contrast.
  static const textLabel = Color(0xFF8A8E9B);

  // ---------- Accents, one role each ----------

  /// Anything tappable, or the thing being followed: the route line, primary
  /// buttons, the active tab, progress fills.
  ///
  /// Carried on the map as well as in the app — see `trackLine`, which is this
  /// token rather than a second magenta.
  static const accentPrimary = Color(0xFFFF3D9A);

  /// Achievement and timers: steps toward a goal, the rest timer, the
  /// last-session marker, the run start marker.
  static const accentSuccess = Color(0xFFC6FF33);

  /// Secondary metrics — protein and the rest of nutrition — and the run
  /// finish marker.
  static const accentSecondary = Color(0xFF22D3EE);

  // ---------- Roles the system above does not cover ----------
  //
  // Kept rather than merged into the three accents, because each encodes a
  // distinction the app actually makes and a palette that cannot say "this
  // failed" is missing a role rather than being disciplined. Converted to
  // single-theme like everything else, and measured by the oracle.

  /// Destructive and error states.
  static const danger = Color(0xFFFF6B5E);

  /// A caution that is not an error — a permission that will degrade a
  /// feature rather than break it.
  static const warning = Color(0xFFFFB340);

  /// The plyometric block, kept distinct from lifting.
  static const plyo = Color(0xFFC98BFF);

  /// The warm-up block.
  static const warmup = Color(0xFF8B93FF);

  /// The navigation bar on a screen whose content runs underneath it.
  ///
  /// Deliberately NOT opaque. `CupertinoPageScaffold` shifts its child below
  /// an opaque bar and lets it draw behind a translucent one, keying entirely
  /// off this alpha — so a full-bleed map needs a bar that is see-through.
  static const barOverContent = Color(0xB30F1014);

  // ---------- The map overlay ----------

  /// The recorded route.
  ///
  /// **[accentPrimary], and the "theme-invariant orange" reasoning that used
  /// to live here is superseded rather than deleted.** #FF9500 was chosen
  /// because it was the rare hue holding against both a near-white and a
  /// near-black basemap, back when the map followed the system appearance.
  /// U-3 made the map single-theme and this change made the app single-theme,
  /// so the constraint that bought orange no longer exists — there is one
  /// ground now, and it is dark.
  ///
  /// Measured rather than assumed: magenta's worst ground is 3.09:1 (water)
  /// against orange's 3.10:1 (minor road), under the max(core, casing) rule.
  /// The swap costs nothing and buys the route the app's own primary colour.
  ///
  /// **#7D39EB was rejected, and it is recorded so it is not re-proposed.** It
  /// measures 1.77:1 at its worst ground against magenta's 3.09 — too dark
  /// against #14151B. That is the same value-not-hue error that rejected
  /// #FC3E57 (worst 2.34) when the ground was still light: a hue can look
  /// right in a swatch and still have nowhere to go in luminance.
  static const Color trackLine = accentPrimary;

  /// Casing under [trackLine], for contrast against whatever the tile happens
  /// to be.
  ///
  /// **Still dark, and it survived the basemap inversion by being
  /// complementary rather than by being re-tuned.** On a dark ground it
  /// composites to 1.06–1.68:1 and does nothing; on the light roads it reaches
  /// 3.10–8.45:1 and does everything. The route's core covers exactly the
  /// grounds the casing cannot, which is why the rule everywhere here is
  /// max(core, casing) rather than a floor on either alone.
  static const trackLineCasing = Color(0xCC1C1C1E);

  /// Where the run started, and where it ended. A matched pair of 28 px
  /// donuts, identical but for these two colours.
  ///
  /// **The pair was ASYMMETRIC until 8 Sep 2026, and the reason it was is
  /// worth keeping.** The finish was a thin ring and the start a filled dot
  /// drawn inside it, so that on a loop — where the two coordinates coincide —
  /// one marker could not hide the other. That case is real and it is the
  /// common route here, not an edge case.
  ///
  /// **What replaced it: the same asymmetry, but only when it is needed.** The
  /// price of solving the coincident case in the geometry was paying for it on
  /// every run that is not a loop, where a hairline ring next to a solid disc
  /// reads as an unfinished pair rather than as a start and a finish. So the
  /// coincidence is now detected — `AppSpacing.runMarkerCoincidentM` — and
  /// answered with a single donut split down the middle, start colour left,
  /// finish colour right. The overlapping case says "both, here"; every other
  /// case gets two markers that look like each other.
  ///
  /// **Neither colour is load-bearing on its own.** Simulated, the pair holds
  /// at ΔE2000 19–52 across deuteranopia, protanopia and tritanopia, and it
  /// would still separate at zero: the two markers of a loop are one marker,
  /// split, and the split is a shape.
  static const Color runStartMarker = accentSuccess;
  static const Color runFinishMarker = accentSecondary;

  /// The donut's outer ring and its core — the dark that holds a marker
  /// against whatever tile it lands on.
  ///
  /// [trackLineCasing] at full alpha, and the alpha is the whole difference.
  /// The casing is translucent because it sits under the route for its whole
  /// length and must not black out the map beneath it. A marker is two points
  /// on a run, it is meant to be found, and it may cover what it covers — so
  /// it gets the opaque version, and the core reads as a hole rather than as a
  /// dark tint of the colour underneath it.
  static const trackMarkerCasing = Color(0xFF1C1C1E);

  /// Where the runner is, while a run is being recorded. The ring stays white:
  /// it is what holds the puck against whatever the tile happens to be.
  static const Color trackPosition = accentSecondary;
  static const trackPositionBorder = Color(0xFFFFFFFF);

  /// Debug overlay: the raw accepted fixes, drawn under the smoothed line.
  ///
  /// **Deliberately NOT derived from any app accent any more, and that broken
  /// link is the point.** It used to read off the accent so the cloud and the
  /// app could not drift apart. The accent is now the same magenta as
  /// [trackLine], and a magenta cloud under a magenta route destroys the one
  /// thing this overlay exists to show — where the smoothed line leaves the
  /// measurements it came from. So it keeps the teal it has always rendered
  /// in, as its own value.
  ///
  /// It stays distinguishable from [runFinishMarker], which is also in the
  /// cyan family: 4.57:1 apart, which is a different colour rather than a
  /// darker one.
  static final Color trackRawFix = const Color(
    0xFF105666,
  ).withValues(alpha: _rawFixAlpha);

  /// The hairline around one raw fix, and the reason the cloud survives both
  /// water and a near-white road.
  ///
  /// **A translucent fill cannot be legible on an arbitrary ground**, and this
  /// was the one element on the map without an answer to that. The route has
  /// [trackLineCasing] and the puck has [trackPositionBorder] for the same
  /// reason; the cloud had nothing, so it composited 60% of the way toward
  /// whatever it sat on and vanished at 1.00:1 on water.
  ///
  /// **White is a measured compromise, NOT a default**, written out because
  /// the next reader will see white, assume nobody thought about it, and
  /// optimise it into a collision. Under the max(fill, border) rule white
  /// takes the worst ground to 2.20:1 and a sweep of every colour reaches no
  /// further: any border dark enough to improve on a mid-luminance road lands
  /// on the same tone as a footpath. A better number needs a different fill.
  static const Color trackRawFixBorder = trackPositionBorder;
}

/// What [AppColors.trackRawFix] fades its teal to. 0.6, the 0x99 the overlay
/// has always used — the alpha has never moved, only the hue around it.
const _rawFixAlpha = 0.6;
