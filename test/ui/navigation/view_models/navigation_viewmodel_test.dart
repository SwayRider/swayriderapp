import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/models/route/reroute_request.dart';
import 'package:swayriderapp/domain/models/route/route_lane.dart';
import 'package:swayriderapp/domain/models/route/route_request_spec.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/domain/navigation/camera_zoom.dart';
import 'package:swayriderapp/ui/navigation/view_models/navigation_viewmodel.dart';

import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/memory_telemetry.dart';

/// 3 km straight north (one point per ~100 m): depart at 0, turn left at
/// 2000 m, arrive at the end.
RoutePlan buildPlan({
  List<RouteLane> lanes = const [],
  int turnType = 15,
  double durationSeconds = 0,
}) {
  final path = [for (var i = 0; i <= 30; i++) LatLng(51.0 + i * 0.0009, 4.0)];
  return RoutePlan(
    path: path,
    language: 'nl-NL',
    distanceMeters: 3000,
    durationSeconds: durationSeconds,
    maneuvers: [
      const RouteManeuver(
        type: 2,
        instruction: 'Rij naar het noorden.',
        beginShapeIndex: 0,
        endShapeIndex: 20,
        verbalPre: 'Rij naar het noorden.',
      ),
      RouteManeuver(
        type: turnType,
        instruction: 'Sla linksaf.',
        lanes: lanes,
        beginShapeIndex: 20,
        endShapeIndex: 30,
        verbalAlert: 'Sla linksaf.',
        verbalPre: 'Sla linksaf naar Zijstraat.',
        streetNames: ['Zijstraat'],
      ),
      const RouteManeuver(
        type: 4,
        instruction: 'U bent aangekomen.',
        beginShapeIndex: 30,
        endShapeIndex: 30,
        verbalPre: 'U bent aangekomen.',
      ),
    ],
  );
}

LatLng at(num hundredMeters) => LatLng(51.0 + hundredMeters * 0.0009, 4.0);

