/// Formats a weight in kilograms without trailing zeros: 60, 57.5, 2.25.
String formatKg(double? weightKg) {
  if (weightKg == null) return '—';
  final text = weightKg.toStringAsFixed(2);
  final trimmed = text.contains('.')
      ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : text;
  return trimmed;
}

/// "60 kg", or "BW" when the exercise carries no load.
String formatLoad(double? weightKg) =>
    weightKg == null ? 'BW' : '${formatKg(weightKg)} kg';

/// Formats a duration as m:ss, for the rest timer.
String formatClock(Duration duration) {
  final total = duration.inSeconds.clamp(0, 59 * 60 + 59);
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Formats a session length as "48 min", or "1 h 12 min" past the hour.
String formatSessionLength(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${minutes % 60} min';
}
