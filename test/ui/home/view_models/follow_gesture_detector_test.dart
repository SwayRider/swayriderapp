import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/home/view_models/follow_gesture_detector.dart';

void main() {
  late FollowGestureDetector detector;

  setUp(() => detector = FollowGestureDetector());

  test('a tap does not end follow mode', () {
    expect(detector.pointerDown(1, const Offset(100, 100)), isNull);
    expect(detector.pointerMove(1, const Offset(103, 102)), isNull);
    detector.pointerUp(1);
    expect(detector.isTouching, isFalse);
  });

  group('one finger', () {
    test('a drag past the slop is a pan, reported once', () {
      detector.pointerDown(1, const Offset(100, 100));
      expect(detector.pointerMove(1, const Offset(110, 100)), isNull);
      expect(detector.pointerMove(1, const Offset(130, 100)), FollowBreak.pan);
      expect(
        detector.pointerMove(1, const Offset(200, 100)),
        isNull,
        reason: 'only once per gesture',
      );
    });

    test('a new gesture can fire again', () {
      detector.pointerDown(1, const Offset(0, 0));
      expect(detector.pointerMove(1, const Offset(50, 0)), FollowBreak.pan);
      detector.pointerUp(1);

      detector.pointerDown(2, const Offset(0, 0));
      expect(detector.pointerMove(2, const Offset(0, 50)), FollowBreak.pan);
    });

    test('moves of unknown pointers are ignored', () {
      expect(detector.pointerMove(9, const Offset(500, 500)), isNull);
    });
  });

  group('two fingers', () {
    Offset around(Offset centre, double radius, double degrees) {
      final r = degrees * math.pi / 180;
      return centre + Offset(math.cos(r), math.sin(r)) * radius;
    }

    test('turning them is a rotation', () {
      const c = Offset(200, 400);
      detector.pointerDown(1, around(c, 80, 0));
      detector.pointerDown(2, around(c, 80, 180));

      expect(detector.pointerMove(1, around(c, 80, 8)), isNull);
      expect(detector.pointerMove(2, around(c, 80, 188)), isNull);
      expect(detector.pointerMove(1, around(c, 80, 20)), FollowBreak.rotate);
    });

    test('turning the other way too', () {
      const c = Offset(200, 400);
      detector.pointerDown(1, around(c, 80, 90));
      detector.pointerDown(2, around(c, 80, 270));
      expect(detector.pointerMove(1, around(c, 80, 60)), FollowBreak.rotate);
    });

    test('pinching to zoom does not end follow mode', () {
      const c = Offset(200, 400);
      detector.pointerDown(1, around(c, 40, 0));
      detector.pointerDown(2, around(c, 40, 180));
      for (var radius = 45.0; radius <= 160; radius += 5) {
        expect(detector.pointerMove(1, around(c, radius, 0)), isNull);
        expect(detector.pointerMove(2, around(c, radius, 180)), isNull);
      }
    });

    test(
      'a finger that lands after a one-finger touch starts from scratch',
      () {
        detector.pointerDown(1, const Offset(100, 100));
        detector.pointerMove(1, const Offset(105, 100));
        detector.pointerDown(2, const Offset(300, 100));
        // moving only slightly: neither a pan (two fingers) nor a rotation
        expect(detector.pointerMove(2, const Offset(300, 104)), isNull);
      },
    );

    test('lifting one finger while the other stays is not a drag', () {
      detector.pointerDown(1, const Offset(100, 100));
      detector.pointerDown(2, const Offset(300, 100));
      detector.pointerUp(2);
      expect(detector.pointerMove(1, const Offset(104, 100)), isNull);
    });
  });

  test('reset clears everything', () {
    detector.pointerDown(1, const Offset(0, 0));
    detector.reset();
    expect(detector.isTouching, isFalse);
    expect(detector.pointerMove(1, const Offset(300, 0)), isNull);
  });
}
