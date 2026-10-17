import 'dart:math' as math;

/// Spoken form of [meters] for TTS prompts, in the route's [language]
/// (`nl-NL` or anything else = English). Rounded so it sounds natural:
/// nearest 50 m below 1 km, 0.5 km steps up to 10 km, whole km above.
String spokenDistance(double meters, String language) {
  final dutch = language.startsWith('nl');
  if (meters < 1000) {
    final rounded = math.max(50, (meters / 50).round() * 50);
    if (rounded >= 1000) return '1 kilometer';
    return dutch ? '$rounded meter' : '$rounded meters';
  }
  final km = meters < 10000
      ? (meters / 500).round() / 2
      : (meters / 1000).roundToDouble();
  final text = km == km.roundToDouble()
      ? km.round().toString()
      : km.toStringAsFixed(1);
  final localized = dutch ? text.replaceAll('.', ',') : text;
  return '$localized kilometer';
}

/// "In 500 meters, " / "Over 500 meter, " prefix for an advance alert.
String inDistancePrefix(double meters, String language) {
  final lead = language.startsWith('nl') ? 'Over' : 'In';
  return '$lead ${spokenDistance(meters, language)}, ';
}
