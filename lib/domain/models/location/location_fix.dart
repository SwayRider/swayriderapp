import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

/// One GPS fix.
class LocationFix {
  const LocationFix({
    required this.position,
    this.courseDegrees,
    this.speedMps = 0,
    this.accuracyMeters,
  });

  final LatLng position;

  /// Direction of travel in degrees clockwise from north, or `null` when
  /// the platform doesn't know it (e.g. while standing still).
  final double? courseDegrees;

  /// Ground speed in meters per second (never negative).
  final double speedMps;

  final double? accuracyMeters;
}
