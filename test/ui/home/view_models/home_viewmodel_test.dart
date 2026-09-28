import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/services/api/model/search/search_result_item.dart';
import 'package:swayriderapp/domain/models/route/route_point.dart';
import 'package:swayriderapp/ui/home/view_models/home_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

const _defaultLocation = LatLng(51.2194, 4.4025);
const _testLocation = LatLng(50.8503, 4.3517);
const _testStyle = '{"version": 8}';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTilesRepository mockTilesRepository;
  late MockLocationService mockLocationService;
  late MockSearchRepository mockSearchRepository;
  late MockRouterRepository mockRouterRepository;
  late HomeViewModel viewModel;

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(const <LatLng>[]);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTilesRepository = MockTilesRepository();
    mockLocationService = MockLocationService();
    mockSearchRepository = MockSearchRepository();
    mockRouterRepository = MockRouterRepository();
    when(
      () => mockRouterRepository.calculateRoute(
        points: any(named: 'points'),
        isRoundTrip: any(named: 'isRoundTrip'),
      ),
    ).thenAnswer((_) async => const Result.ok([]));
    viewModel = HomeViewModel(
      authRepository: mockAuthRepository,
      tilesRepository: mockTilesRepository,
      locationService: mockLocationService,
      searchRepository: mockSearchRepository,
      routerRepository: mockRouterRepository,
    );
  });

  test('initial state is idle', () {
    expect(viewModel.logout.running, isFalse);
    expect(viewModel.logout.completed, isFalse);
    expect(viewModel.logout.error, isFalse);
    expect(viewModel.logout.result, isNull);
  });

  test('execute calls AuthRepository.logout with no arguments', () async {
    when(
      () => mockAuthRepository.logout(),
    ).thenAnswer((_) async => const Result.ok(null));

    await viewModel.logout.execute();

    verify(() => mockAuthRepository.logout()).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(
      () => mockAuthRepository.logout(),
    ).thenAnswer((_) async => const Result.ok(null));

    await viewModel.logout.execute();

    expect(viewModel.logout.completed, isTrue);
    expect(viewModel.logout.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('logout failed');
    when(
      () => mockAuthRepository.logout(),
    ).thenAnswer((_) async => Result.error(exception));

    await viewModel.logout.execute();

    expect(viewModel.logout.error, isTrue);
    expect((viewModel.logout.result as Error).error, exception);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(
      () => mockAuthRepository.logout(),
    ).thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.logout.addListener(() => notifications++);

    await viewModel.logout.execute();

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.logout()).thenAnswer((_) => completer.future);

    final first = viewModel.logout.execute();
    final second = viewModel.logout.execute();

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.logout()).called(1);
  });

  group('loadMap', () {
    test('initial state has no location or style', () {
      expect(viewModel.location, isNull);
      expect(viewModel.mapStyle, isNull);
      expect(viewModel.loadMap.running, isFalse);
      expect(viewModel.loadMap.completed, isFalse);
    });

    test('success sets location and mapStyle from the repositories', () async {
      when(
        () => mockLocationService.getCurrentLocation(),
      ).thenAnswer((_) async => const Result.ok(_testLocation));
      when(
        () => mockTilesRepository.getMapStyle(name: 'light'),
      ).thenAnswer((_) async => const Result.ok(_testStyle));

      await viewModel.loadMap.execute();

      expect(viewModel.location, _testLocation);
      expect(viewModel.mapStyle, _testStyle);
      expect(viewModel.loadMap.completed, isTrue);
      expect(viewModel.loadMap.error, isFalse);
    });

    test('location error falls back to the default location', () async {
      when(
        () => mockLocationService.getCurrentLocation(),
      ).thenAnswer((_) async => Result.error(Exception('denied')));
      when(
        () => mockTilesRepository.getMapStyle(name: 'light'),
      ).thenAnswer((_) async => const Result.ok(_testStyle));

      await viewModel.loadMap.execute();

      expect(viewModel.location, _defaultLocation);
      expect(viewModel.mapStyle, _testStyle);
      expect(viewModel.loadMap.completed, isTrue);
      expect(viewModel.loadMap.error, isFalse);
    });

    test('style error marks the command as error', () async {
      final exception = Exception('style fetch failed');
      when(
        () => mockLocationService.getCurrentLocation(),
      ).thenAnswer((_) async => const Result.ok(_testLocation));
      when(
        () => mockTilesRepository.getMapStyle(name: 'light'),
      ).thenAnswer((_) async => Result.error(exception));

      await viewModel.loadMap.execute();

      expect(viewModel.location, _testLocation);
      expect(viewModel.mapStyle, isNull);
      expect(viewModel.loadMap.error, isTrue);
      expect((viewModel.loadMap.result as Error).error, exception);
    });

    test('notifies listeners exactly twice per execute cycle', () async {
      when(
        () => mockLocationService.getCurrentLocation(),
      ).thenAnswer((_) async => const Result.ok(_testLocation));
      when(
        () => mockTilesRepository.getMapStyle(name: 'light'),
      ).thenAnswer((_) async => const Result.ok(_testStyle));

      var notifications = 0;
      viewModel.loadMap.addListener(() => notifications++);

      await viewModel.loadMap.execute();

      expect(notifications, 2);
    });
  });

  group('resolveHouseNumber', () {
    const street = SearchResultItem(
      label: 'Kerkstraat, Diest',
      locality: 'Diest',
      region: '',
      country: 'Belgium',
      confidence: 1.0,
      layer: 'street',
      lat: 50.98,
      lon: 5.05,
      street: 'Kerkstraat',
    );

    void stubAutocomplete(Result<List<SearchResultItem>> result) {
      when(
        () => mockSearchRepository.autocomplete(
          text: any(named: 'text'),
          focusPoint: any(named: 'focusPoint'),
          language: any(named: 'language'),
          targetHousenumber: any(named: 'targetHousenumber'),
        ),
      ).thenAnswer((_) async => result);
    }

    test('resolves to the result matching the street and locality', () async {
      const resolved = SearchResultItem(
        label: 'Kerkstraat 16, Diest, Belgium',
        locality: 'Diest',
        region: '',
        country: 'Belgium',
        confidence: 0.9,
        layer: 'address',
        lat: 50.98,
        lon: 5.05,
        street: 'Kerkstraat',
        houseNumber: '16',
      );
      stubAutocomplete(const Result.ok([resolved]));

      await viewModel.resolveHouseNumber.execute((
        street: street,
        houseNumber: '15',
        language: 'en',
      ));

      expect(viewModel.resolveHouseNumber.completed, isTrue);
      expect(
        (viewModel.resolveHouseNumber.result as Ok<SearchResultItem>).value,
        resolved,
      );
    });

    test('ignores results for a different street', () async {
      const otherStreet = SearchResultItem(
        label: 'Molenstraat 16, Diest, Belgium',
        locality: 'Diest',
        region: '',
        country: 'Belgium',
        confidence: 0.9,
        layer: 'address',
        lat: 50.98,
        lon: 5.05,
        street: 'Molenstraat',
        houseNumber: '16',
      );
      stubAutocomplete(const Result.ok([otherStreet]));

      await viewModel.resolveHouseNumber.execute((
        street: street,
        houseNumber: '15',
        language: 'en',
      ));

      expect(viewModel.resolveHouseNumber.error, isTrue);
    });

    test('picks the candidate nearest the selected street when the same '
        'street name exists in multiple villages', () async {
      // Reproduces a real scenario: "Erkstraat" exists in Bocholt,
      // Kaulille and Balenhoek. Selecting the Kaulille row (lat/lon near
      // it) must not resolve to the Bocholt candidate just because it's
      // also named "Erkstraat" and happens to come back first.
      const near = SearchResultItem(
        label: 'Erkstraat 5, Kaulille, Belgium',
        locality: 'Kaulille',
        region: '',
        country: 'Belgium',
        confidence: 0.5,
        layer: 'address',
        lat: 51.10,
        lon: 5.30,
        street: 'Erkstraat',
        houseNumber: '5',
      );
      const far = SearchResultItem(
        label: 'Erkstraat 5, Bocholt, Belgium',
        locality: 'Bocholt',
        region: '',
        country: 'Belgium',
        confidence: 0.9,
        layer: 'address',
        lat: 51.18,
        lon: 5.58,
        street: 'Erkstraat',
        houseNumber: '5',
      );
      // far listed first: a naive "take the first match" would pick it.
      stubAutocomplete(const Result.ok([far, near]));

      const kaulilleStreet = SearchResultItem(
        label: 'Erkstraat, Kaulille',
        locality: 'Kaulille',
        region: '',
        country: 'Belgium',
        confidence: 1.0,
        layer: 'address',
        lat: 51.10,
        lon: 5.30,
        street: 'Erkstraat',
      );

      await viewModel.resolveHouseNumber.execute((
        street: kaulilleStreet,
        houseNumber: '5',
        language: 'en',
      ));

      expect(viewModel.resolveHouseNumber.completed, isTrue);
      expect(
        (viewModel.resolveHouseNumber.result as Ok<SearchResultItem>).value,
        near,
      );
    });

    test('errors when nothing at all comes back', () async {
      stubAutocomplete(const Result.ok([]));

      await viewModel.resolveHouseNumber.execute((
        street: street,
        houseNumber: '15',
        language: 'en',
      ));

      expect(viewModel.resolveHouseNumber.error, isTrue);
    });

    test('propagates a repository error', () async {
      final exception = Exception('network error');
      stubAutocomplete(Result.error(exception));

      await viewModel.resolveHouseNumber.execute((
        street: street,
        houseNumber: '15',
        language: 'en',
      ));

      expect(viewModel.resolveHouseNumber.error, isTrue);
      expect((viewModel.resolveHouseNumber.result as Error).error, exception);
    });

    test('passes the typed house number as targetHousenumber', () async {
      stubAutocomplete(const Result.ok([]));

      await viewModel.resolveHouseNumber.execute((
        street: street,
        houseNumber: '15',
        language: 'en',
      ));

      verify(
        () => mockSearchRepository.autocomplete(
          text: any(named: 'text'),
          focusPoint: any(named: 'focusPoint'),
          language: 'en',
          targetHousenumber: '15',
        ),
      ).called(1);
    });
  });

  group('route recalculation', () {
    const pointA = RoutePoint(label: 'A', point: LatLng(51.0, 4.0));
    const pointB = RoutePoint(label: 'B', point: LatLng(51.1, 4.1));

    test('does not call the router below 2 points', () async {
      viewModel.setAsDestination(pointA);
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => mockRouterRepository.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
        ),
      );
      expect(viewModel.routePath, isNull);
    });

    test('calls the router with the current points once there are 2', () async {
      viewModel.setAsStartPoint(pointA);
      viewModel.setAsDestination(pointB);
      await Future<void>.delayed(Duration.zero);

      verify(
        () => mockRouterRepository.calculateRoute(
          points: [pointA.point, pointB.point],
          isRoundTrip: false,
        ),
      ).called(1);
    });

    test('sets routePath on success', () async {
      final path = [pointA.point, pointB.point];
      when(
        () => mockRouterRepository.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
        ),
      ).thenAnswer((_) async => Result.ok(path));

      viewModel.setAsStartPoint(pointA);
      viewModel.setAsDestination(pointB);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.routePath, path);
    });

    test(
      'a repository error clears routePath instead of leaving a stale route',
      () async {
        final path = [pointA.point, pointB.point];
        when(
          () => mockRouterRepository.calculateRoute(
            points: any(named: 'points'),
            isRoundTrip: any(named: 'isRoundTrip'),
          ),
        ).thenAnswer((_) async => Result.ok(path));
        viewModel.setAsStartPoint(pointA);
        viewModel.setAsDestination(pointB);
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.routePath, path);

        when(
          () => mockRouterRepository.calculateRoute(
            points: any(named: 'points'),
            isRoundTrip: any(named: 'isRoundTrip'),
          ),
        ).thenAnswer((_) async => Result.error(Exception('no route')));
        viewModel.setRoundTrip(true);
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.routePath, isNull);
      },
    );

    test(
      'toggling round trip re-triggers a calculation with isRoundTrip',
      () async {
        viewModel.setAsStartPoint(pointA);
        viewModel.setAsDestination(pointB);
        await Future<void>.delayed(Duration.zero);

        viewModel.setRoundTrip(true);
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockRouterRepository.calculateRoute(
            points: [pointA.point, pointB.point],
            isRoundTrip: true,
          ),
        ).called(1);
      },
    );

    test('discards a stale response superseded by a newer call', () async {
      final staleCompleter = Completer<Result<List<LatLng>>>();
      final freshPath = [pointA.point, pointB.point];
      var callCount = 0;
      when(
        () => mockRouterRepository.calculateRoute(
          points: any(named: 'points'),
          isRoundTrip: any(named: 'isRoundTrip'),
        ),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) return staleCompleter.future;
        return Future.value(Result.ok(freshPath));
      });

      viewModel.setAsStartPoint(pointA);
      viewModel.setAsDestination(pointB);
      // First call is in flight (stale); trigger a second before it resolves.
      viewModel.setRoundTrip(true);
      await Future<void>.delayed(Duration.zero);

      staleCompleter.complete(const Result.ok([]));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.routePath, freshPath);
    });
  });
}
