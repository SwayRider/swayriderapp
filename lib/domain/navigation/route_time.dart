import '../models/route/route_maneuver.dart';

/// Seconds still to travel when the rider is [alongMeters] along the route.
///
/// Valhalla gives every maneuver the travel time of the stretch that follows
/// it, so this is the unfinished part of the current stretch plus all the
/// stretches after it. Without such times it falls back to the route's total
/// time, spread evenly over its length.
double remainingSeconds({
  required List<RouteManeuver> maneuvers,
  required List<double> maneuverDistances,
  required double alongMeters,
  required double totalSeconds,
  required double totalMeters,
}) {
  final along = alongMeters.clamp(0.0, totalMeters);
  final summed = maneuvers.fold<double>(0, (sum, m) => sum + m.timeSeconds);
  if (summed <= 0) {
    return totalMeters <= 0
        ? 0
        : totalSeconds * (totalMeters - along) / totalMeters;
  }

  var current = -1;
  for (var i = 0; i < maneuvers.length; i++) {
    if (maneuverDistances[i] <= along) current = i;
  }
  if (current < 0) return summed;

  var remaining = 0.0;
  for (var j = current + 1; j < maneuvers.length; j++) {
    remaining += maneuvers[j].timeSeconds;
  }
  final end = current + 1 < maneuvers.length
      ? maneuverDistances[current + 1]
      : totalMeters;
  final length = end - maneuverDistances[current];
  final left = length <= 0 ? 0.0 : ((end - along) / length).clamp(0.0, 1.0);
  return remaining + maneuvers[current].timeSeconds * left;
}
