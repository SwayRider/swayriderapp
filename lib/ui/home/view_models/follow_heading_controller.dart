import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../data/services/compass_service.dart';
import 'heading_filter.dart';

/// Moves the camera: [position] to recentre on (null = keep the centre) and
/// [bearing] to rotate to (null = keep the bearing).
typedef ApplyFollowCamera = void Function(LatLng? position, double? bearing);

/// "Follow my heading": keeps the map centred on the user and rotated to the
/// direction they face - a calm direction, thanks to [HeadingFilter].
///
/// MapLibre's own compass tracking cannot be tuned (and on many phones it
/// spins), so the app drives the camera itself while following. This class is
/// map agnostic: the screen feeds it GPS fixes ([onUserLocation]), the camera's
/// bearing ([onCameraBearing]) and touches ([setTouching]) and applies what it
/// asks for through [bind]. It reads the compass from a [CompassService].
///
/// Following ends by itself when the user turns the map by hand: the camera
/// bearing stays far away from what was commanded for a second. (Dragging the
/// map is detected by the screen, see `FollowGestureDetector`, which calls
/// [stop].)
class FollowHeadingController extends ChangeNotifier {
  FollowHeadingController({
    required this._compassService,
    HeadingFilter Function(DateTime Function() clock)? filterFactory,
    this.period = const Duration(milliseconds: 100),
    this.recentreMetres = 0.5,
    this.divergence = const Duration(seconds: 1),
    this.divergenceDegrees = 25,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _filterFactory =
           filterFactory ?? ((clock) => HeadingFilter(clock: clock));

  final CompassService _compassService;
  final HeadingFilter Function(DateTime Function() clock) _filterFactory;
  final DateTime Function() _clock;
  final _log = Logger('FollowHeadingController');

  /// How often the filter is asked for a new bearing.
  final Duration period;

  /// The camera is only recentred when the user moved at least this far.
  final double recentreMetres;

  /// The user counts as having turned the map when the camera bearing stays
  /// more than [divergenceDegrees] away from the commanded one for this long.
  final Duration divergence;
  final double divergenceDegrees;

  late final HeadingFilter _filter = _filterFactory(_clock);
  ApplyFollowCamera? _apply;
  StreamSubscription<CompassReading>? _compassSub;
  Timer? _timer;

  bool _following = false;
  bool _compassUnreliable = false;
  bool _touching = false;

  LatLng? _position;
  LatLng? _appliedPosition;
  double? _commandedBearing;
  DateTime? _divergingSince;

  /// Whether the map is following the heading.
  bool get following => _following;

  /// Whether the compass has been inaccurate for a while: the user should move
  /// the phone in a figure 8 to calibrate it.
  bool get compassUnreliable => _compassUnreliable;

  /// Whether the GPS course (rather than the compass) currently drives it.
  bool get usingCourse => _filter.usingCourse;

  /// Sets what moves the camera; the screen calls this with its map controller.
  void bind(ApplyFollowCamera? apply) => _apply = apply;

  void start() {
    if (_following) return;
    _filter.reset();
    _appliedPosition = null;
    _commandedBearing = null;
    _divergingSince = null;
    _following = true;
    _compassUnreliable = false;
    _compassSub = _compassService.readings.listen(
      (r) => _filter.addCompass(r.heading, accuracy: r.accuracy),
      onError: (Object e) => _log.info('Compass unavailable: $e'),
    );
    _timer = Timer.periodic(period, (_) => _tick());
    _log.info('Following the heading');
    notifyListeners();
    _tick();
  }

  void stop() {
    if (!_following) return;
    _following = false;
    _compassUnreliable = false;
    unawaited(_compassSub?.cancel());
    _compassSub = null;
    _timer?.cancel();
    _timer = null;
    _log.info('Stopped following the heading');
    notifyListeners();
  }

  /// A fix of the user's location: [course] (direction of travel) and [speed]
  /// (m/s) when known.
  void onUserLocation({
    required LatLng position,
    double? course,
    double? speed,
  }) {
    _position = position;
    if (_following) _filter.addCourse(course ?? -1, speed ?? 0);
  }

  /// Fingers on the map: no camera moves while the user touches it.
  void setTouching(bool touching) => _touching = touching;

  /// The camera's current bearing, to notice the user turning the map.
  void onCameraBearing(double bearing) {
    final commanded = _commandedBearing;
    if (!_following || _touching || commanded == null) return;
    final off = _angleBetween(bearing, commanded);
    if (off <= divergenceDegrees) {
      _divergingSince = null;
      return;
    }
    final since = _divergingSince ??= _clock();
    if (_clock().difference(since) >= divergence) {
      _log.info('The map was turned by hand, no longer following');
      stop();
    }
  }

  void _tick() {
    if (!_following) return;

    final unreliable = _filter.compassUnreliable;
    if (unreliable != _compassUnreliable) {
      _compassUnreliable = unreliable;
      notifyListeners();
    }

    final apply = _apply;
    if (apply == null || _touching) return;

    final bearing = _filter.step();
    final position = _position;
    final recentre =
        position != null &&
        (_appliedPosition == null ||
            _metersBetween(_appliedPosition!, position) >= recentreMetres);

    if (bearing == null && !recentre) return;
    if (bearing != null) _commandedBearing = bearing;
    if (recentre) _appliedPosition = position;
    apply(recentre ? position : null, bearing);
  }

  @override
  void dispose() {
    unawaited(_compassSub?.cancel());
    _timer?.cancel();
    super.dispose();
  }

  static double _angleBetween(double a, double b) {
    final d = ((a - b) % 360 + 360) % 360;
    return d > 180 ? 360 - d : d;
  }

  // Equirectangular approximation: fine for the metres between two fixes.
  static double _metersBetween(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon =
        (b.longitude - a.longitude) *
        math.pi /
        180 *
        math.cos((a.latitude + b.latitude) * math.pi / 360);
    return earth * math.sqrt(dLat * dLat + dLon * dLon);
  }
}
