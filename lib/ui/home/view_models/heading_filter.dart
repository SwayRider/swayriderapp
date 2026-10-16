import 'dart:math' as math;

/// Turns a noisy compass (and the GPS course) into a calm map bearing.
///
/// A raw phone compass jitters by several degrees, jumps when the device is
/// near metal or magnets (a bike frame, a phone mount) and is wrong when it is
/// not calibrated. Rotating the map straight from it makes it spin. This filter:
///
/// - **averages on the circle**: readings are blended as unit vectors, so 359°
///   and 1° average to 0°, not 180°;
/// - **smooths over time** ([compassSmoothing], a time constant; slower when
///   the sensor says its accuracy is only medium);
/// - **rejects readings the sensor itself calls inaccurate**
///   ([rejectAccuracyAt] and up) and reports [compassUnreliable] when that
///   lasts, so the app can ask the user to calibrate;
/// - **has a dead band**: the shown bearing does not move for changes under
///   [compassDeadBand] degrees, so a device lying still shows a still map; once
///   it moves it follows until it is within half the dead band of the target;
/// - **limits the turning speed** to [maxRate] degrees per second;
/// - **prefers the GPS course while moving**: above [courseEnterSpeed] the
///   direction of travel is far more reliable than the magnetometer (which a
///   bike disturbs); it is used until the speed falls below [courseExitSpeed].
///
/// Feed it with [addCompass] and [addCourse] as readings arrive, and call
/// [step] regularly (about 10 times a second); it returns the bearing to show
/// when that changes.
class HeadingFilter {
  HeadingFilter({
    this.compassSmoothing = const Duration(milliseconds: 600),
    this.courseSmoothing = const Duration(milliseconds: 500),
    this.compassDeadBand = 4.0,
    this.courseDeadBand = 1.5,
    this.maxRate = 120.0,
    this.courseEnterSpeed = 3.0,
    this.courseExitSpeed = 1.5,
    this.softAccuracyAt = 30.0,
    this.rejectAccuracyAt = 45.0,
    this.unreliableAfter = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : assert(courseExitSpeed < courseEnterSpeed),
       assert(softAccuracyAt < rejectAccuracyAt),
       _clock = clock ?? DateTime.now;

  final Duration compassSmoothing;
  final Duration courseSmoothing;

  /// Degrees the target must differ from the shown bearing before it moves.
  final double compassDeadBand;
  final double courseDeadBand;

  /// Maximum turning speed in degrees per second.
  final double maxRate;

  /// Speeds in m/s: at or above [courseEnterSpeed] the GPS course takes over,
  /// below [courseExitSpeed] the compass does again.
  final double courseEnterSpeed;
  final double courseExitSpeed;

  /// Accuracies (± degrees) from which a compass reading is smoothed twice as
  /// slowly, and from which it is ignored.
  final double softAccuracyAt;
  final double rejectAccuracyAt;

  /// How long compass readings must have been rejected before
  /// [compassUnreliable] turns true.
  final Duration unreliableAfter;

  final DateTime Function() _clock;

  // The smoothed direction as a vector (x = sin, y = cos); null before the
  // first reading.
  double? _x;
  double? _y;
  DateTime? _estimateAt;

  double? _shown;
  DateTime? _stepAt;
  bool _moving = false;

  bool _usingCourse = false;
  DateTime? _compassBadSince;

  /// The bearing last returned by [step] (degrees clockwise from north, 0-360).
  double? get bearing => _shown;

  /// The smoothed direction the shown bearing is heading for (before the dead
  /// band and the turning speed limit); null before the first reading.
  double? get targetBearing {
    final x = _x;
    final y = _y;
    if (x == null || y == null) return null;
    return _normalize(math.atan2(x, y) * 180 / math.pi);
  }

  /// Whether the GPS course (instead of the compass) is driving the bearing.
  bool get usingCourse => _usingCourse;

  /// Whether the compass has been reporting poor accuracy for a while (and the
  /// GPS course is not taking over): the user should calibrate it.
  bool get compassUnreliable {
    final since = _compassBadSince;
    return !_usingCourse &&
        since != null &&
        _clock().difference(since) >= unreliableAfter;
  }

  void reset() {
    _x = _y = null;
    _estimateAt = null;
    _shown = null;
    _stepAt = null;
    _moving = false;
    _usingCourse = false;
    _compassBadSince = null;
  }

  /// A compass reading: [heading] in degrees (any range), [accuracy] the ±
  /// error in degrees if known.
  void addCompass(double heading, {double? accuracy}) {
    if (!heading.isFinite) return;
    final now = _clock();
    if (accuracy != null && accuracy >= rejectAccuracyAt) {
      _compassBadSince ??= now;
      return;
    }
    _compassBadSince = null;
    if (_usingCourse) return; // the direction of travel drives
    final soft = accuracy != null && accuracy >= softAccuracyAt;
    _blend(heading, soft ? compassSmoothing * 2 : compassSmoothing, now);
  }

  /// A GPS fix: [course] is the direction of travel in degrees (negative or
  /// NaN when unknown), [speed] in m/s.
  void addCourse(double course, double speed) {
    if (!speed.isFinite) return;
    if (_usingCourse) {
      if (speed < courseExitSpeed) _usingCourse = false;
    } else if (speed >= courseEnterSpeed) {
      _usingCourse = true;
    }
    if (_usingCourse && course.isFinite && course >= 0) {
      _blend(course, courseSmoothing, _clock());
    }
  }

  void _blend(double degrees, Duration tau, DateTime now) {
    final rad = degrees * math.pi / 180;
    final sx = math.sin(rad);
    final sy = math.cos(rad);
    final x = _x;
    final y = _y;
    final at = _estimateAt;
    if (x == null || y == null || at == null) {
      _x = sx;
      _y = sy;
    } else {
      final dt = now.difference(at).inMicroseconds;
      final alpha = dt <= 0 ? 0.0 : 1 - math.exp(-dt / tau.inMicroseconds);
      _x = x + alpha * (sx - x);
      _y = y + alpha * (sy - y);
    }
    _estimateAt = now;
  }

  /// The bearing to show now, or null when it stays as it is.
  double? step() {
    final x = _x;
    final y = _y;
    if (x == null || y == null) return null;

    // Remember when we last looked, even if we hold now: the turning speed
    // limit is measured against it.
    final now = _clock();
    final last = _stepAt;
    _stepAt = now;

    // Readings that cancel each other out (a sudden half turn passes through
    // zero when blending vectors) have no direction: hold.
    if (math.sqrt(x * x + y * y) < 0.05) return null;

    final target = _normalize(math.atan2(x, y) * 180 / math.pi);

    final shown = _shown;
    if (shown == null) return _shown = target;

    final delta = _signedDelta(target, shown);
    final band = _usingCourse ? courseDeadBand : compassDeadBand;
    if (!_moving && delta.abs() < band) return null;
    _moving = true;

    // Arrived: within half the dead band, which is hardly visible. Stop here
    // instead of chasing the last bit of noise with pointless camera nudges.
    if (delta.abs() < band / 2) {
      _moving = false;
      return null;
    }

    final dt = last == null
        ? 0.1
        : (now.difference(last).inMicroseconds / 1e6).clamp(0.0, 0.5);
    final limit = maxRate * dt;
    return _shown = _normalize(shown + delta.clamp(-limit, limit));
  }

  static double _normalize(double degrees) {
    final d = degrees % 360;
    return d < 0 ? d + 360 : d;
  }

  /// `a - b` folded into (-180, 180].
  static double _signedDelta(double a, double b) {
    var d = (a - b) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }
}
