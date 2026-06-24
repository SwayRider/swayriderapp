import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:mocktail/mocktail.dart';
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
  late HomeViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTilesRepository = MockTilesRepository();
    mockLocationService = MockLocationService();
    mockSearchRepository = MockSearchRepository();
    viewModel = HomeViewModel(
      authRepository: mockAuthRepository,
      tilesRepository: mockTilesRepository,
      locationService: mockLocationService,
      searchRepository: mockSearchRepository,
    );
  });

  test('initial state is idle', () {
    expect(viewModel.logout.running, isFalse);
    expect(viewModel.logout.completed, isFalse);
    expect(viewModel.logout.error, isFalse);
    expect(viewModel.logout.result, isNull);
  });

  test('execute calls AuthRepository.logout with no arguments', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

    await viewModel.logout.execute();

    verify(() => mockAuthRepository.logout()).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

    await viewModel.logout.execute();

    expect(viewModel.logout.completed, isTrue);
    expect(viewModel.logout.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('logout failed');
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => Result.error(exception));

    await viewModel.logout.execute();

    expect(viewModel.logout.error, isTrue);
    expect((viewModel.logout.result as Error).error, exception);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

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
      when(() => mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Result.ok(_testLocation));
      when(() => mockTilesRepository.getMapStyle(name: 'light'))
          .thenAnswer((_) async => const Result.ok(_testStyle));

      await viewModel.loadMap.execute();

      expect(viewModel.location, _testLocation);
      expect(viewModel.mapStyle, _testStyle);
      expect(viewModel.loadMap.completed, isTrue);
      expect(viewModel.loadMap.error, isFalse);
    });

    test('location error falls back to the default location', () async {
      when(() => mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => Result.error(Exception('denied')));
      when(() => mockTilesRepository.getMapStyle(name: 'light'))
          .thenAnswer((_) async => const Result.ok(_testStyle));

      await viewModel.loadMap.execute();

      expect(viewModel.location, _defaultLocation);
      expect(viewModel.mapStyle, _testStyle);
      expect(viewModel.loadMap.completed, isTrue);
      expect(viewModel.loadMap.error, isFalse);
    });

    test('style error marks the command as error', () async {
      final exception = Exception('style fetch failed');
      when(() => mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Result.ok(_testLocation));
      when(() => mockTilesRepository.getMapStyle(name: 'light'))
          .thenAnswer((_) async => Result.error(exception));

      await viewModel.loadMap.execute();

      expect(viewModel.location, _testLocation);
      expect(viewModel.mapStyle, isNull);
      expect(viewModel.loadMap.error, isTrue);
      expect((viewModel.loadMap.result as Error).error, exception);
    });

    test('notifies listeners exactly twice per execute cycle', () async {
      when(() => mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const Result.ok(_testLocation));
      when(() => mockTilesRepository.getMapStyle(name: 'light'))
          .thenAnswer((_) async => const Result.ok(_testStyle));

      var notifications = 0;
      viewModel.loadMap.addListener(() => notifications++);

      await viewModel.loadMap.execute();

      expect(notifications, 2);
    });
  });
}
