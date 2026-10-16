import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:swayriderapp/data/services/map_style_preference_service.dart';
import 'package:swayriderapp/domain/models/map/map_style_mode.dart';
import 'package:swayriderapp/ui/home/view_models/auto_variant_resolver.dart';
import 'package:swayriderapp/ui/home/view_models/map_style_view_model.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/mocks.dart';

const _light = '{"name":"light"}';
const _dark = '{"name":"dark"}';

void main() {
  late MockTilesRepository tiles;
  late FakeAmbientLightService light;
  late MapStylePreferenceService prefs;
  var brightness = Brightness.light;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tiles = MockTilesRepository();
    light = FakeAmbientLightService();
    prefs = MapStylePreferenceService(preferences: SharedPreferencesAsync());
    brightness = Brightness.light;
    when(
      () => tiles.getMapStyle(name: 'swayrider/light'),
    ).thenAnswer((_) async => const Result.ok(_light));
    when(
      () => tiles.getMapStyle(name: 'swayrider/dark'),
    ).thenAnswer((_) async => const Result.ok(_dark));
  });

  MapStyleViewModel create({
    FakeAsync? async,
    FakeAmbientLightService? sensor,
  }) => MapStyleViewModel(
    tilesRepository: tiles,
    preferences: prefs,
    ambientLight: sensor ?? light,
    styleId: 'swayrider',
    platformBrightness: () => brightness,
    resolverFactory: async == null
        ? null
        : (initial) => AutoVariantResolver(
            initial: initial,
            clock: async.getClock(DateTime(2026, 10, 16, 21)).now,
          ),
  );

  group('load', () {
    test('auto on a light system loads the light style', () async {
      final vm = create();
      await vm.load.execute();

      expect(vm.mode, MapStyleMode.auto);
      expect(vm.variant, MapVariant.light);
      expect(vm.mapStyle, _light);
      expect(vm.load.completed, isTrue);
      vm.dispose();
    });

    test('auto on a dark system loads the dark style', () async {
      brightness = Brightness.dark;
      final vm = create();
      await vm.load.execute();

      expect(vm.variant, MapVariant.dark);
      expect(vm.mapStyle, _dark);
      vm.dispose();
    });

    test('a saved mode wins over the system appearance', () async {
      await prefs.saveMode(MapStyleMode.night);
      final vm = create();
      await vm.load.execute();

      expect(vm.mode, MapStyleMode.night);
      expect(vm.mapStyle, _dark);
      vm.dispose();
    });

    test('prefetches the other variant', () async {
      final vm = create();
      await vm.load.execute();
      await Future<void>.delayed(Duration.zero);

      verify(() => tiles.getMapStyle(name: 'swayrider/dark')).called(1);
      vm.dispose();
    });

    test('a failed load is an error and leaves no style', () async {
      when(
        () => tiles.getMapStyle(name: 'swayrider/light'),
      ).thenAnswer((_) async => Result.error(Exception('offline')));
      final vm = create();
      await vm.load.execute();

      expect(vm.load.error, isTrue);
      expect(vm.mapStyle, isNull);
      vm.dispose();
    });
  });

  group('setMode', () {
    test('keeps the old style until the new one is loaded', () async {
      final vm = create();
      await vm.load.execute();
      await prefs.saveMode(MapStyleMode.day);

      final darkLoad = Completer<Result<String>>();
      // Not cached yet: make a fresh view model whose dark fetch is slow.
      when(
        () => tiles.getMapStyle(name: 'swayrider/dark'),
      ).thenAnswer((_) => darkLoad.future);
      final slow = create();
      await slow.load.execute();
      final switching = slow.setMode(MapStyleMode.night);

      expect(slow.mode, MapStyleMode.night, reason: 'the choice shows at once');
      expect(slow.mapStyle, _light, reason: 'the map keeps its style');
      expect(slow.variant, MapVariant.light);

      darkLoad.complete(const Result.ok(_dark));
      await switching;
      expect(slow.mapStyle, _dark);
      expect(slow.variant, MapVariant.dark);
      vm.dispose();
      slow.dispose();
    });

    test('saves the choice', () async {
      final vm = create();
      await vm.load.execute();
      await vm.setMode(MapStyleMode.night);

      expect(
        (await prefs.loadMode() as Ok<MapStyleMode>).value,
        MapStyleMode.night,
      );
      vm.dispose();
    });

    test('the last choice wins when an older load finishes late', () async {
      final darkLoad = Completer<Result<String>>();
      when(
        () => tiles.getMapStyle(name: 'swayrider/dark'),
      ).thenAnswer((_) => darkLoad.future);
      final vm = create();
      await vm.load.execute();

      final toNight = vm.setMode(MapStyleMode.night); // slow
      await vm.setMode(MapStyleMode.day); // back to what is shown
      darkLoad.complete(const Result.ok(_dark));
      await toNight;

      expect(vm.mode, MapStyleMode.day);
      expect(vm.variant, MapVariant.light);
      expect(vm.mapStyle, _light, reason: 'the stale dark style is discarded');
      vm.dispose();
    });

    test('a failed switch keeps the style and counts the failure', () async {
      final vm = create();
      await vm.load.execute();
      when(
        () => tiles.getMapStyle(name: 'swayrider/dark'),
      ).thenAnswer((_) async => Result.error(Exception('offline')));
      final fresh = create();
      await fresh.load.execute();

      await fresh.setMode(MapStyleMode.night);

      expect(fresh.mapStyle, _light);
      expect(fresh.variant, MapVariant.light);
      expect(fresh.switchFailures, 1);
      vm.dispose();
      fresh.dispose();
    });

    test('switching back and forth fetches each variant once', () async {
      final vm = create();
      await vm.load.execute();
      await vm.setMode(MapStyleMode.night);
      await vm.setMode(MapStyleMode.day);
      await vm.setMode(MapStyleMode.night);

      verify(() => tiles.getMapStyle(name: 'swayrider/light')).called(1);
      verify(() => tiles.getMapStyle(name: 'swayrider/dark')).called(1);
      vm.dispose();
    });

    test('notifies listeners when the style changes', () async {
      final vm = create();
      await vm.load.execute();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.setMode(MapStyleMode.night);

      expect(notifications, greaterThanOrEqualTo(2)); // mode, then style
      vm.dispose();
    });
  });

  group('auto without a sensor reading', () {
    test('follows the system appearance', () async {
      final vm = create();
      await vm.load.execute();
      expect(vm.variant, MapVariant.light);

      brightness = Brightness.dark;
      vm.onPlatformBrightnessChanged();
      await Future<void>.delayed(Duration.zero);

      expect(vm.variant, MapVariant.dark);
      expect(vm.mapStyle, _dark);
      vm.dispose();
    });

    test('is ignored for day and night', () async {
      final vm = create();
      await vm.load.execute();
      await vm.setMode(MapStyleMode.day);

      brightness = Brightness.dark;
      vm.onPlatformBrightnessChanged();
      await Future<void>.delayed(Duration.zero);

      expect(vm.variant, MapVariant.light);
      vm.dispose();
    });

    test('a sensor error leaves Auto on the system appearance', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();

        light.emitError('NO_SENSOR');
        async.elapse(const Duration(seconds: 30));

        expect(vm.variant, MapVariant.light);
        expect(vm.autoUsesSensor, isFalse);
        vm.dispose();
      });
    });
  });

  group('auto with the light sensor (Android)', () {
    test('goes dark in a dark room after about two evaluations', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();
        expect(vm.variant, MapVariant.light);
        expect(light.listening, isTrue);

        light.emit(3);
        async.elapse(const Duration(seconds: 5));
        expect(vm.variant, MapVariant.light, reason: 'needs two evaluations');
        light.emit(3);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(vm.variant, MapVariant.dark);
        expect(vm.mapStyle, _dark);
        expect(vm.autoUsesSensor, isTrue);
        vm.dispose();
      });
    });

    test('a brief shadow does not switch the map', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();

        for (var i = 0; i < 6; i++) {
          light.emit(300);
          async.elapse(const Duration(seconds: 1));
        }
        light.emit(1); // a hand over the sensor
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(vm.variant, MapVariant.light);
        vm.dispose();
      });
    });

    test('once the sensor has readings the system appearance is ignored', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();
        light.emit(500);
        async.flushMicrotasks(); // the reading is delivered

        brightness = Brightness.dark;
        vm.onPlatformBrightnessChanged();
        async.flushMicrotasks();

        expect(vm.variant, MapVariant.light);
        vm.dispose();
      });
    });

    test('the sensor runs only for Auto', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();
        expect(light.starts, 1);

        vm.setMode(MapStyleMode.day);
        async.flushMicrotasks();
        expect(light.listening, isFalse);
        expect(light.stops, 1);

        vm.setMode(MapStyleMode.night);
        async.flushMicrotasks();
        expect(light.starts, 1, reason: 'night does not need it either');

        vm.setMode(MapStyleMode.auto);
        async.flushMicrotasks();
        expect(light.listening, isTrue);
        expect(light.starts, 2);
        vm.dispose();
      });
    });

    test(
      'the sensor stops in the background and restarts in the foreground',
      () {
        fakeAsync((async) {
          final vm = create(async: async);
          vm.load.execute();
          async.flushMicrotasks();
          expect(light.listening, isTrue);

          vm.setAppActive(false);
          async.flushMicrotasks();
          expect(light.listening, isFalse);

          vm.setAppActive(true);
          async.flushMicrotasks();
          expect(light.listening, isTrue);
          expect(light.starts, 2);
          vm.dispose();
        });
      },
    );

    test('dispose stops the sensor and the timer', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();

        vm.dispose();
        async.flushMicrotasks();

        expect(light.listening, isFalse);
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  group('iOS (camera needs an explicit opt-in)', () {
    test('Auto at first launch does not start the camera', () {
      fakeAsync((async) {
        final ios = FakeAmbientLightService(needsExplicitOptIn: true);
        final vm = create(async: async, sensor: ios);
        vm.load.execute();
        async.flushMicrotasks();

        expect(vm.mode, MapStyleMode.auto);
        expect(ios.starts, 0);
        expect(vm.autoNeedsCamera, isTrue);
        vm.dispose();
      });
    });

    test('picking Auto explicitly starts it and remembers the consent', () {
      fakeAsync((async) {
        final ios = FakeAmbientLightService(needsExplicitOptIn: true);
        final vm = create(async: async, sensor: ios);
        vm.load.execute();
        async.flushMicrotasks();
        vm.setMode(MapStyleMode.day);
        async.flushMicrotasks();
        expect(ios.starts, 0);

        vm.setMode(MapStyleMode.auto);
        async.flushMicrotasks();

        expect(ios.starts, 1);
        vm.dispose();

        // next launch: the consent is remembered, the camera starts by itself
        final again = create(async: async, sensor: ios);
        again.load.execute();
        async.flushMicrotasks();
        expect(ios.starts, 2);
        again.dispose();
      });
    });

    test('Android needs no opt-in', () {
      fakeAsync((async) {
        final vm = create(async: async);
        vm.load.execute();
        async.flushMicrotasks();
        expect(light.starts, 1);
        expect(vm.autoNeedsCamera, isFalse);
        vm.dispose();
      });
    });
  });
}
