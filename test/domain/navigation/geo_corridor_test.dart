import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/navigation/geo.dart';

void main() {
  test('a corridor along a road going north is a thin strip', () {
    final centerline = [
      for (var i = 0; i < 4; i++) LatLng(51 + i * 0.0009, 4), // ~100 m apart
    ];

    final ring = corridorPolygon(centerline, 8);

    expect(ring, hasLength(8));
    // Left side forward (west), right side back (east).
    for (final p in ring.sublist(0, 4)) {
      expect(p.longitude, lessThan(4));
      expect(distanceMeters(p, LatLng(p.latitude, 4)), closeTo(8, 0.5));
    }
    for (final p in ring.sublist(4)) {
      expect(p.longitude, greaterThan(4));
    }
    expect(ring[0].latitude, closeTo(51, 1e-6));
    expect(ring[3].latitude, closeTo(51.0027, 1e-6));
    expect(ring[4].latitude, closeTo(51.0027, 1e-6)); // right side runs back
  });

  test('too few points give no corridor', () {
    expect(corridorPolygon(const [LatLng(51, 4)], 8), isEmpty);
  });
}
