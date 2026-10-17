import '../../../domain/models/map/map_style_mode.dart';

/// Colours of the route and the position dot on the map, as hex strings for
/// MapLibre. They are inverted on the dark map, so the route never blends in
/// with the orange motorways (light map: petrol route, orange dot) or with
/// the dark roads (dark map: orange route, petrol dot).
class RouteMapColors {
  const RouteMapColors._({
    required this.line,
    required this.casing,
    required this.dot,
  });

  /// `AppColors.deepPetrolBlue` on `AppColors.apexOrange`.
  static const _petrol = '#0F4C5C';
  static const _orange = '#FF7A00';

  static const _light = RouteMapColors._(
    line: _petrol,
    casing: '#FFFFFF',
    dot: _orange,
  );
  static const _dark = RouteMapColors._(
    line: _orange,
    casing: '#101010',
    dot: _petrol,
  );

  factory RouteMapColors.of(MapVariant variant) =>
      variant == MapVariant.dark ? _dark : _light;

  /// The route line and the thin edge drawn under it.
  final String line;
  final String casing;

  /// The position dot (its ring is white on both maps).
  final String dot;
}
