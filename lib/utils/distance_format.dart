/// Display text for a distance, e.g. `350 m`, `1.2 km` (`1,2 km` for Dutch).
///
/// Below 1 km it rounds to 10 m (50 m steps above 200 m would feel jumpy on
/// a counting-down header, so only 10 m steps are used); from 1 km on it
/// shows one decimal below 10 km and whole kilometers above.
String formatDistance(double meters, {String languageCode = 'en'}) {
  if (meters < 1000) {
    final rounded = meters < 10 ? 0 : (meters / 10).round() * 10;
    return rounded >= 1000 ? '1 km' : '$rounded m';
  }
  final km = meters / 1000;
  final text = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
  return '${languageCode == 'nl' ? text.replaceAll('.', ',') : text} km';
}
