import 'package:flutter/material.dart';

/// The icon for a Valhalla `ManeuverType` (see `router.proto`).
IconData maneuverIcon(int type) => switch (type) {
  1 || 8 || 7 || 22 || 17 => Icons.straight,
  2 || 20 || 23 => Icons.fork_right,
  3 || 21 || 24 => Icons.fork_left,
  4 || 5 || 6 => Icons.flag,
  9 => Icons.turn_slight_right,
  10 => Icons.turn_right,
  11 => Icons.turn_sharp_right,
  12 => Icons.u_turn_right,
  13 => Icons.u_turn_left,
  14 => Icons.turn_sharp_left,
  15 => Icons.turn_left,
  16 => Icons.turn_slight_left,
  18 => Icons.ramp_right,
  19 => Icons.ramp_left,
  25 || 37 || 38 => Icons.merge,
  26 || 27 => Icons.roundabout_right,
  28 || 29 => Icons.directions_boat,
  _ => Icons.navigation,
};
