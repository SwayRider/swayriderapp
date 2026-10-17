/// One lane of the road at a maneuver, as reported by Valhalla.
///
/// [directions] is a bitmask of the directions the lane's markings allow;
/// [active] is the subset that leads along the route (set only on lanes the
/// rider should use). Bit values follow Valhalla's `turnlanes.h`.
class RouteLane {
  const RouteLane({required this.directions, this.valid, this.active});

  static const none = 1;
  static const through = 2;
  static const sharpLeft = 4;
  static const left = 8;
  static const slightLeft = 16;
  static const slightRight = 32;
  static const right = 64;
  static const sharpRight = 128;
  static const reverse = 256;
  static const mergeToLeft = 512;
  static const mergeToRight = 1024;

  final int directions;
  final int? valid;
  final int? active;

  /// Whether the rider should use this lane.
  bool get isActive => (active ?? 0) != 0 || (valid ?? 0) != 0;

  /// The direction to draw: the active one when there is one, else the
  /// first marking of the lane. Returns [none] for unmarked lanes.
  int get primaryDirection {
    final source = (active ?? 0) != 0
        ? active!
        : (valid ?? 0) != 0
        ? valid!
        : directions;
    const order = [
      through,
      slightLeft,
      left,
      sharpLeft,
      slightRight,
      right,
      sharpRight,
      reverse,
      mergeToLeft,
      mergeToRight,
    ];
    for (final bit in order) {
      if (source & bit != 0) return bit;
    }
    return none;
  }
}
