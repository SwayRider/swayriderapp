import 'dart:async';

import 'package:swayriderapp/data/repositories/router/router_repository.dart';
import 'package:swayriderapp/data/services/ambient_light_service.dart';
import 'package:swayriderapp/domain/models/route/rejoin.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/data/services/compass_service.dart';
import 'package:swayriderapp/data/services/location_service.dart';
import 'package:swayriderapp/data/services/speech_service.dart';
import 'package:swayriderapp/domain/models/location/location_fix.dart';
import 'package:swayriderapp/utils/result.dart';

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

/// A [LocationService] whose live fixes are driven by the test via [emit].
class FakeLocationService implements LocationService {
  final _controller = StreamController<LocationFix>.broadcast();

  bool get listening => _controller.hasListener;

  @override
  Future<Result<LatLng>> getCurrentLocation() async =>
      const Result.ok(LatLng(51.0, 4.0));

  @override
  Stream<LocationFix> positions() => _controller.stream;

  void emit(LatLng position, {double speedMps = 10, double? course}) =>
      _controller.add(
        LocationFix(
          position: position,
          speedMps: speedMps,
          courseDegrees: course,
        ),
      );

  void emitError(Object error) => _controller.addError(error);
}

/// A [SpeechService] that records what would have been spoken.
class FakeSpeechService implements SpeechService {
  final spoken = <String>[];
  final languages = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text, {required String language}) async {
    spoken.add(text);
    languages.add(language);
  }

  @override
  Future<void> stop() async => stops++;
}

/// A [RouterRepository] whose way-back answers are controlled by the test:
/// [rejoin] records the request and waits for [answer].
class FakeRouterRepository implements RouterRepository {
  final requests = <RejoinRequest>[];
  final _pending = <Completer<Result<RejoinResult>>>[];

  /// Answers the oldest request that has not been answered yet.
  void answer(Result<RejoinResult> result) =>
      _pending.removeAt(0).complete(result);

  @override
  Future<Result<RejoinResult>> rejoin(RejoinRequest request) {
    requests.add(request);
    final completer = Completer<Result<RejoinResult>>();
    _pending.add(completer);
    return completer.future;
  }

  @override
  Future<Result<RoutePlan>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
    String language = 'en-US',
  }) async => Result.error(Exception('not used'));
}
