import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

const _earthRadiusMeters = 6371008.8;

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

/// Great-circle distance between [a] and [b] in meters.
double distanceMeters(LatLng a, LatLng b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

/// Initial bearing from [a] to [b] in degrees clockwise from north, 0..360.
double bearingDegrees(LatLng a, LatLng b) {
  final lat1 = _rad(a.latitude);
  final lat2 = _rad(b.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (_deg(math.atan2(y, x)) + 360) % 360;
}

/// Linear interpolation between two nearby coordinates.
LatLng lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
  a.latitude + (b.latitude - a.latitude) * t,
  a.longitude + (b.longitude - a.longitude) * t,
);

/// The point [meters] away from [from] in direction [bearing] (degrees
/// clockwise from north).
LatLng destinationPoint(LatLng from, double bearing, double meters) {
  final angular = meters / _earthRadiusMeters;
  final theta = _rad(bearing);
  final lat1 = _rad(from.latitude);
  final lon1 = _rad(from.longitude);
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angular) +
        math.cos(lat1) * math.sin(angular) * math.cos(theta),
  );
  final lon2 =
      lon1 +
      math.atan2(
        math.sin(theta) * math.sin(angular) * math.cos(lat1),
        math.cos(angular) - math.sin(lat1) * math.sin(lat2),
      );
  return LatLng(_deg(lat2), _deg(lon2));
}

/// Signed shortest rotation from [from] to [to] in degrees, in -180..180.
double shortestAngleDelta(double from, double to) =>
    ((to - from + 540) % 360) - 180;

/// Whether [points] curve clockwise (`true`) or counter-clockwise (`false`):
/// the sum of the signed heading changes along the path. `null` when the
/// path is too short or bends less than [minDegrees] net, so it says nothing.
///
/// Used on the shape of a roundabout: traffic circulates counter-clockwise
/// where people drive on the right and clockwise where they drive on the
/// left.
bool? isClockwise(List<LatLng> points, {double minDegrees = 10}) {
  if (points.length < 3) return null;
  var total = 0.0;
  for (var i = 1; i < points.length - 1; i++) {
    total += shortestAngleDelta(
      bearingDegrees(points[i - 1], points[i]),
      bearingDegrees(points[i], points[i + 1]),
    );
  }
  if (total.abs() < minDegrees) return null;
  return total > 0;
}

/// A thin polygon around [centerline]: every point moved [halfWidthMeters] to
/// the left and to the right of the direction of travel, left side forward
/// and right side back. At most `2 x centerline.length` points; the ring is
/// open (the last point is not repeated).
List<LatLng> corridorPolygon(List<LatLng> centerline, double halfWidthMeters) {
  if (centerline.length < 2) return const [];
  final left = <LatLng>[];
  final right = <LatLng>[];
  for (var i = 0; i < centerline.length; i++) {
    final from = centerline[math.max(0, i - 1)];
    final to = centerline[math.min(centerline.length - 1, i + 1)];
    final bearing = bearingDegrees(from, to);
    left.add(destinationPoint(centerline[i], bearing - 90, halfWidthMeters));
    right.add(destinationPoint(centerline[i], bearing + 90, halfWidthMeters));
  }
  return [...left, ...right.reversed];
}
