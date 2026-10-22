import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

/// What the server needs to calculate a new route for a rider who left the
/// route they were following.
class RerouteRequest {
  const RerouteRequest({
    required this.from,
    required this.stops,
    this.heading,
    this.exclusions = const [],
    this.language = 'en-US',
  });

  /// The rider's position.
  final LatLng from;

  /// Direction of travel in degrees clockwise from north, or `null` when
  /// unknown (standing still). The new route prefers it.
  final int? heading;

  /// The stops still to visit: via points not yet passed, then the
  /// destination.
  final List<LatLng> stops;

  /// Areas to avoid (suspected closures): rings of points.
  final List<List<LatLng>> exclusions;

  final String language;
}
