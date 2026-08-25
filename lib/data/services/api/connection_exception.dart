/// Thrown when a request fails because the backend could not be reached at
/// all — DNS failure, connection refused, connect/read timeout, or a failed
/// TLS handshake — as opposed to a response the backend actually returned.
///
/// Callers should treat this distinctly from other [Exception]s returned by
/// [Result.error]: it means "we don't know the answer" (unauthenticated?
/// unverified? something else?), not "the answer is no".
class ConnectionException implements Exception {
  const ConnectionException(this.cause);

  /// The underlying I/O error (`SocketException`, `TimeoutException`, or
  /// `HandshakeException`).
  final Exception cause;

  @override
  String toString() => 'Could not reach the server: $cause';
}
