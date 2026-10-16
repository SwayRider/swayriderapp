import '../../../domain/models/map/map_style_mode.dart';

/// Decides between the light and dark map from ambient light readings.
///
/// A style switch is a network fetch and a native reload of the map, so this
/// is deliberately slow and sticky:
///
/// - It looks at the **median** of the readings of the last [window], not at
///   single events (a hand passing over the sensor must not flip the map).
///   The light sensor reports on change only, so when nothing arrived within
///   the window the last reading still counts as the current one.
/// - **Hysteresis:** it goes dark below [darkBelowLux] and back to light only
///   above [lightAboveLux] (which is higher), so a room that sits near one
///   threshold does not flicker.
/// - The other side must be seen on [confirmations] consecutive [evaluate]
///   calls before it switches.
/// - After a switch it stays put for at least [minDwell].
///
/// Typical values: a dark room or night street is below 10 lx, a lit living
/// room 100-300 lx, overcast daylight over 1000 lx.
class AutoVariantResolver {
  AutoVariantResolver({
    MapVariant initial = MapVariant.light,
    this.darkBelowLux = 10,
    this.lightAboveLux = 40,
    this.window = const Duration(seconds: 10),
    this.confirmations = 2,
    this.minDwell = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : assert(darkBelowLux < lightAboveLux),
       assert(confirmations >= 1),
       _variant = initial,
       _clock = clock ?? DateTime.now;

  final double darkBelowLux;
  final double lightAboveLux;
  final Duration window;
  final int confirmations;
  final Duration minDwell;
  final DateTime Function() _clock;

  final _readings = <({DateTime at, double lux})>[];
  MapVariant _variant;
  int _pending = 0;
  DateTime? _lastSwitch;

  /// The variant decided so far.
  MapVariant get variant => _variant;

  /// Whether at least one reading has been seen.
  bool get hasReadings => _readings.isNotEmpty;

  /// Starts again from [variant], e.g. when Auto is switched on.
  void reset(MapVariant variant) {
    _variant = variant;
    _readings.clear();
    _pending = 0;
    _lastSwitch = null;
  }

  void addReading(double lux) {
    if (lux.isNaN || lux.isInfinite || lux < 0) return;
    _readings.add((at: _clock(), lux: lux));
    // Keep what is inside the window, plus the newest one older than it.
    final cutoff = _clock().subtract(window);
    while (_readings.length > 1 && _readings[1].at.isBefore(cutoff)) {
      _readings.removeAt(0);
    }
  }

  /// Median of the current window (or the last reading if none is in it);
  /// null before the first reading.
  double? get currentLux {
    if (_readings.isEmpty) return null;
    final cutoff = _clock().subtract(window);
    var inWindow = [
      for (final r in _readings)
        if (!r.at.isBefore(cutoff)) r.lux,
    ];
    if (inWindow.isEmpty) inWindow = [_readings.last.lux];
    inWindow.sort();
    final mid = inWindow.length ~/ 2;
    return inWindow.length.isOdd
        ? inWindow[mid]
        : (inWindow[mid - 1] + inWindow[mid]) / 2;
  }

  /// Looks at the readings and maybe switches. Call it on a slow timer.
  /// Returns true when [variant] changed.
  bool evaluate() {
    final lux = currentLux;
    if (lux == null) return false;

    final wanted = switch (_variant) {
      MapVariant.light when lux < darkBelowLux => MapVariant.dark,
      MapVariant.dark when lux > lightAboveLux => MapVariant.light,
      _ => null,
    };
    if (wanted == null) {
      _pending = 0;
      return false;
    }

    _pending++;
    if (_pending < confirmations) return false;
    final last = _lastSwitch;
    if (last != null && _clock().difference(last) < minDwell) return false;

    _variant = wanted;
    _pending = 0;
    _lastSwitch = _clock();
    return true;
  }
}
