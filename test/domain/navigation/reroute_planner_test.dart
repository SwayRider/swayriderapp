import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/models/location/location_fix.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/domain/models/route/route_request_spec.dart';
import 'package:swayriderapp/domain/navigation/geo.dart';
import 'package:swayriderapp/domain/navigation/reroute_planner.dart';
import 'package:swayriderapp/domain/navigation/route_progress.dart';

/// A straight road north: 60 segments of about 100 m (6 km).
List<LatLng> northRoad() => [
  for (var i = 0; i <= 60; i++) LatLng(51.0 + i * 0.0009, 4.0),
];

RouteManeuver maneuver(int type, int index) => RouteManeuver(
  type: type,
  instruction: '',
  beginShapeIndex: index,
  endShapeIndex: index,
);

RoutePlan buildPlan({
  List<LatLng> via = const [],
  bool roundTrip = false,
  bool withRequest = true,
}) {
  final path = northRoad();
  return RoutePlan(
    path: path,
    language: 'nl-NL',
    maneuvers: [maneuver(2, 0), maneuver(4, 60)],
    request: withRequest
        ? RouteRequestSpec(
            points: [path.first, ...via, path.last],
            isRoundTrip: roundTrip,
            language: 'nl-NL',
          )
        : null,
  );
}

void main() {
  const planner = ReroutePlanner();

  ReroutePlan plan(
    RoutePlan route, {
    double along = 1000,
    double speed = 14,
    double? course = 10,
    double? left,
    double corridorLength = ReroutePlanner.corridorLengthMeters,
    List<List<LatLng>> earlier = const [],
  }) => planner.plan(
    route: route,
    progress: RouteProgress(route.path),
    fix: LocationFix(
      position: const LatLng(51.0095, 4.0007), // beside the road
      speedMps: speed,
      courseDegrees: course,
    ),
    alongMeters: along,
    leftRouteAlongMeters: left,
    corridorLength: corridorLength,
    earlierExclusions: earlier,
  );

  test('the request starts at the rider and ends at the destination', () {
    final result = plan(buildPlan());
    expect(result.request.from, const LatLng(51.0095, 4.0007));
    expect(result.request.stops, [northRoad().last]);
    expect(result.request.language, 'nl-NL');
  });

  group('direction of travel', () {
    test('is the course when moving', () {
      expect(plan(buildPlan(), course: 10).request.heading, 10);
      expect(plan(buildPlan(), course: 359.6).request.heading, 0);
    });

    test('is not sent when standing still or without a course', () {
      expect(plan(buildPlan(), speed: 1).request.heading, isNull);
      expect(plan(buildPlan(), course: null).request.heading, isNull);
    });
  });

  group('remaining stops', () {
    test('a via point still ahead is visited first', () {
      final road = northRoad();
      final result = plan(buildPlan(via: [road[20]]));
      expect(result.request.stops, [road[20], road.last]);
    });

    test('a via point already passed is dropped', () {
      final road = northRoad();
      final result = plan(buildPlan(via: [road[5]])); // 500 m, rider at 1000 m
      expect(result.request.stops, [road.last]);
    });

    test('a via point the rider has not reached yet stays', () {
      final road = northRoad();
      // The rider left the road at 400 m, before the via point at 500 m.
      final result = plan(buildPlan(via: [road[5]]), along: 400);
      expect(result.request.stops, [road[5], road.last]);
    });

    test('via points are taken in order', () {
      final road = northRoad();
      final result = plan(buildPlan(via: [road[10], road[20], road[40]]));
      expect(result.request.stops, [road[10], road[20], road[40], road.last]);
    });

    test('a round trip returns to the start at the end', () {
      final road = northRoad();
      final result = plan(buildPlan(via: [road[40]], roundTrip: true));
      // Points are start, via, end; a round trip visits the end, then the
      // start again.
      expect(result.request.stops, [road[40], road.last, road.first]);
    });

    test('a plan without a request goes to the end of the route', () {
      final result = plan(buildPlan(withRequest: false));
      expect(result.request.stops, [northRoad().last]);
    });
  });

  group('suspected closure', () {
    test('the road just ahead of where the rider left is excluded', () {
      final result = plan(buildPlan(), left: 1000);

      expect(result.corridor, isNotEmpty);
      expect(result.corridor.length, lessThanOrEqualTo(40));
      final latitudes = result.corridor.map((p) => p.latitude);
      // From 1030 m to 1400 m along the road (51 + 0.0009 per 100 m).
      expect(latitudes.reduce((a, b) => a < b ? a : b), closeTo(51.0093, 5e-4));
      expect(latitudes.reduce((a, b) => a > b ? a : b), closeTo(51.0126, 5e-4));
      expect(result.request.exclusions.first, result.corridor);
    });

    test('a longer closure still fits the 40 points the server accepts', () {
      final result = plan(buildPlan(), left: 1000, corridorLength: 740);
      expect(result.corridor.length, lessThanOrEqualTo(40));
      final latitudes = result.corridor.map((p) => p.latitude);
      expect(latitudes.reduce((a, b) => a > b ? a : b), closeTo(51.0159, 5e-4));
    });

    test('earlier closures are sent again', () {
      const earlier = [
        [LatLng(51.0, 4.0), LatLng(51.0, 4.001), LatLng(51.001, 4.001)],
      ];
      final result = plan(buildPlan(), left: 1000, earlier: earlier);
      expect(result.request.exclusions, hasLength(2));
      expect(result.request.exclusions.last, earlier.first);

      final without = plan(buildPlan(), earlier: earlier);
      expect(without.corridor, isEmpty);
      expect(without.request.exclusions, earlier);
    });

    test('no closure is assumed when the rider never was on the route', () {
      final result = plan(buildPlan(), left: null);
      expect(result.corridor, isEmpty);
      expect(result.request.exclusions, isEmpty);
    });

    test('nothing is excluded near the end of the route', () {
      final result = plan(buildPlan(), left: 6000, along: 6000);
      expect(result.corridor, isEmpty);
    });

    test('the corridor lies on the old route', () {
      final result = plan(buildPlan(), left: 1000);
      for (final p in result.corridor) {
        expect(distanceMeters(p, LatLng(p.latitude, 4.0)), lessThan(10));
      }
    });
  });
}
