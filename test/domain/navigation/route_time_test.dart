import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/navigation/route_time.dart';

RouteManeuver maneuver(double seconds) => RouteManeuver(
  type: 10,
  instruction: '',
  beginShapeIndex: 0,
  endShapeIndex: 0,
  timeSeconds: seconds,
);

void main() {
  // Stretches: 0-1000 m in 100 s, 1000-3000 m in 200 s, 3000-4000 m in 60 s.
  final maneuvers = [maneuver(100), maneuver(200), maneuver(60), maneuver(0)];
  const distances = [0.0, 1000.0, 3000.0, 4000.0];

  double remaining(double along) => remainingSeconds(
    maneuvers: maneuvers,
    maneuverDistances: distances,
    alongMeters: along,
    totalSeconds: 360,
    totalMeters: 4000,
  );

  test('is the whole route at the start', () {
    expect(remaining(0), 360);
  });

  test('takes only the unfinished part of the current stretch', () {
    expect(remaining(500), closeTo(310, 1e-9)); // half of 100 + 200 + 60
    expect(remaining(2000), closeTo(160, 1e-9)); // half of 200 + 60
  });

  test('drops a stretch once its maneuver is passed', () {
    expect(remaining(3000), 60);
    expect(remaining(3500), closeTo(30, 1e-9));
  });

  test('is zero at the end and clamps beyond it', () {
    expect(remaining(4000), 0);
    expect(remaining(5000), 0);
  });

  test('falls back to the route total, spread over its length', () {
    final result = remainingSeconds(
      maneuvers: [maneuver(0), maneuver(0)],
      maneuverDistances: const [0, 2000],
      alongMeters: 1000,
      totalSeconds: 400,
      totalMeters: 4000,
    );
    expect(result, 300);
  });

  test('has nothing to fall back on for an empty route', () {
    expect(
      remainingSeconds(
        maneuvers: const [],
        maneuverDistances: const [],
        alongMeters: 0,
        totalSeconds: 0,
        totalMeters: 0,
      ),
      0,
    );
  });
}
