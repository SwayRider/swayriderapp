import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../domain/models/route/rejoin.dart';
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

  /// Asks for the way back onto a route a rider left: the best connector to
  /// one of [request]'s rejoin points, or a fresh route when rejoining is
  /// clearly worse (see [RejoinResult]).
  Future<Result<RejoinResult>> rejoin(RejoinRequest request);
}
