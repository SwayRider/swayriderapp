import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/navigation/widgets/maneuver_icon.dart';

void main() {
  testWidgets('roads that cross are not brighter where they overlap', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            // A roundabout with exits to the north and the east (taken).
            child: const ManeuverIcon(
              type: 26,
              exitNumber: 2,
              exitAngles: [0, 90],
              size: 64,
            ),
          ),
        ),
      ),
    );

    late final ByteData pixels;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      pixels = (await image.toByteData())!;
    });

    int alphaAt(int x, int y) => pixels.getUint8((y * 64 + x) * 4 + 3);

    // The west side of the ring: a road on its own.
    final ring = alphaAt(19, 29);
    // The north spoke, away from the ring: a road on its own.
    final spoke = alphaAt(32, 9);
    // Where the north spoke meets the ring: both roads.
    final crossing = alphaAt(32, 16);

    expect(ring, greaterThan(0));
    expect(spoke, closeTo(ring, 2));
    expect(crossing, closeTo(ring, 2));
  });
}
