import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../data/services/location_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../domain/models/location/location_fix.dart';
import '../../../domain/models/route/route_maneuver.dart';
import '../../../domain/models/route/route_plan.dart';
import '../../../domain/navigation/announcer.dart';
import '../../../domain/navigation/route_progress.dart';

/// Turn-by-turn state for one navigation session along a fixed [RoutePlan].
///
/// Feeds GPS fixes through [RouteProgress] (snapping them to the route) and
/// [Announcer] (deciding what to say), and exposes what the screen shows:
/// the upcoming maneuver, the distance to it, and where the dot and camera
/// should be. There is no re-routing: leaving the route just stops progress
/// until the rider is back on it.
class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({
    required this.plan,
    required this._locationService,
    required this._speechService,
  }) : _progress = RouteProgress(plan.path),
       _maneuvers = plan.maneuvers {
    final progress = _progress;
    _maneuverDistances = [
      for (final m in _maneuvers)
        progress.cumulative[m.beginShapeIndex.clamp(
          0,
          progress.path.length - 1,
        )],
    ];
    _announcer = Announcer(
      maneuvers: _maneuvers,
      maneuverDistances: _maneuverDistances,
      language: plan.language,
    );
  }

  final RoutePlan plan;
  final LocationService _locationService;
  final SpeechService _speechService;
  final _log = Logger('NavigationViewModel');

  final RouteProgress _progress;
  final List<RouteManeuver> _maneuvers;
  late final List<double> _maneuverDistances;
  late final Announcer _announcer;

  StreamSubscription<LocationFix>? _subscription;

  /// Within this distance of the route line the dot is drawn snapped to the
  /// line; further away it follows the raw GPS position instead.
  static const snapToRouteMeters = 50.0;

  /// The rider counts as arrived this close to the end of the route.
  static const arrivalMeters = 25.0;

  /// A maneuver counts as reached this close to its position.
  static const _reachedMeters = 5.0;

  LocationFix? _fix;
  ProgressSnapshot? _snapshot;
  bool _arrived = false;
  Object? _locationError;

  /// The latest raw GPS fix, or `null` before the first one.
  LocationFix? get fix => _fix;

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

  bool get arrived => _arrived;

  /// Set when the position stream failed (permission revoked, GPS off).
  Object? get locationError => _locationError;

  /// The next maneuver the rider has to perform, or `null` before the first
  /// fix.
  RouteManeuver? get upcoming {
    final index = _upcomingIndex;
    return index == null ? null : _maneuvers[index];
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
    final snapshot = _progress.update(fix.position);
    _snapshot = snapshot;

    final utterance = _announcer.update(
      alongMeters: snapshot.alongMeters,
      speedMps: fix.speedMps,
    );
    if (utterance != null) {
      unawaited(_speechService.speak(utterance.text, language: plan.language));
    }

    if (snapshot.remainingMeters <= arrivalMeters) {
      _arrived = true;
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
    notifyListeners();
  }

  /// Stops guidance: no more fixes, and any phrase being spoken is cut off.
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await _speechService.stop();
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}
