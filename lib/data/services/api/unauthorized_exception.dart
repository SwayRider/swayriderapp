/// Thrown when an authenticated request is rejected because the access
/// token is missing, expired, or otherwise invalid (HTTP 401).
class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'Not authenticated';
}
