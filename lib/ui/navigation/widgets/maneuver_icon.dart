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
    this.drivesOnRight = true,
    this.size = 56,
    this.routeColor = AppColors.apexOrange,
    this.roadColor = const Color(0x59FFFFFF),
  });

  /// Valhalla maneuver type.
  final int type;

  /// The roundabout exit to take (1 = first), for types 26 and 27.
  final int? exitNumber;
  final bool drivesOnRight;
  final double size;
  final Color routeColor;
  final Color roadColor;

  @override
  Widget build(BuildContext context) {
    final spec = buildGlyph(
      type,
      exitNumber: exitNumber,
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
    // Roads first, so the route is drawn on top of them.
    for (final part in parts) {
      if (!_isRoute(part)) _paintPart(canvas, part);
    }
    for (final part in parts) {
      if (_isRoute(part)) _paintPart(canvas, part);
    }
  }

  bool _isRoute(GlyphPart part) => switch (part) {
    GlyphLine() => part.route,
    GlyphArc() => part.route,
    GlyphDot() || GlyphFlag() => true,
    GlyphRing() => false,
  };

  Paint _stroke(bool route, [double width = _strokeWidth]) => Paint()
    ..color = route ? routeColor : roadColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void _paintPart(Canvas canvas, GlyphPart part) {
    switch (part) {
      case GlyphLine():
        _paintLine(canvas, part);
      case GlyphArc():
        canvas.drawArc(
          Rect.fromCircle(center: part.center, radius: part.radius),
          part.startAngle,
          part.sweep,
          false,
          _stroke(part.route),
        );
      case GlyphRing():
        canvas.drawCircle(part.center, part.radius, _stroke(false, _ringWidth));
      case GlyphDot():
        canvas.drawCircle(
          part.at,
          5,
          Paint()
            ..color = routeColor
            ..isAntiAlias = true,
        );
      case GlyphFlag():
        _paintFlag(canvas, part);
    }
  }

  void _paintLine(Canvas canvas, GlyphLine line) {
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
    canvas.drawPath(path, _stroke(line.route));
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
          ..color = line.route ? routeColor : roadColor
          ..isAntiAlias = true,
      );
    }
  }

  void _paintFlag(Canvas canvas, GlyphFlag flag) {
    final top = flag.base - const Offset(0, 30);
    canvas.drawLine(flag.base, top, _stroke(true, 5));
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + flag.pennantDx, top.dy + 8)
        ..lineTo(top.dx, top.dy + 16)
        ..close(),
      Paint()
        ..color = routeColor
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.parts != parts ||
      old.routeColor != routeColor ||
      old.roadColor != roadColor;
}
