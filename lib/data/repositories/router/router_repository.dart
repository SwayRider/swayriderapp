import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../domain/models/route/route_plan.dart';
import '../../../utils/result.dart';

/// Computes a route through an ordered list of points.
abstract class RouterRepository {
  /// Returns the route (path geometry and maneuvers) through [points]
  /// (ordered: first = start, last = end). [language] selects the language
  /// of the verbal instructions (see `routeLanguageFor`).
  ///
  /// When [isRoundTrip] is set, the returned path closes back into a loop
  /// at the start point.
  Future<Result<RoutePlan>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
    String language = 'en-US',
  });
}
