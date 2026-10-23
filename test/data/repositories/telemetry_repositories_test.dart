import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/router/telemetry_router_repository.dart';
import 'package:swayriderapp/data/repositories/search/telemetry_search_repository.dart';
import 'package:swayriderapp/data/services/api/model/search/search_result_item.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../helpers/memory_telemetry.dart';
import '../../helpers/mocks.dart';

void main() {
  const focus = LatLng(50.88, 4.7);
  late MemoryTelemetryService telemetry;

  setUpAll(() => registerFallbackValue(focus));
  setUp(() => telemetry = MemoryTelemetryService());

  group('TelemetrySearchRepository', () {
    late MockSearchRepository inner;
    late TelemetrySearchRepository repository;

    setUp(() {
      inner = MockSearchRepository();
      repository = TelemetrySearchRepository(
        inner: inner,
        telemetry: telemetry,
      );
    });

    test('records the query and the results, and passes them on', () async {
      const item = SearchResultItem(
        label: 'Leuven, Belgium',
        locality: 'Leuven',
        region: 'Flemish Brabant',
        country: 'Belgium',
        confidence: 0.9,
        layer: 'locality',
        lat: 50.88,
        lon: 4.7,
      );
      when(
        () => inner.autocomplete(
          text: any(named: 'text'),
          focusPoint: any(named: 'focusPoint'),
          language: any(named: 'language'),
          targetHousenumber: any(named: 'targetHousenumber'),
        ),
      ).thenAnswer((_) async => const Result.ok([item]));

      final result = await repository.autocomplete(
        text: 'leuv',
        focusPoint: focus,
        language: 'nl',
      );

      expect((result as Ok<List<SearchResultItem>>).value, [item]);
      final query = telemetry.of('search_query').single;
      expect(query['text'], 'leuv');
      expect(query['language'], 'nl');
      final answer = telemetry.of('search_result').single;
      expect(answer['id'], query['id']);
      expect(
        (answer['items']! as List).single,
        containsPair('label', item.label),
      );
      expect(() => jsonEncode(answer), returnsNormally);
    });

    test('records an error answer', () async {
      when(
        () => inner.autocomplete(
          text: any(named: 'text'),
          focusPoint: any(named: 'focusPoint'),
          language: any(named: 'language'),
          targetHousenumber: any(named: 'targetHousenumber'),
        ),
      ).thenAnswer((_) async => Result.error(Exception('boom')));

      final result = await repository.autocomplete(
        text: 'x',
        focusPoint: focus,
      );

      expect(result, isA<Error<List<SearchResultItem>>>());
      expect(telemetry.of('search_result').single['error'], contains('boom'));
    });
  });

  group('TelemetryRouterRepository', () {
    late MockRouterRepository inner;
    late TelemetryRouterRepository repository;

    setUp(() {
      inner = MockRouterRepository();
      repository = TelemetryRouterRepository(
        inner: inner,
        telemetry: telemetry,
      );
    });

    test('records the request and the plan that came back', () async {
      when(
        () => inner.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
          language: any(named: 'language'),
        ),
      ).thenAnswer(
        (_) async => const Result.ok(
          RoutePlan(path: [focus, LatLng(50.9, 4.8)], distanceMeters: 1000),
        ),
      );

      await repository.calculateRoute(points: const [focus, LatLng(50.9, 4.8)]);

      final request = telemetry.of('route_request').single;
      final response = telemetry.of('route_response').single;
      expect(request['kind'], 'route');
      expect(response['id'], request['id']);
      final plan = response['plan']! as Map<String, Object?>;
      expect(plan['path'], [50.88, 4.7, 50.9, 4.8]);
      expect(plan['distanceM'], 1000);
      expect(() => jsonEncode(response), returnsNormally);
    });

    test('records a failed route', () async {
      when(
        () => inner.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => Result.error(Exception('no route')));

      await repository.calculateRoute(points: const [focus, focus]);

      expect(
        telemetry.of('route_response').single['error'],
        contains('no route'),
      );
    });
  });
}
