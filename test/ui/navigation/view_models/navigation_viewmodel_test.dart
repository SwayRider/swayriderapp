import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/ui/navigation/view_models/navigation_viewmodel.dart';

import '../../../helpers/fakes.dart';

/// 3 km straight north (one point per ~100 m): depart at 0, turn left at
/// 2000 m, arrive at the end.
RoutePlan buildPlan() {
  final path = [for (var i = 0; i <= 30; i++) LatLng(51.0 + i * 0.0009, 4.0)];
  return RoutePlan(
    path: path,
    language: 'nl-NL',
    distanceMeters: 3000,
    maneuvers: const [
      RouteManeuver(
        type: 2,
        instruction: 'Rij naar het noorden.',
        beginShapeIndex: 0,
        endShapeIndex: 20,
        verbalPre: 'Rij naar het noorden.',
      ),
      RouteManeuver(
        type: 15,
        instruction: 'Sla linksaf.',
        beginShapeIndex: 20,
        endShapeIndex: 30,
        verbalAlert: 'Sla linksaf.',
        verbalPre: 'Sla linksaf naar Zijstraat.',
        streetNames: ['Zijstraat'],
      ),
      RouteManeuver(
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
    // 10 m/s => alert within 300 m, pre within 80 m of the turn at 2000 m.
    location.emit(at(18));
    await pump();
    expect(speech.spoken.last, 'Over 200 meter, sla linksaf.');

    location.emit(at(19));
    await pump();
    expect(speech.spoken, hasLength(2));

    location.emit(at(19.5));
    location.emit(at(19.6));
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

  test('a fix beside the route is snapped onto it', () async {
    location.emit(const LatLng(51.0045, 4.0002));
    await pump();

    expect(viewModel.dotPosition?.longitude, closeTo(4.0, 1e-9));
    expect(viewModel.offRoute, isFalse);
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
}
