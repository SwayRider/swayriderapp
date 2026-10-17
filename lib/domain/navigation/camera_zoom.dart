/// Map zoom for the navigation camera, in fixed steps.
///
/// While cruising the camera sits at one of three zoom levels chosen by
/// speed band (further out the faster the rider goes), and close to a
/// maneuver it steps in to [turnZoom]. Because the zoom only changes when a
/// threshold is crossed, the map stays still while the speed wobbles; the
/// screen eases between levels.
///
/// The speed is averaged over a few fixes and each band edge has a margin
/// (hysteresis), so a speed hovering around an edge doesn't flip the zoom
/// back and forth.
class CameraZoom {
  static const slowZoom = 16.5; // town
  static const mediumZoom = 15.5; // country road
  static const fastZoom = 14.5; // motorway
  static const turnZoom = 17.5;

  /// Speeds (km/h) at which the zoom steps out...
  static const _upEdgesKmh = [50.0, 95.0];

  /// ...and (lower, so there is a margin) at which it steps back in.
  static const _downEdgesKmh = [40.0, 85.0];

  static const _bandZooms = [slowZoom, mediumZoom, fastZoom];

  /// Zoom in on a maneuver once it is this close.
  static const turnZoomDistanceMeters = 300.0;

  /// Weight of the newest fix in the averaged speed.
  static const _speedSmoothing = 0.3;

  int _band = 0;
  double? _speedMps;

  /// Zoom level for the latest fix: [speedMps] is the ground speed and
  /// [distanceToManeuverMeters] the distance to the next maneuver (`null` =
  /// none / arrived). Call once per fix.
  double update({
    required double speedMps,
    required double? distanceToManeuverMeters,
  }) {
    final previous = _speedMps;
    final speed = previous == null
        ? speedMps
        : previous + (speedMps - previous) * _speedSmoothing;
    _speedMps = speed;
    final kmh = speed * 3.6;

    while (_band < _upEdgesKmh.length && kmh > _upEdgesKmh[_band]) {
      _band++;
    }
    while (_band > 0 && kmh < _downEdgesKmh[_band - 1]) {
      _band--;
    }

    final distance = distanceToManeuverMeters;
    if (distance != null && distance <= turnZoomDistanceMeters) {
      return turnZoom;
    }
    return _bandZooms[_band];
  }
}
