import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/widgets/agent_action_tile.dart';
import 'package:agent_mobile/theme/agent_poste_theme.dart';

void main() {
  group('AgentActionTile', () {
    testWidgets('displays icon and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAgentPosteTheme(),
          home: Scaffold(
            body: AgentActionTile(
              icon: Icons.arrow_downward,
              label: 'Cash In',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.text('Cash In'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAgentPosteTheme(),
          home: Scaffold(
            body: AgentActionTile(
              icon: Icons.arrow_downward,
              label: 'Cash In',
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AgentActionTile));
      await tester.pump();

      expect(tapCalled, true);
    });
  });
}
