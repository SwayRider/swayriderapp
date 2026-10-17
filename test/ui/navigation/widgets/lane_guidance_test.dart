import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/route/route_lane.dart';
import 'package:swayriderapp/ui/navigation/widgets/lane_guidance.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<RouteLane> lanes) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LaneGuidance(lanes: lanes)),
        ),
      );

  testWidgets('shows one cell per lane and highlights the active ones', (
    tester,
  ) async {
    await pump(tester, const [
      RouteLane(directions: RouteLane.left, active: RouteLane.left),
      RouteLane(directions: RouteLane.left, active: RouteLane.left),
      RouteLane(directions: RouteLane.right),
    ]);

    expect(find.byKey(const ValueKey('lane-active')), findsNWidgets(2));
    expect(find.byKey(const ValueKey('lane-inactive')), findsOneWidget);
    expect(find.byIcon(Icons.turn_left), findsNWidgets(2));
    expect(find.byIcon(Icons.turn_right), findsOneWidget);
  });

  testWidgets('draws the active direction of a multi-purpose lane', (
    tester,
  ) async {
    await pump(tester, const [
      RouteLane(
        directions: RouteLane.through | RouteLane.slightRight,
        active: RouteLane.slightRight,
      ),
      RouteLane(directions: RouteLane.through),
    ]);

    expect(find.byIcon(Icons.turn_slight_right), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  test('primaryDirection falls back to the markings of unused lanes', () {
    expect(
      const RouteLane(directions: RouteLane.right).primaryDirection,
      RouteLane.right,
    );
    expect(const RouteLane(directions: 0).primaryDirection, RouteLane.none);
  });
}
