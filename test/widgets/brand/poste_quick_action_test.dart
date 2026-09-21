import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/widgets/brand/poste_quick_action.dart';
import 'package:yole_mobile/theme/poste_theme.dart';

void main() {
  group('PosteQuickAction', () {
    testWidgets('displays icon and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteQuickAction(
              icon: Icons.send,
              label: 'Send Money',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Send Money'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildPosteTheme(),
          home: Scaffold(
            body: PosteQuickAction(
              icon: Icons.send,
              label: 'Send Money',
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PosteQuickAction));
      await tester.pump();

      expect(tapCalled, true);
    });
  });
}
