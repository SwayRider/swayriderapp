import 'dart:math' as math;

import '../../../domain/models/map/map_style_mode.dart';

/// Decides between the light and dark map from ambient light readings, fast
/// enough to follow a tunnel entrance or exit within a couple of seconds.
///
/// - **Log scale.** Light is perceived (and varies) on a log scale: daylight is
///   10 000 lx, a lit tunnel 100-300 lx, a dark road 1 lx. The readings are
///   smoothed as `log10(lux + 1)`, so a drop from daylight to dark crosses a
///   threshold in well under a second. Averaging in plain lux would take
///   several seconds to decay.
/// - **Time-based smoothing** with time constant [smoothing] (about 1 s): a
///   shadow or a flash shorter than that barely moves the level. It is time
///   based because the Android light sensor reports on change only; between
///   events the last reading simply holds, and the level keeps approaching it.
/// - **Hysteresis.** Dark below [darkBelowLux], light again above
///   [lightAboveLux] (higher), so a level sitting near one threshold cannot
///   flicker.
/// - **Debounce.** The other side must hold for [confirm] (half a second)
///   before it switches.
/// - **Calm period.** After a switch it stays put for [minDwell] (a few
///   seconds), because a switch reloads the map style.
///
/// [evaluate] is cheap (a little arithmetic); call it on every reading and on
/// a short timer.
class AutoVariantResolver {
  AutoVariantResolver({
    MapVariant initial = MapVariant.light,
    this.darkBelowLux = 150,
    this.lightAboveLux = 500,
    this.smoothing = const Duration(seconds: 1),
    this.confirm = const Duration(milliseconds: 500),
    this.minDwell = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : assert(darkBelowLux < lightAboveLux),
       assert(smoothing > Duration.zero),
       _variant = initial,
       _clock = clock ?? DateTime.now;

  final double darkBelowLux;
  final double lightAboveLux;
  final Duration smoothing;
  final Duration confirm;
  final Duration minDwell;
  final DateTime Function() _clock;

  MapVariant _variant;

  // The smoothed level (log10 lux + 1) as of _levelAt, moving towards _target,
  // the log level of the latest reading.
  double? _level;
  double _target = 0;
  DateTime? _levelAt;

  DateTime? _candidateSince;
  DateTime? _lastSwitch;

  /// The variant decided so far.
  MapVariant get variant => _variant;

  /// Whether at least one reading has been seen.
  bool get hasReadings => _level != null;

  static double _toLevel(double lux) => math.log(lux + 1) / math.ln10;
  static double _toLux(double level) => math.pow(10, level).toDouble() - 1;

  /// The smoothed light level in lux now; null before the first reading.
  double? get currentLux {
    final level = _levelNow();
    return level == null ? null : _toLux(level);
  }

  double? _levelNow() {
    final level = _level;
    final at = _levelAt;
    if (level == null || at == null) return null;
    final dt = _clock().difference(at).inMicroseconds;
    if (dt <= 0) return level;
    final keep = math.exp(-dt / smoothing.inMicroseconds);
    return _target + (level - _target) * keep;
  }

  /// Starts again from [variant], e.g. when Auto is switched on.
  void reset(MapVariant variant) {
    _variant = variant;
    _level = null;
    _levelAt = null;
    _candidateSince = null;
    _lastSwitch = null;
  }

  void addReading(double lux) {
    if (lux.isNaN || lux.isInfinite || lux < 0) return;
    // Move the smoothed level up to now, then aim it at the new reading. The
    // very first reading is taken as it is.
    final now = _clock();
    _level = _levelNow() ?? _toLevel(lux);
    _levelAt = now;
    _target = _toLevel(lux);
  }

  /// Looks at the smoothed level and maybe switches. Returns true when
  /// [variant] changed.
  bool evaluate() {
    final level = _levelNow();
    if (level == null) return false;
    final now = _clock();

    final crossed = switch (_variant) {
      MapVariant.light => level < _toLevel(darkBelowLux),
      MapVariant.dark => level > _toLevel(lightAboveLux),
    };
    if (!crossed) {
      _candidateSince = null;
      return false;
    }

    final since = _candidateSince ??= now;
    if (now.difference(since) < confirm) return false;
    final last = _lastSwitch;
    if (last != null && now.difference(last) < minDwell) return false;

    _variant = _variant == MapVariant.light
        ? MapVariant.dark
        : MapVariant.light;
    _candidateSince = null;
    _lastSwitch = now;
    return true;
  }
}
