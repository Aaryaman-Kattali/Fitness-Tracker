/// 8pt spacing scale.
///
/// Every gap, pad and inset in the app comes from here. [xxs] and [xs] are the
/// half-steps that iOS itself uses for tight label stacks; everything else is a
/// multiple of 8.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  /// Standard horizontal screen margin.
  static const double gutter = 16;

  /// Corner radius for inset grouped cards.
  static const double cardRadius = 12;

  /// Corner radius for controls sitting inside a card.
  static const double controlRadius = 8;

  /// Minimum tap target. Apple specifies 44pt; gym controls use more.
  static const double minTapTarget = 44;

  /// Tap target for the weight and rep steppers, sized to be hit reliably
  /// one-handed while standing at a machine.
  static const double stepperTapTarget = 60;

  /// Height of a modal wheel picker sheet, matching iOS's own.
  static const double pickerSheetHeight = 260;

  /// Outer diameter of the steps ring on the Today screen.
  static const double ringDiameter = 92;

  /// Ring stroke. Thick enough to read at a glance without the hole in the
  /// middle getting too small for the step count to sit in it.
  static const double ringStroke = 10;

  /// The stats sheet over a full-bleed map, as a fraction of screen height.
  ///
  /// Collapsed shows the grabber and one summary line — distance, time, pace —
  /// which is the comparison the screen exists to support, so it must be
  /// readable without dragging anything. Expanded stops short of the top: a
  /// sheet that covers the map entirely has become a page, and the map is the
  /// reason this screen is laid out this way.
  static const double sheetCollapsedFraction = 0.22;
  static const double sheetExpandedFraction = 0.85;

  /// The sheet's top corners and its drag handle.
  static const double sheetRadius = 20;
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 5;

  /// Stroke of the recorded route, and of the casing beneath it.
  static const double trackStroke = 4;
  static const double trackCasingStroke = 7;

  /// Radius of one raw fix in the debug overlay. Small on purpose: at 1 Hz a
  /// walk puts one every metre or two, and anything larger merges into a band.
  static const double trackRawFixRadius = 2;

  /// The hairline around one raw fix. See `AppColors.trackRawFixBorder` for
  /// why the dot needs one at all.
  ///
  /// **2 because only half of it survives.** flutter_map draws the border of a
  /// TRANSLUCENT circle as a stroke centred on the fill's own radius and then
  /// paints the disc over it (`circle_layer/painter.dart`), so the inner half
  /// ends up under 0.6-alpha accent and only the outer half stays opaque. At 1
  /// that opaque ring is half a logical pixel, which antialiases to roughly
  /// half coverage and gives back a fraction of the contrast it was added for.
  /// 2 buys a full logical pixel of opaque ring.
  ///
  /// The fill radius is deliberately unchanged: the ring grows the dot's
  /// footprint from 2 to 3, but what merges into a band at 1 Hz is the FILL,
  /// and an outline makes overlapping dots more separable rather than less.
  static const double trackRawFixBorder = 2;

  /// The start and finish markers: one 28 px donut each, identical but for
  /// their colour.
  ///
  /// Three concentric discs, outside in: a dark ring [trackMarkerSize] across,
  /// the coloured band, and a dark core [trackMarkerCore] across. The band is
  /// what is left between them — 5 px — and it is the only part that carries a
  /// colour, which is why the pair still separates for a reader who cannot
  /// tell the two colours apart: a ring on a dark ground is a shape before it
  /// is a hue.
  ///
  /// **The asymmetric pair this replaced is described in
  /// `AppColors.runStartMarker`, and so is the case it existed for.** The
  /// coincident-loop case is now handled where it happens, by
  /// [runMarkerCoincidentM], instead of by making the finish permanently a
  /// thin ring.
  static const double trackMarkerSize = 28;
  static const double trackMarkerCore = 14;
  static const double trackMarkerRing = 2;

  /// How close the start and finish have to be before one marker is drawn for
  /// both.
  ///
  /// Metres, not pixels, because the question is about the route rather than
  /// about the camera: whether a run ended where it began does not change when
  /// the map is pinched.
  ///
  /// **35 m, and it is set by measurement rather than by what a doorway is
  /// worth.** The same 1610 m loop closes to 11.1 m on 23 Aug and 31.8 m on
  /// 24 Aug. At the 15 m this started at, one of those two walks rendered as
  /// a loop and the other did not — one route, one receiver, two afternoons,
  /// two different pictures — which is the worst available outcome, because
  /// it makes the marker report the closing error instead of the route. 35 m
  /// covers the measured spread and is still under the shortest gap a
  /// deliberate out-and-back leaves; `run_map_test` pins both ends of that.
  static const double runMarkerCoincidentM = 35;

  /// The live position puck. Larger than the start dot on purpose — while a
  /// run is recording it is the one thing on the map worth finding at a
  /// glance, held at arm's length, moving.
  static const double trackPositionRadius = 9;
  static const double trackPositionBorder = 3;

  /// The recentre control: a circular button in the map's bottom corner.
  static const double mapButtonSize = 40;

  /// Padding between the track and the edge of the map when the camera is
  /// fitted to it, so the polyline never touches the frame.
  static const double mapFitPadding = 32;

  /// Zoom for a map with a position but no track yet — before Start, and
  /// during the seconds the pipeline spends discarding the opening fixes.
  ///
  /// There is nothing to fit a camera to in that state, so this is a chosen
  /// framing rather than a derived one: street level, close enough to see
  /// which side of the road the puck is on, wide enough to recognise where you
  /// are standing. Once there are two points [mapFitPadding] takes over and
  /// this is never used again for that run.
  static const double mapLocatingZoom = 16;

  /// Blur behind a card floating on the map.
  ///
  /// The cards are translucent so the map keeps running underneath them, which
  /// on a basemap dense with roads and labels leaves numerals competing with
  /// whatever they happen to be over. Blurring the ground rather than making
  /// the card more opaque keeps the map visible AND the numbers readable; it
  /// is the same trade iOS makes for a nav bar over content.
  static const double mapOverlayBlur = 20;

  /// The Start / Finish control: one large circle, low on the screen.
  ///
  /// Sized well past [minTapTarget] on purpose. It is pressed with a thumb, at
  /// arm's length, by someone who has just been running, and it is the only
  /// control on the screen that has to be hit first time.
  static const double runPrimaryButtonSize = 88;
}
