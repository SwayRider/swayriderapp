import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/navigation/widgets/maneuver_icon.dart';

/// Review sheet of every maneuver icon on the header's dark background, row
/// by row:
///   1. start, straight, slight right, right, sharp right, u-turn right,
///      destination, destination right
///   2. start left, straight, slight left, left, sharp left, u-turn left,
///      destination left, merge (right-hand traffic)
///   3. exit right, exit left, stay right, stay left, ramp right, ramp left,
///      merge right, merge left
///   4. roundabout exits 1-5 for right-hand traffic, ferry, unknown
///   5. roundabout exits 1-5 for left-hand traffic, merge (left-hand traffic)
void main() {
  Widget cell(int type, {int? exit, bool right = true}) => Padding(
    padding: const EdgeInsets.all(8),
    child: ManeuverIcon(
      type: type,
      exitNumber: exit,
      drivesOnRight: right,
      size: 96,
    ),
  );

  testWidgets('maneuver icon sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final rows = <List<Widget>>[
      [
        cell(2),
        cell(8),
        cell(9),
        cell(10),
        cell(11),
        cell(12),
        cell(4),
        cell(5),
      ],
      [
        cell(3),
        cell(8),
        cell(16),
        cell(15),
        cell(14),
        cell(13),
        cell(6),
        cell(25),
      ],
      [
        cell(20),
        cell(21),
        cell(23),
        cell(24),
        cell(18),
        cell(19),
        cell(37),
        cell(38),
      ],
      [
        for (var exit = 1; exit <= 5; exit++) cell(26, exit: exit),
        cell(28),
        cell(999),
      ],
      [
        for (var exit = 1; exit <= 5; exit++)
          cell(26, exit: exit, right: false),
        cell(25, right: false),
      ],
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF101114),
          body: RepaintBoundary(
            child: Container(
              color: const Color(0xFF101114),
              child: Column(
                children: [for (final row in rows) Row(children: row)],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/maneuver_icons.png'),
    );
  });
}
