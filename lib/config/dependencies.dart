import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/feedback/feedback_repository.dart';
import '../data/repositories/feedback/feedback_repository_remote.dart';
import '../data/repositories/router/router_repository.dart';
import '../data/repositories/router/router_repository_remote.dart';
import '../data/repositories/router/telemetry_router_repository.dart';
import '../data/repositories/search/search_repository.dart';
import '../data/repositories/search/search_repository_remote.dart';
import '../data/repositories/search/telemetry_search_repository.dart';
import '../data/repositories/tiles/tiles_repository.dart';
import '../data/repositories/tiles/tiles_repository_remote.dart';
import '../data/services/api/auth_api_client.dart';
import '../data/services/api/feedback_api_client.dart';
import '../data/services/api/router_api_client.dart';
import '../data/services/api/search_api_client.dart';
import '../data/services/ambient_light_service.dart';
import '../data/services/api/tiles_api_client.dart';
import '../data/services/compass_service.dart';
import '../data/services/location_service.dart';
import '../data/services/speech_service.dart';
import '../data/services/map_style_preference_service.dart';
import '../data/services/secure_token_storage_service.dart';
import '../data/services/telemetry/telemetry_service.dart';
import '../data/services/tile_cache.dart';
import '../ui/home/view_models/follow_heading_controller.dart';
import '../ui/home/view_models/home_viewmodel.dart';
import '../ui/home/view_models/map_style_view_model.dart';
import 'app_config.dart';

/// What the backend needs to interpret a telemetry trace.
Map<String, Object?> _sessionMeta() => <String, Object?>{
  'schema': telemetrySchemaVersion,
  'platform': Platform.operatingSystem,
  'osVersion': Platform.operatingSystemVersion,
  'locale': Platform.localeName,
  'debugBuild': kDebugMode,
  'routerHost': AppConfig.routerApiHost,
  'searchHost': AppConfig.searchApiHost,
};

Future<void> _startTelemetry(TelemetryService telemetry) async {
  final meta = _sessionMeta();
  try {
    final info = await PackageInfo.fromPlatform();
    meta['appVersion'] = info.version;
    meta['buildNumber'] = info.buildNumber;
  } on Object {
    // The version is nice to have; the trace is useful without it.
  }
  await telemetry.start(meta: meta);
}

/// Shared providers for all configurations.
List<SingleChildWidget> _sharedProviders = [];

/// Configure dependencies for dev data.
/// This dependency list uses repositories that connect to a remote dev server.
List<SingleChildWidget> get providerDev {
  return [
    Provider(
      create: (context) => AuthApiClient(
        scheme: AppConfig.authApiScheme,
        host: AppConfig.authApiHost,
        port: AppConfig.authApiPort,
        pathPrefix: AppConfig.authApiPathPrefix,
      ),
    ),
    Provider<TelemetryService>(
      // Not lazy: the session file is opened at app start, not on first use.
      lazy: false,
      create: (context) {
        if (!AppConfig.debugTelemetry) return const NoopTelemetryService();
        final telemetry = FileTelemetryService();
        unawaited(_startTelemetry(telemetry));
        return telemetry;
      },
      dispose: (context, telemetry) => telemetry.flush(),
    ),
    Provider(create: (context) => SecureTokenStorageService()),
    ChangeNotifierProvider(
      create: (context) =>
          AuthRepositoryRemote(
                authApiClient: context.read(),
                tokenStorageService: context.read(),
              )
              as AuthRepository,
    ),
    Provider(
      create: (context) => TilesApiClient(
        scheme: AppConfig.tilesApiScheme,
        host: AppConfig.tilesApiHost,
        port: AppConfig.tilesApiPort,
        pathPrefix: AppConfig.tilesApiPathPrefix,
      ),
    ),
    Provider<TileCache>(create: (context) => NoopTileCache()),
    Provider(
      create: (context) => SearchApiClient(
        scheme: AppConfig.searchApiScheme,
        host: AppConfig.searchApiHost,
        port: AppConfig.searchApiPort,
        pathPrefix: AppConfig.searchApiPathPrefix,
      ),
    ),
    Provider<SearchRepository>(
      create: (context) {
        final remote = SearchRepositoryRemote(
          searchApiClient: context.read(),
          authRepository: context.read(),
        );
        final telemetry = context.read<TelemetryService>();
        return telemetry.enabled
            ? TelemetrySearchRepository(inner: remote, telemetry: telemetry)
            : remote;
      },
    ),
    Provider(
      create: (context) => RouterApiClient(
        scheme: AppConfig.routerApiScheme,
        host: AppConfig.routerApiHost,
        port: AppConfig.routerApiPort,
        pathPrefix: AppConfig.routerApiPathPrefix,
      ),
    ),
    Provider<RouterRepository>(
      create: (context) {
        final remote = RouterRepositoryRemote(
          routerApiClient: context.read(),
          authRepository: context.read(),
        );
        final telemetry = context.read<TelemetryService>();
        return telemetry.enabled
            ? TelemetryRouterRepository(inner: remote, telemetry: telemetry)
            : remote;
      },
    ),
    Provider(
      // The feedback endpoint is served by the same gateway as the router.
      create: (context) => FeedbackApiClient(
        scheme: AppConfig.routerApiScheme,
        host: AppConfig.routerApiHost,
        port: AppConfig.routerApiPort,
        path: AppConfig.feedbackApiPath,
      ),
    ),
    Provider<FeedbackRepository>(
      create: (context) => FeedbackRepositoryRemote(
        feedbackApiClient: context.read(),
        telemetry: context.read(),
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
    Provider<SpeechService>(create: (context) => SpeechServiceChannel()),
    ChangeNotifierProvider<HomeViewModel>(
      create: (context) => HomeViewModel(
        authRepository: context.read(),
        locationService: context.read(),
        searchRepository: context.read(),
        routerRepository: context.read(),
      ),
    ),
    Provider<CompassService>(create: (context) => CompassServiceChannel()),
    ChangeNotifierProvider<FollowHeadingController>(
      create: (context) =>
          FollowHeadingController(compassService: context.read()),
    ),
    Provider(create: (context) => MapStylePreferenceService()),
    Provider<AmbientLightService>(
      create: (context) => AmbientLightServicePlugin(),
    ),
    ChangeNotifierProvider<MapStyleViewModel>(
      create: (context) => MapStyleViewModel(
        tilesRepository: context.read(),
        preferences: context.read(),
        ambientLight: context.read(),
        styleId: AppConfig.tilesStyleId,
        platformBrightness: () =>
            WidgetsBinding.instance.platformDispatcher.platformBrightness,
      ),
    ),
    ..._sharedProviders,
  ];
}
