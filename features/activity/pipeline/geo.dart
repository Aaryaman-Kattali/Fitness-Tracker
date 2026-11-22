import 'dart:math' as math;

/// Mean Earth radius (IUGG), metres.
///
/// Every distance in the pipeline is spherical. Over a 5 km run the difference
/// against a proper ellipsoidal (Vincenty) distance is well under a metre,
/// which is two orders of magnitude below GPS noise — the error that actually
/// dominates. Paying for an ellipsoid here would buy nothing measurable.
const earthRadiusM = 6371008.8;

/// Great-circle distance between two points, in metres.
double haversineMetres(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final phi1 = _radians(lat1);
  final phi2 = _radians(lat2);
  final dPhi = phi2 - phi1;
  final dLambda = _radians(lon2 - lon1);

  final a =
      math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(dLambda / 2) *
          math.sin(dLambda / 2);

  return 2 * earthRadiusM * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;
