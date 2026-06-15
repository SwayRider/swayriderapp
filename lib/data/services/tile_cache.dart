import 'dart:typed_data';

/// Cache for raw MVT tile bytes, keyed by tileset and tile coordinates.
///
/// This is the seam for offline tile caching (e.g. for offline navigation):
/// [TilesRepositoryRemote]'s proxy handler reads through [get] and writes
/// through [put] for every tile request, so a persistent implementation can
/// be dropped in later without touching the proxy/rewrite logic.
abstract class TileCache {
  Future<Uint8List?> get(String tileset, int z, int x, int y);

  Future<void> put(String tileset, int z, int x, int y, Uint8List bytes);
}

/// Default [TileCache] that never caches anything.
class NoopTileCache implements TileCache {
  @override
  Future<Uint8List?> get(String tileset, int z, int x, int y) async => null;

  @override
  Future<void> put(String tileset, int z, int x, int y, Uint8List bytes) async {}
}
