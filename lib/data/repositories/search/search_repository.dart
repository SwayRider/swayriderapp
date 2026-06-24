import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../services/api/model/search/search_result_item.dart';
import '../../../utils/result.dart';

/// Provides location-search autocomplete suggestions.
abstract class SearchRepository {
  /// Returns location suggestions matching [text], biased toward [focusPoint].
  Future<Result<List<SearchResultItem>>> autocomplete({
    required String text,
    required LatLng focusPoint,
    String language = 'en',
  });
}
