import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/navigation/widgets/speed_indicator.dart';

void main() {
  testWidgets('shows the speed and the unit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SpeedIndicator(speedKmh: 74))),
    );

    expect(find.text('74'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    expect(find.bySemanticsLabel('74 km/h'), findsOneWidget);
  });
}
