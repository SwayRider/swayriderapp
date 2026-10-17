import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter/material.dart' show Icons;

/// One drawn element of a maneuver icon, in a 64 x 64 box (y points down).
///
/// A glyph is composed of a few kinds of parts: the *route* (what the rider
/// does, drawn bold with an arrowhead at the end) and the *roads* around it
/// (drawn light, never with an arrowhead).
sealed class GlyphPart {
  const GlyphPart();
}

/// A polyline. With [arrow] the last point is the tip of an arrowhead.
class GlyphLine extends GlyphPart {
  const GlyphLine(
    this.points, {
    this.route = false,
    this.arrow = false,
    this.smallHead = false,
  });

  final List<Offset> points;
  final bool route;
  final bool arrow;

  /// A smaller arrowhead, for icons that are drawn tightly (roundabouts).
  final bool smallHead;
}

/// A circular arc; angles in radians as on a canvas (0 = east, increasing
/// clockwise on screen).
class GlyphArc extends GlyphPart {
  const GlyphArc(
    this.center,
    this.radius,
    this.startAngle,
    this.sweep, {
    this.route = false,
  });

  final Offset center;
  final double radius;
  final double startAngle;
  final double sweep;
  final bool route;
}

/// A light ring (the island of a roundabout).
class GlyphRing extends GlyphPart {
  const GlyphRing(this.center, this.radius);

  final Offset center;
  final double radius;
}

/// A filled dot.
class GlyphDot extends GlyphPart {
  const GlyphDot(this.at);

  final Offset at;
}

/// A flag on a pole standing on [base]; the pennant points sideways by
/// [pennantDx] (negative = to the left).
class GlyphFlag extends GlyphPart {
  const GlyphFlag(this.base, {this.pennantDx = 16});

  final Offset base;
  final double pennantDx;
}

/// What to draw for a maneuver: [parts], or a Material [fallback] icon for
/// types that have no drawing of their own (ferries, unknown types).
class GlyphSpec {
  const GlyphSpec(this.parts) : fallback = null;
  const GlyphSpec.fallback(this.fallback) : parts = const [];

  final List<GlyphPart> parts;
  final IconData? fallback;
}

const double glyphBox = 64;

const _centerX = 32.0;
const _bottom = 60.0;

/// Builds the icon for a Valhalla `ManeuverType` ([type], see
/// `router.proto`).
///
/// [exitNumber] is the roundabout exit that is taken (1 = first). The
/// router does not say how many exits a roundabout has, so a generic layout
/// is drawn: at least four spokes, the exits before ours and the filler
/// after it in a light shade. [drivesOnRight] decides which way round the
/// roundabout is taken: counter-clockwise, first exit on the right, where
/// people drive on the right, mirrored where they drive on the left.
GlyphSpec buildGlyph(int type, {int? exitNumber, bool drivesOnRight = true}) {
  switch (type) {
    case 1 || 2 || 3:
      return _spec(_start());
    case 4:
      return _spec(_destination(0));
    case 5:
      return _spec(_destination(1));
    case 6:
      return _spec(_destination(-1));
    case 7 || 8 || 17 || 22:
      return _spec(_straight());
    case 9:
      return _spec(_turn(45));
    case 10:
      return _spec(_turn(90));
    case 11:
      return _spec(_turn(135));
    case 12:
      return _spec(_uTurn());
    case 13:
      return _spec(_mirror(_uTurn()));
    case 14:
      return _spec(_mirror(_turn(135)));
    case 15:
      return _spec(_mirror(_turn(90)));
    case 16:
      return _spec(_mirror(_turn(45)));
    case 18 || 20:
      return _spec(_branch(40));
    case 19 || 21:
      return _spec(_mirror(_branch(40)));
    case 23:
      return _spec(_branch(25));
    case 24:
      return _spec(_mirror(_branch(25)));
    case 25:
      // The ramp joins from the side of the road that is driven on.
      return _spec(
        drivesOnRight ? _mergeFromRight() : _mirror(_mergeFromRight()),
      );
    case 37:
      return _spec(_mirror(_mergeFromRight()));
    case 38:
      return _spec(_mergeFromRight());
    case 26 || 27:
      final parts = _roundabout(exitNumber ?? 2);
      return _spec(drivesOnRight ? parts : _mirror(parts));
    case 28 || 29:
      return const GlyphSpec.fallback(Icons.directions_boat);
    default:
      return const GlyphSpec.fallback(Icons.navigation);
  }
}

GlyphSpec _spec(List<GlyphPart> parts) => GlyphSpec(parts);

Offset _along(Offset from, double degrees, double length) {
  final a = degrees * math.pi / 180;
  return Offset(from.dx + length * math.sin(a), from.dy - length * math.cos(a));
}

List<GlyphPart> _straight() => const [
  GlyphLine(
    [Offset(_centerX, _bottom), Offset(_centerX, 6)],
    route: true,
    arrow: true,
  ),
];

List<GlyphPart> _start() => const [
  GlyphDot(Offset(_centerX, 56)),
  GlyphLine(
    [Offset(_centerX, 56), Offset(_centerX, 6)],
    route: true,
    arrow: true,
  ),
];

