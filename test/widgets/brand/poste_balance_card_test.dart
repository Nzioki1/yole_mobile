import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/widgets/brand/poste_balance_card.dart';
import 'package:yole_mobile/theme/poste_theme.dart';

void main() {
  group('PosteBalanceCard', () {
    testWidgets('displays balances when balanceVisible is true', (WidgetTester tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteBalanceCard(
              cdfBalance: 'FC 15,832,157.85',
              usdBalance: '\$ 8,000.00',
              balanceVisible: true,
              onToggleVisibility: () => toggleCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('FC 15,832,157.85'), findsOneWidget);
      expect(find.text('\$ 8,000.00'), findsOneWidget);
      expect(find.text('Total Balance'), findsOneWidget);
    });

    testWidgets('hides balances when balanceVisible is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteBalanceCard(
              cdfBalance: 'FC 15,832,157.85',
              usdBalance: '\$ 8,000.00',
              balanceVisible: false,
              onToggleVisibility: () {},
            ),
          ),
        ),
      );

      expect(find.text('FC ••••••'), findsOneWidget);
      expect(find.text('\$ ••••••'), findsOneWidget);
      expect(find.text('FC 15,832,157.85'), findsNothing);
      expect(find.text('\$ 8,000.00'), findsNothing);
    });

    testWidgets('calls onToggleVisibility when icon button is tapped', (WidgetTester tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteBalanceCard(
              cdfBalance: 'FC 15,832,157.85',
              usdBalance: '\$ 8,000.00',
              balanceVisible: true,
              onToggleVisibility: () => toggleCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(toggleCalled, true);
    });
  });
}
