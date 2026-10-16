import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../view_models/compass_state.dart';

/// Compass on the map. The needle always points to north: it is rotated by the
/// opposite of the map's [bearing], so it turns when the user rotates the map
/// and when the map follows the device heading. An orange ring shows that the
/// map is following the heading.
///
/// A tap does [CompassState.actionFor] the current [mode].
class CompassButton extends StatelessWidget {
  const CompassButton({
    super.key,
    required this.bearing,
    required this.mode,
    required this.onPressed,
    this.size = 48.0,
  });

  /// The map's bearing in degrees, clockwise from north.
  final double bearing;
  final CompassMode mode;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final label = switch (mode) {
      CompassMode.northUp => localization.compassFollowHeading,
      CompassMode.following => localization.compassFollowingHeading,
      CompassMode.free => localization.compassPointNorth,
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: CircleBorder(
          side: mode == CompassMode.following
              ? const BorderSide(color: AppColors.apexOrange, width: 2.5)
              : BorderSide.none,
        ),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Transform.rotate(
              angle: -bearing * math.pi / 180,
              child: CustomPaint(painter: _NeedlePainter()),
            ),
          ),
        ),
      ),
    );
  }
}

/// A diamond needle: the north half orange, the south half grey.
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final halfWidth = size.width * 0.14;
    final halfHeight = size.height * 0.30;

    final north = Path()
      ..moveTo(c.dx, c.dy - halfHeight)
      ..lineTo(c.dx + halfWidth, c.dy)
      ..lineTo(c.dx - halfWidth, c.dy)
      ..close();
    final south = Path()
      ..moveTo(c.dx, c.dy + halfHeight)
      ..lineTo(c.dx + halfWidth, c.dy)
      ..lineTo(c.dx - halfWidth, c.dy)
      ..close();

    canvas.drawPath(south, Paint()..color = AppColors.grey3);
    canvas.drawPath(north, Paint()..color = AppColors.apexOrange);
    canvas.drawCircle(c, size.width * 0.04, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) => false;
}