/// A turn to the right by [degrees] (45 slight, 90 normal, 135 sharp). The
/// road straight ahead, and for real turns the opposite side road, are shown
/// light.
List<GlyphPart> _turn(double degrees) {
  const x = 26.0;
  final junction = Offset(x, degrees > 100 ? 26 : 34);
  final tip = _along(junction, degrees, 30);
  return [
    GlyphLine([junction, Offset(x, 6)]),
    if (degrees >= 90) GlyphLine([junction, _along(junction, -90, 22)]),
    GlyphLine([Offset(x, _bottom), junction, tip], route: true, arrow: true),
  ];
}

/// A U-turn that loops over to the right.
List<GlyphPart> _uTurn() => [
  const GlyphLine([Offset(16, _bottom), Offset(16, 26)], route: true),
  GlyphArc(const Offset(28, 26), 12, math.pi, math.pi, route: true),
  const GlyphLine([Offset(40, 26), Offset(40, 54)], route: true, arrow: true),
];

/// An exit, ramp or stay to the right, [degrees] off the road. The road that
/// continues straight is light and has no arrowhead; only the way to take
/// has one.
List<GlyphPart> _branch(double degrees) {
  const x = 28.0;
  const junction = Offset(x, 38);
  return [
    const GlyphLine([junction, Offset(x, 6)]),
    GlyphLine(
      [const Offset(x, _bottom), junction, _along(junction, degrees, 36)],
      route: true,
      arrow: true,
    ),
  ];
}

/// Merging onto a road to the left: the ramp comes from the right, the road
/// it joins is light.
List<GlyphPart> _mergeFromRight() => const [
  GlyphLine([Offset(_centerX - 6, _bottom), Offset(_centerX - 6, 6)]),
  GlyphLine(
    [
      Offset(50, _bottom),
      Offset(50, 50),
      Offset(_centerX - 6, 32),
      Offset(_centerX - 6, 6),
    ],
    route: true,
    arrow: true,
  ),
];

/// Arrival: straight on is `0`, the destination on the right `1`, on the
/// left `-1`.
List<GlyphPart> _destination(int side) {
  if (side == 0) {
    return const [
      GlyphLine([Offset(_centerX, _bottom), Offset(_centerX, 36)], route: true),
      GlyphFlag(Offset(_centerX, 36)),
    ];
  }
  const x = 24.0;
  final parts = <GlyphPart>[
    const GlyphLine([Offset(x, _bottom), Offset(x, 6)]),
    const GlyphLine([
      Offset(x, _bottom),
      Offset(x, 42),
      Offset(38, 42),
    ], route: true),
    const GlyphFlag(Offset(42, 46)),
  ];
  return side > 0 ? parts : _mirror(parts);
}

/// A roundabout entered from the bottom and left by exit [exit], drawn for
/// traffic that circulates counter-clockwise (first exit on the right).
List<GlyphPart> _roundabout(int exit) {
  const center = Offset(_centerX, 29);
  const radius = 11.0;
  final k = math.max(1, exit);
  final spokes = math.max(4, k + 1);
  final step = 2 * math.pi / spokes;
  // Angles on a canvas: the entry is at the bottom (pi / 2); going
  // counter-clockwise on screen means decreasing angles.
  Offset onCircle(double angle, double r) =>
      center + Offset(math.cos(angle), math.sin(angle)) * r;

  final parts = <GlyphPart>[const GlyphRing(center, radius)];
  for (var i = 1; i < spokes; i++) {
    if (i == k) continue;
    final angle = math.pi / 2 - i * step;
    parts.add(
      GlyphLine([onCircle(angle, radius), onCircle(angle, radius + 13)]),
    );
  }
  final exitAngle = math.pi / 2 - k * step;
  parts
    ..add(GlyphArc(center, radius, math.pi / 2, -k * step, route: true))
    ..add(
      GlyphLine(
        [onCircle(exitAngle, radius), onCircle(exitAngle, radius + 17)],
        route: true,
        arrow: true,
        smallHead: true,
      ),
    )
    ..add(
      const GlyphLine([
        Offset(_centerX, _bottom),
        Offset(_centerX, 40),
      ], route: true),
    );
  return parts;
}

/// The mirror image (left <-> right) of [parts].
List<GlyphPart> _mirror(List<GlyphPart> parts) {
  Offset flip(Offset o) => Offset(glyphBox - o.dx, o.dy);
  return [
    for (final part in parts)
      switch (part) {
        GlyphLine() => GlyphLine(
          [for (final p in part.points) flip(p)],
          route: part.route,
          arrow: part.arrow,
          smallHead: part.smallHead,
        ),
        GlyphArc() => GlyphArc(
          flip(part.center),
          part.radius,
          math.pi - part.startAngle,
          -part.sweep,
          route: part.route,
        ),
        GlyphRing() => GlyphRing(flip(part.center), part.radius),
        GlyphDot() => GlyphDot(flip(part.at)),
        GlyphFlag() => GlyphFlag(flip(part.base), pennantDx: -part.pennantDx),
      },
  ];
}
