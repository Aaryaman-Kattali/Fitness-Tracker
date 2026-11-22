import 'package:flutter/cupertino.dart';

/// The type ramp, rendered in Inter (an SF Pro substitute — the SF Pro licence
/// forbids use on non-Apple platforms).
///
/// Sizes and weights follow the iOS text styles this app uses. Colours are
/// deliberately omitted so they inherit from the surrounding [CupertinoTheme];
/// a widget that needs an explicit one calls `copyWith` at the call site.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  /// iOS Large Title — 34pt bold. Navigation bar titles when expanded.
  static const largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 41 / 34,
  );

  /// iOS Title 1 — 28pt. Section headline inside a screen.
  static const title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.36,
    height: 34 / 28,
  );

  /// iOS Title 2 — 22pt. The Cupertino picker and date-picker text style, set
  /// once in `app_theme.dart` — not called directly by any widget.
  static const title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.35,
    height: 28 / 22,
  );

  /// iOS Headline — 17pt semibold. Row titles, emphasised body.
  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 22 / 17,
  );

  /// iOS Body — 17pt regular. Default text.
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 22 / 17,
  );

  /// iOS Subhead — 15pt. Secondary row text.
  static const subhead = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 20 / 15,
  );

  /// iOS Footnote — 13pt. Captions, last-session numbers, hints.
  static const footnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 18 / 13,
  );

  /// Footnote at semibold, for the uppercase section headers above a group.
  static const footnoteEmphasis = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.08,
    height: 18 / 13,
  );

  /// iOS Caption 2 — 11pt. The smallest legible size, for text that has to be
  /// present without competing for attention: map attribution and nothing else
  /// so far.
  static const caption2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 13 / 11,
  );

  /// Large tabular figure display, for the rest timer and the stepper values.
  static const numeric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Medium tabular figure display, for inline weights and reps.
  static const numericSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 24 / 20,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
