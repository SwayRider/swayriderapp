import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import 'geo.dart';

/// Where a GPS fix lies relative to the route.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.snapped,
    required this.bearing,
    required this.alongMeters,
    required this.remainingMeters,
    required this.offRouteMeters,
  });

  /// The fix projected onto the route line.
  final LatLng snapped;

  /// Direction of the route a few meters ahead of [snapped].
  final double bearing;

  /// Distance travelled along the route.
  final double alongMeters;
  final double remainingMeters;

  /// Distance between the raw fix and the route line.
  final double offRouteMeters;
}

/// Tracks progress along a fixed route polyline.
///
/// The first fix is matched against the whole route; after that, fixes are
/// matched with a forward-only window starting at the last matched segment, so progress never jumps back and an out-and-back or looping
/// route can't snap to the "wrong" pass over the same road. When the rider
/// leaves the route the match simply stays where it was (there is no
/// re-routing yet).
class RouteProgress {
  RouteProgress(this.path) {
    cumulative = List<double>.filled(path.length, 0);
    for (var i = 1; i < path.length; i++) {
      cumulative[i] = cumulative[i - 1] + distanceMeters(path[i - 1], path[i]);
    }
  }

  final List<LatLng> path;

  /// Distance from the route start to each path point, in meters.
  late final List<double> cumulative;

  /// How far ahead of the last match a fix may be matched.
  static const searchAheadMeters = 800.0;

  /// A later segment must beat the current best by this much to win, which
  /// keeps ties (same road traversed twice) on the earlier pass.
  static const _hysteresisMeters = 3.0;

  /// Beyond this distance from the line the fix is not allowed to advance
  /// the match.
  static const maxMatchDistanceMeters = 150.0;

  /// Matches beyond the search window must be at least this close to the
  /// line (recovery after a GPS gap).
  static const recoverMatchDistanceMeters = 40.0;

  static const _lookAheadMeters = 30.0;

  int _segment = 0;
  bool _acquired = false;
  double _along = 0;

  double get totalMeters => cumulative.isEmpty ? 0 : cumulative.last;

  /// Point at [along] meters from the start (clamped to the route).
  LatLng pointAt(double along) {
    if (path.length < 2) return path.isEmpty ? const LatLng(0, 0) : path.first;
    final d = along.clamp(0.0, totalMeters).toDouble();
    var lo = 0;
    var hi = path.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (cumulative[mid] <= d) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final len = cumulative[lo + 1] - cumulative[lo];
    final t = len <= 0 ? 0.0 : (d - cumulative[lo]) / len;
    return lerpLatLng(path[lo], path[lo + 1], t);
  }

  ProgressSnapshot update(LatLng position) {
    if (path.length < 2) {
      return ProgressSnapshot(
        snapped: position,
        bearing: 0,
        alongMeters: 0,
        remainingMeters: 0,
        offRouteMeters: 0,
      );
    }

    var bestSegment = _segment;
    var bestDistance = double.infinity;
    var bestT = 0.0;
    var windowEnd = path.length - 1;
    for (var i = _segment; i < path.length - 1; i++) {
      if (_acquired &&
          cumulative[i] - cumulative[_segment] > searchAheadMeters) {
        windowEnd = i;
        break;
      }
      final (distance, t) = _project(position, path[i], path[i + 1]);
      if (distance < bestDistance - _hysteresisMeters) {
        bestDistance = distance;
        bestSegment = i;
        bestT = t;
      }
    }

    // Nothing close inside the window: the rider may have come out of a GPS
    // gap (tunnel) or taken a shortcut. Look at the rest of the route, but
    // only accept a match that is clearly on the line.
    if (bestDistance > recoverMatchDistanceMeters) {
      for (var i = windowEnd; i < path.length - 1; i++) {
        final (distance, t) = _project(position, path[i], path[i + 1]);
        if (distance <= recoverMatchDistanceMeters &&
            distance < bestDistance - _hysteresisMeters) {
          bestDistance = distance;
          bestSegment = i;
          bestT = t;
        }
      }
    }

    if (bestDistance <= maxMatchDistanceMeters) {
      _acquired = true;
      final segLen = cumulative[bestSegment + 1] - cumulative[bestSegment];
      final along = cumulative[bestSegment] + bestT * segLen;
      if (along > _along) {
        _along = along;
        _segment = bestSegment;
      }
    }

    final snapped = pointAt(_along);
    final ahead = pointAt(math.min(_along + _lookAheadMeters, totalMeters));
    final bearing = distanceMeters(snapped, ahead) < 1
        ? bearingDegrees(path[_segment], path[_segment + 1])
        : bearingDegrees(snapped, ahead);

    return ProgressSnapshot(
      snapped: snapped,
      bearing: bearing,
      alongMeters: _along,
      remainingMeters: math.max(0, totalMeters - _along),
      offRouteMeters: bestDistance.isFinite
          ? bestDistance
          : distanceMeters(position, snapped),
    );
  }

  /// Distance from [p] to segment [a]-[b] in meters and the position `t`
  /// (0..1) of the closest point on it, using a local flat projection.
  static (double, double) _project(LatLng p, LatLng a, LatLng b) {
    final cosLat = math.cos(a.latitude * math.pi / 180);
    const mPerDegLat = 110574.0;
    final mPerDegLon = 111320.0 * cosLat;
    final ax = 0.0, ay = 0.0;
    final bx = (b.longitude - a.longitude) * mPerDegLon;
    final by = (b.latitude - a.latitude) * mPerDegLat;
    final px = (p.longitude - a.longitude) * mPerDegLon;
    final py = (p.latitude - a.latitude) * mPerDegLat;
    final len2 = bx * bx + by * by;
    final t = len2 == 0
        ? 0.0
        : (((px - ax) * bx + (py - ay) * by) / len2).clamp(0.0, 1.0);
    final cx = ax + t * bx;
    final cy = ay + t * by;
    final dx = px - cx;
    final dy = py - cy;
    return (math.sqrt(dx * dx + dy * dy), t);
  }
}
