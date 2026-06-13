import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/utils/command.dart';
import 'package:swayriderapp/utils/result.dart';

void main() {
  group('Command0', () {
    test('starts in an idle state', () {
      final command = Command0<void>(() async => const Result.ok(null));

      expect(command.running, isFalse);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(command.result, isNull);
    });

    test('sets running to true synchronously while pending', () async {
      final completer = Completer<Result<void>>();
      final command = Command0<void>(() => completer.future);

      final future = command.execute();

      expect(command.running, isTrue);

      completer.complete(const Result.ok(null));
      await future;
    });

    test('reflects an Ok result on success', () async {
      final command = Command0<int>(() async => const Result.ok(42));

      await command.execute();

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect((command.result as Ok<int>).value, 42);
    });

    test('reflects an Error result on failure', () async {
      final exception = Exception('boom');
      final command = Command0<void>(() async => Result.error(exception));

      await command.execute();

      expect(command.running, isFalse);
      expect(command.completed, isFalse);
      expect(command.error, isTrue);
      expect((command.result as Error<void>).error, exception);
    });

    test('notifies listeners exactly twice per execute cycle', () async {
      final command = Command0<void>(() async => const Result.ok(null));
      var notifyCount = 0;
      command.addListener(() => notifyCount++);

      await command.execute();

      expect(notifyCount, 2);
    });

    test('ignores re-entrant execute() calls while running', () async {
      var callCount = 0;
      final completer = Completer<Result<void>>();
      final command = Command0<void>(() {
        callCount++;
        return completer.future;
      });

      final first = command.execute();
      final second = command.execute();

      completer.complete(const Result.ok(null));
      await first;
      await second;

      expect(callCount, 1);
    });

    test('clearResult resets the result and notifies listeners', () async {
      final command = Command0<void>(() async => const Result.ok(null));
      await command.execute();
      expect(command.completed, isTrue);

      var notified = false;
      command.addListener(() => notified = true);
      command.clearResult();

      expect(command.result, isNull);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(notified, isTrue);
    });

    test('resets running to false if the action throws', () async {
      final command = Command0<void>(() async => throw Exception('boom'));

      await expectLater(command.execute(), throwsA(isA<Exception>()));

      expect(command.running, isFalse);
    });
  });

  group('Command1', () {
    test('forwards the argument to the action', () async {
      String? receivedArg;
      final command = Command1<void, String>((arg) async {
        receivedArg = arg;
        return const Result.ok(null);
      });

      await command.execute('hello');

      expect(receivedArg, 'hello');
      expect(command.completed, isTrue);
    });

    test('reflects an Error result on failure', () async {
      final exception = Exception('boom');
      final command = Command1<void, String>(
        (arg) async => Result.error(exception),
      );

      await command.execute('x');

      expect(command.completed, isFalse);
      expect(command.error, isTrue);
      expect((command.result as Error<void>).error, exception);
    });

    test('ignores re-entrant execute() calls while running', () async {
      var callCount = 0;
      final completer = Completer<Result<void>>();
      final command = Command1<void, String>((arg) {
        callCount++;
        return completer.future;
      });

      final first = command.execute('a');
      final second = command.execute('b');

      completer.complete(const Result.ok(null));
      await first;
      await second;

      expect(callCount, 1);
    });
  });
}
