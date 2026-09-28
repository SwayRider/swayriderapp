import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../utils/result.dart';

/// Computes a route through an ordered list of points.
abstract class RouterRepository {
  /// Returns the route's path geometry through [points] (ordered: first =
  /// start, last = end).
  ///
  /// When [isRoundTrip] is set, the returned path closes back into a loop
  /// at the start point.
  Future<Result<List<LatLng>>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
  });
}
