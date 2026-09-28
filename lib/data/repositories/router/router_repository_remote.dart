import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../utils/result.dart';
import '../../services/api/router_api_client.dart';
import '../auth/auth_repository.dart';
import 'router_repository.dart';

/// [RouterRepository] backed by [RouterApiClient].
class RouterRepositoryRemote implements RouterRepository {
  RouterRepositoryRemote({
    required this._routerApiClient,
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _routerApiClient.authHeaderProvider = authRepository.authHeaderProvider;
  }

  final RouterApiClient _routerApiClient;
  final AuthRepository _authRepository;

  @override
  Future<Result<List<LatLng>>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
  }) => _authRepository.withAuthRetry(
    () => _routerApiClient.calculateRoute(
      points: points,
      isRoundTrip: isRoundTrip,
    ),
  );
}
