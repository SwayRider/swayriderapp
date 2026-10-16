import 'dart:async';

import 'package:swayriderapp/data/services/ambient_light_service.dart';
import 'package:swayriderapp/data/services/compass_service.dart';

/// An [AmbientLightService] driven by the test: [emit] sends a reading, and
/// [listening] tells whether the "sensor" is currently running.
class FakeAmbientLightService implements AmbientLightService {
  FakeAmbientLightService({this.needsExplicitOptIn = false});

  @override
  final bool needsExplicitOptIn;

  StreamController<double>? _controller;

  /// How many times the sensor was started.
  int starts = 0;

  /// How many times it was stopped.
  int stops = 0;

  bool get listening => _controller?.hasListener ?? false;

  @override
  Stream<double> get lux {
    final controller = StreamController<double>(
      onListen: () => starts++,
      onCancel: () => stops++,
    );
    _controller = controller;
    return controller.stream;
  }

  void emit(double lux) => _controller!.add(lux);

  void emitError(Object error) => _controller!.addError(error);
}

/// A [CompassService] driven by the test: [emit] sends a reading, and
/// [listening] tells whether the compass is currently running.
class FakeCompassService implements CompassService {
  StreamController<CompassReading>? _controller;

  int starts = 0;
  int stops = 0;

  bool get listening => _controller?.hasListener ?? false;

  @override
  Stream<CompassReading> get readings {
    final controller = StreamController<CompassReading>(
      onListen: () => starts++,
      onCancel: () => stops++,
    );
    _controller = controller;
    return controller.stream;
  }

  void emit(double heading, {double? accuracy}) =>
      _controller!.add(CompassReading(heading: heading, accuracy: accuracy));
}
