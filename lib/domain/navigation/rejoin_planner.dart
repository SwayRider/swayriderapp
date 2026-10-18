import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../models/location/location_fix.dart';
import '../models/route/rejoin.dart';
import '../models/route/route_plan.dart';
import 'geo.dart';
import 'route_progress.dart';
import 'route_time.dart';

/// What to ask the server when the rider has left the route, and what the
/// answer needs to be glued back onto the route.
class RejoinPlan {
  const RejoinPlan({
    required this.request,
    required this.corridor,
    required this.remainingStops,
  });

  final RejoinRequest request;

  /// The area of the old route that is suspected to be closed and was sent as
  /// an exclusion this time (empty when there was none).
  final List<LatLng> corridor;

  /// The stops still to visit, the destination last.
  final List<LatLng> remainingStops;
}

/// Chooses the rejoin points on the original route for a rider who left it.
///
/// The points lie ahead of the rider at growing distances, so the server can
/// pick the nearest one that is reachable without a turn-back. They never
/// skip a via point, and when the deviation suggests the road ahead is
/// closed they start beyond the suspected closure (which is sent as an
/// exclusion so the way back goes around it).
class RejoinPlanner {
  const RejoinPlanner();

  /// Rejoin points at these multiples of the base distance ahead.
  static const _multipliers = [1.0, 2.5, 6.0, 14.0, 30.0];

  static const _minBaseMeters = 300.0;
  static const _maxBaseMeters = 1200.0;
  static const _baseSeconds = 15.0;

  /// The suspected closure runs from this far to this far (the default
  /// length) behind the point where the rider left the route.
  static const corridorStartMeters = 30.0;
  static const corridorLengthMeters = 370.0;
  static const _corridorHalfWidthMeters = 8.0;
  static const _corridorSampleMeters = 25.0;

  /// Rejoin points start this far beyond the suspected closure.
  static const _beyondCorridorMeters = 100.0;

  /// A rejoin point must stay this far before the end of the route and
  /// before a via point it would skip.
  static const _endMarginMeters = 100.0;
  static const _viaMarginMeters = 50.0;

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
  RejoinPlan plan({
    required RoutePlan route,
    required RouteProgress progress,
    required List<double> maneuverDistances,
    required LocationFix fix,
    required double alongMeters,
    double? leftRouteAlongMeters,
    double corridorLength = corridorLengthMeters,
    List<List<LatLng>> earlierExclusions = const [],
  }) {
    final total = progress.totalMeters;
    final stops = _remainingStops(route, progress, alongMeters);

    // The suspected closure: the road just ahead of where the rider left.
    var corridor = const <LatLng>[];
    var corridorEnd = 0.0;
    final left = leftRouteAlongMeters;
    if (left != null && left > 0) {
      final from = math.min(left + corridorStartMeters, total);
      final to = math.min(left + corridorStartMeters + corridorLength, total);
      if (to - from > 10) {
        corridor = _corridor(progress, from, to);
        corridorEnd = to;
      }
    }

    // Candidate rejoin positions along the old route.
    final base = (fix.speedMps * _baseSeconds).clamp(
      _minBaseMeters,
      _maxBaseMeters,
    );
    var positions = <double>[];
    final first = math.max(
      alongMeters + base * _multipliers.first,
      corridor.isEmpty ? 0.0 : corridorEnd + _beyondCorridorMeters,
    );
    for (final multiplier in _multipliers) {
      positions.add(first + base * (multiplier - _multipliers.first));
    }
    positions = positions.where((p) => p <= total - _endMarginMeters).toList();

    // Never skip a via point: stop before the next one and rejoin there.
    final nextVia = _nextViaAlong(route, progress, alongMeters);
    if (nextVia != null) {
      positions = positions
          .where((p) => p <= nextVia - _viaMarginMeters)
          .toList();
      if (nextVia > alongMeters + _passedMarginMeters &&
          nextVia <= total - 1 &&
          (positions.isEmpty || nextVia > positions.last)) {
        positions.add(nextVia);
      }
    }

    final points = [
      for (final along in positions)
        RejoinPoint(
          position: progress.pointAt(along),
          heading: _headingAt(progress, along),
          remainingSeconds: remainingSeconds(
            maneuvers: route.maneuvers,
            maneuverDistances: maneuverDistances,
            alongMeters: along,
            totalSeconds: route.durationSeconds,
            totalMeters: total,
          ),
          alongMeters: along,
        ),
    ];

    final heading =
        fix.courseDegrees != null && fix.speedMps >= _minHeadingSpeedMps
        ? fix.courseDegrees!.round() % 360
        : null;

    return RejoinPlan(
      request: RejoinRequest(
        from: fix.position,
        heading: heading,
        stops: stops,
        points: points,
        exclusions: [if (corridor.isNotEmpty) corridor, ...earlierExclusions],
        language: route.language,
      ),
      corridor: corridor,
      remainingStops: stops,
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

  double? _nextViaAlong(
    RoutePlan route,
    RouteProgress progress,
    double alongMeters,
  ) {
    final spec = route.request;
    if (spec == null || spec.stops.length < 2) return null;
    final via = spec.stops.sublist(0, spec.stops.length - 1);
    for (final along in _viaAlongs(via, progress)) {
      if (along > alongMeters - _passedMarginMeters) return along;
    }
    return null;
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

  int _headingAt(RouteProgress progress, double along) {
    final before = progress.pointAt(math.max(0, along - 10));
    final after = progress.pointAt(math.min(progress.totalMeters, along + 25));
    return bearingDegrees(before, after).round() % 360;
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
