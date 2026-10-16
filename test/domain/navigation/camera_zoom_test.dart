import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/navigation/camera_zoom.dart';

void main() {
  group('cruiseZoom', () {
    test('is 16.5 in town and 14.5 at motorway speed', () {
      expect(CameraZoom.cruiseZoom(0), 16.5);
      expect(CameraZoom.cruiseZoom(8), 16.5);
      expect(CameraZoom.cruiseZoom(30), 14.5);
      expect(CameraZoom.cruiseZoom(50), 14.5);
    });

    test('falls linearly in between', () {
      expect(CameraZoom.cruiseZoom(19), closeTo(15.5, 1e-9));
    });
  });

  group('target', () {
    double target(double speed, double? distance) =>
        CameraZoom.target(speedMps: speed, distanceToManeuverMeters: distance);

    test('is the cruise zoom without a maneuver or far from it', () {
      expect(target(19, null), closeTo(15.5, 1e-9));
      expect(target(19, 400), closeTo(15.5, 1e-9));
      expect(target(19, 5000), closeTo(15.5, 1e-9));
    });

    test('reaches the turn zoom 100 m before the maneuver and stays there', () {
      expect(target(19, 100), CameraZoom.turnZoom);
      expect(target(19, 0), CameraZoom.turnZoom);
      expect(target(30, 50), CameraZoom.turnZoom);
    });

    test('zooms in monotonically while approaching', () {
      var previous = target(19, 400);
      for (var d = 380.0; d >= 100; d -= 20) {
        final zoom = target(19, d);
        expect(zoom, greaterThanOrEqualTo(previous));
        previous = zoom;
      }
      expect(target(19, 250), inExclusiveRange(15.5, CameraZoom.turnZoom));
    });

    test('never goes below the cruise zoom', () {
      for (var speed = 0.0; speed <= 40; speed += 5) {
        for (var d = 0.0; d <= 600; d += 50) {
          expect(
            target(speed, d),
            greaterThanOrEqualTo(CameraZoom.cruiseZoom(speed)),
          );
        }
      }
    });
  });
}
