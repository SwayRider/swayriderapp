import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/navigation/camera_zoom.dart';

double kmh(double v) => v / 3.6;

void main() {
  late CameraZoom zoom;

  setUp(() => zoom = CameraZoom());

  /// Feeds [fixes] of the same speed and returns the last zoom.
  double settle(double speedKmh, {double? distance, int fixes = 20}) {
    var result = 0.0;
    for (var i = 0; i < fixes; i++) {
      result = zoom.update(
        speedMps: kmh(speedKmh),
        distanceToManeuverMeters: distance,
      );
    }
    return result;
  }

  test('picks a zoom level per speed band', () {
    expect(settle(20), CameraZoom.slowZoom);
    expect(
      CameraZoom().update(speedMps: kmh(75), distanceToManeuverMeters: null),
      CameraZoom.mediumZoom,
    );
    expect(
      CameraZoom().update(speedMps: kmh(100), distanceToManeuverMeters: null),
      CameraZoom.fastZoom,
    );
    expect(
      CameraZoom().update(speedMps: kmh(120), distanceToManeuverMeters: null),
      CameraZoom.motorwayZoom,
    );
  });

  test('the motorway zoom is the furthest out and zooms in for a turn', () {
    expect(CameraZoom.motorwayZoom, lessThan(CameraZoom.fastZoom));
    expect(settle(120), CameraZoom.motorwayZoom);
    expect(settle(120, distance: 250), CameraZoom.turnZoom);
    expect(settle(120, distance: 900), CameraZoom.motorwayZoom);
  });

  test('hysteresis: 105 km/h does not leave or enter the motorway zoom', () {
    settle(120);
    // 98 and 112 km/h average out around the 100 / 110 km/h edges.
    final levels = <double>{};
    for (var i = 0; i < 40; i++) {
      levels.add(
        zoom.update(
          speedMps: kmh(i.isEven ? 112 : 102),
          distanceToManeuverMeters: null,
        ),
      );
    }
    expect(levels, {CameraZoom.motorwayZoom});
    expect(settle(95), CameraZoom.fastZoom);
  });

  test('zooms in on a maneuver within 300 m, out of it beyond', () {
    expect(settle(75, distance: 301), CameraZoom.mediumZoom);
    expect(settle(75, distance: 300), CameraZoom.turnZoom);
    expect(settle(75, distance: 40), CameraZoom.turnZoom);
    expect(settle(75, distance: 900), CameraZoom.mediumZoom);
  });

  test('speed noise around a cruising speed never changes the zoom', () {
    final levels = <double>{};
    // 75 km/h +- 12 km/h of GPS speed noise, 200 fixes.
    for (var i = 0; i < 200; i++) {
      final noise = (i.isEven ? 1 : -1) * (i % 5) * 3.0;
      levels.add(
        zoom.update(speedMps: kmh(75 + noise), distanceToManeuverMeters: null),
      );
    }
    expect(levels, {CameraZoom.mediumZoom});
  });

  test('hysteresis: hovering around a band edge does not flip the zoom', () {
    settle(60); // medium band
    // 49 and 51 km/h straddle the 50 km/h edge between slow and medium.
    final levels = <double>{};
    for (var i = 0; i < 40; i++) {
      levels.add(
        zoom.update(
          speedMps: kmh(i.isEven ? 49 : 41),
          distanceToManeuverMeters: null,
        ),
      );
    }
    expect(levels, {CameraZoom.mediumZoom});
  });

  test('steps back in only once clearly below the lower edge', () {
    settle(75);
    expect(settle(45), CameraZoom.mediumZoom);
    expect(settle(30), CameraZoom.slowZoom);
  });

  test('a single outlier fix is averaged out', () {
    settle(30);
    // One spurious 80 km/h fix after a long run at 30 km/h.
    expect(
      zoom.update(speedMps: kmh(80), distanceToManeuverMeters: null),
      CameraZoom.slowZoom,
    );
  });
}
