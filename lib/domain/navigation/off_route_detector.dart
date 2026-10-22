/// Where the rider stands relative to the route.
enum OffRouteState {
  /// On the route (or close enough that the dot is snapped to it).
  onRoute,

  /// Too far from the route, but not for long enough to be sure.
  suspect,

  /// Off the route: time to find the way back.
  off,
}

/// Decides when the rider has really left the route, so a noisy fix, a
/// tunnel or a parallel road does not trigger a new route.
///
/// Off route means further from the route than [offMeters] (twice the GPS
/// accuracy when that is worse) for at least [confirm], or further than
/// [immediateMeters] at once. Within [backOnRouteMeters] the rider is on the
/// route again; in between the previous state is kept, so the state does not
/// flicker around a threshold.
class OffRouteDetector {
  OffRouteDetector({this.confirm = const Duration(seconds: 4)});

  static const backOnRouteMeters = 30.0;
  static const offMeters = 50.0;
  static const immediateMeters = 120.0;

  final Duration confirm;

  DateTime? _since;
  OffRouteState _state = OffRouteState.onRoute;

  OffRouteState get state => _state;

  /// Feeds the distance of a fix from the route (and the fix's accuracy, if
  /// known) at [now] and returns the new state.
  OffRouteState update({
    required double offRouteMeters,
    double? accuracyMeters,
    required DateTime now,
  }) {
    if (offRouteMeters <= backOnRouteMeters) {
      reset();
      return _state;
    }

    final threshold = accuracyMeters == null
        ? offMeters
        : accuracyMeters * 2 > offMeters
        ? accuracyMeters * 2
        : offMeters;
    if (offRouteMeters > threshold) {
      final since = _since ??= now;
      _state =
          offRouteMeters > immediateMeters || now.difference(since) >= confirm
          ? OffRouteState.off
          : OffRouteState.suspect;
    }
    // Between "back on route" and the threshold the state stays as it is.
    return _state;
  }

  /// Back to on route, forgetting how long the rider has been away.
  void reset() {
    _since = null;
    _state = OffRouteState.onRoute;
  }
}
