import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/screens/agent_home_screen.dart';
import 'package:agent_mobile/screens/agent_history_screen.dart';
import 'package:agent_mobile/theme/agent_poste_theme.dart';
import 'package:agent_mobile/services/offline_agent_repository.dart';
import 'package:agent_mobile/services/agent_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    OfflineAgentRepository.createFresh();
  });

  testWidgets('offline login then home renders AgentFloatCard', (tester) async {
    final api = AgentApiService();
    await api.init();
    // login offline
    await api.login(
      email: 'agent001@postefinance-agents.cd',
      password: 'Password1!',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAgentPosteTheme(),
        routes: {
          '/': (_) => const AgentHomeScreen(),
          '/assisted-pay': (_) => const Scaffold(body: Text('assisted')),
        },
        home: const AgentHomeScreen(),
      ),
    );
    // allow async load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    final ex = tester.takeException();
    expect(ex, isNull, reason: 'Home threw: $ex');
    expect(find.textContaining('Agent Float'), findsWidgets);
  });

  testWidgets('history screen pumps', (tester) async {
    final api = AgentApiService();
    await api.init();
    await api.login(
      email: 'agent001@postefinance-agents.cd',
      password: 'Password1!',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAgentPosteTheme(),
        home: const AgentHistoryScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final ex = tester.takeException();
    expect(ex, isNull, reason: 'History threw: $ex');
  });
}
