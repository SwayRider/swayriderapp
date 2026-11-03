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

    group('with the arms of the roundabout', () {
      GlyphSpec armed(
        int exit, {
        List<int> exits = const [90, 0, 270],
        bool right = true,
      }) => buildGlyph(
        26,
        exitNumber: exit,
        exitAngles: exits,
        drivesOnRight: right,
      );

      List<GlyphLine> spokes(GlyphSpec spec) =>
          lines(spec).where((l) => !l.route).toList();

      test('draws one spoke per exit, the exit taken is the arrow', () {
        for (final exits in [
          [90, 0, 270],
          [90, 30, 0, 300, 250],
          [100, 50, 10, 330, 290, 260],
        ]) {
          final spec = armed(exits.length, exits: exits);
          expect(spokes(spec).length, exits.length - 1, reason: '$exits');
          expect(arrow(spec).route, isTrue);
        }
      });

      test('a five exit roundabout has five exits, not the generic four', () {
        expect(spokes(armed(5, exits: [90, 30, 0, 300, 250])).length, 4);
        expect(spokes(armed(2, exits: [90, 250])).length, 1);
        expect(spokes(armed(1, exits: [90, 30, 0, 300, 250])).length, 4);
      });

      test('the spokes point where the roads are', () {
        // 90 degrees clockwise from straight on is to the right, 270 to the left.
        expect(arrow(armed(1)).points.last.dx, greaterThan(glyphBox / 2 + 15));
        expect(arrow(armed(3)).points.last.dx, lessThan(glyphBox / 2 - 15));
        final up = arrow(armed(2));
        expect(up.points.last.dx, closeTo(glyphBox / 2, 0.01));
        expect(up.points.last.dy, lessThan(10));
      });

      test('uneven angles are kept, not spread evenly', () {
        // Spokes 100 and 30 degrees clockwise of straight on, exit 3 taken.
        final dxs = spokes(
          armed(3, exits: [100, 30, 270]),
        ).map((l) => l.points.last.dx).toList()..sort();
        const reach = 24.0;
        expect(
          dxs[0],
          closeTo(glyphBox / 2 + reach * math.sin(30 * math.pi / 180), 0.5),
        );
        expect(
          dxs[1],
          closeTo(glyphBox / 2 + reach * math.sin(100 * math.pi / 180), 0.5),
        );
      });

      test('spokes closer than 22.5 degrees are pushed apart when drawn', () {
        // 357 and 11 degrees: the 11 degree spoke moves to about 19.5.
        final spec = armed(5, exits: [91, 11, 357, 276, 260]);
        double degrees(Offset tip) {
          final d = tip - const Offset(glyphBox / 2, 29);
          return (math.atan2(d.dx, -d.dy) * 180 / math.pi + 360) % 360;
        }

        final angles = spokes(spec).map((l) => degrees(l.points.last)).toList()
          ..sort();
        for (var i = 1; i < angles.length; i++) {
          expect(angles[i] - angles[i - 1], greaterThanOrEqualTo(22.4));
        }
        // Including 357 and 19.5 degrees, which are either side of straight on.
        expect(angles.first + 360 - angles.last, greaterThanOrEqualTo(22.4));
        // The arrow is the exit taken, 260 degrees, and stays where it is.
        expect(degrees(arrow(spec).points.last), closeTo(260, 0.5));
      });

      test(
        'right-hand traffic goes counter-clockwise, left-hand clockwise',
        () {
          expect(
            armed(3).parts.whereType<GlyphArc>().single.sweep,
            lessThan(0),
          );
          expect(
            armed(
              1,
              exits: [270, 0, 90],
              right: false,
            ).parts.whereType<GlyphArc>().single.sweep,
            greaterThan(0),
          );
        },
      );

      test('left-hand traffic uses the angles as they are', () {
        // Exit 1 is on the left, as the real road is.
        final tip = arrow(
          armed(1, exits: [270, 0, 90], right: false),
        ).points.last;
        expect(tip.dx, lessThan(glyphBox / 2 - 15));
      });

      test(
        'an exit number outside the arms falls back to the generic icon',
        () {
          final generic = buildGlyph(26, exitNumber: 6).parts.length;
          expect(armed(6).parts.length, generic);
          expect(
            armed(0).parts.length,
            buildGlyph(26, exitNumber: 0).parts.length,
          );
          expect(
            buildGlyph(26, exitNumber: 2, exitAngles: [90, 400]).parts.length,
            buildGlyph(26, exitNumber: 2).parts.length,
          );
        },
      );

      test('no arms draws exactly what it did before', () {
        for (final exit in [1, 2, 3, 5]) {
          final plain = buildGlyph(26, exitNumber: exit);
          final empty = buildGlyph(26, exitNumber: exit, exitAngles: const []);
          expect(empty.parts.length, plain.parts.length);
          expect(arrow(empty).points.last, arrow(plain).points.last);
        }
      });

      test('leaving the roundabout (27) uses the same arms', () {
        expect(
          buildGlyph(27, exitNumber: 3, exitAngles: [90, 0, 270]).parts.length,
          armed(3).parts.length,
        );
      });
    });

    test('leaving the roundabout (27) is drawn like entering it', () {
      expect(
        buildGlyph(27, exitNumber: 3).parts.length,
        buildGlyph(26, exitNumber: 3).parts.length,
      );
    });
  });

  group('spreading the exits of a roundabout', () {
    void expectAngles(List<double> got, List<double> want) {
      expect(got.length, want.length);
      for (var i = 0; i < want.length; i++) {
        expect(got[i], closeTo(want[i], 0.01), reason: 'exit ${i + 1}: $got');
      }
    }

    test('exits that are far enough apart do not move', () {
      expectAngles(spreadRoundaboutExits([90, 0, 270]), [90, 0, 270]);
    });

    test('the one that is too close is pushed away from the next one', () {
      // Right-hand: the exits are passed 91, 11, 357, 276, 260. 11 and 357 are
      // 14 degrees apart, as are 276 and 260: the earlier one moves.
      expectAngles(spreadRoundaboutExits([91, 11, 357, 276, 260]), [
        91,
        19.5,
        357,
        282.5,
        260,
      ]);
    });

    test('a crowd is pushed apart one after the other', () {
      // 80, 70 and 60 degrees are 10 apart: each moves 22.5 from the next.
      expectAngles(spreadRoundaboutExits([80, 70, 60]), [105, 82.5, 60]);
    });

    test('with no room at all they are spread evenly, between neighbours', () {
      // 16 exits cannot be 22.5 degrees apart.
      final out = spreadRoundaboutExits([for (var i = 0; i < 16; i++) 100 - i]);
      for (var i = 1; i < out.length; i++) {
        expect(
          (out[i - 1] - out[i] + 360) % 360,
          closeTo(360 / 17, 0.01),
          reason: 'exit $i of $out',
        );
      }
    });

    test('whatever the exits, the order is kept and the spacing is met', () {
      var seed = 7;
      int next(int max) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return seed % max;
      }

      for (var round = 0; round < 500; round++) {
        final n = 1 + next(8);
        final right = next(2) == 0;
        final keys = <int>{};
        while (keys.length < n) {
          keys.add(next(360));
        }
        final angles = [
          for (final k in (keys.toList()..sort()))
            right ? (180 - k + 360) % 360 : (k + 180) % 360,
        ];
        final out = spreadRoundaboutExits(angles, drivesOnRight: right);
        final placed = [
          for (final a in out)
            right ? (180 - a + 360) % 360 : (a - 180 + 360) % 360,
        ];
        final all = [0.0, ...placed, 360.0];
        for (var i = 1; i < all.length; i++) {
          expect(
            all[i] - all[i - 1],
            greaterThanOrEqualTo(22.5 - 1e-6),
            reason: '$angles gave $out',
          );
        }
      }
    });

    test('keeps away from the road the roundabout was entered from', () {
      expectAngles(spreadRoundaboutExits([170]), [157.5]);
      expectAngles(spreadRoundaboutExits([190]), [202.5]);
    });

    test('left-hand traffic mirrors right-hand traffic', () {
      expectAngles(
        spreadRoundaboutExits([269, 349, 3, 84, 100], drivesOnRight: false),
        [269, 340.5, 3, 77.5, 100],
      );
    });

    test('the order of the exits never changes', () {
      for (final exits in [
        [80, 70, 60, 50, 40],
        [91, 11, 357, 276, 260],
        [10, 5, 0, 355, 350],
      ]) {
        final out = spreadRoundaboutExits(exits);
        // Position along the roundabout for right-hand traffic.
        final keys = [for (final a in out) (180 - a + 360) % 360];
        for (var i = 1; i < keys.length; i++) {
          expect(keys[i], greaterThanOrEqualTo(keys[i - 1]), reason: '$exits');
        }
      }
    });

    test('angles that are not in the order they are passed are left alone', () {
      expectAngles(spreadRoundaboutExits([0, 90, 270]), [0, 90, 270]);
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
