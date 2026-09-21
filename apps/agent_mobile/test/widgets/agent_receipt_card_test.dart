import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/widgets/agent_receipt_card.dart';
import 'package:agent_mobile/theme/agent_poste_theme.dart';

void main() {
  group('AgentReceiptCard', () {
    testWidgets('displays title and fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAgentPosteTheme(),
          home: Scaffold(
            body: AgentReceiptCard(
              title: 'Bill Payment Successful',
              fields: [
                MapEntry('Customer', 'Jean-Paul Kabila'),
                MapEntry('Biller', 'SNEL Kinshasa'),
                MapEntry('Amount', 'FC 50.00'),
              ],
              onDone: () {},
            ),
          ),
        ),
      );

      expect(find.text('Bill Payment Successful'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Jean-Paul Kabila'), findsOneWidget);
      expect(find.text('Biller'), findsOneWidget);
      expect(find.text('SNEL Kinshasa'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('calls onDone when Done button is tapped', (WidgetTester tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAgentPosteTheme(),
          home: Scaffold(
            body: AgentReceiptCard(
              title: 'Bill Payment Successful',
              fields: [
                MapEntry('Customer', 'Jean-Paul Kabila'),
              ],
              onDone: () => doneCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(doneCalled, true);
    });
  });
}
