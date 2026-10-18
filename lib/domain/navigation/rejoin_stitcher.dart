import '../models/route/route_maneuver.dart';
import '../models/route/route_plan.dart';
import 'geo.dart';
import 'route_progress.dart';

/// Glues the way back onto the original route: the [connector] (from the
/// rider to the rejoin point) followed by the original route from
/// [rejoinAlongMeters] on, so the maneuvers, lanes and speech after the
/// rejoin point stay exactly as planned.
///
/// The connector's own start and arrival maneuvers are dropped (there is no
/// stop to announce), and so is the "continue for ..." phrase of its last
/// maneuver, which would be wrong once the route goes on. Original maneuvers
/// that begin before the rejoin point are dropped too.
///
/// [progress] belongs to [original]; [remainingSeconds] is the travel time
/// left on the original route after the rejoin point.
RoutePlan stitchRejoin({
  required RoutePlan original,
  required RouteProgress progress,
  required RoutePlan connector,
  required double rejoinAlongMeters,
  required double remainingSeconds,
}) {
  final cumulative = progress.cumulative;
  final lastIndex = original.path.length - 1;

  // The original route continues at the first vertex after the rejoin
  // point.
  var segment = 0;
  for (var i = 0; i < lastIndex; i++) {
    if (cumulative[i] <= rejoinAlongMeters) segment = i;
  }
  var resume = segment + 1;
  if (connector.path.isNotEmpty &&
      resume < original.path.length &&
      distanceMeters(connector.path.last, original.path[resume]) < 3) {
    resume++;
  }
  resume = resume.clamp(0, original.path.length);

  final path = [...connector.path, ...original.path.skip(resume)];
  final offset = connector.path.length - resume;

  final connectorManeuvers = [
    for (final m in connector.maneuvers)
      if (!m.isStart && !m.isArrival) m,
  ];
  if (connectorManeuvers.isNotEmpty) {
    connectorManeuvers[connectorManeuvers.length - 1] = connectorManeuvers.last
        .withoutPost();
  }
  final rest = <RouteManeuver>[
    for (final m in original.maneuvers)
      if (m.beginShapeIndex >= resume) m.shifted(offset),
  ];

  return RoutePlan(
    path: path,
    maneuvers: [...connectorManeuvers, ...rest],
    distanceMeters:
        connector.distanceMeters +
        (progress.totalMeters - rejoinAlongMeters).clamp(0.0, double.infinity),
    durationSeconds: connector.durationSeconds + remainingSeconds,
    language: original.language,
    drivesOnRight: original.drivesOnRight,
    request: original.request,
  );
}
