import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../services/api/model/search/search_result_item.dart';
import '../../../utils/result.dart';

/// Provides location-search autocomplete suggestions.
abstract class SearchRepository {
  /// Returns location suggestions matching [text], biased toward [focusPoint].
  ///
  /// When [targetHousenumber] is set, street-level results are biased toward
  /// the address numerically closest to it instead of the most confident one.
  Future<Result<List<SearchResultItem>>> autocomplete({
    required String text,
    required LatLng focusPoint,
    String language = 'en',
    String targetHousenumber = '',
  });
}
