import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/search/search_repository.dart';
import '../data/repositories/search/search_repository_remote.dart';
import '../data/repositories/tiles/tiles_repository.dart';
import '../data/repositories/tiles/tiles_repository_remote.dart';
import '../data/services/api/auth_api_client.dart';
import '../data/services/api/search_api_client.dart';
import '../data/services/api/tiles_api_client.dart';
import '../data/services/location_service.dart';
import '../data/services/shared_preferences_service.dart';
import '../data/services/tile_cache.dart';
import '../ui/home/view_models/home_viewmodel.dart';
import 'app_config.dart';

/// Shared providers for all configurations.
List<SingleChildWidget> _sharedProviders = [
];

/// Configure dependencies for dev data.
/// This dependency list uses repositories that connect to a remote dev server.
List<SingleChildWidget> get providerDev {
  return [
    Provider(create: (context) => AuthApiClient(
      scheme: AppConfig.authApiScheme,
      host: AppConfig.authApiHost,
      port: AppConfig.authApiPort,
      pathPrefix: AppConfig.authApiPathPrefix,
    )),
    Provider(create: (context) => SharedPreferencesService()),
    ChangeNotifierProvider(create: (context) =>
      AuthRepositoryRemote(
        authApiClient: context.read(),
        sharedPreferencesService: context.read(),
      ) as AuthRepository),
    Provider(create: (context) => TilesApiClient(
      scheme: AppConfig.tilesApiScheme,
      host: AppConfig.tilesApiHost,
      port: AppConfig.tilesApiPort,
      pathPrefix: AppConfig.tilesApiPathPrefix,
    )),
    Provider<TileCache>(create: (context) => NoopTileCache()),
    Provider(create: (context) => SearchApiClient(
      scheme: AppConfig.searchApiScheme,
      host: AppConfig.searchApiHost,
      port: AppConfig.searchApiPort,
      pathPrefix: AppConfig.searchApiPathPrefix,
    )),
    Provider<SearchRepository>(
      create: (context) => SearchRepositoryRemote(
        searchApiClient: context.read(),
        authRepository: context.read(),
      ),
    ),
    Provider<TilesRepository>(
      create: (context) => TilesRepositoryRemote(
        tilesApiClient: context.read(),
        authRepository: context.read(),
        tilesBaseUrl: Uri(
          scheme: AppConfig.tilesApiScheme,
          host: AppConfig.tilesApiHost,
          port: AppConfig.tilesApiPort,
        ),
        tileCache: context.read(),
      ),
      dispose: (context, repository) => repository.close(),
    ),
    Provider<LocationService>(create: (context) => LocationServiceGeolocator()),
    ChangeNotifierProvider<HomeViewModel>(
      create: (context) => HomeViewModel(
        authRepository: context.read(),
        tilesRepository: context.read(),
        locationService: context.read(),
        searchRepository: context.read(),
      ),
    ),
    ..._sharedProviders
  ];
}