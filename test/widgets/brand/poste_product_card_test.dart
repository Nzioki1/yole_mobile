import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/widgets/brand/poste_product_card.dart';
import 'package:yole_mobile/theme/poste_theme.dart';

void main() {
  group('PosteProductCard', () {
    testWidgets('displays title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteProductCard(
              title: 'Epargne Scolaire',
              description: '2% APY • Min FC 10,000',
              onActivate: () {},
            ),
          ),
        ),
      );

      expect(find.text('Epargne Scolaire'), findsOneWidget);
      expect(find.text('2% APY • Min FC 10,000'), findsOneWidget);
      expect(find.text('Activate'), findsOneWidget);
    });

    testWidgets('calls onActivate when Activate button is tapped', (WidgetTester tester) async {
      bool activateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteProductCard(
              title: 'Epargne Scolaire',
              description: '2% APY • Min FC 10,000',
              onActivate: () => activateCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Activate'));
      await tester.pump();

      expect(activateCalled, true);
    });
  });
}
