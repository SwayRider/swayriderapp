import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:swayriderapp/data/services/map_style_preference_service.dart';
import 'package:swayriderapp/domain/models/map/map_style_mode.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/home/view_models/map_style_view_model.dart';
import 'package:swayriderapp/ui/home/widgets/map_style_button.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MapStyleViewModel viewModel;
  late FakeAmbientLightService light;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final tiles = MockTilesRepository();
    when(
      () => tiles.getMapStyle(name: any(named: 'name')),
    ).thenAnswer((_) async => const Result.ok('{}'));
    light = FakeAmbientLightService();
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool ios = false,
  }) async {
    if (ios) light = FakeAmbientLightService(needsExplicitOptIn: true);
    final tiles = MockTilesRepository();
    when(
      () => tiles.getMapStyle(name: any(named: 'name')),
    ).thenAnswer((_) async => const Result.ok('{}'));
    viewModel = MapStyleViewModel(
      tilesRepository: tiles,
      preferences: MapStylePreferenceService(
        preferences: SharedPreferencesAsync(),
      ),
      ambientLight: light,
      styleId: 'swayrider',
      platformBrightness: () => Brightness.light,
    );
    await tester.runAsync(() => viewModel.load.execute());
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('nl')],
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizationDelegate(),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMapStyleSheet(context, viewModel: viewModel),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  tearDown(() => viewModel.dispose());

  group('MapStyleButton', () {
    Future<void> pump(
      WidgetTester tester,
      MapStyleMode mode,
      MapVariant variant, {
      VoidCallback? onPressed,
      Locale locale = const Locale('en'),
    }) => tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('nl')],
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizationDelegate(),
        ],
        home: Scaffold(
          body: Center(
            child: MapStyleButton(
              mode: mode,
              variant: variant,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      ),
    );

    setUp(() {
      // viewModel is created lazily by pumpSheet; give tearDown something.
      viewModel = MapStyleViewModel(
        tilesRepository: MockTilesRepository(),
        preferences: MapStylePreferenceService(
          preferences: SharedPreferencesAsync(),
        ),
        ambientLight: FakeAmbientLightService(),
        styleId: 'swayrider',
        platformBrightness: () => Brightness.light,
      );
    });

    testWidgets('shows the choice as text and the variant as icon', (
      tester,
    ) async {
      await pump(tester, MapStyleMode.auto, MapVariant.dark);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);

      await pump(tester, MapStyleMode.auto, MapVariant.light);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);

      await pump(tester, MapStyleMode.day, MapVariant.light);
      expect(find.text('Day'), findsOneWidget);

      await pump(tester, MapStyleMode.night, MapVariant.dark);
      expect(find.text('Night'), findsOneWidget);
    });

    testWidgets('is translated', (tester) async {
      await pump(
        tester,
        MapStyleMode.night,
        MapVariant.dark,
        locale: const Locale('nl'),
      );
      expect(find.text('Nacht'), findsOneWidget);
    });

    testWidgets('tapping calls onPressed', (tester) async {
      var taps = 0;
      await pump(
        tester,
        MapStyleMode.day,
        MapVariant.light,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(MapStyleButton));
      expect(taps, 1);
    });
  });

  group('picker sheet', () {
    testWidgets('lists day, night and auto and marks the current choice', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('Map style'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      // the default is Auto, so exactly one check mark, on that row
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Auto'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('choosing night applies it and closes the sheet', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Night'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(viewModel.mode, MapStyleMode.night);
      expect(find.text('Map style'), findsNothing, reason: 'sheet closed');
    });

    testWidgets('the Auto hint is shown, the camera hint only on iOS', (
      tester,
    ) async {
      await pumpSheet(tester);
      expect(
        find.textContaining('depending on the light around you'),
        findsOneWidget,
      );
      expect(find.textContaining('camera'), findsNothing);
    });

    testWidgets('on iOS the camera is mentioned', (tester) async {
      await pumpSheet(tester, ios: true);
      expect(find.textContaining('camera measures the light'), findsOneWidget);
    });

    testWidgets('is translated', (tester) async {
      await pumpSheet(tester, locale: const Locale('nl'));
      expect(find.text('Kaartstijl'), findsOneWidget);
      expect(find.text('Dag'), findsOneWidget);
      expect(find.text('Nacht'), findsOneWidget);
      expect(find.text('Automatisch'), findsOneWidget);
    });
  });
}
