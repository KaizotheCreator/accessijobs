import 'package:accessijobs/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accessijobs/navigator.dart';

void main() {
  testWidgets('AppNavigator loads without crashing', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: MyApp(initialRoute: '/choose_login'), // 👈 provide initialRoute
      ),
    );

    // Example check: see if a widget from your AppNavigator is present
    expect(find.byType(AppNavigator), findsOneWidget);
  });
}
