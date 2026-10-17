import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/navigation/widgets/maneuver_glyph.dart';

List<GlyphLine> lines(GlyphSpec spec) =>
    spec.parts.whereType<GlyphLine>().toList();

GlyphLine arrow(GlyphSpec spec) =>
    lines(spec).singleWhere((line) => line.arrow);

void main() {
  group('exits and stays', () {
    for (final entry in {20: 1, 18: 1, 23: 1, 21: -1, 19: -1, 24: -1}.entries) {
      test('type ${entry.key} has a single arrow, on the branch', () {
        final spec = buildGlyph(entry.key);
        final branch = arrow(spec);
        expect(branch.route, isTrue);
        // The branch ends on the side of the exit.
        final stem = branch.points.first.dx;
        expect((branch.points.last.dx - stem).sign, entry.value);

        // The road that continues straight is light, goes up and has no
        // arrowhead.
        final continuing = lines(spec).where((l) => !l.route).single;
        expect(continuing.arrow, isFalse);
        expect(continuing.points.last.dx, continuing.points.first.dx);
        expect(continuing.points.last.dy, lessThan(continuing.points.first.dy));
      });
    }
  });

  test('no glyph has an arrow on a road, or more than one arrow', () {
    for (var type = 0; type <= 40; type++) {
      for (final right in [true, false]) {
        final spec = buildGlyph(type, exitNumber: 2, drivesOnRight: right);
        final arrows = lines(spec).where((l) => l.arrow);
        expect(arrows.length, lessThanOrEqualTo(1), reason: 'type $type');
        expect(arrows.every((l) => l.route), isTrue, reason: 'type $type');
      }
    }
  });

  group('roundabouts', () {
    Offset tip(int exit, {bool right = true}) => arrow(
      buildGlyph(26, exitNumber: exit, drivesOnRight: right),
    ).points.last;

    test('right-hand traffic: exit 1 right, 2 straight, 3 left', () {
      expect(tip(1).dx, greaterThan(glyphBox / 2 + 15));
      expect(tip(2).dx, closeTo(glyphBox / 2, 0.01));
      expect(tip(2).dy, lessThan(10));
      expect(tip(3).dx, lessThan(glyphBox / 2 - 15));
    });

    test('left-hand traffic mirrors them: exit 1 left, 3 right', () {
      expect(tip(1, right: false).dx, lessThan(glyphBox / 2 - 15));
      expect(tip(2, right: false).dx, closeTo(glyphBox / 2, 0.01));
      expect(tip(3, right: false).dx, greaterThan(glyphBox / 2 + 15));
    });

    test('the route goes round counter-clockwise for right-hand traffic', () {
      final arc = buildGlyph(
        26,
        exitNumber: 3,
      ).parts.whereType<GlyphArc>().single;
      expect(arc.startAngle, closeTo(math.pi / 2, 1e-9)); // the entry
      expect(arc.sweep, lessThan(0)); // decreasing angle = counter-clockwise
      final left = buildGlyph(
        26,
        exitNumber: 3,
        drivesOnRight: false,
      ).parts.whereType<GlyphArc>().single;
      expect(left.sweep, greaterThan(0));
    });

    test('the layout has at least four spokes, more for later exits', () {
      int fillers(int exit) =>
          lines(buildGlyph(26, exitNumber: exit)).where((l) => !l.route).length;
      // Spokes other than the entry and our exit.
      expect(fillers(1), 2);
      expect(fillers(3), 2);
      expect(fillers(5), 4);
    });

    test('leaving the roundabout (27) is drawn like entering it', () {
      expect(
        buildGlyph(27, exitNumber: 3).parts.length,
        buildGlyph(26, exitNumber: 3).parts.length,
      );
    });
  });

  group('turns', () {
    test('right turns end on the right, left turns on the left', () {
      for (final type in [9, 10, 11]) {
        final route = arrow(buildGlyph(type));
        expect(route.points.last.dx, greaterThan(route.points.first.dx));
      }
      for (final type in [14, 15, 16]) {
        final route = arrow(buildGlyph(type));
        expect(route.points.last.dx, lessThan(route.points.first.dx));
      }
    });

    test('a sharp turn points back down, a slight one stays upward', () {
      expect(
        arrow(buildGlyph(11)).points.last.dy,
        greaterThan(arrow(buildGlyph(11)).points[1].dy),
      );
      expect(
        arrow(buildGlyph(9)).points.last.dy,
        lessThan(arrow(buildGlyph(9)).points[1].dy),
      );
    });
  });

  test('a merge joins from the side that is driven on', () {
    double start(bool right) =>
        arrow(buildGlyph(25, drivesOnRight: right)).points.first.dx;
    expect(start(true), greaterThan(glyphBox / 2));
    expect(start(false), lessThan(glyphBox / 2));
  });

  test('ferries and unknown types fall back to Material icons', () {
    expect(buildGlyph(28).fallback, Icons.directions_boat);
    expect(buildGlyph(29).fallback, Icons.directions_boat);
    expect(buildGlyph(999).fallback, Icons.navigation);
    expect(buildGlyph(10).fallback, isNull);
  });

  test('every route type from 1 to 38 builds without throwing', () {
    for (var type = 1; type <= 38; type++) {
      expect(() => buildGlyph(type, exitNumber: 1), returnsNormally);
    }
  });
}
