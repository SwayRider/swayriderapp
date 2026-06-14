import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/core/themes/colors.dart';
import 'package:swayriderapp/ui/core/ui/password_strength_fields.dart';
import 'package:swayriderapp/utils/result.dart';

void main() {
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  setUp(() {
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  });

  tearDown(() {
    passwordController.dispose();
    confirmPasswordController.dispose();
  });

  Future<void> pumpFields(
    WidgetTester tester, {
    required Future<Result<bool>> Function(String) checkPasswordStrength,
    ValueChanged<bool?>? onStrengthChanged,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [AppLocalizationDelegate()],
      home: Scaffold(
        body: PasswordStrengthFields(
          passwordController: passwordController,
          confirmPasswordController: confirmPasswordController,
          checkPasswordStrength: checkPasswordStrength,
          onStrengthChanged: onStrengthChanged,
        ),
      ),
    ));
  }

  Color barColor(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byKey(const Key('password_strength_bar')),
    );
    return (container.decoration as BoxDecoration).color!;
  }

  testWidgets('bar is transparent before any password is entered', (tester) async {
    await pumpFields(tester, checkPasswordStrength: (_) async => const Result.ok(true));

    expect(barColor(tester), Colors.transparent);
  });

  testWidgets('weak password turns the bar orange after the debounce delay', (tester) async {
    final notified = <bool?>[];

    await pumpFields(
      tester,
      checkPasswordStrength: (_) async => const Result.ok(false),
      onStrengthChanged: notified.add,
    );

    await tester.enterText(find.byType(TextField).first, 'abc123');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(barColor(tester), AppColors.apexOrange);
    expect(notified, [false]);
  });

  testWidgets('strong password turns the bar green after the debounce delay', (tester) async {
    final notified = <bool?>[];

    await pumpFields(
      tester,
      checkPasswordStrength: (_) async => const Result.ok(true),
      onStrengthChanged: notified.add,
    );

    await tester.enterText(find.byType(TextField).first, 'Tr0ub4dorXk9pQ!');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(barColor(tester), AppColors.green);
    expect(notified, [true]);
  });

  testWidgets('rapid edits within the debounce window only trigger one check', (tester) async {
    var callCount = 0;

    await pumpFields(tester, checkPasswordStrength: (_) async {
      callCount++;
      return const Result.ok(true);
    });

    final passwordField = find.byType(TextField).first;
    await tester.enterText(passwordField, 'a');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(passwordField, 'ab');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(passwordField, 'abc');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(callCount, 1);
  });

  testWidgets('clearing the password resets the bar to transparent', (tester) async {
    final notified = <bool?>[];

    await pumpFields(
      tester,
      checkPasswordStrength: (_) async => const Result.ok(true),
      onStrengthChanged: notified.add,
    );

    final passwordField = find.byType(TextField).first;
    await tester.enterText(passwordField, 'Tr0ub4dorXk9pQ!');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(barColor(tester), AppColors.green);

    await tester.enterText(passwordField, '');
    await tester.pump();

    expect(barColor(tester), Colors.transparent);
    expect(notified, [true, null]);
  });
}
