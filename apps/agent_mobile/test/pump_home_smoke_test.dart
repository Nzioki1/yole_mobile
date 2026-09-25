import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/screens/agent_home_screen.dart';
import 'package:agent_mobile/theme/agent_poste_theme.dart';
import 'package:agent_mobile/services/offline_agent_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AgentHomeScreen pumps without exception', (tester) async {
    // Ensure offline repo ready if possible
    try {
      OfflineAgentRepository.instance; // may need createFresh
    } catch (_) {}

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAgentPosteTheme(),
        home: const AgentHomeScreen(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(AgentHomeScreen), findsOneWidget);
  });
}
