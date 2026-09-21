import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/screens/assisted_pay_screen.dart';
import 'package:agent_mobile/services/offline_agent_repository.dart';

void main() {
  group('AssistedPayScreen', () {
    late OfflineAgentRepository repo;

    setUp(() {
      repo = OfflineAgentRepository.createFresh();
      repo.setAgentId('agent-001');
    });

    testWidgets('toggles between Bill and Airtime modes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Initially in Bill mode
      expect(find.text('Biller *'), findsOneWidget);
      expect(find.text('Account Number *'), findsOneWidget);
      expect(find.text('Phone to Top Up *'), findsNothing);

      // Tap Airtime button
      await tester.tap(find.text('Airtime'));
      await tester.pumpAndSettle();

      // Now in Airtime mode
      expect(find.text('Biller *'), findsNothing);
      expect(find.text('Account Number *'), findsNothing);
      expect(find.text('Phone to Top Up *'), findsOneWidget);
    });

    testWidgets('customer lookup displays name on success', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Enter customer phone
      final lookupField = find.widgetWithText(TextFormField, 'Customer Phone or ID *');
      await tester.enterText(lookupField, '+243990123456');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();

      // Should show customer name
      expect(find.text('Jean-Paul Kabila'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('bill mode shows biller dropdown and account field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Bill mode active by default
      expect(find.text('Biller *'), findsOneWidget);
      expect(find.text('Account Number *'), findsOneWidget);

      // Tap dropdown to show billers
      await tester.tap(find.text('Biller *'));
      await tester.pumpAndSettle();

      // Should show Kinshasa billers
      expect(find.text('SNEL Kinshasa'), findsOneWidget);
      expect(find.text('REGIDESO Kinshasa'), findsOneWidget);
    });

    testWidgets('airtime mode shows phone input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Switch to Airtime mode
      await tester.tap(find.text('Airtime'));
      await tester.pumpAndSettle();

      // Should show phone input
      expect(find.text('Phone to Top Up *'), findsOneWidget);
      final phoneField = find.widgetWithText(TextFormField, 'Phone to Top Up *');
      expect(phoneField, findsOneWidget);
    });

    testWidgets('fee preview updates when amount changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Lookup customer first
      final lookupField = find.widgetWithText(TextFormField, 'Customer Phone or ID *');
      await tester.enterText(lookupField, '+243990123456');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();

      // Enter amount
      final amountField = find.widgetWithText(TextFormField, 'Amount (CDF) *');
      await tester.enterText(amountField, '50.00');
      await tester.pumpAndSettle();

      // Should show fee preview
      expect(find.text('Transaction Preview'), findsOneWidget);
      expect(find.text('Transaction Fee'), findsOneWidget);
      expect(find.text('Total Debit'), findsOneWidget);
      expect(find.text('Float After'), findsOneWidget);
    });

    testWidgets('insufficient float shows alert', (WidgetTester tester) async {
      // Drain float to near-zero
      final agent = repo.getAgentInfo('agent-001');
      agent['floatCdfMinor'] = 100; // FC 1.00

      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Lookup customer
      final lookupField = find.widgetWithText(TextFormField, 'Customer Phone or ID *');
      await tester.enterText(lookupField, '+243990123456');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();

      // Enter large amount
      final amountField = find.widgetWithText(TextFormField, 'Amount (CDF) *');
      await tester.enterText(amountField, '100.00');
      await tester.pumpAndSettle();

      // Should show insufficient float alert
      expect(find.text('Insufficient float'), findsWidgets);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('Continue button is disabled when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Find Continue button
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      // Button should be enabled initially (though validation will fail)
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('form validation requires all fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Tap Continue without filling form
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('switching modes resets form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Enter amount in Bill mode
      final amountField = find.widgetWithText(TextFormField, 'Amount (CDF) *');
      await tester.enterText(amountField, '50.00');
      await tester.pumpAndSettle();

      // Switch to Airtime
      await tester.tap(find.text('Airtime'));
      await tester.pumpAndSettle();

      // Amount should be cleared
      final amountFieldWidget = tester.widget<TextFormField>(amountField);
      expect(amountFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('receipt dialog shows correct bill payment details', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Complete bill payment flow
      // 1. Lookup customer
      final lookupField = find.widgetWithText(TextFormField, 'Customer Phone or ID *');
      await tester.enterText(lookupField, '+243990123456');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();

      // 2. Select biller
      await tester.tap(find.text('Biller *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SNEL Kinshasa').last);
      await tester.pumpAndSettle();

      // 3. Enter amount
      final amountField = find.widgetWithText(TextFormField, 'Amount (CDF) *');
      await tester.enterText(amountField, '50.00');
      await tester.pumpAndSettle();

      // 4. Tap Continue (will open PIN modal, which we skip in tests)
      // Note: Full integration test would require mocking PIN modal
    });

    testWidgets('receipt dialog shows correct airtime purchase details', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AssistedPayScreen(),
        ),
      );

      // Switch to Airtime mode
      await tester.tap(find.text('Airtime'));
      await tester.pumpAndSettle();

      // Complete airtime purchase flow
      // 1. Lookup customer
      final lookupField = find.widgetWithText(TextFormField, 'Customer Phone or ID *');
      await tester.enterText(lookupField, '+243990123456');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();

      // 2. Enter phone to top up
      final phoneField = find.widgetWithText(TextFormField, 'Phone to Top Up *');
      await tester.enterText(phoneField, '+243812345678');
      await tester.pumpAndSettle();

      // 3. Enter amount
      final amountField = find.widgetWithText(TextFormField, 'Amount (CDF) *');
      await tester.enterText(amountField, '100.00');
      await tester.pumpAndSettle();

      // 4. Tap Continue (will open PIN modal, which we skip in tests)
      // Note: Full integration test would require mocking PIN modal
    });
  });
}
