import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/widgets/agent_float_card.dart';
import 'package:agent_mobile/theme/agent_poste_theme.dart';

void main() {
  group('AgentFloatCard', () {
    testWidgets('displays CDF and USD float amounts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAgentPosteTheme(),
          home: Scaffold(
            body: AgentFloatCard(
              cdfFloat: 'FC 5,000,000',
              usdFloat: '\$ 10,000',
            ),
          ),
        ),
      );

      expect(find.text('Agent Float'), findsOneWidget);
      expect(find.text('CDF: FC 5,000,000'), findsOneWidget);
      expect(find.text('USD: \$ 10,000'), findsOneWidget);
    });
  });
}
