import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/services/api/auth_api_client.dart';
import '../data/services/shared_preferences_service.dart';

/// Shared providers for all configurations.
List<SingleChildWidget> _sharedProviders = [
];

/// Configure dependencies for dev data.
/// This dependency list uses repositories that connect to a remote dev server.
List<SingleChildWidget> get providerDev {
  return [
    Provider(create: (context) => AuthApiClient(
      scheme: 'https',
      host: 'api.swayrider-dev.hevanto-it.com',
      port: 443,
      pathPrefix: '/api/v1/auth',
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