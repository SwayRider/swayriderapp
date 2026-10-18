import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../data/repositories/router/router_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../domain/models/location/location_fix.dart';
import '../../../domain/models/route/rejoin.dart';
import '../../../domain/models/route/route_maneuver.dart';
import '../../../domain/models/route/route_plan.dart';
import '../../../domain/models/route/route_request_spec.dart';
import '../../../domain/models/route/route_lane.dart';
import '../../../domain/navigation/announcer.dart';
import '../../../domain/navigation/geo.dart';
import '../../../domain/navigation/off_route_detector.dart';
import '../../../domain/navigation/prompt_phrases.dart';
import '../../../domain/navigation/rejoin_planner.dart';
import '../../../domain/navigation/rejoin_stitcher.dart';
import '../../../utils/result.dart';
import '../../../domain/navigation/prompt_queue.dart';
import '../../../domain/navigation/camera_zoom.dart';
import '../../../domain/navigation/route_progress.dart';
import '../../../domain/navigation/route_time.dart';

/// How the search for the way back onto the route is going.
enum RerouteStatus {
  /// On the route, or off it but not yet asking for a way back.
  idle,

  /// A way back has been asked for.
  pending,

  /// The last attempt failed; a new one follows after a pause.
  failed,
}

/// Turn-by-turn state for one navigation session along a [RoutePlan].
///
/// Feeds GPS fixes through [RouteProgress] (snapping them to the route) and
/// [Announcer] (deciding what to say), and exposes what the screen shows:
/// the upcoming maneuver, the distance to it, and where the dot and camera
/// should be.
///
/// When the rider leaves the route (see [OffRouteDetector]) and a
/// [RouterRepository] is given, the way back is asked for from the server:
/// usually a short connector to a point further along the original route,
/// which is glued to the rest of the route, or else a fresh route. Until it
/// arrives the old route stays; [routeVersion] changes when the plan is
/// replaced.
class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({
    required RoutePlan plan,
    required this._locationService,
    required this._speechService,
    this._routerRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _plan = plan,
       _progress = RouteProgress(plan.path),
       _maneuvers = plan.maneuvers {
    _maneuverDistances = _distancesOf(_maneuvers, _progress);
    _announcer = Announcer(
      maneuvers: _maneuvers,
      maneuverDistances: _maneuverDistances,
      language: plan.language,
    );
    _prompts = PromptQueue(speech: _speechService, language: plan.language);
  }

  RoutePlan _plan;
  final LocationService _locationService;
  final SpeechService _speechService;
  final RouterRepository? _routerRepository;
  final DateTime Function() _clock;
  final _log = Logger('NavigationViewModel');

  RouteProgress _progress;
  List<RouteManeuver> _maneuvers;
  late List<double> _maneuverDistances;
  late Announcer _announcer;
  late final PromptQueue _prompts;

  // Getting back onto the route.
  final _detector = OffRouteDetector();
  final _planner = const RejoinPlanner();
  RerouteStatus _rerouteStatus = RerouteStatus.idle;
  int _routeVersion = 0;
  int _requestSerial = 0;
  int _failures = 0;
  DateTime? _retryAt;
  bool _recalculatingAnnounced = false;
  double? _leftRouteAlong;

  /// Areas suspected to be closed, from earlier deviations (newest last);
  /// they are avoided by every later way back.
  final _exclusions = <List<LatLng>>[];

  /// Where the rider left the route before, to spot the same place again.
  final _deviations = <LatLng>[];

  static const _maxExclusions = 5;
  static const _sameDeviationMeters = 200.0;
  static const _retryDelays = [10, 20, 40];

  /// The route being followed. Replaced when a way back is found; see
  /// [routeVersion].
  RoutePlan get plan => _plan;

  /// Changes whenever [plan] is replaced, so the screen can redraw it.
  int get routeVersion => _routeVersion;

  RerouteStatus get rerouteStatus => _rerouteStatus;

  static List<double> _distancesOf(
    List<RouteManeuver> maneuvers,
    RouteProgress progress,
  ) => [
    for (final m in maneuvers)
      progress.cumulative[m.beginShapeIndex.clamp(0, progress.path.length - 1)],
  ];

  StreamSubscription<LocationFix>? _subscription;

  /// Within this distance of the route line the dot is drawn snapped to the
  /// line; further away it follows the raw GPS position instead.
  static const snapToRouteMeters = 50.0;

  /// The rider counts as arrived this close to the end of the route.
  static const arrivalMeters = 25.0;

  /// The lane strip appears this far before a maneuver (1 km before a
  /// motorway exit, which is taken at speed).
  static const laneGuidanceMeters = 400.0;
  static const laneGuidanceHighwayMeters = 1000.0;

  /// A maneuver counts as reached this close to its position.
  static const _reachedMeters = 5.0;

  LocationFix? _fix;
  ProgressSnapshot? _snapshot;
  bool _arrived = false;
  double? _displaySpeedMps;

  /// Weight of the newest fix in the displayed speed.
  static const _displaySpeedSmoothing = 0.3;
  final _cameraZoom = CameraZoom();
  double _targetZoom = CameraZoom.slowZoom;
  Object? _locationError;

  /// The latest raw GPS fix, or `null` before the first one.
  LocationFix? get fix => _fix;

  /// Ground speed for display in km/h: a running average over the last few
  /// fixes (raw GPS speed jitters by several km/h), rounded. Below 2 km/h
  /// counts as standing still, as GPS speed creeps around zero.
  int get speedKmh {
    final kmh = (_displaySpeedMps ?? 0) * 3.6;
    return kmh < 2 ? 0 : kmh.round();
  }

  /// Where the dot should be drawn, or `null` before the first fix.
  LatLng? get dotPosition {
    final snapshot = _snapshot;
    final fix = _fix;
    if (snapshot == null || fix == null) return null;
    return snapshot.offRouteMeters <= snapToRouteMeters
        ? snapshot.snapped
        : fix.position;
  }

  /// Direction of the route ahead, for rotating the camera; `null` before
  /// the first fix.
  double? get routeBearing => _snapshot?.bearing;

  bool get offRoute => (_snapshot?.offRouteMeters ?? 0) > snapToRouteMeters;

  double get remainingMeters =>
      _snapshot?.remainingMeters ?? plan.distanceMeters;

  /// Travel time still to go, from the router's estimate for the stretches
  /// ahead.
  Duration get remainingTime {
    if (_arrived) return Duration.zero;
    final seconds = remainingSeconds(
      maneuvers: _maneuvers,
      maneuverDistances: _maneuverDistances,
      alongMeters: _snapshot?.alongMeters ?? 0,
      totalSeconds: plan.durationSeconds,
      totalMeters: _progress.totalMeters,
    );
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// When the rider is expected to arrive, if they keep to the router's
  /// pace.
  DateTime get eta => _clock().add(remainingTime);

  bool get arrived => _arrived;

  /// Set when the position stream failed (permission revoked, GPS off).
  Object? get locationError => _locationError;

  /// The next maneuver the rider has to perform, or `null` before the first
  /// fix.
  RouteManeuver? get upcoming {
    final index = _upcomingIndex;
    return index == null ? null : _maneuvers[index];
  }

  /// Side of the road driven on along the route.
  bool get drivesOnRight => plan.drivesOnRight;

  /// Lanes to show for [upcoming]: only when the road data says which lanes
  /// to use, and only once the maneuver is near enough (earlier for
  /// motorway exits, which are taken at speed).
  List<RouteLane> get laneGuidance {
    final maneuver = upcoming;
    final distance = distanceToUpcomingMeters;
    if (maneuver == null || distance == null) return const [];
    if (!maneuver.lanes.any((lane) => lane.isActive)) return const [];
    final limit = maneuver.isHighwayType
        ? laneGuidanceHighwayMeters
        : laneGuidanceMeters;
    return distance <= limit ? maneuver.lanes : const [];
  }

  /// Distance to [upcoming] along the route, in meters.
  double? get distanceToUpcomingMeters {
    final index = _upcomingIndex;
    final snapshot = _snapshot;
    if (index == null || snapshot == null) return null;
    return (_maneuverDistances[index] - snapshot.alongMeters).clamp(
      0.0,
      double.infinity,
    );
  }

  /// The zoom the camera should head for: one of a few fixed levels by
  /// speed, and in close to the upcoming maneuver (see [CameraZoom]).
  double get targetZoom => _targetZoom;

  int? get _upcomingIndex {
    final snapshot = _snapshot;
    if (snapshot == null || _maneuvers.isEmpty) return null;
    for (var i = 0; i < _maneuvers.length; i++) {
      if (_maneuvers[i].isStart) continue;
      if (_maneuverDistances[i] - snapshot.alongMeters > _reachedMeters) {
        return i;
      }
    }
    return _maneuvers.length - 1;
  }

  /// Starts listening to GPS fixes.
  void start() {
    _subscription ??= _locationService.positions().listen(
      _onFix,
      onError: (Object error) {
        _log.warning('Location stream failed: $error');
        _locationError = error;
        notifyListeners();
      },
    );
  }

  void _onFix(LocationFix fix) {
    if (_arrived) return;
    _locationError = null;
    _fix = fix;
    final shown = _displaySpeedMps;
    _displaySpeedMps = shown == null
        ? fix.speedMps
        : shown + (fix.speedMps - shown) * _displaySpeedSmoothing;
    final snapshot = _progress.update(fix.position);
    _snapshot = snapshot;
    _watchRoute(fix, snapshot);

    _targetZoom = _cameraZoom.update(
      speedMps: fix.speedMps,
      distanceToManeuverMeters: distanceToUpcomingMeters,
    );

    _prompts.update(snapshot.alongMeters);
    _prompts.add(
      _announcer.update(
        alongMeters: snapshot.alongMeters,
        speedMps: fix.speedMps,
      ),
    );

    if (snapshot.remainingMeters <= arrivalMeters) {
      _arrived = true;
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
    notifyListeners();
  }

  /// Follows whether the rider is on the route and, once clearly off it, asks
  /// for the way back.
  void _watchRoute(LocationFix fix, ProgressSnapshot snapshot) {
    final state = _detector.update(
      offRouteMeters: snapshot.offRouteMeters,
      accuracyMeters: fix.accuracyMeters,
      now: _clock(),
    );
    switch (state) {
      case OffRouteState.onRoute:
        if (snapshot.offRouteMeters <= snapToRouteMeters) {
          _leftRouteAlong = snapshot.alongMeters;
        }
        // Back on the route (or never left it): any pending answer is moot.
        if (_rerouteStatus != RerouteStatus.idle) {
          _requestSerial++;
          _rerouteStatus = RerouteStatus.idle;
        }
        _failures = 0;
        _retryAt = null;
        _recalculatingAnnounced = false;
      case OffRouteState.suspect:
        break;
      case OffRouteState.off:
        _askForWayBack(fix, snapshot);
    }
  }

  void _askForWayBack(LocationFix fix, ProgressSnapshot snapshot) {
    final router = _routerRepository;
    if (router == null || _rerouteStatus == RerouteStatus.pending) return;
    final retryAt = _retryAt;
    if (retryAt != null && _clock().isBefore(retryAt)) return;

    // The same place again: the closure is probably longer than guessed.
    final leftAlong = _leftRouteAlong;
    var corridorLength = RejoinPlanner.corridorLengthMeters;
    LatLng? leftAt;
    if (leftAlong != null) {
      leftAt = _progress.pointAt(leftAlong);
      if (_deviations.any(
        (d) => distanceMeters(d, leftAt!) < _sameDeviationMeters,
      )) {
        corridorLength *= 2;
      }
    }

    final rejoin = _planner.plan(
      route: _plan,
      progress: _progress,
      maneuverDistances: _maneuverDistances,
      fix: fix,
      alongMeters: snapshot.alongMeters,
      leftRouteAlongMeters: leftAlong,
      corridorLength: corridorLength,
      earlierExclusions: _exclusions,
    );

    final serial = ++_requestSerial;
    _rerouteStatus = RerouteStatus.pending;
    if (!_recalculatingAnnounced) {
      _recalculatingAnnounced = true;
      _prompts.add([Utterance(recalculatingPhrase(_plan.language))]);
    }
    _log.info(
      'Off route (${snapshot.offRouteMeters.round()} m): asking for the way '
      'back, ${rejoin.request.points.length} rejoin points, heading '
      '${rejoin.request.heading}',
    );
    unawaited(
      router.rejoin(rejoin.request).then((result) {
        if (serial != _requestSerial) return; // outdated: the rider moved on
        switch (result) {
          case Ok<RejoinResult>():
            if (leftAt != null) _deviations.add(leftAt);
            _applyWayBack(rejoin, result.value);
          case Error<RejoinResult>():
            _log.warning('No way back: ${result.error}');
            _failures++;
            final delay =
                _retryDelays[(_failures - 1).clamp(0, _retryDelays.length - 1)];
            _retryAt = _clock().add(Duration(seconds: delay));
            _rerouteStatus = RerouteStatus.failed;
            notifyListeners();
        }
      }),
    );
    notifyListeners();
  }

  /// Replaces the route by the way back the server found.
  void _applyWayBack(RejoinPlan asked, RejoinResult result) {
    final request = asked.request;
    final spec = RouteRequestSpec(
      points: [request.from, ...asked.remainingStops],
      language: request.language,
    );
    final RoutePlan next;
    if (result.kind == RejoinKind.rejoin &&
        result.rejoinIndex < request.points.length) {
      final point = request.points[result.rejoinIndex];
      next = stitchRejoin(
        original: _plan,
        progress: _progress,
        connector: result.plan,
        rejoinAlongMeters: point.alongMeters,
        remainingSeconds: point.remainingSeconds,
      ).withRequest(spec);
    } else {
      next = result.plan.withRequest(spec);
    }
    if (asked.corridor.isNotEmpty) {
      _exclusions.add(asked.corridor);
      if (_exclusions.length > _maxExclusions) _exclusions.removeAt(0);
    }
    _log.info(
      'Way back found (${result.kind.name}): ${next.maneuvers.length} '
      'maneuvers, ${next.distanceMeters.round()} m',
    );
    _replacePlan(next);
  }

  /// Switches to [next]: new progress tracking, new prompts (the departure
  /// is not announced again), and a new [routeVersion].
  void _replacePlan(RoutePlan next) {
    _plan = next;
    _progress = RouteProgress(next.path);
    _maneuvers = next.maneuvers;
    _maneuverDistances = _distancesOf(_maneuvers, _progress);
    _announcer = Announcer(
      maneuvers: _maneuvers,
      maneuverDistances: _maneuverDistances,
      language: next.language,
      speakDeparture: false,
    );
    _prompts.clear();
    _detector.reset();
    _leftRouteAlong = null;
    _rerouteStatus = RerouteStatus.idle;
    _failures = 0;
    _retryAt = null;
    _recalculatingAnnounced = false;
    _routeVersion++;

    final fix = _fix;
    if (fix != null) {
      final snapshot = _progress.update(fix.position);
      _snapshot = snapshot;
      _prompts.update(snapshot.alongMeters);
      _prompts.add(
        _announcer.update(
          alongMeters: snapshot.alongMeters,
          speedMps: fix.speedMps,
        ),
      );
    } else {
      _snapshot = null;
    }
    notifyListeners();
  }

  /// Stops guidance: no more fixes, and any phrase being spoken is cut off.
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await _prompts.stop();
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}
