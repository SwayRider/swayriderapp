import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import 'route_plan.dart';

/// A point of the original route a rider can rejoin at.
class RejoinPoint {
  const RejoinPoint({
    required this.position,
    required this.heading,
    required this.remainingSeconds,
    required this.alongMeters,
  });

  final LatLng position;

  /// Direction of the original route at the point, degrees clockwise from
  /// north; the way back arrives travelling that way.
  final int heading;

  /// Travel time left on the original route after this point.
  final double remainingSeconds;

  /// Distance of the point from the start of the original route.
  final double alongMeters;
}

/// What the server needs to find the way back onto a route.
class RejoinRequest {
  const RejoinRequest({
    required this.from,
    required this.stops,
    required this.points,
    this.heading,
    this.exclusions = const [],
    this.language = 'en-US',
  });

  /// The rider's position.
  final LatLng from;

  /// Direction of travel, or `null` when unknown (standing still).
  final int? heading;

  /// The remaining stops for the fresh-route fallback (via points still
  /// ahead, then the destination).
  final List<LatLng> stops;

  /// Points of the original route that can be rejoined, nearest first.
  final List<RejoinPoint> points;

  /// Areas to avoid: rings of points.
  final List<List<LatLng>> exclusions;

  final String language;
}

enum RejoinKind {
  /// The plan is the connector to the chosen rejoin point.
  rejoin,

  /// The plan is a fresh route to the remaining stops.
  fresh,
}

class RejoinResult {
  const RejoinResult({
    required this.kind,
    required this.plan,
    this.rejoinIndex = 0,
  });

  final RejoinKind kind;

  /// Index into [RejoinRequest.points] (for [RejoinKind.rejoin]).
  final int rejoinIndex;

  final RoutePlan plan;
}
