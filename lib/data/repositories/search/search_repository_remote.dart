import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../services/api/model/search/search_result_item.dart';
import '../../services/api/search_api_client.dart';
import '../../../utils/result.dart';
import '../auth/auth_repository.dart';
import 'search_repository.dart';

/// [SearchRepository] backed by [SearchApiClient].
class SearchRepositoryRemote implements SearchRepository {
  SearchRepositoryRemote({
    required this._searchApiClient,
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _searchApiClient.authHeaderProvider = authRepository.authHeaderProvider;
  }

  final SearchApiClient _searchApiClient;
  final AuthRepository _authRepository;

  @override
  Future<Result<List<SearchResultItem>>> autocomplete({
    required String text,
    required LatLng focusPoint,
    String language = 'en',
  }) => _authRepository.withAuthRetry(
    () => _searchApiClient.autocomplete(
      text: text,
      focusPoint: focusPoint,
      language: language,
    ),
  );
}
