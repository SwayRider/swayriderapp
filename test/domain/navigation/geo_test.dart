import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/navigation/geo.dart';

/// Points on a circle, from [from] to [to] radians (increasing = counter-
/// clockwise on a north-up map).
List<LatLng> arc(double from, double to, {int steps = 8}) => [
  for (var i = 0; i <= steps; i++)
    LatLng(
      51 + 0.0005 * math.sin(from + (to - from) * i / steps),
      4 + 0.0008 * math.cos(from + (to - from) * i / steps),
    ),
];

void main() {
  group('isClockwise', () {
    test('a counter-clockwise arc is not clockwise', () {
      expect(isClockwise(arc(0, math.pi)), isFalse);
    });

    test('a clockwise arc is clockwise', () {
      expect(isClockwise(arc(math.pi, 0)), isTrue);
    });

    test('a short quarter arc still tells the direction', () {
      expect(isClockwise(arc(0, math.pi / 2, steps: 3)), isFalse);
    });

    test('too few points or a nearly straight line say nothing', () {
      expect(isClockwise(const [LatLng(51, 4), LatLng(51.001, 4)]), isNull);
      expect(
        isClockwise(const [
          LatLng(51, 4),
          LatLng(51.001, 4),
          LatLng(51.002, 4.00001),
        ]),
        isNull,
      );
    });
  });
}
