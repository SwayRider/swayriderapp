import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/search/search_repository_remote.dart';
import 'package:swayriderapp/data/services/api/model/search/search_result_item.dart';
import 'package:swayriderapp/data/services/api/unauthorized_exception.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  test(
    'autocomplete routes the api call through authRepository.withAuthRetry',
    () async {
      final mockApiClient = MockSearchApiClient();
      final mockAuthRepository = MockAuthRepository();
      when(
        () => mockApiClient.authHeaderProvider = any(),
      ).thenReturn(() => null);
      when(() => mockAuthRepository.authHeaderProvider).thenReturn(() => null);
      when(
        () => mockApiClient.autocomplete(
          text: any(named: 'text'),
          focusPoint: any(named: 'focusPoint'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => const Result.error(UnauthorizedException()));
      when(
        () => mockAuthRepository.withAuthRetry<List<SearchResultItem>>(any()),
      ).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.single
                as Future<Result<List<SearchResultItem>>> Function())(),
      );

      final repository = SearchRepositoryRemote(
        searchApiClient: mockApiClient,
        authRepository: mockAuthRepository,
      );

      final result = await repository.autocomplete(
        text: 'query',
        focusPoint: const LatLng(51.2194, 4.4025),
      );

      expect(result, isA<Error<List<SearchResultItem>>>());
      expect(
        (result as Error<List<SearchResultItem>>).error,
        isA<UnauthorizedException>(),
      );
      verify(
        () => mockAuthRepository.withAuthRetry<List<SearchResultItem>>(any()),
      ).called(1);
    },
  );
}
