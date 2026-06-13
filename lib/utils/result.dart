/// Represents the outcome of an operation that can either succeed or fail.
///
/// Use [Result.ok] to wrap a success value and [Result.error] to wrap a
/// failure. Because this class is `sealed`, a `switch` expression over a
/// [Result] must handle both [Ok] and [Error] — the compiler enforces
/// exhaustiveness.
///
/// Example:
/// ```dart
/// Result<String> fetchName(int id) {
///   if (id <= 0) return Result.error(Exception('Invalid id'));
///   return Result.ok('Alice');
/// }
///
/// switch (fetchName(1)) {
///   case Ok(:final value) => print('Got: $value');
///   case Error(:final error) => print('Failed: $error');
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result wrapping [value].
  const factory Result.ok(T value) = Ok._;

  /// Creates a failed result wrapping [error].
  const factory Result.error(Exception error) = Error._;
}

/// A [Result] subtype representing success, carrying [value] of type [T].
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  /// The success value.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// A [Result] subtype representing failure, carrying the [error] that occurred.
final class Error<T> extends Result<T> {
  const Error._(this.error);

  /// The exception describing what went wrong.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}