import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/services/api/auth_api_client.dart';
import '../data/services/shared_preferences_service.dart';
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
    ..._sharedProviders
  ];
}