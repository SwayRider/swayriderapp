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
  );

  /// Valhalla `ManeuverType` values that represent the start / end of the
  /// route rather than a turn.
  bool get isStart => type >= 1 && type <= 3;
  bool get isArrival => type >= 4 && type <= 6;
}
