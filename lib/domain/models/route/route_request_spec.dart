import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

/// What a route was requested with, kept on the [RoutePlan] so a way back
/// onto it can be asked for later: the ordered points (first = start, then
/// via points, last = end), and whether the route closes into a loop.
class RouteRequestSpec {
  const RouteRequestSpec({
    required this.points,
    this.isRoundTrip = false,
    this.language = 'en-US',
  });

  final List<LatLng> points;
  final bool isRoundTrip;
  final String language;

  /// The stops after the start, in order; for a round trip the start comes
  /// again as the final stop.
  List<LatLng> get stops => [...points.skip(1), if (isRoundTrip) points.first];
}
