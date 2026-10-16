import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/ui/home/view_models/follow_heading_controller.dart';

import '../../../helpers/fakes.dart';

typedef _Applied = ({LatLng? position, double? bearing});

const _home = LatLng(51.2194, 4.4025);

/// About [metres] north of [_home].
LatLng _north(double metres) =>
    LatLng(_home.latitude + metres / 111320, _home.longitude);

double _diff(double a, double b) {
  final d = ((a - b) % 360 + 360) % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  late FakeCompassService compass;

  setUp(() => compass = FakeCompassService());

  /// A controller whose clock follows [async]; [applied] collects the camera
  /// moves it asks for.
  (FollowHeadingController, List<_Applied>) create(FakeAsync async) {
    final applied = <_Applied>[];
    final controller = FollowHeadingController(
      compassService: compass,
      clock: async.getClock(DateTime(2026, 10, 16, 14)).now,
    )..bind((p, b) => applied.add((position: p, bearing: b)));
    return (controller, applied);
  }

  group('start and stop', () {
    test('start listens to the compass, stop stops it', () {
      fakeAsync((async) {
        final (c, _) = create(async);
        expect(c.following, isFalse);

        c.start();
        c.start(); // idempotent
        expect(c.following, isTrue);
        expect(compass.starts, 1);
        expect(compass.listening, isTrue);

        c.stop();
        c.stop();
        async.flushMicrotasks();
        expect(c.following, isFalse);
        expect(compass.listening, isFalse);
        expect(async.pendingTimers, isEmpty);
        c.dispose();
      });
    });

    test('listeners hear about it', () {
      fakeAsync((async) {
        final (c, _) = create(async);
        var notified = 0;
        c.addListener(() => notified++);
        c.start();
        c.stop();
        expect(notified, 2);
        c.dispose();
      });
    });
  });

  group('following', () {
    test('recentres on the user and rotates to the heading', () {
      fakeAsync((async) {
        final (c, applied) = create(async);
        c.onUserLocation(position: _home);
        c.start();
        compass.emit(120);
        async.elapse(const Duration(milliseconds: 150));

        // it recentres at once, and rotates as soon as the compass answers
        expect(applied.first.position, _home);
        expect(applied.any((a) => a.bearing != null), isTrue);
        c.dispose();
      });
    });

    test('a still device and a still user move nothing after settling', () {
      fakeAsync((async) {
        final (c, applied) = create(async);
        c.onUserLocation(position: _home);
        c.start();
        for (var i = 0; i < 100; i++) {
          compass.emit(120 + (i.isEven ? 4 : -4)); // jitter
          async.elapse(const Duration(milliseconds: 33));
        }
        applied.clear();

        for (var i = 0; i < 300; i++) {
          compass.emit(120 + (i.isEven ? 5 : -5));
          async.elapse(const Duration(milliseconds: 33));
        }

        expect(applied, isEmpty, reason: 'the map stays put');
        c.dispose();
      });
    });

    test('the camera only follows the user after about half a metre', () {
      fakeAsync((async) {
        final (c, applied) = create(async);
        c.onUserLocation(position: _home);
        c.start();
        compass.emit(90);
        async.elapse(const Duration(seconds: 1));
        applied.clear();

        c.onUserLocation(position: _north(0.2)); // GPS noise
        async.elapse(const Duration(milliseconds: 300));
        expect(applied, isEmpty);

        c.onUserLocation(position: _north(2));
        async.elapse(const Duration(milliseconds: 300));
        expect(applied, hasLength(1));
        expect(applied.single.position, _north(2));
        expect(applied.single.bearing, isNull, reason: 'only a recentre');
        c.dispose();
      });
    });

    test(
      'a real turn rotates step by step, never faster than 12 degrees a tick',
      () {
        fakeAsync((async) {
          final (c, applied) = create(async);
          c.start();
          compass.emit(0);
          async.elapse(const Duration(seconds: 1));
          applied.clear();

          for (var i = 0; i < 60; i++) {
            compass.emit(180);
            async.elapse(const Duration(milliseconds: 33));
          }

          final bearings = applied
              .map((a) => a.bearing)
              .whereType<double>()
              .toList();
          expect(bearings.length, greaterThan(3));
          for (var i = 1; i < bearings.length; i++) {
            expect(
              _diff(bearings[i], bearings[i - 1]),
              lessThanOrEqualTo(12.5),
            );
          }
          expect(_diff(bearings.last, 180), lessThan(15));
          c.dispose();
        });
      },
    );

    test(
      'nothing moves while the user touches the map, and it resumes after',
      () {
        fakeAsync((async) {
          final (c, applied) = create(async);
          c.onUserLocation(position: _home);
          c.start();
          compass.emit(90);
          async.elapse(const Duration(seconds: 1));
          applied.clear();

          c.setTouching(true);
          c.onUserLocation(position: _north(50));
          for (var i = 0; i < 30; i++) {
            compass.emit(200);
            async.elapse(const Duration(milliseconds: 33));
          }
          expect(applied, isEmpty);

          c.setTouching(false);
          async.elapse(const Duration(milliseconds: 300));
          expect(applied, isNotEmpty);
          c.dispose();
        });
      },
    );

    test('works while nothing is bound (no crash)', () {
      fakeAsync((async) {
        final c = FollowHeadingController(
          compassService: compass,
          clock: async.getClock(DateTime(2026)).now,
        );
        c.start();
        compass.emit(10);
        async.elapse(const Duration(seconds: 1));
        c.dispose();
      });
    });

    test('starting again begins afresh', () {
      fakeAsync((async) {
        final (c, applied) = create(async);
        c.onUserLocation(position: _home);
        c.start();
        compass.emit(90);
        async.elapse(const Duration(seconds: 1));
        c.stop();
        async.flushMicrotasks();
        applied.clear();

        c.start();
        compass.emit(90);
        async.elapse(const Duration(milliseconds: 300));
        expect(applied, isNotEmpty, reason: 'recentres again');
        expect(applied.first.position, _home);
        c.dispose();
      });
    });
  });

  group('GPS course', () {
    test('while moving fast the direction of travel wins over the compass', () {
      fakeAsync((async) {
        final (c, applied) = create(async);
        c.start();
        compass.emit(90);
        async.elapse(const Duration(seconds: 1));

        for (var i = 0; i < 40; i++) {
          c.onUserLocation(position: _north(i * 8.0), course: 270, speed: 8);
          compass.emit(90); // the disturbed compass
          async.elapse(const Duration(milliseconds: 100));
        }

        expect(c.usingCourse, isTrue);
        final bearings = applied.map((a) => a.bearing).whereType<double>();
        expect(_diff(bearings.last, 270), lessThan(5));
        c.dispose();
      });
    });
  });

  group('calibration hint', () {
    test(
      'inaccurate readings for a few seconds raise the flag, good ones clear it',
      () {
        fakeAsync((async) {
          final (c, _) = create(async);
          var notified = 0;
          c.addListener(() => notified++);
          c.start();
          notified = 0;

          compass.emit(90, accuracy: 15);
          compass.emit(95, accuracy: 45);
          async.elapse(const Duration(seconds: 2));
          expect(c.compassUnreliable, isFalse);

          compass.emit(95, accuracy: 45);
          async.elapse(const Duration(seconds: 2));
          expect(c.compassUnreliable, isTrue);
          expect(notified, 1);

          compass.emit(95, accuracy: 15);
          async.elapse(const Duration(milliseconds: 200));
          expect(c.compassUnreliable, isFalse);
          expect(notified, 2);
          c.dispose();
        });
      },
    );
  });

  group('the user turns the map by hand', () {
    FollowHeadingController following(FakeAsync async) {
      final (c, _) = create(async);
      c.onUserLocation(position: _home);
      c.start();
      compass.emit(90);
      async.elapse(const Duration(seconds: 1)); // commanded bearing ~90
      return c;
    }

    test(
      'a bearing far from the commanded one for a second ends following',
      () {
        fakeAsync((async) {
          final c = following(async);
          c.onCameraBearing(200);
          async.elapse(const Duration(milliseconds: 600));
          c.onCameraBearing(200);
          expect(c.following, isTrue);
          async.elapse(const Duration(milliseconds: 500));
          c.onCameraBearing(200);
          expect(c.following, isFalse);
          c.dispose();
        });
      },
    );

    test('a short deviation (the map is still animating) does not', () {
      fakeAsync((async) {
        final c = following(async);
        c.onCameraBearing(200);
        async.elapse(const Duration(milliseconds: 300));
        c.onCameraBearing(92); // arrived
        async.elapse(const Duration(seconds: 2));
        c.onCameraBearing(92);
        expect(c.following, isTrue);
        c.dispose();
      });
    });

    test('small differences are ignored', () {
      fakeAsync((async) {
        final c = following(async);
        for (var i = 0; i < 40; i++) {
          c.onCameraBearing(110); // 20 degrees off, under the tolerance
          async.elapse(const Duration(milliseconds: 100));
        }
        expect(c.following, isTrue);
        c.dispose();
      });
    });

    test('while touching the map it is not judged', () {
      fakeAsync((async) {
        final c = following(async);
        c.setTouching(true);
        for (var i = 0; i < 30; i++) {
          c.onCameraBearing(200);
          async.elapse(const Duration(milliseconds: 100));
        }
        expect(c.following, isTrue);
        c.dispose();
      });
    });

    test('ignored when not following', () {
      fakeAsync((async) {
        final (c, _) = create(async);
        c.onCameraBearing(200);
        async.elapse(const Duration(seconds: 3));
        c.onCameraBearing(200);
        expect(c.following, isFalse);
        c.dispose();
      });
    });
  });
}
