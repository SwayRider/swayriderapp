import 'package:flutter/services.dart';

/// One compass reading.
class CompassReading {
  const CompassReading({required this.heading, this.accuracy});

  /// Reads the map the native side sends: `{heading, accuracy}`.
  factory CompassReading.fromMap(Map<Object?, Object?> map) {
    final accuracy = map['accuracy'];
    return CompassReading(
      heading: (map['heading']! as num).toDouble(),
      accuracy: accuracy is num ? accuracy.toDouble() : null,
    );
  }

  /// Where the user points the device, in degrees clockwise from north.
  final double heading;

  /// The plus-or-minus error of [heading] in degrees; null while unknown.
  /// A very large value (90) means the sensor says it is unreliable.
  final double? accuracy;
}

/// Compass headings of the device.
abstract class CompassService {
  /// The stream is only active while it has a listener, and it fails with an
  /// error on devices without a compass.
  Stream<CompassReading> get readings;
}

/// [CompassService] on top of the app's own platform channel (`MainActivity` /
/// `CompassStreamHandler` on Android, `AppDelegate` on iOS).
///
/// It is not a package because the common one forces CocoaPods on a Swift
/// Package Manager project, and the native side can report what a generic
/// package cannot: the rotation vector sensor's real accuracy on Android, true
/// north and Core Location's calibration prompt on iOS.
class CompassServiceChannel implements CompassService {
  CompassServiceChannel({EventChannel? channel})
    : _channel =
          channel ?? const EventChannel('com.hevanto_it.swayriderapp/compass');

  final EventChannel _channel;

  @override
  Stream<CompassReading> get readings => _channel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => CompassReading.fromMap(event as Map<Object?, Object?>));
}
