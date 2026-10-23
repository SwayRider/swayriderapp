import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../utils/result.dart';
import '../../services/api/model/search/search_result_item.dart';
import '../../services/telemetry/telemetry_encoders.dart';
import '../../services/telemetry/telemetry_service.dart';
import 'search_repository.dart';

/// Records every autocomplete query and its answer in the telemetry trace,
/// then passes the result through unchanged.
class TelemetrySearchRepository implements SearchRepository {
  TelemetrySearchRepository({required this._inner, required this._telemetry});

  final SearchRepository _inner;
  final TelemetryService _telemetry;
  int _serial = 0;

  @override
  Future<Result<List<SearchResultItem>>> autocomplete({
    required String text,
    required LatLng focusPoint,
    String language = 'en',
    String targetHousenumber = '',
  }) async {
    final id = ++_serial;
    final watch = Stopwatch()..start();
    _telemetry.record('search_query', {
      'id': id,
      'text': text,
      'focus': encodeLatLng(focusPoint),
      'language': language,
      'targetHousenumber': targetHousenumber,
    });
    final result = await _inner.autocomplete(
      text: text,
      focusPoint: focusPoint,
      language: language,
      targetHousenumber: targetHousenumber,
    );
    _telemetry.record('search_result', {
      'id': id,
      'latencyMs': watch.elapsedMilliseconds,
      ...switch (result) {
        Ok<List<SearchResultItem>>() => {
          'items': result.value.map(encodeSearchItem).toList(),
        },
        Error<List<SearchResultItem>>() => {'error': '${result.error}'},
      },
    });
    return result;
  }
}
