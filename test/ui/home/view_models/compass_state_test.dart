import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/home/view_models/compass_state.dart';

void main() {
  group('normalizeBearing', () {
    test('folds into (-180, 180]', () {
      expect(CompassState.normalizeBearing(0), 0);
      expect(CompassState.normalizeBearing(90), 90);
      expect(CompassState.normalizeBearing(180), 180);
      expect(CompassState.normalizeBearing(270), -90);
      expect(CompassState.normalizeBearing(359), -1);
      expect(CompassState.normalizeBearing(360), 0);
      expect(CompassState.normalizeBearing(-90), -90);
      expect(CompassState.normalizeBearing(-370), -10);
      expect(CompassState.normalizeBearing(725), 5);
    });
  });

  group('modeFor', () {
    test('north up within a degree of 0, on either side and at 360', () {
      for (final bearing in [0.0, 0.4, -0.4, 1.0, -1.0, 359.5, 360.0, -360.0]) {
        expect(
          CompassState.modeFor(bearing: bearing, following: false),
          CompassMode.northUp,
          reason: '$bearing',
        );
      }
    });

    test('free when rotated by hand', () {
      for (final bearing in [1.5, -1.5, 45.0, 180.0, 270.0, 358.0]) {
        expect(
          CompassState.modeFor(bearing: bearing, following: false),
          CompassMode.free,
          reason: '$bearing',
        );
      }
    });

    test('following wins, whatever the bearing is', () {
      for (final bearing in [0.0, 90.0, 200.0]) {
        expect(
          CompassState.modeFor(bearing: bearing, following: true),
          CompassMode.following,
        );
      }
    });
  });

  group('actionFor', () {
    test('north up -> follow the heading', () {
      expect(
        CompassState.actionFor(CompassMode.northUp),
        CompassAction.followHeading,
      );
    });

    test('free or following -> point north', () {
      expect(
        CompassState.actionFor(CompassMode.free),
        CompassAction.pointNorth,
      );
      expect(
        CompassState.actionFor(CompassMode.following),
        CompassAction.pointNorth,
      );
    });
  });

  test('taps cycle: free -> north up -> following -> north up', () {
    var bearing = 120.0;
    var following = false;
    void tap() {
      final mode = CompassState.modeFor(bearing: bearing, following: following);
      switch (CompassState.actionFor(mode)) {
        case CompassAction.pointNorth:
          bearing = 0;
          following = false;
        case CompassAction.followHeading:
          following = true;
          bearing = 75; // the device heading
      }
    }

    tap();
    expect(
      CompassState.modeFor(bearing: bearing, following: following),
      CompassMode.northUp,
    );
    tap();
    expect(
      CompassState.modeFor(bearing: bearing, following: following),
      CompassMode.following,
    );
    tap();
    expect(
      CompassState.modeFor(bearing: bearing, following: following),
      CompassMode.northUp,
    );
  });
}
