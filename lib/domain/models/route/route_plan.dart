import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import 'route_maneuver.dart';

/// A calculated route: the merged path geometry of all legs plus the
/// turn-by-turn maneuvers needed for navigation.
///
/// [maneuvers] reference [path] through `beginShapeIndex` /
/// `endShapeIndex` (already offset when several legs were merged).
class RoutePlan {
  const RoutePlan({
    required this.path,
    this.maneuvers = const [],
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.language = 'en-US',
  });

  /// Path-only plan, e.g. for callers that have no maneuver data.
  const RoutePlan.pathOnly(this.path)
    : maneuvers = const [],
      distanceMeters = 0,
      durationSeconds = 0,
      language = 'en-US';

  final List<LatLng> path;
  final List<RouteManeuver> maneuvers;
  final double distanceMeters;
  final double durationSeconds;

  /// Valhalla language the verbal instructions are written in.
  final String language;

  bool get canNavigate => path.length >= 2 && maneuvers.isNotEmpty;
}

/// Maps an app language code (`nl`, `en`, ...) to the Valhalla language tag
/// the router understands. Unsupported languages fall back to English.
String routeLanguageFor(String languageCode) =>
    languageCode == 'nl' ? 'nl-NL' : 'en-US';
