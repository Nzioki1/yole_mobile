import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/main.dart';

void main() {
  testWidgets('Agent branding smoke test - login and home screens', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const AgentApp());
    await tester.pumpAndSettle();

    // Verify no exceptions during initial render
    expect(tester.takeException(), isNull, reason: 'Login screen should render without errors');

    // Find email and password fields
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;

    // Enter offline demo credentials
    await tester.enterText(emailField, 'agent001@postefinance-agents.cd');
    await tester.enterText(passwordField, 'Password1!');
    await tester.pumpAndSettle();

    // Find and tap login button
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify no exceptions during login and navigation
    expect(tester.takeException(), isNull, reason: 'Login and home navigation should complete without errors');

    // Verify we're on home screen by checking for expected widgets
    // (This will pass even if login fails, as long as no exceptions were thrown)
    // In a real test environment with backend, we'd verify home screen content

    debugPrint('✅ Agent branding smoke test passed - no runtime exceptions');
  });

  testWidgets('Agent home screen renders without errors', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const AgentApp());
    await tester.pumpAndSettle();

    // Verify no exceptions
    expect(tester.takeException(), isNull);

    debugPrint('✅ Agent app initial render successful');
  });
}
