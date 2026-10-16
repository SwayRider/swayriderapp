import 'dart:math' as math;
import 'dart:ui' show Offset;

/// What ended the follow mode.
enum FollowBreak {
  /// One finger dragged the map.
  pan,

  /// Two fingers turned the map.
  rotate,
}

/// Decides, from raw pointer events over the map, whether the user is taking
/// over the map while it follows the heading: dragging it ([FollowBreak.pan])
/// or turning it with two fingers ([FollowBreak.rotate]).
///
/// Pinch-zooming does not end follow mode (two fingers whose angle hardly
/// changes), and neither does a tap. The map itself is a native view, so the
/// app watches the raw pointers on top of it instead of asking the map.
///
/// Each call returns a [FollowBreak] the first time one is detected in a
/// gesture, and null otherwise; a new gesture starts when all fingers are up.
class FollowGestureDetector {
  FollowGestureDetector({this.panSlop = 16, this.rotateSlopDegrees = 12});

  /// Logical pixels a single finger may move before it counts as a drag.
  final double panSlop;

  /// Degrees the line between two fingers may turn before it counts as a
  /// rotation.
  final double rotateSlopDegrees;

  final _start = <int, Offset>{};
  final _current = <int, Offset>{};
  double? _pairAngle;
  bool _fired = false;

  /// Whether any finger is on the map.
  bool get isTouching => _current.isNotEmpty;

  FollowBreak? pointerDown(int pointer, Offset position) {
    _current[pointer] = position;
    _rebaseline();
    return null;
  }

  FollowBreak? pointerMove(int pointer, Offset position) {
    if (!_current.containsKey(pointer)) return null;
    _current[pointer] = position;
    if (_fired) return null;

    if (_current.length == 1) {
      final moved = (position - _start[pointer]!).distance;
      if (moved > panSlop) return _fire(FollowBreak.pan);
    } else if (_current.length == 2) {
      final start = _pairAngle;
      if (start != null) {
        final turned = _angleDelta(_angleOfPair(), start).abs();
        if (turned > rotateSlopDegrees) return _fire(FollowBreak.rotate);
      }
    }
    return null;
  }

  void pointerUp(int pointer) {
    _current.remove(pointer);
    _start.remove(pointer);
    if (_current.isEmpty) _fired = false;
    _rebaseline();
  }

  void reset() {
    _current.clear();
    _start.clear();
    _pairAngle = null;
    _fired = false;
  }

  FollowBreak _fire(FollowBreak kind) {
    _fired = true;
    return kind;
  }

  // Measure from where the fingers are now: lifting or adding a finger must
  // not be mistaken for movement.
  void _rebaseline() {
    _start
      ..clear()
      ..addAll(_current);
    _pairAngle = _current.length == 2 ? _angleOfPair() : null;
  }

  double _angleOfPair() {
    final points = _current.values.toList(growable: false);
    final d = points[1] - points[0];
    return math.atan2(d.dy, d.dx) * 180 / math.pi;
  }

  // The turn between two line angles. A line has no direction, so 0° and 180°
  // are the same line.
  static double _angleDelta(double a, double b) {
    var d = (a - b) % 180;
    if (d > 90) d -= 180;
    return d;
  }
}
