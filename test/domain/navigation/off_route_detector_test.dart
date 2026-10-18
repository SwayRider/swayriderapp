import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/navigation/off_route_detector.dart';

void main() {
  final t0 = DateTime(2026, 10, 18, 12);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  test('close to the route is on the route', () {
    final d = OffRouteDetector();
    expect(d.update(offRouteMeters: 10, now: at(0)), OffRouteState.onRoute);
    expect(d.update(offRouteMeters: 45, now: at(1)), OffRouteState.onRoute);
  });

  test('far away for a few seconds is only suspect, then off', () {
    final d = OffRouteDetector();
    expect(d.update(offRouteMeters: 70, now: at(0)), OffRouteState.suspect);
    expect(d.update(offRouteMeters: 75, now: at(2)), OffRouteState.suspect);
    expect(d.update(offRouteMeters: 80, now: at(4)), OffRouteState.off);
  });

  test('very far away is off at once', () {
    final d = OffRouteDetector();
    expect(d.update(offRouteMeters: 130, now: at(0)), OffRouteState.off);
  });

  test('a single noisy fix does not trigger', () {
    final d = OffRouteDetector();
    expect(d.update(offRouteMeters: 90, now: at(0)), OffRouteState.suspect);
    expect(d.update(offRouteMeters: 12, now: at(1)), OffRouteState.onRoute);
    // The clock starts again after being back on the route.
    expect(d.update(offRouteMeters: 90, now: at(2)), OffRouteState.suspect);
    expect(d.update(offRouteMeters: 90, now: at(5)), OffRouteState.suspect);
  });

  test('a poor GPS accuracy raises the threshold', () {
    final d = OffRouteDetector();
    // 70 m away with an accuracy of 50 m: could be a good fix on the route.
    expect(
      d.update(offRouteMeters: 70, accuracyMeters: 50, now: at(0)),
      OffRouteState.onRoute,
    );
    expect(
      d.update(offRouteMeters: 70, accuracyMeters: 50, now: at(10)),
      OffRouteState.onRoute,
    );
    expect(
      d.update(offRouteMeters: 110, accuracyMeters: 50, now: at(11)),
      OffRouteState.suspect,
    );
  });

  test('the state is kept between "back on route" and the threshold', () {
    final d = OffRouteDetector();
    expect(d.update(offRouteMeters: 130, now: at(0)), OffRouteState.off);
    // 40 m: not clearly back, not far enough to start over.
    expect(d.update(offRouteMeters: 40, now: at(1)), OffRouteState.off);
    expect(d.update(offRouteMeters: 20, now: at(2)), OffRouteState.onRoute);
  });

  test('reset forgets everything', () {
    final d = OffRouteDetector();
    d.update(offRouteMeters: 130, now: at(0));
    d.reset();
    expect(d.state, OffRouteState.onRoute);
    expect(d.update(offRouteMeters: 70, now: at(1)), OffRouteState.suspect);
  });
}
