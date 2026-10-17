import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/models/route/route_lane.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/domain/navigation/camera_zoom.dart';
import 'package:swayriderapp/ui/navigation/view_models/navigation_viewmodel.dart';

import '../../../helpers/fakes.dart';

/// 3 km straight north (one point per ~100 m): depart at 0, turn left at
/// 2000 m, arrive at the end.
RoutePlan buildPlan({List<RouteLane> lanes = const [], int turnType = 15}) {
  final path = [for (var i = 0; i <= 30; i++) LatLng(51.0 + i * 0.0009, 4.0)];
  return RoutePlan(
    path: path,
    language: 'nl-NL',
    distanceMeters: 3000,
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
    expect(speech.spoken.last, 'Sla linksaf naar Zijstraat.');
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
}
