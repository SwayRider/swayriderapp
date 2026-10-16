import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/compass_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel('test/compass');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockStreamHandler(channel, null));

  group('CompassReading.fromMap', () {
    test('reads heading and accuracy', () {
      final r = CompassReading.fromMap({'heading': 123.5, 'accuracy': 15.0});
      expect(r.heading, 123.5);
      expect(r.accuracy, 15.0);
    });

    test('accepts integers', () {
      final r = CompassReading.fromMap({'heading': 90, 'accuracy': 30});
      expect(r.heading, 90.0);
      expect(r.accuracy, 30.0);
    });

    test('a missing or null accuracy is unknown', () {
      expect(CompassReading.fromMap({'heading': 1.0}).accuracy, isNull);
      expect(
        CompassReading.fromMap({'heading': 1.0, 'accuracy': null}).accuracy,
        isNull,
      );
    });
  });

  group('CompassServiceChannel', () {
    test('turns what the native side sends into readings', () async {
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({'heading': 90.0, 'accuracy': 15.0});
            events.success({'heading': 350.25, 'accuracy': null});
            events.success('not a reading'); // ignored
            events.endOfStream();
          },
        ),
      );

      final readings = await CompassServiceChannel(
        channel: channel,
      ).readings.toList();

      expect(readings, hasLength(2));
      expect(readings[0].heading, 90.0);
      expect(readings[0].accuracy, 15.0);
      expect(readings[1].heading, 350.25);
      expect(readings[1].accuracy, isNull);
    });

    test('a device without a compass is a stream error', () async {
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.error(code: 'NO_SENSOR', message: 'no compass');
            events.endOfStream();
          },
        ),
      );

      final errors = <Object>[];
      await CompassServiceChannel(
        channel: channel,
      ).readings.handleError(errors.add).toList();

      expect(errors.single, isA<PlatformException>());
      expect((errors.single as PlatformException).code, 'NO_SENSOR');
    });

    test('the native side only runs while someone listens', () async {
      var listening = 0;
      var cancelled = 0;
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) => listening++,
          onCancel: (arguments) => cancelled++,
        ),
      );

      final service = CompassServiceChannel(channel: channel);
      final sub = service.readings.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(listening, 1);

      await sub.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(cancelled, 1);
    });
  });
}
