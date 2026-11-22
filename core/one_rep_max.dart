/// Estimated one-rep max via the Epley formula: `w × (1 + reps / 30)`.
///
/// Returns null when the set carries no usable load — bodyweight, band and
/// plyometric work has a null [weightKg], and a null propagates so those
/// exercises are excluded from 1RM trends rather than plotted at zero.
///
/// A single rep is returned unchanged: Epley's multiplier is 1.0333 at one
/// rep, which would claim a 3% heavier max than the lift that actually
/// happened. Accuracy degrades above roughly 12 reps in any case; the value is
/// a trend line, not a test result.
double? epleyOneRepMax({required double? weightKg, required int reps}) {
  if (weightKg == null || weightKg <= 0 || reps <= 0) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

/// The best estimated 1RM across a group of sets, or null if none qualify.
double? bestOneRepMax(Iterable<({double? weightKg, int reps})> sets) {
  double? best;
  for (final set in sets) {
    final estimate = epleyOneRepMax(weightKg: set.weightKg, reps: set.reps);
    if (estimate != null && (best == null || estimate > best)) {
      best = estimate;
    }
  }
  return best;
}
