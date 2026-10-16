import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/ambient_light_service.dart';

/// Stands in for the plugin: every call to [open] is one sensor/camera session.
class _FakeSensor {
  final sessions = <StreamController<double>>[];

  Stream<double> open() {
    final controller = StreamController<double>();
    sessions.add(controller);
    return controller.stream;
  }

  StreamController<double> get current => sessions.last;

  /// Sessions that are still running (someone is listening).
  int get running => sessions.where((c) => c.hasListener).length;
}

AmbientLightServicePlugin _ios(_FakeSensor sensor) => AmbientLightServicePlugin(
  openSensor: sensor.open,
  isIos: true,
  iosInterval: const Duration(seconds: 15),
  iosSettleFrames: 2,
  iosSampleFrames: 3,
  iosSampleTimeout: const Duration(seconds: 6),
);

void main() {
  group('Android', () {
    test('streams the sensor values as they are, in lux', () {
      fakeAsync((async) {
        final sensor = _FakeSensor();
        final service = AmbientLightServicePlugin(
          openSensor: sensor.open,
          isIos: false,
        );
        expect(service.needsExplicitOptIn, isFalse);

        final readings = <double>[];
        final sub = service.lux.listen(readings.add);
        sensor.current
          ..add(5)
          ..add(120.5);
        async.elapse(const Duration(milliseconds: 10));
        expect(readings, [5, 120.5]);

        sub.cancel();
        async.elapse(const Duration(milliseconds: 10));
        expect(sensor.running, 0, reason: 'cancelling stops the sensor');
      });
    });

    test('a missing sensor arrives as a stream error', () {
      fakeAsync((async) {
        final sensor = _FakeSensor();
        final service = AmbientLightServicePlugin(
          openSensor: sensor.open,
          isIos: false,
        );
        final errors = <Object>[];
        service.lux.listen((_) {}, onError: errors.add);
        sensor.current.addError('NO_SENSOR');
        async.elapse(const Duration(milliseconds: 10));
        expect(errors, ['NO_SENSOR']);
      });
    });
  });

  group('iOS', () {
    test('needs the explicit opt-in (camera)', () {
      expect(_ios(_FakeSensor()).needsExplicitOptIn, isTrue);
    });

    test(
      'drops the settling frames and reports the median of the next ones',
      () {
        fakeAsync((async) {
          final sensor = _FakeSensor();
          final readings = <double>[];
          _ios(sensor).lux.listen(readings.add);
          async.elapse(const Duration(milliseconds: 10));

          expect(
            sensor.sessions,
            hasLength(1),
            reason: 'a burst starts at once',
          );
          // two settling frames (way off), then three real ones
          for (final bv in [12.0, 11.0, 3.0, 1.0, 2.0]) {
            sensor.current.add(bv);
          }
          async.elapse(const Duration(milliseconds: 10));

          expect(readings, hasLength(1));
          expect(readings.single, closeTo(128, 0.001)); // median Bv 2 -> 2^7
          expect(sensor.running, 0, reason: 'the camera is off between bursts');
        });
      },
    );

    test('takes a new burst every interval and never keeps the camera on', () {
      fakeAsync((async) {
        final sensor = _FakeSensor();
        final readings = <double>[];
        _ios(sensor).lux.listen(readings.add);
        async.elapse(const Duration(milliseconds: 10));

        void burst(double bv) {
          for (var i = 0; i < 5; i++) {
            sensor.current.add(bv);
          }
          async.elapse(const Duration(milliseconds: 10));
        }

        burst(0);
        async.elapse(const Duration(seconds: 15));
        expect(sensor.sessions, hasLength(2));
        burst(4);
        async.elapse(const Duration(seconds: 15));
        expect(sensor.sessions, hasLength(3));

        expect(readings, hasLength(2));
        expect(readings[0], closeTo(32, 0.001));
        expect(readings[1], closeTo(512, 0.001));
        expect(sensor.running, 1, reason: 'only the burst in progress');
      });
    });

    test(
      'a burst without frames times out as an error and stops the camera',
      () {
        fakeAsync((async) {
          final sensor = _FakeSensor();
          final errors = <Object>[];
          _ios(sensor).lux.listen((_) {}, onError: errors.add);
          async.elapse(const Duration(milliseconds: 10));

          async.elapse(const Duration(seconds: 7));

          expect(errors.single, isA<TimeoutException>());
          expect(sensor.running, 0);
          // and the next burst still happens
          async.elapse(const Duration(seconds: 10));
          expect(sensor.sessions, hasLength(2));
        });
      },
    );

    test(
      'a camera error (e.g. permission denied) arrives as a stream error',
      () {
        fakeAsync((async) {
          final sensor = _FakeSensor();
          final errors = <Object>[];
          _ios(sensor).lux.listen((_) {}, onError: errors.add);
          async.elapse(const Duration(milliseconds: 10));

          sensor.current.addError('INPUT_ERROR');
          async.elapse(const Duration(milliseconds: 10));

          expect(errors, ['INPUT_ERROR']);
          expect(sensor.running, 0);
        });
      },
    );

    test('cancelling the subscription stops the bursts', () {
      fakeAsync((async) {
        final sensor = _FakeSensor();
        final sub = _ios(sensor).lux.listen((_) {});
        async.elapse(const Duration(milliseconds: 10));
        sub.cancel();
        async.elapse(const Duration(milliseconds: 10));

        async.elapse(const Duration(minutes: 2));

        expect(sensor.sessions, hasLength(1));
        expect(sensor.running, 0);
      });
    });
  });

  test('luxFromApexBrightness: 2^(Bv+5)', () {
    expect(
      AmbientLightServicePlugin.luxFromApexBrightness(3),
      closeTo(256, 1e-9),
    );
    expect(
      AmbientLightServicePlugin.luxFromApexBrightness(-1),
      closeTo(16, 1e-9),
    );
    expect(
      AmbientLightServicePlugin.luxFromApexBrightness(-5),
      closeTo(1, 1e-9),
    );
  });
}
