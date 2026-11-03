import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import 'maneuver_glyph.dart';

/// The icon for a Valhalla `ManeuverType` (see `router.proto`), drawn from
/// the parts in [buildGlyph]: the route in [routeColor] with an arrowhead,
/// the other roads in [roadColor]. Types without a drawing of their own
/// (ferries, unknown types) show a Material icon in [routeColor].
class ManeuverIcon extends StatelessWidget {
  const ManeuverIcon({
    super.key,
    required this.type,
    this.exitNumber,
    this.exitAngles = const [],
    this.drivesOnRight = true,
    this.size = 56,
    this.routeColor = AppColors.apexOrange,
    this.roadColor = const Color(0x59FFFFFF),
  });

  /// Valhalla maneuver type.
  final int type;

  /// The roundabout exit to take (1 = first), for types 26 and 27.
  final int? exitNumber;

  /// The exits of the roundabout when the router knows them (see
  /// [RouteManeuver.roundaboutExitAngles]); empty draws a generic roundabout.
  final List<int> exitAngles;
  final bool drivesOnRight;
  final double size;
  final Color routeColor;
  final Color roadColor;

  @override
  Widget build(BuildContext context) {
    final spec = buildGlyph(
      type,
      exitNumber: exitNumber,
      exitAngles: exitAngles,
      drivesOnRight: drivesOnRight,
    );
    final fallback = spec.fallback;
    if (fallback != null) {
      return Icon(fallback, size: size, color: routeColor);
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(spec.parts, routeColor, roadColor),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.parts, this.routeColor, this.roadColor);

  final List<GlyphPart> parts;
  final Color routeColor;
  final Color roadColor;

  static const _strokeWidth = 7.0;
  static const _ringWidth = 5.0;
  static const _headLength = 14.0;
  static const _headHalfWidth = 9.0;
  static const _smallHeadLength = 11.0;
  static const _smallHeadHalfWidth = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / glyphBox, size.height / glyphBox);
    // Roads first, so the route is drawn on top of them. The roads are
    // semi-transparent, so they are drawn solid in a layer that is made
    // transparent as a whole: where roads cross, they must not add up to a
    // brighter spot.
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(0, 0, 0, roadColor.a),
    );
    final solidRoad = roadColor.withValues(alpha: 1);
    for (final part in parts) {
      if (!_isRoute(part)) _paintPart(canvas, part, solidRoad);
    }
    canvas.restore();
    for (final part in parts) {
      if (_isRoute(part)) _paintPart(canvas, part, routeColor);
    }
  }

  bool _isRoute(GlyphPart part) => switch (part) {
    GlyphLine() => part.route,
    GlyphArc() => part.route,
    GlyphDot() || GlyphFlag() => true,
    GlyphRing() => false,
  };

  Paint _stroke(Color color, [double width = _strokeWidth]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void _paintPart(Canvas canvas, GlyphPart part, Color color) {
    switch (part) {
      case GlyphLine():
        _paintLine(canvas, part, color);
      case GlyphArc():
        canvas.drawArc(
          Rect.fromCircle(center: part.center, radius: part.radius),
          part.startAngle,
          part.sweep,
          false,
          _stroke(color, part.width ?? _strokeWidth),
        );
      case GlyphRing():
        canvas.drawCircle(
          part.center,
          part.radius,
          _stroke(color, part.width ?? _ringWidth),
        );
      case GlyphDot():
        canvas.drawCircle(
          part.at,
          5,
          Paint()
            ..color = color
            ..isAntiAlias = true,
        );
      case GlyphFlag():
        _paintFlag(canvas, part, color);
    }
  }

  void _paintLine(Canvas canvas, GlyphLine line, Color color) {
    final points = [...line.points];
    final headLength = line.smallHead ? _smallHeadLength : _headLength;
    final headHalfWidth = line.smallHead ? _smallHeadHalfWidth : _headHalfWidth;
    Offset? tip;
    Offset? direction;
    if (line.arrow && points.length >= 2) {
      tip = points.last;
      final delta = tip - points[points.length - 2];
      direction = delta / delta.distance;
      // The stroke stops inside the arrowhead so it can't poke out of it.
      points[points.length - 1] = tip - direction * (headLength - 1);
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, _stroke(color, line.width ?? _strokeWidth));
    if (tip != null && direction != null) {
      final perpendicular = Offset(-direction.dy, direction.dx);
      final base = tip - direction * headLength;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            base.dx + perpendicular.dx * headHalfWidth,
            base.dy + perpendicular.dy * headHalfWidth,
          )
          ..lineTo(
            base.dx - perpendicular.dx * headHalfWidth,
            base.dy - perpendicular.dy * headHalfWidth,
          )
          ..close(),
        Paint()
          ..color = color
          ..isAntiAlias = true,
      );
    }
  }

  void _paintFlag(Canvas canvas, GlyphFlag flag, Color color) {
    final top = flag.base - const Offset(0, 30);
    canvas.drawLine(flag.base, top, _stroke(color, 5));
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + flag.pennantDx, top.dy + 8)
        ..lineTo(top.dx, top.dy + 16)
        ..close(),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.parts != parts ||
      old.routeColor != routeColor ||
      old.roadColor != roadColor;
}
