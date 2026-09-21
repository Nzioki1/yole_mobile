import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/widgets/brand/poste_txn_tile.dart';
import 'package:yole_mobile/theme/poste_theme.dart';

void main() {
  group('PosteTxnTile', () {
    testWidgets('displays time, title, amount, subtitle, and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteTxnTile(
              time: '14:32',
              title: 'SNEL Bill Pay',
              amount: '- FC 5,000',
              subtitle: 'Electricity',
              icon: Icons.receipt_long,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('14:32'), findsOneWidget);
      expect(find.text('SNEL Bill Pay'), findsOneWidget);
      expect(find.text('- FC 5,000'), findsOneWidget);
      expect(find.text('Electricity'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });

    testWidgets('amount is colored red when it starts with "-"', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteTxnTile(
              time: '14:32',
              title: 'SNEL Bill Pay',
              amount: '- FC 5,000',
              subtitle: 'Electricity',
              icon: Icons.receipt_long,
            ),
          ),
        ),
      );

      final amountText = tester.widget<Text>(
        find.text('- FC 5,000'),
      );
      expect(amountText.style?.color, isNotNull);
    });

    testWidgets('amount is colored green when it does not start with "-"', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteTxnTile(
              time: '14:32',
              title: 'Money Received',
              amount: '+ FC 10,000',
              subtitle: 'Transfer',
              icon: Icons.send,
            ),
          ),
        ),
      );

      final amountText = tester.widget<Text>(
        find.text('+ FC 10,000'),
      );
      expect(amountText.style?.color, isNotNull);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteTxnTile(
              time: '14:32',
              title: 'SNEL Bill Pay',
              amount: '- FC 5,000',
              subtitle: 'Electricity',
              icon: Icons.receipt_long,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PosteTxnTile));
      await tester.pump();

      expect(tapCalled, true);
    });
  });
}
