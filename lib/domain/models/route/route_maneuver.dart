import 'route_lane.dart';

/// One turn-by-turn step of a [RoutePlan], as produced by Valhalla.
class RouteManeuver {
  const RouteManeuver({
    required this.type,
    required this.instruction,
    required this.beginShapeIndex,
    required this.endShapeIndex,
    this.verbalAlert,
    this.verbalPre,
    this.verbalPost,
    this.streetNames = const [],
    this.lengthMeters = 0,
    this.timeSeconds = 0,
    this.roundaboutExitCount,
    this.lanes = const [],
  });

  /// Valhalla / `router.proto` `ManeuverType` value.
  final int type;
  final String instruction;

  /// Spoken well ahead of the maneuver ("In 1 kilometer, turn left").
  final String? verbalAlert;

  /// Spoken close to the maneuver ("Turn left onto Main Street").
  final String? verbalPre;

  /// Spoken after the maneuver ("Continue for 5 kilometers").
  final String? verbalPost;

  final List<String> streetNames;

  /// Length of the stretch that *follows* this maneuver, up to the next one.
  final double lengthMeters;
  final double timeSeconds;

  /// Indices into [RoutePlan.path]; the maneuver happens at
  /// [beginShapeIndex].
  final int beginShapeIndex;
  final int endShapeIndex;

  final int? roundaboutExitCount;

  /// Lane layout at the maneuver; empty when the road data has none.
  final List<RouteLane> lanes;

  RouteManeuver shifted(int offset) => RouteManeuver(
    type: type,
    instruction: instruction,
    beginShapeIndex: beginShapeIndex + offset,
    endShapeIndex: endShapeIndex + offset,
    verbalAlert: verbalAlert,
    verbalPre: verbalPre,
    verbalPost: verbalPost,
    streetNames: streetNames,
    lengthMeters: lengthMeters,
    timeSeconds: timeSeconds,
    roundaboutExitCount: roundaboutExitCount,
    lanes: lanes,
  );

  /// Valhalla `ManeuverType` values that represent the start / end of the
  /// route rather than a turn.
  /// A copy without the phrase spoken after the maneuver ("continue for 5
  /// kilometers"), for a maneuver whose stretch has been cut short.
  RouteManeuver withoutPost() => RouteManeuver(
    type: type,
    instruction: instruction,
    beginShapeIndex: beginShapeIndex,
    endShapeIndex: endShapeIndex,
    verbalAlert: verbalAlert,
    verbalPre: verbalPre,
    streetNames: streetNames,
    lengthMeters: lengthMeters,
    timeSeconds: timeSeconds,
    roundaboutExitCount: roundaboutExitCount,
    lanes: lanes,
  );

  /// A copy that names the roundabout exit it belongs to.
  RouteManeuver withRoundaboutExit(int exit) => RouteManeuver(
    type: type,
    instruction: instruction,
    beginShapeIndex: beginShapeIndex,
    endShapeIndex: endShapeIndex,
    verbalAlert: verbalAlert,
    verbalPre: verbalPre,
    verbalPost: verbalPost,
    streetNames: streetNames,
    lengthMeters: lengthMeters,
    timeSeconds: timeSeconds,
    roundaboutExitCount: exit,
    lanes: lanes,
  );

  /// Ramps, exits, stay left / right and merges (types 17..25): decisions
  /// that are taken at motorway speed and need an early warning.
  bool get isHighwayType => type >= 17 && type <= 25;

  bool get isStart => type >= 1 && type <= 3;
  bool get isArrival => type >= 4 && type <= 6;
}
