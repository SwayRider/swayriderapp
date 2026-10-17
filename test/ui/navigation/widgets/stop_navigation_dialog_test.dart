import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/navigation/widgets/stop_navigation_dialog.dart';

void main() {
  bool? answer;

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    answer = null;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('nl')],
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizationDelegate(),
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  answer = await confirmStopNavigation(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks, with Yes highlighted and No plain', (tester) async {
    await open(tester);

    expect(find.text('Stop navigation?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Yes'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'No'), findsOneWidget);
  });

  testWidgets('Yes confirms', (tester) async {
    await open(tester);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(answer, isTrue);
    expect(find.text('Stop navigation?'), findsNothing);
  });

  testWidgets('No keeps navigating', (tester) async {
    await open(tester);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('tapping outside the dialog counts as No', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('is localized in Dutch', (tester) async {
    await open(tester, locale: const Locale('nl'));

    expect(find.text('Navigatie stoppen?'), findsOneWidget);
    expect(find.text('Ja'), findsOneWidget);
    expect(find.text('Nee'), findsOneWidget);
  });
}
