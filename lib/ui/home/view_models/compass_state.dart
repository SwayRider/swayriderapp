/// How the map is oriented, as the compass button sees it.
enum CompassMode {
  /// North is up and the map does not follow the device.
  northUp,

  /// The map follows the device's compass heading (and the user's position).
  following,

  /// Rotated by hand (or any other bearing), not following.
  free,
}

/// What a tap on the compass button does.
enum CompassAction { pointNorth, followHeading }

/// The compass button's rules, kept free of any map code so they can be tested.
///
/// A tap cycles: free or following → north up → following → north up …
class CompassState {
  const CompassState._();

  /// A bearing this close to 0 counts as north up.
  static const northToleranceDegrees = 1.0;

  /// Folds a bearing (clockwise degrees from north, possibly 360 or negative)
  /// into (-180, 180].
  static double normalizeBearing(double bearing) {
    final b = bearing % 360;
    return b > 180 ? b - 360 : b;
  }

  static CompassMode modeFor({
    required double bearing,
    required bool following,
  }) {
    if (following) return CompassMode.following;
    return normalizeBearing(bearing).abs() <= northToleranceDegrees
        ? CompassMode.northUp
        : CompassMode.free;
  }

  static CompassAction actionFor(CompassMode mode) =>
      mode == CompassMode.northUp
      ? CompassAction.followHeading
      : CompassAction.pointNorth;
}
