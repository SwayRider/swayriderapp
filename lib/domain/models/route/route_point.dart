import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

/// A point committed to the in-progress route. Role (start / waypoint /
/// destination) is derived from position in `HomeViewModel.routePoints`,
/// not stored here.
class RoutePoint {
  const RoutePoint({
    required this.label,
    required this.point,
    this.isCurrentLocation = false,
  });

  /// Ignored by the UI when [isCurrentLocation] is true.
  final String label;
  final LatLng point;

  /// True when auto-inserted from the device's current location as the
  /// implicit start point (see `HomeViewModel.setAsDestination`).
  final bool isCurrentLocation;
}

enum RouteRole { start, waypoint, destination }

/// index 0 is "start" (including the degenerate single-item list); the
/// last index is "destination" once length >= 2, unless [isRoundTrip] is
/// set — the start point doubles as the final destination in that case, so
/// the last index is a waypoint too, like everything in between. Shared by
/// marker coloring, waypoint-removal eligibility, and the reorder sheet's
/// role labels/icons so this branching lives in exactly one place.
RouteRole routeRoleAt(int index, int length, {bool isRoundTrip = false}) {
  if (index == 0) return RouteRole.start;
  if (index == length - 1 && !isRoundTrip) return RouteRole.destination;
  return RouteRole.waypoint;
}
