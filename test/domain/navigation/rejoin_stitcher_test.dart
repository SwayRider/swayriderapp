import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/domain/navigation/geo.dart';
import 'package:swayriderapp/domain/navigation/rejoin_stitcher.dart';
import 'package:swayriderapp/domain/navigation/route_progress.dart';

List<LatLng> northRoad() => [
  for (var i = 0; i <= 60; i++) LatLng(51.0 + i * 0.0009, 4.0),
];

RouteManeuver maneuver(
  int type,
  int index, {
  double seconds = 0,
  String? post,
  String text = '',
}) => RouteManeuver(
  type: type,
  instruction: text,
  beginShapeIndex: index,
  endShapeIndex: index,
  timeSeconds: seconds,
  verbalPre: text,
  verbalPost: post,
);

void main() {
  final original = RoutePlan(
    path: northRoad(),
    language: 'nl-NL',
    drivesOnRight: false,
    distanceMeters: 6004,
    durationSeconds: 360,
    maneuvers: [
      maneuver(2, 0, post: 'start post', text: 'Drive north'),
      maneuver(10, 30, post: 'turn post', text: 'Turn right'),
      maneuver(4, 60, text: 'Arrive'),
    ],
  );
  final progress = RouteProgress(original.path);

  /// A connector from beside the road (start) to the road at 1500 m, with a
  /// right turn halfway.
  RoutePlan connector({LatLng? end}) => RoutePlan(
    path: [
      const LatLng(51.0100, 4.0010),
      const LatLng(51.0120, 4.0010),
      const LatLng(51.0125, 4.0005),
      end ?? const LatLng(51.0135, 4.0), // 1500 m along the road
    ],
    distanceMeters: 300,
    durationSeconds: 30,
    maneuvers: [
      maneuver(2, 0, post: 'connector start', text: 'Head north'),
      maneuver(15, 2, post: 'connector post', text: 'Turn left onto A'),
      maneuver(4, 3, text: 'Arrived'),
    ],
  );

  RoutePlan stitch({RoutePlan? with_}) => stitchRejoin(
    original: original,
    progress: progress,
    connector: with_ ?? connector(),
    rejoinAlongMeters: 1500,
    remainingSeconds: 270,
  );

  test('the path is the connector followed by the rest of the route', () {
    final plan = stitch();

    // 4 connector points, then the original from the vertex after 1500 m.
    final resume = plan.path.indexOf(original.path[16]);
    expect(resume, 4);
    expect(plan.path.last, original.path.last);
    expect(plan.path.length, 4 + (61 - 16));
    // Continuous: no jump at the join.
    expect(distanceMeters(plan.path[3], plan.path[4]), lessThan(110));
  });

  test('the maneuvers are the connector turns and the rest of the route', () {
    final plan = stitch();
    final texts = plan.maneuvers.map((m) => m.instruction).toList();

    // The connector's start and arrival are gone.
    expect(texts, ['Turn left onto A', 'Turn right', 'Arrive']);
  });

  test('the original maneuvers keep pointing at the same places', () {
    final plan = stitch();
    final turn = plan.maneuvers[1];
    final arrival = plan.maneuvers[2];

    expect(plan.path[turn.beginShapeIndex], original.path[30]);
    expect(plan.path[arrival.beginShapeIndex], original.path[60]);
    expect(turn.endShapeIndex, turn.beginShapeIndex);
    for (final m in plan.maneuvers) {
      expect(m.beginShapeIndex, lessThan(plan.path.length));
    }
  });

  test('the last connector maneuver loses its "continue for" phrase', () {
    final plan = stitch();
    expect(plan.maneuvers[0].verbalPost, isNull);
    // The original ones keep theirs.
    expect(plan.maneuvers[1].verbalPost, 'turn post');
  });

  test(
    'a maneuver of the original route before the rejoin point is dropped',
    () {
      final plan = stitch();
      expect(
        plan.maneuvers.any((m) => m.instruction == 'Drive north'),
        isFalse,
      );
    },
  );

  test('distance and time add up', () {
    final plan = stitch();
    expect(
      plan.distanceMeters,
      closeTo(300 + (progress.totalMeters - 1500), 1),
    );
    expect(plan.durationSeconds, 300);
  });

  test('language and driving side come from the original route', () {
    final plan = stitch();
    expect(plan.language, 'nl-NL');
    expect(plan.drivesOnRight, isFalse);
  });

  test('a connector that ends on a vertex does not repeat it', () {
    final plan = stitch(with_: connector(end: original.path[15]));
    // original[15] is the connector's last point; the route resumes after it.
    final occurrences = plan.path.where((p) => p == original.path[15]).length;
    expect(occurrences, 1);
  });

  test('a connector without turns leaves only the original maneuvers', () {
    final straight = RoutePlan(
      path: [const LatLng(51.0120, 4.0001), const LatLng(51.0135, 4.0)],
      distanceMeters: 150,
      durationSeconds: 10,
      maneuvers: [maneuver(2, 0), maneuver(4, 1)],
    );
    final plan = stitch(with_: straight);
    expect(plan.maneuvers.map((m) => m.instruction), ['Turn right', 'Arrive']);
  });
}
