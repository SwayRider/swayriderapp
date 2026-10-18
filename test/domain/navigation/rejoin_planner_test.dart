import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/models/location/location_fix.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/domain/models/route/route_request_spec.dart';
import 'package:swayriderapp/domain/navigation/geo.dart';
import 'package:swayriderapp/domain/navigation/rejoin_planner.dart';
import 'package:swayriderapp/domain/navigation/route_progress.dart';

/// A straight road north: 60 segments of about 100 m (6 km).
List<LatLng> northRoad() => [
  for (var i = 0; i <= 60; i++) LatLng(51.0 + i * 0.0009, 4.0),
];

RouteManeuver maneuver(int type, int index, double seconds) => RouteManeuver(
  type: type,
  instruction: '',
  beginShapeIndex: index,
  endShapeIndex: index,
  timeSeconds: seconds,
);

RoutePlan buildPlan({List<LatLng> via = const []}) {
  final path = northRoad();
  return RoutePlan(
    path: path,
    language: 'nl-NL',
    durationSeconds: 360,
    maneuvers: [maneuver(2, 0, 180), maneuver(10, 30, 180), maneuver(4, 60, 0)],
    request: RouteRequestSpec(
      points: [path.first, ...via, path.last],
      language: 'nl-NL',
    ),
  );
}

void main() {
  const planner = RejoinPlanner();

  RejoinPlan plan(
    RoutePlan route, {
    double along = 1000,
    double speed = 14,
    double? course = 10,
    double? left,
    double corridorLength = RejoinPlanner.corridorLengthMeters,
    List<List<LatLng>> earlier = const [],
  }) {
    final progress = RouteProgress(route.path);
    final distances = [
      for (final m in route.maneuvers) progress.cumulative[m.beginShapeIndex],
    ];
    return planner.plan(
      route: route,
      progress: progress,
      maneuverDistances: distances,
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
  }

  test('rejoin points lie ahead at growing distances', () {
    final result = plan(buildPlan());
    final alongs = result.request.points.map((p) => p.alongMeters).toList();

    // 14 m/s x 15 s = 210 m, raised to the 300 m minimum: 1x, 2.5x, 6x, 14x
    // ahead of the rider at 1000 m; 30x is beyond the end of the route.
    expect(alongs, hasLength(4));
    expect(alongs[0], closeTo(1300, 1));
    expect(alongs[1], closeTo(1750, 1));
    expect(alongs[2], closeTo(2800, 1));
    expect(alongs[3], closeTo(5200, 1));
  });

  test('a faster rider gets points further ahead, up to a limit', () {
    final fast = plan(buildPlan(), speed: 30);
    // 30 m/s x 15 s = 450 m.
    expect(fast.request.points.first.alongMeters, closeTo(1450, 1));
    final veryFast = plan(buildPlan(), speed: 80);
    expect(veryFast.request.points.first.alongMeters, closeTo(2200, 1));
  });

  test('each point has the route heading and the time left after it', () {
    final result = plan(buildPlan());
    final first = result.request.points.first;

    expect(first.heading, 0); // the road runs north
    expect(first.position.longitude, closeTo(4.0, 1e-9));
    expect(first.position.latitude, closeTo(51.0117, 1e-3));
    // 1300 m: the rest of the first stretch (1700/3000 of 180 s) plus 180 s.
    expect(first.remainingSeconds, closeTo(282, 3));
  });

  test('the heading is the course, only when moving', () {
    expect(plan(buildPlan(), course: 10).request.heading, 10);
    expect(plan(buildPlan(), course: 359.6).request.heading, 0);
    expect(plan(buildPlan(), speed: 1).request.heading, isNull);
    expect(plan(buildPlan(), course: null).request.heading, isNull);
  });

  test('the fresh route goes to the destination from the rider', () {
    final result = plan(buildPlan());
    expect(result.request.from, const LatLng(51.0095, 4.0007));
    expect(result.request.stops, [northRoad().last]);
    expect(result.request.language, 'nl-NL');
  });

  test('a via point still ahead is never skipped', () {
    final road = northRoad();
    final result = plan(buildPlan(via: [road[20]])); // 2000 m

    final alongs = result.request.points.map((p) => p.alongMeters).toList();
    expect(alongs, hasLength(3));
    expect(alongs[0], closeTo(1300, 1));
    expect(alongs[1], closeTo(1750, 1));
    expect(alongs.last, closeTo(2000, 5)); // the via point itself
    expect(result.request.stops, [road[20], road.last]);
  });

  test('a via point already passed is dropped', () {
    final road = northRoad();
    final result = plan(buildPlan(via: [road[5]])); // 500 m, rider at 1000 m

    expect(result.request.stops, [road.last]);
    expect(result.request.points, hasLength(4));
  });

  test('near the end of the route there is nothing to rejoin', () {
    final result = plan(buildPlan(), along: 5800);
    expect(result.request.points, isEmpty);
    expect(result.request.stops, [northRoad().last]);
  });

  test('a plan without a request goes to the end of the route', () {
    final route = RoutePlan(
      path: northRoad(),
      maneuvers: [maneuver(2, 0, 100), maneuver(4, 60, 0)],
    );
    expect(plan(route).request.stops, [northRoad().last]);
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

    test('rejoin points start beyond the closure', () {
      final result = plan(buildPlan(), left: 1000);
      // 1000 + 30 + 370 + 100.
      expect(result.request.points.first.alongMeters, closeTo(1500, 1));
      // The spacing between the points is kept.
      expect(
        result.request.points[1].alongMeters -
            result.request.points[0].alongMeters,
        closeTo(450, 1),
      );
    });

    test('a longer closure moves the points further away', () {
      final result = plan(buildPlan(), left: 1000, corridorLength: 740);
      expect(result.corridor.length, lessThanOrEqualTo(40));
      expect(result.request.points.first.alongMeters, closeTo(1870, 1));
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

    test('the corridor lies on the old route', () {
      final result = plan(buildPlan(), left: 1000);
      for (final p in result.corridor) {
        expect(distanceMeters(p, LatLng(p.latitude, 4.0)), lessThan(10));
      }
    });
  });
}
