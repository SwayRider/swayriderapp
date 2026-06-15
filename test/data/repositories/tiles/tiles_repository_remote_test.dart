import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/repositories/tiles/tiles_repository_remote.dart';

void main() {
  const origin = 'http://127.0.0.1:54321';

  test('rewrites tile source URLs to the local proxy origin', () {
    final style = {
      'sources': {
        'swayrider': {
          'type': 'vector',
          'tiles': [
            'https://api.swayrider-dev.hevanto-it.com/v1/tiles/base/{z}/{x}/{y}',
          ],
        },
      },
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(
      rewritten['sources']['swayrider']['tiles'][0],
      '$origin/v1/tiles/base/{z}/{x}/{y}',
    );
  });

  test('rewrites a sprite URL under /v1/tiles/', () {
    final style = {
      'sprite': 'https://api.swayrider-dev.hevanto-it.com/v1/tiles/sprites/light',
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(rewritten['sprite'], '$origin/v1/tiles/sprites/light');
  });

  test('leaves URLs without /v1/tiles/ untouched', () {
    final style = {
      'glyphs': 'https://fonts.openmaptiles.org/{fontstack}/{range}.pbf',
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(rewritten['glyphs'], style['glyphs']);
  });

  test('leaves non-string values untouched', () {
    final style = {'version': 8, 'enabled': true, 'meta': null};

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(rewritten, style);
  });
}
