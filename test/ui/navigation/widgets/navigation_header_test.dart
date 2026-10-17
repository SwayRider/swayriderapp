import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/navigation/widgets/maneuver_icon.dart';
import 'package:swayriderapp/ui/navigation/widgets/navigation_header.dart';

const _left = RouteManeuver(
  type: 15,
  instruction: 'Turn left onto Main Street.',
  beginShapeIndex: 0,
  endShapeIndex: 0,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    RouteManeuver? maneuver = _left,
    double? distance = 347,
    bool arrived = false,
    bool offRoute = false,
    bool locationError = false,
    VoidCallback? onEnd,
    bool drivesOnRight = true,
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
        body: NavigationHeader(
          maneuver: maneuver,
          distanceMeters: distance,
          arrived: arrived,
          offRoute: offRoute,
          hasLocationError: locationError,
          onEnd: onEnd ?? () {},
          drivesOnRight: drivesOnRight,
        ),
      ),
    ),
  );

  testWidgets('shows icon, distance and instruction', (tester) async {
    await pump(tester);

    final icon = tester.widget<ManeuverIcon>(find.byType(ManeuverIcon));
    expect(icon.type, 15);
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('Turn left onto Main Street.'), findsOneWidget);
  });

  testWidgets('waits for GPS before the first fix', (tester) async {
    await pump(tester, maneuver: null, distance: null);

    expect(find.text('Waiting for GPS…'), findsOneWidget);
  });

  testWidgets('shows the off-route and location error status', (tester) async {
    await pump(tester, offRoute: true);
    expect(find.text('Off route'), findsOneWidget);

    await pump(tester, locationError: true);
    expect(find.textContaining('Location unavailable'), findsOneWidget);
  });

  testWidgets('the close button ends navigation', (tester) async {
    var ended = 0;
    await pump(tester, onEnd: () => ended++);

    await tester.tap(find.byIcon(Icons.close));

    expect(ended, 1);
  });

  testWidgets('arrival shows a Done button instead of the close button', (
    tester,
  ) async {
    var ended = 0;
    await pump(tester, arrived: true, onEnd: () => ended++);

    expect(find.text('You have arrived'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tap(find.text('Done'));
    expect(ended, 1);
  });

  testWidgets('is localized in Dutch', (tester) async {
    await pump(tester, arrived: true, locale: const Locale('nl'));

    expect(find.text('U bent aangekomen'), findsOneWidget);
    expect(find.text('Klaar'), findsOneWidget);
  });

  testWidgets('a roundabout icon gets the exit and the driving side', (
    tester,
  ) async {
    const roundabout = RouteManeuver(
      type: 26,
      instruction: 'Enter the roundabout.',
      beginShapeIndex: 0,
      endShapeIndex: 0,
      roundaboutExitCount: 3,
    );
    await pump(tester, maneuver: roundabout, drivesOnRight: false);

    final icon = tester.widget<ManeuverIcon>(find.byType(ManeuverIcon));
    expect(icon.exitNumber, 3);
    expect(icon.drivesOnRight, isFalse);
  });

  testWidgets('arrival and waiting states keep their plain icons', (
    tester,
  ) async {
    await pump(tester, arrived: true);
    expect(find.byIcon(Icons.flag), findsOneWidget);
    expect(find.byType(ManeuverIcon), findsNothing);
  });
}
