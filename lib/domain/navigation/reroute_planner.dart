import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../models/location/location_fix.dart';
import '../models/route/reroute_request.dart';
import '../models/route/route_plan.dart';
import 'geo.dart';
import 'route_progress.dart';

/// What to ask the server when the rider has left the route.
class ReroutePlan {
  const ReroutePlan({required this.request, required this.corridor});

  final RerouteRequest request;

  /// The area of the old route that is suspected to be closed and was sent as
  /// an exclusion this time (empty when there was none).
  final List<LatLng> corridor;
}

/// Prepares the request for a new route when the rider has left the route:
/// the stops still to visit, the direction of travel, and the road just ahead
/// of where the rider left, which is avoided because leaving a route there
/// often means the road is closed.
class ReroutePlanner {
  const ReroutePlanner();

  /// The suspected closure runs from this far to this far (the default
  /// length) behind the point where the rider left the route.
  static const corridorStartMeters = 30.0;
  static const corridorLengthMeters = 370.0;
  static const _corridorHalfWidthMeters = 8.0;
  static const _corridorSampleMeters = 25.0;

  /// Direction of travel is only trusted from this speed on (8 km/h).
  static const _minHeadingSpeedMps = 8 / 3.6;

  /// A via point counts as passed this far behind the rider.
  static const _passedMarginMeters = 30.0;

  static const _viaMatchMeters = 40.0;

  /// Builds the request for a rider at [fix], whose progress along the route
  /// is [alongMeters] and who left it at [leftRouteAlongMeters] (`null` when
  /// the rider never was on the route). [corridorLength] is the length of
  /// the suspected closure, [earlierExclusions] closures of earlier reroutes
  /// that must stay avoided.
  ReroutePlan plan({
    required RoutePlan route,
    required RouteProgress progress,
    required LocationFix fix,
    required double alongMeters,
    double? leftRouteAlongMeters,
    double corridorLength = corridorLengthMeters,
    List<List<LatLng>> earlierExclusions = const [],
  }) {
    final total = progress.totalMeters;

    var corridor = const <LatLng>[];
    final left = leftRouteAlongMeters;
    if (left != null && left > 0) {
      final from = math.min(left + corridorStartMeters, total);
      final to = math.min(left + corridorStartMeters + corridorLength, total);
      if (to - from > 10) corridor = _corridor(progress, from, to);
    }

    final heading =
        fix.courseDegrees != null && fix.speedMps >= _minHeadingSpeedMps
        ? fix.courseDegrees!.round() % 360
        : null;

    return ReroutePlan(
      request: RerouteRequest(
        from: fix.position,
        heading: heading,
        stops: _remainingStops(route, progress, alongMeters),
        exclusions: [if (corridor.isNotEmpty) corridor, ...earlierExclusions],
        language: route.language,
      ),
      corridor: corridor,
    );
  }

  /// The stops still to visit: via points not yet passed, then the
  /// destination. Without a request on the plan only the end of the route.
  List<LatLng> _remainingStops(
    RoutePlan route,
    RouteProgress progress,
    double alongMeters,
  ) {
    final spec = route.request;
    if (spec == null || spec.stops.isEmpty) return [progress.path.last];
    final stops = spec.stops;
    final via = stops.sublist(0, stops.length - 1);
    final alongs = _viaAlongs(via, progress);
    return [
      for (var i = 0; i < via.length; i++)
        if (alongs[i] > alongMeters - _passedMarginMeters) via[i],
      stops.last,
    ];
  }

  /// Where each via point lies along the route, in order: every one is
  /// searched from the previous one on, so an out-and-back route does not
  /// match a via point on the way back.
  List<double> _viaAlongs(List<LatLng> via, RouteProgress progress) {
    final result = <double>[];
    var from = 0.0;
    for (final point in via) {
      final along = _alongOf(progress, point, from);
      result.add(along);
      from = along;
    }
    return result;
  }

  /// The along of the first stretch of the route (from [fromAlong] on) that
  /// passes within [_viaMatchMeters] of [point], else of the closest point.
  double _alongOf(RouteProgress progress, LatLng point, double fromAlong) {
    final path = progress.path;
    final cumulative = progress.cumulative;
    var bestAlong = fromAlong;
    var bestDistance = double.infinity;
    for (var i = 0; i < path.length - 1; i++) {
      if (cumulative[i + 1] < fromAlong) continue;
      final (distance, t) = _project(point, path[i], path[i + 1]);
      final along = cumulative[i] + t * (cumulative[i + 1] - cumulative[i]);
      if (along < fromAlong) continue;
      if (distance <= _viaMatchMeters) return along;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestAlong = along;
      }
    }
    return bestAlong;
  }

  static (double, double) _project(LatLng p, LatLng a, LatLng b) {
    final cosLat = math.cos(a.latitude * math.pi / 180);
    const mPerDegLat = 110574.0;
    final mPerDegLon = 111320.0 * cosLat;
    final bx = (b.longitude - a.longitude) * mPerDegLon;
    final by = (b.latitude - a.latitude) * mPerDegLat;
    final px = (p.longitude - a.longitude) * mPerDegLon;
    final py = (p.latitude - a.latitude) * mPerDegLat;
    final lengthSquared = bx * bx + by * by;
    final t = lengthSquared == 0
        ? 0.0
        : ((px * bx + py * by) / lengthSquared).clamp(0.0, 1.0);
    final dx = px - bx * t;
    final dy = py - by * t;
    return (math.sqrt(dx * dx + dy * dy), t);
  }

  List<LatLng> _corridor(RouteProgress progress, double from, double to) {
    // At most 20 points on the centerline, so the ring stays within the 40
    // points the server accepts.
    final segments = math.max(
      1,
      math.min(19, ((to - from) / _corridorSampleMeters).ceil()),
    );
    final step = (to - from) / segments;
    final centerline = [
      for (var i = 0; i <= segments; i++) progress.pointAt(from + step * i),
    ];
    return corridorPolygon(centerline, _corridorHalfWidthMeters);
  }
}
