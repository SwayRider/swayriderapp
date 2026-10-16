import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:ambient_light/ambient_light.dart';
import 'package:logging/logging.dart';

/// Ambient light readings in (approximate) lux.
///
/// The stream is single-subscription and only runs the sensor while it has a
/// listener: cancel the subscription to stop it. Errors (no sensor, camera
/// access denied) arrive as stream errors; callers fall back to something else.
abstract class AmbientLightService {
  Stream<double> get lux;

  /// Whether measuring needs the user's explicit consent first. True on iOS,
  /// where the value is estimated from the camera (camera permission prompt,
  /// camera-in-use indicator, battery); false on Android's light sensor.
  bool get needsExplicitOptIn;
}

/// [AmbientLightService] on top of the `ambient_light` plugin.
///
/// - **Android:** the plugin streams `Sensor.TYPE_LIGHT` events in lux. The
///   sensor reports on change, so a steady room produces few events.
/// - **iOS:** there is no light sensor API. The plugin starts a camera
///   session and returns the frame's EXIF *brightness value* (APEX, a log2
///   scale, despite the plugin's "lux" docs). The camera must stay on for a
///   moment to settle its exposure, so this takes a short burst every
///   [iosInterval], ignores the first frames, takes the median of the rest and
///   stops the camera again. [luxFromApexBrightness] converts it.
class AmbientLightServicePlugin implements AmbientLightService {
  AmbientLightServicePlugin({
    Stream<double> Function()? openSensor,
    bool? isIos,
    this.iosInterval = const Duration(seconds: 15),
    this.iosSettleFrames = 10,
    this.iosSampleFrames = 5,
    this.iosSampleTimeout = const Duration(seconds: 6),
  }) : _openSensor = openSensor ?? (() => AmbientLight().ambientLightStream),
       _isIos = isIos ?? Platform.isIOS;

  final Stream<double> Function() _openSensor;
  final bool _isIos;

  /// Time between camera bursts on iOS.
  final Duration iosInterval;

  /// Frames dropped at the start of a burst while the exposure settles.
  final int iosSettleFrames;

  /// Frames whose median is reported.
  final int iosSampleFrames;

  /// Give up on a burst that produces no frames.
  final Duration iosSampleTimeout;

  final _log = Logger('AmbientLightService');

  @override
  bool get needsExplicitOptIn => _isIos;

  @override
  Stream<double> get lux => _isIos ? _iosBursts() : _openSensor();

  /// Approximate lux for an APEX brightness value `Bv`.
  ///
  /// `lux ≈ 2^(Bv + 5)` — a rough rule of thumb (a normally lit room, Bv≈3,
  /// is about 250 lx; a dim room, Bv≈-1, about 16 lx). **Provisional:** it has
  /// not been calibrated against a real light meter; adjust
  /// [apexToLuxExponentOffset] after measuring on devices.
  static double luxFromApexBrightness(double bv) =>
      math.pow(2, bv + apexToLuxExponentOffset).toDouble();

  static const apexToLuxExponentOffset = 5.0;

  Stream<double> _iosBursts() {
    Timer? timer;
    var running = false;
    late final StreamController<double> controller;

    Future<void> burst() async {
      if (running || controller.isClosed) return;
      running = true;
      try {
        final bv = await _sampleBurst();
        if (!controller.isClosed) controller.add(luxFromApexBrightness(bv));
      } on Object catch (e, st) {
        _log.fine('Ambient light burst failed', e);
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        running = false;
      }
    }

    controller = StreamController<double>(
      onListen: () {
        unawaited(burst());
        timer = Timer.periodic(iosInterval, (_) => unawaited(burst()));
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  /// Runs the camera briefly and returns the median APEX brightness.
  Future<double> _sampleBurst() async {
    final frames = <double>[];
    var seen = 0;
    final done = Completer<void>();
    final subscription = _openSensor().listen(
      (bv) {
        if (++seen <= iosSettleFrames) return;
        frames.add(bv);
        if (frames.length >= iosSampleFrames && !done.isCompleted) {
          done.complete();
        }
      },
      onError: (Object e, StackTrace st) {
        if (!done.isCompleted) done.completeError(e, st);
      },
    );
    try {
      await done.future.timeout(iosSampleTimeout);
    } finally {
      // Cancelling stops the camera session at once; nothing needs to wait
      // for the platform to confirm it.
      unawaited(subscription.cancel());
    }
    frames.sort();
    return frames[frames.length ~/ 2];
  }
}