void main() {
  late FakeLocationService location;
  late FakeSpeechService speech;
  late NavigationViewModel viewModel;

  setUp(() {
    location = FakeLocationService();
    speech = FakeSpeechService();
    viewModel = NavigationViewModel(
      plan: buildPlan(),
      locationService: location,
      speechService: speech,
    )..start();
  });

  tearDown(() => viewModel.dispose());

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('has no state before the first fix', () {
    expect(viewModel.upcoming, isNull);
    expect(viewModel.dotPosition, isNull);
    expect(viewModel.arrived, isFalse);
  });

  test(
    'first fix speaks the start instruction in the route language',
    () async {
      location.emit(at(0));
      await pump();

      expect(speech.spoken, ['Rij naar het noorden.']);
      expect(speech.languages, ['nl-NL']);
    },
  );

  test('upcoming maneuver and distance follow the rider', () async {
    location.emit(at(5));
    await pump();

    expect(viewModel.upcoming?.type, 15);
    expect(viewModel.distanceToUpcomingMeters, closeTo(1500, 10));
    expect(viewModel.remainingMeters, closeTo(2500, 10));
    expect(viewModel.routeBearing, closeTo(0, 1));
  });

  test('speaks the alert, then the pre-transition prompt once', () async {
    location.emit(at(0));
    // 10 m/s => alert within 300 m, pre within 120 m of the turn at 2000 m.
    location.emit(at(18));
    await pump();
    expect(speech.spoken.last, 'Over 200 meter, Sla linksaf.');

    location.emit(at(18.5));
    await pump();
    expect(speech.spoken, hasLength(2));

    location.emit(at(19));
    location.emit(at(19.2));
    await pump();
    expect(speech.spoken.last, 'Sla linksaf.');
    expect(speech.spoken, hasLength(3));
  });

  test('switches to the next maneuver once the turn is reached', () async {
    location.emit(at(19));
    await pump();
    expect(viewModel.upcoming?.type, 15);

    location.emit(at(21));
    await pump();
    expect(viewModel.upcoming?.type, 4);
  });

  test(
    'target zoom is a fixed level that steps in only near the turn',
    () async {
      expect(viewModel.targetZoom, CameraZoom.slowZoom); // before the first fix

      location.emit(at(5), speedMps: 20); // 72 km/h, 1500 m before the turn
      await pump();
      expect(viewModel.targetZoom, CameraZoom.mediumZoom);

      location.emit(at(15), speedMps: 20); // 500 m before: still wide
      await pump();
      expect(viewModel.targetZoom, CameraZoom.mediumZoom);

      location.emit(at(18), speedMps: 20); // 200 m before: zoom in
      await pump();
      expect(viewModel.targetZoom, CameraZoom.turnZoom);

      location.emit(
        at(22),
        speedMps: 20,
      ); // turn passed, destination 800 m away
      await pump();
      expect(viewModel.targetZoom, CameraZoom.mediumZoom);
    },
  );

  test('a fix beside the route is snapped onto it', () async {
    location.emit(const LatLng(51.0045, 4.0002));
    await pump();

    expect(viewModel.dotPosition?.longitude, closeTo(4.0, 1e-9));
    expect(viewModel.offRoute, isFalse);
  });

  test('speedKmh is the rounded ground speed from the first fix on', () async {
    expect(viewModel.speedKmh, 0); // before the first fix

    location.emit(at(1), speedMps: 20.4); // 73.4 km/h
    await pump();
    expect(viewModel.speedKmh, 73);
  });

  test('speedKmh smooths noisy fixes instead of following each one', () async {
    var previous = 0;
    var biggestStep = 0;
    for (var i = 0; i < 30; i++) {
      // 72 km/h with +-10 km/h GPS speed noise.
      location.emit(at(1 + i * 0.1), speedMps: 20 + (i.isEven ? 2.8 : -2.8));
      await pump();
      if (i > 0) {
        final step = (viewModel.speedKmh - previous).abs();
        if (step > biggestStep) biggestStep = step;
      }
      previous = viewModel.speedKmh;
    }
    expect(viewModel.speedKmh, inInclusiveRange(68, 76));
    expect(biggestStep, lessThan(8)); // raw steps are 20 km/h
  });

  test('speedKmh settles to 0 when stopping, ignoring GPS creep', () async {
    location.emit(at(1), speedMps: 20);
    await pump();
    for (var i = 0; i < 25; i++) {
      location.emit(at(1), speedMps: 0.3);
      await pump();
    }
    expect(viewModel.speedKmh, 0);
  });

  test('a fix far from the route draws the raw position', () async {
    location.emit(at(5));
    await pump();
    const away = LatLng(51.0045, 4.01);
    location.emit(away);
    await pump();

    expect(viewModel.offRoute, isTrue);
    expect(viewModel.dotPosition, away);
  });

  test('reaching the end announces arrival and stops listening', () async {
    location.emit(at(29));
    location.emit(at(30));
    await pump();

    expect(viewModel.arrived, isTrue);
    expect(speech.spoken.last, 'U bent aangekomen.');
    expect(location.listening, isFalse);
  });

  test('a location error is surfaced and cleared by the next fix', () async {
    location.emitError(Exception('gps off'));
    await pump();
    expect(viewModel.locationError, isNotNull);

    location.emit(at(1));
    await pump();
    expect(viewModel.locationError, isNull);
  });

  test('stop cancels the subscription and silences speech', () async {
    await viewModel.stop();

    expect(location.listening, isFalse);
    expect(speech.stops, 1);
  });

  group('lane guidance', () {
    const lanes = [
      RouteLane(directions: RouteLane.left, active: RouteLane.left),
      RouteLane(directions: RouteLane.right),
    ];

    NavigationViewModel startWith(RoutePlan plan) {
      viewModel.dispose();
      return viewModel = NavigationViewModel(
        plan: plan,
        locationService: location,
        speechService: speech,
      )..start();
    }

    test('shows the lanes within 400 m of a turn, not before', () async {
      startWith(buildPlan(lanes: lanes));
      location.emit(at(10));
      await pump();
      expect(viewModel.laneGuidance, isEmpty);

      location.emit(at(17));
      await pump();
      expect(viewModel.laneGuidance, lanes);
    });

    test('a motorway exit shows its lanes from 1 km', () async {
      startWith(buildPlan(lanes: lanes, turnType: 20));
      location.emit(at(11));
      await pump();
      expect(viewModel.laneGuidance, lanes);
    });

    test('stays empty when no lane is marked for the route', () async {
      startWith(
        buildPlan(
          lanes: const [
            RouteLane(directions: RouteLane.left),
            RouteLane(directions: RouteLane.right),
          ],
        ),
      );
      location.emit(at(19));
      await pump();
      expect(viewModel.laneGuidance, isEmpty);
    });
  });

  group('ETA', () {
    final now = DateTime(2026, 10, 17, 14, 0);

    NavigationViewModel startAt(RoutePlan plan) {
      viewModel.dispose();
      return viewModel = NavigationViewModel(
        plan: plan,
        locationService: location,
        speechService: speech,
        clock: () => now,
      )..start();
    }

    test('before the first fix it is the whole route', () {
      startAt(buildPlan(durationSeconds: 300));
      expect(viewModel.remainingTime, const Duration(seconds: 300));
      expect(viewModel.eta, now.add(const Duration(minutes: 5)));
    });

    test('counts down as the rider progresses', () async {
      startAt(buildPlan(durationSeconds: 300));
      location.emit(at(15)); // half way
      await pump();

      expect(viewModel.remainingTime.inSeconds, closeTo(150, 5));
      expect(viewModel.eta.difference(now).inSeconds, closeTo(150, 5));
    });

    test('is the current time once arrived', () async {
      startAt(buildPlan(durationSeconds: 300));
      location.emit(at(30));
      await pump();

      expect(viewModel.arrived, isTrue);
      expect(viewModel.eta, now);
    });
  });

  group('telemetry', () {
    late MemoryTelemetryService telemetry;
    late FakeRouterRepository router;
    late DateTime now;
    final beside = LatLng(51.0045, 4.0029);

    setUp(() {
      viewModel.dispose();
      telemetry = MemoryTelemetryService();
      router = FakeRouterRepository();
      now = DateTime(2026, 10, 18, 12);
      viewModel = NavigationViewModel(
        plan: buildPlan(),
        locationService: location,
        speechService: speech,
        routerRepository: router,
        telemetry: telemetry,
        clock: () => now,
      )..start();
    });

    test('records the route at the start', () {
      final start = telemetry.of('nav_start').single;
      final plan = start['plan']! as Map<String, Object?>;
      expect(plan['maneuvers'], hasLength(3));
      expect((plan['path']! as List).length, 31 * 2);
    });

    test('records at most one GPS fix per second', () async {
      location.emit(at(1));
      await pump();
      now = now.add(const Duration(milliseconds: 400));
      location.emit(at(2));
      await pump();
      now = now.add(const Duration(milliseconds: 700));
      location.emit(at(3));
      await pump();

      final fixes = telemetry.of('gps_fix');
      expect(fixes, hasLength(2));
      expect(fixes.last['alongM'], closeTo(300, 5));
      expect(fixes.last['offRouteM'], closeTo(0, 1));
    });

    test('records leaving the route and the way back', () async {
      location.emit(at(4), speedMps: 12, course: 0);
      await pump();
      now = now.add(const Duration(seconds: 2));
      location.emit(beside, speedMps: 12, course: 0);
      await pump();
      now = now.add(const Duration(seconds: 5));
      location.emit(beside, speedMps: 12, course: 0);
      await pump();

      expect(
        telemetry.of('offroute_state').map((e) => e['state']),
        containsAllInOrder(['onRoute', 'off']),
      );
      expect(telemetry.of('reroute_asked'), hasLength(1));
      expect(telemetry.types, contains('prompt_enqueued'));

      router.answer(
        Result.ok(
          RoutePlan(
            path: [beside, LatLng(51.0045, 4.004), const LatLng(51.027, 4.0)],
            language: 'nl-NL',
            maneuvers: const [
              RouteManeuver(
                type: 2,
                instruction: 'Rij.',
                beginShapeIndex: 0,
                endShapeIndex: 1,
              ),
              RouteManeuver(
                type: 4,
                instruction: 'Aangekomen.',
                beginShapeIndex: 2,
                endShapeIndex: 2,
              ),
            ],
          ),
        ),
      );
      await pump();
      expect(telemetry.of('plan_replaced').single['routeVersion'], 1);
    });

    test('records why navigation ended, once', () async {
      await viewModel.stop();
      await viewModel.stop();

      expect(telemetry.of('nav_end'), hasLength(1));
      expect(telemetry.of('nav_end').single['reason'], 'user_stop');
    });

    test('records arrival', () async {
      location.emit(at(30));
      await pump();
      await viewModel.stop();

      expect(telemetry.types, contains('arrived'));
      expect(telemetry.of('nav_end').single['reason'], 'arrived');
    });

    test('every event can be written as JSON', () async {
      location.emit(at(4), speedMps: 12, course: 0);
      await pump();
      location.emit(at(30));
      await pump();
      await viewModel.stop();

      for (final e in telemetry.events) {
        expect(() => jsonEncode(e.data), returnsNormally, reason: e.type);
      }
    });
  });

  group('a new route after leaving the route', () {
    late FakeRouterRepository router;
    late DateTime now;

    // 200 m east of the road, level with 500 m.
    final beside = LatLng(51.0045, 4.0029);

    NavigationViewModel startWithRouter() {
      viewModel.dispose();
      router = FakeRouterRepository();
      now = DateTime(2026, 10, 18, 12);
      return viewModel = NavigationViewModel(
        plan: buildPlan(),
        locationService: location,
        speechService: speech,
        routerRepository: router,
        clock: () => now,
      )..start();
    }

    /// The new route the server would answer: from the rider, a right turn,
    /// and the destination.
    RoutePlan newRoute(RerouteRequest request) => RoutePlan(
      path: [
        request.from,
        LatLng(request.from.latitude, 4.004),
        request.stops.last,
      ],
      distanceMeters: 2500,
      durationSeconds: 200,
      language: 'nl-NL',
      request: RouteRequestSpec(
        points: [request.from, ...request.stops],
        language: 'nl-NL',
      ),
      maneuvers: const [
        RouteManeuver(
          type: 2,
          instruction: 'Rij naar het noorden.',
          beginShapeIndex: 0,
          endShapeIndex: 1,
          verbalPre: 'Rij naar het noorden.',
        ),
        RouteManeuver(
          type: 10,
          instruction: 'Sla rechtsaf.',
          beginShapeIndex: 1,
          endShapeIndex: 2,
          verbalPre: 'Sla rechtsaf.',
        ),
        RouteManeuver(
          type: 4,
          instruction: 'Aangekomen.',
          beginShapeIndex: 2,
          endShapeIndex: 2,
          verbalPre: 'Aangekomen.',
        ),
      ],
    );

    Future<void> driveOffRoute() async {
      location.emit(at(4), speedMps: 12, course: 0);
      await pump();
      location.emit(at(5), speedMps: 12, course: 0);
      await pump();
      location.emit(beside, speedMps: 12, course: 0);
      await pump();
    }

    test('leaving the route asks for a new route, once', () async {
      startWithRouter();
      await driveOffRoute();

      expect(router.requests, hasLength(1));
      final request = router.requests.single;
      expect(request.from, beside);
      expect(request.heading, 0);
      expect(request.stops, [buildPlan().path.last]);
      // The road ahead of where the rider left is suspected closed.
      expect(request.exclusions, isNotEmpty);
      expect(viewModel.rerouteStatus, RerouteStatus.pending);

      // More fixes while waiting do not ask again.
      location.emit(LatLng(51.0046, 4.0029), speedMps: 12);
      await pump();
      expect(router.requests, hasLength(1));
    });

    test('says that it is recalculating, once', () async {
      startWithRouter();
      await driveOffRoute();
      location.emit(LatLng(51.0046, 4.0029), speedMps: 12);
      await pump();

      expect(
        speech.spoken.where((t) => t == 'Route wordt herberekend.'),
        hasLength(1),
      );
    });

    test('the new route replaces the old one', () async {
      startWithRouter();
      await driveOffRoute();

      router.answer(Result.ok(newRoute(router.requests.single)));
      await pump();

      expect(viewModel.routeVersion, 1);
      expect(viewModel.rerouteStatus, RerouteStatus.idle);
      expect(viewModel.plan.path.first, beside);
      expect(viewModel.upcoming?.instruction, 'Sla rechtsaf.');
      // The next reroute starts from the stops of this one.
      expect(viewModel.plan.request!.points.first, beside);
    });

    test('the departure is not announced again', () async {
      startWithRouter();
      await driveOffRoute();
      speech.spoken.clear();

      router.answer(Result.ok(newRoute(router.requests.single)));
      await pump();

      expect(speech.spoken, isNot(contains('Rij naar het noorden.')));
    });

    test('an answer that comes after the rider is back is ignored', () async {
      startWithRouter();
      await driveOffRoute();
      final request = router.requests.single;

      location.emit(at(6), speedMps: 12); // back on the road
      await pump();
      router.answer(Result.ok(newRoute(request)));
      await pump();

      expect(viewModel.routeVersion, 0);
      expect(viewModel.rerouteStatus, RerouteStatus.idle);
    });

    test('the closure that was avoided stays avoided', () async {
      startWithRouter();
      await driveOffRoute();
      final first = router.requests.single.exclusions.first;
      router.answer(Result.ok(newRoute(router.requests.single)));
      await pump();

      // Off the new route too: the earlier closure is sent again.
      location.emit(at(3), speedMps: 12, course: 0);
      await pump();
      // (the new route started beside the road; leave it by going far away)
      location.emit(LatLng(51.0010, 4.0100), speedMps: 12, course: 0);
      await pump();
      expect(router.requests, hasLength(2));
      expect(router.requests.last.exclusions, contains(first));
    });

    test('a failure is retried after a pause, with a growing delay', () async {
      startWithRouter();
      await driveOffRoute();
      router.answer(Result.error(Exception('no route')));
      await pump();
      expect(viewModel.rerouteStatus, RerouteStatus.failed);

      // Too soon: nothing new.
      location.emit(beside, speedMps: 12);
      await pump();
      expect(router.requests, hasLength(1));

      // After 10 s the next attempt.
      now = now.add(const Duration(seconds: 11));
      location.emit(beside, speedMps: 12);
      await pump();
      expect(router.requests, hasLength(2));
      expect(viewModel.rerouteStatus, RerouteStatus.pending);

      router.answer(Result.error(Exception('no route')));
      await pump();
      // The second failure waits 20 s.
      now = now.add(const Duration(seconds: 15));
      location.emit(beside, speedMps: 12);
      await pump();
      expect(router.requests, hasLength(2));
      now = now.add(const Duration(seconds: 6));
      location.emit(beside, speedMps: 12);
      await pump();
      expect(router.requests, hasLength(3));
    });

    test('without a router nothing is asked', () async {
      // The default view model of the other tests has no router.
      location.emit(at(5), speedMps: 12);
      location.emit(beside, speedMps: 12);
      await pump();
      expect(viewModel.rerouteStatus, RerouteStatus.idle);
      expect(viewModel.routeVersion, 0);
    });

    test('a short excursion is not a reason to ask', () async {
      startWithRouter();
      location.emit(at(5), speedMps: 12);
      await pump();
      // 70 m beside the road for 2 s.
      location.emit(LatLng(51.0045, 4.0010), speedMps: 12);
      await pump();
      now = now.add(const Duration(seconds: 2));
      location.emit(LatLng(51.0046, 4.0010), speedMps: 12);
      await pump();
      location.emit(at(5.2), speedMps: 12);
      await pump();

      expect(router.requests, isEmpty);
    });
  });
}
