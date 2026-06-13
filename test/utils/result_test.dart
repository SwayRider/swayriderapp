import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/utils/result.dart';

void main() {
  group('Result.ok', () {
    test('wraps a success value', () {
      const result = Result<String>.ok('hello');

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, 'hello');
    });

    test('is not an Error', () {
      const Result<String> result = Result.ok('hello');

      expect(result, isNot(isA<Error<String>>()));
    });

    test('toString includes the value', () {
      const result = Result<int>.ok(42);

      expect(result.toString(), 'Result<int>.ok(42)');
    });

    test('supports const construction', () {
      const result = Result<void>.ok(null);

      expect(result, isA<Ok<void>>());
    });

    test('pattern matching destructures the value', () {
      const Result<int> result = Result.ok(7);

      final value = switch (result) {
        Ok(:final value) => value,
        Error() => -1,
      };

      expect(value, 7);
    });
  });

  group('Result.error', () {
    test('wraps a failure exception', () {
      final exception = Exception('boom');
      final result = Result<String>.error(exception);

      expect(result, isA<Error<String>>());
      expect((result as Error<String>).error, exception);
    });

    test('is not an Ok', () {
      final Result<String> result = Result.error(Exception('boom'));

      expect(result, isNot(isA<Ok<String>>()));
    });

    test('toString includes the error', () {
      final exception = Exception('boom');
      final result = Result<int>.error(exception);

      expect(result.toString(), 'Result<int>.error($exception)');
    });

    test('supports const construction', () {
      const result = Result<void>.error(HttpExceptionForTest('boom'));

      expect(result, isA<Error<void>>());
    });

    test('pattern matching destructures the error', () {
      final exception = Exception('boom');
      final Result<int> result = Result.error(exception);

      final error = switch (result) {
        Ok() => null,
        Error(:final error) => error,
      };

      expect(error, exception);
    });
  });
}

/// A const-constructible [Exception] used to test `const Result.error(...)`.
class HttpExceptionForTest implements Exception {
  const HttpExceptionForTest(this.message);

  final String message;

  @override
  String toString() => 'HttpExceptionForTest: $message';
}
