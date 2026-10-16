import 'dart:math' as math;

/// Map zoom for the navigation camera.
///
/// While cruising the camera sits far out, further the faster the rider
/// goes, so the road ahead covers a similar number of seconds at any speed.
/// Close to a maneuver it zooms in so the junction is readable, and goes
/// back out once the turn is behind.
abstract final class CameraZoom {
  /// Cruise zoom at or below [slowSpeedMps] (town).
  static const cruiseZoomSlow = 16.5;

  /// Cruise zoom at or above [fastSpeedMps] (motorway).
  static const cruiseZoomFast = 14.5;

  static const slowSpeedMps = 8.0; // ~30 km/h
  static const fastSpeedMps = 30.0; // ~108 km/h

  /// Zoom reached right at a maneuver.
  static const turnZoom = 17.5;

  /// Zooming in starts this far before the maneuver...
  static const zoomInStartMeters = 400.0;

  /// ...and is complete this far before it.
  static const zoomInDoneMeters = 100.0;

  /// The zoom to use at [speedMps] with the next maneuver
  /// [distanceToManeuverMeters] ahead (`null` = none / unknown).
  static double target({
    required double speedMps,
    required double? distanceToManeuverMeters,
  }) {
    final cruise = cruiseZoom(speedMps);
    final distance = distanceToManeuverMeters;
    if (distance == null) return cruise;
    // 0 far away, 1 close; smoothstep so the zoom eases in and out.
    final t =
        ((zoomInStartMeters - distance) /
                (zoomInStartMeters - zoomInDoneMeters))
            .clamp(0.0, 1.0);
    final weight = t * t * (3 - 2 * t);
    return cruise + (math.max(turnZoom, cruise) - cruise) * weight;
  }

  /// The cruise zoom at [speedMps].
  static double cruiseZoom(double speedMps) {
    final t = ((speedMps - slowSpeedMps) / (fastSpeedMps - slowSpeedMps)).clamp(
      0.0,
      1.0,
    );
    return cruiseZoomSlow + (cruiseZoomFast - cruiseZoomSlow) * t;
  }
}
