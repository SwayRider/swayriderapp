import '../../../utils/result.dart';

/// Provides MapLibre-ready style JSON for the tile map.
///
/// Implementations are responsible for authenticating against the tiles
/// backend (which requires a bearer token on every request, including
/// individual tile fetches) so that callers — in particular MapLibre's
/// native renderer, which cannot attach custom headers — can talk to a
/// plain, unauthenticated local endpoint.
abstract class TilesRepository {
  /// Returns a MapLibre style v8 JSON string for the style named [name],
  /// with tile/sprite/glyph URLs rewritten to point at a local,
  /// pre-authenticated endpoint.
  ///
  /// The returned string is ready to pass directly to
  /// `MapLibreMap.styleString`.
  Future<Result<String>> getMapStyle({required String name});

  /// Releases any resources (e.g. a local proxy server) held by this
  /// repository.
  Future<void> close();
}
