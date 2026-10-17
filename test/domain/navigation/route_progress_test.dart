import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/navigation/geo.dart';
import 'package:swayriderapp/domain/navigation/route_progress.dart';

/// A straight route heading north, one point per ~100 m.
List<LatLng> northRoute(int points) => [
  for (var i = 0; i < points; i++) LatLng(51.0 + i * 0.0009, 4.0),
];

void main() {
  group('RouteProgress', () {
    test('cumulative distances and total length', () {
      final progress = RouteProgress(northRoute(11));
      expect(progress.cumulative.first, 0);
      expect(progress.totalMeters, closeTo(1000, 5));
    });

    test('snaps a fix beside the route onto the line', () {
      final progress = RouteProgress(northRoute(11));

      final snap = progress.update(const LatLng(51.0045, 4.0003));

      expect(snap.snapped.longitude, closeTo(4.0, 1e-9));
      expect(snap.alongMeters, closeTo(500, 5));
      expect(snap.remainingMeters, closeTo(500, 5));
      expect(snap.offRouteMeters, closeTo(21, 3));
      expect(snap.bearing, closeTo(0, 1));
    });

    test('progress never goes backwards', () {
      final progress = RouteProgress(northRoute(11));

      final first = progress.update(const LatLng(51.0045, 4.0));
      final back = progress.update(const LatLng(51.0036, 4.0));

      expect(back.alongMeters, first.alongMeters);
      expect(back.snapped.latitude, first.snapped.latitude);
    });

    test('an out-and-back route is not matched to the return pass early', () {
      // North for 500 m, then straight back south over the same road.
      final out = northRoute(6);
      final route = [...out, ...out.reversed.skip(1)];
      final progress = RouteProgress(route);

      final snap = progress.update(const LatLng(51.0036, 4.0));

      expect(snap.alongMeters, lessThan(500));
    });

    test('a fix far from the route does not advance the match', () {
      final progress = RouteProgress(northRoute(11));
      progress.update(const LatLng(51.0018, 4.0));

      final far = progress.update(const LatLng(51.0063, 4.01));

      expect(far.alongMeters, closeTo(200, 5));
      expect(far.offRouteMeters, greaterThan(500));
    });

    test('recovers after a long GPS gap when back on the line', () {
      final progress = RouteProgress(northRoute(31));
      progress.update(const LatLng(51.0, 4.0));

      final snap = progress.update(const LatLng(51.0162, 4.0001));

      expect(snap.alongMeters, closeTo(1800, 10));
    });

    test('clamps at the end of the route', () {
      final progress = RouteProgress(northRoute(11));

      // ~50 m beyond the last point, still within the match distance.
      final snap = progress.update(const LatLng(51.0095, 4.0));

      expect(snap.remainingMeters, closeTo(0, 1e-6));
      expect(snap.alongMeters, closeTo(progress.totalMeters, 1e-6));
    });

    test('bearing follows a turn using the look-ahead', () {
      // North 500 m, then east.
      final route = [
        ...northRoute(6),
        for (var i = 1; i <= 5; i++) LatLng(51.0045, 4.0 + i * 0.0014),
      ];
      final progress = RouteProgress(route);

      final before = progress.update(const LatLng(51.003, 4.0));
      final after = progress.update(const LatLng(51.0045, 4.003));

      expect(before.bearing, closeTo(0, 1));
      expect(after.bearing, closeTo(90, 2));
    });
  });

  group('geo', () {
    test('distance and bearing', () {
      const a = LatLng(51.0, 4.0);
      const b = LatLng(51.0009, 4.0);
      expect(distanceMeters(a, b), closeTo(100, 1));
      expect(bearingDegrees(a, b), closeTo(0, 1e-6));
      expect(bearingDegrees(b, a), closeTo(180, 1e-6));
    });
  });
}
