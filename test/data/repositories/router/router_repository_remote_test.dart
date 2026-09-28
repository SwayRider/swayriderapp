import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/router/router_repository_remote.dart';
import 'package:swayriderapp/data/services/api/unauthorized_exception.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(const <LatLng>[]);
  });

  test(
    'calculateRoute routes the api call through authRepository.withAuthRetry',
    () async {
      final mockApiClient = MockRouterApiClient();
      final mockAuthRepository = MockAuthRepository();
      when(
        () => mockApiClient.authHeaderProvider = any(),
      ).thenReturn(() => null);
      when(() => mockAuthRepository.authHeaderProvider).thenReturn(() => null);
      when(
        () => mockApiClient.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
        ),
      ).thenAnswer((_) async => const Result.error(UnauthorizedException()));
      when(
        () => mockAuthRepository.withAuthRetry<List<LatLng>>(any()),
      ).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.single
                as Future<Result<List<LatLng>>> Function())(),
      );

      final repository = RouterRepositoryRemote(
        routerApiClient: mockApiClient,
        authRepository: mockAuthRepository,
      );

      final result = await repository.calculateRoute(
        points: const [LatLng(51.2194, 4.4025), LatLng(51.22, 4.41)],
      );

      expect(result, isA<Error<List<LatLng>>>());
      expect(
        (result as Error<List<LatLng>>).error,
        isA<UnauthorizedException>(),
      );
      verify(
        () => mockAuthRepository.withAuthRetry<List<LatLng>>(any()),
      ).called(1);
    },
  );

  test(
    'calculateRoute forwards points and isRoundTrip to the api client',
    () async {
      final mockApiClient = MockRouterApiClient();
      final mockAuthRepository = MockAuthRepository();
      when(
        () => mockApiClient.authHeaderProvider = any(),
      ).thenReturn(() => null);
      when(() => mockAuthRepository.authHeaderProvider).thenReturn(() => null);
      when(
        () => mockApiClient.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
        ),
      ).thenAnswer((_) async => const Result.ok([]));
      when(
        () => mockAuthRepository.withAuthRetry<List<LatLng>>(any()),
      ).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.single
                as Future<Result<List<LatLng>>> Function())(),
      );

      final repository = RouterRepositoryRemote(
        routerApiClient: mockApiClient,
        authRepository: mockAuthRepository,
      );

      const points = [LatLng(51.2194, 4.4025), LatLng(51.22, 4.41)];
      await repository.calculateRoute(points: points, isRoundTrip: true);

      verify(
        () => mockApiClient.calculateRoute(points: points, isRoundTrip: true),
      ).called(1);
    },
  );
}
