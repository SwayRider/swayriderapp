import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/home/view_models/compass_state.dart';
import 'package:swayriderapp/ui/home/widgets/compass_button.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double bearing,
    required CompassMode mode,
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
          child: CompassButton(
            bearing: bearing,
            mode: mode,
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    ),
  );

  double needleAngle(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(CompassButton),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .getRotation()
      .entry(1, 0);

  testWidgets('the needle turns against the map so it keeps pointing north', (
    tester,
  ) async {
    await pump(tester, bearing: 0, mode: CompassMode.northUp);
    expect(needleAngle(tester), closeTo(0, 1e-9));

    // map rotated 90° clockwise: north is now to the left -> needle -90°
    await pump(tester, bearing: 90, mode: CompassMode.free);
    expect(needleAngle(tester), closeTo(math.sin(-math.pi / 2), 1e-9));

    // map rotated 30°: sin(-30°) = -0.5
    await pump(tester, bearing: 30, mode: CompassMode.free);
    expect(needleAngle(tester), closeTo(-0.5, 1e-9));

    // and the other way
    await pump(tester, bearing: -30, mode: CompassMode.free);
    expect(needleAngle(tester), closeTo(0.5, 1e-9));
  });

  testWidgets('tapping calls onPressed', (tester) async {
    var taps = 0;
    await pump(
      tester,
      bearing: 0,
      mode: CompassMode.northUp,
      onPressed: () => taps++,
    );
    await tester.tap(find.byType(CompassButton));
    expect(taps, 1);
  });

  testWidgets('the semantics label says what a tap does', (tester) async {
    for (final (mode, label) in [
      (CompassMode.northUp, 'Follow the compass heading'),
      (CompassMode.free, 'Point the map north'),
      (
        CompassMode.following,
        'Following the compass heading. Tap to point the map north.',
      ),
    ]) {
      await pump(tester, bearing: 0, mode: mode);
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: '$mode');
    }
  });

  testWidgets('the label is translated', (tester) async {
    await pump(
      tester,
      bearing: 0,
      mode: CompassMode.free,
      locale: const Locale('nl'),
    );
    expect(
      find.bySemanticsLabel('Kaart naar het noorden richten'),
      findsOneWidget,
    );
  });

  testWidgets('only the following mode has the orange ring', (tester) async {
    ShapeBorder? shape(WidgetTester t) => t
        .widget<Material>(
          find.descendant(
            of: find.byType(CompassButton),
            matching: find.byType(Material),
          ),
        )
        .shape;

    await pump(tester, bearing: 0, mode: CompassMode.northUp);
    expect((shape(tester) as CircleBorder).side, BorderSide.none);

    await pump(tester, bearing: 80, mode: CompassMode.following);
    expect((shape(tester) as CircleBorder).side.width, greaterThan(0));
  });
}
