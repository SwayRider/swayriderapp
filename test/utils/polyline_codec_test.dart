import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/utils/polyline_codec.dart';

void main() {
  test('decodes Google\'s canonical polyline5 example', () {
    final points = decodePolyline(
      r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      precision: 1e5,
    );

    expect(points.length, 3);
    expect(points[0].latitude, closeTo(38.5, 1e-5));
    expect(points[0].longitude, closeTo(-120.2, 1e-5));
    expect(points[1].latitude, closeTo(40.7, 1e-5));
    expect(points[1].longitude, closeTo(-120.95, 1e-5));
    expect(points[2].latitude, closeTo(43.252, 1e-5));
    expect(points[2].longitude, closeTo(-126.453, 1e-5));
  });

  test('decodes at the default 1e6 ("polyline6") precision', () {
    // A single point at (1.0, 2.0) scaled by 1e6, encoded by hand:
    // lat delta = 1_000_000 -> zigzag 2_000_000; lng delta = 2_000_000 ->
    // zigzag 4_000_000.
    String encodeValue(int value) {
      var v = value < 0 ? ~(value << 1) : (value << 1);
      final chars = StringBuffer();
      while (v >= 0x20) {
        chars.writeCharCode((0x20 | (v & 0x1f)) + 63);
        v >>= 5;
      }
      chars.writeCharCode(v + 63);
      return chars.toString();
    }

    final encoded = encodeValue(1000000) + encodeValue(2000000);

    final points = decodePolyline(encoded);

    expect(points.length, 1);
    expect(points.single.latitude, closeTo(1.0, 1e-9));
    expect(points.single.longitude, closeTo(2.0, 1e-9));
  });

  test('returns an empty list for an empty string', () {
    expect(decodePolyline(''), isEmpty);
  });
}
