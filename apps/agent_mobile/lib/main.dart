import 'package:flutter/material.dart';
import 'screens/agent_login_screen.dart';
import 'screens/agent_home_screen.dart';
import 'screens/assisted_pay_screen.dart';
import 'theme/agent_poste_theme.dart';

void main() {
  runApp(const AgentApp());
}

class AgentApp extends StatelessWidget {
  const AgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poste Finance Agent',
      debugShowCheckedModeBanner: false,
      theme: buildAgentPosteTheme(),
      home: const AgentLoginScreen(),
      routes: {
        '/home': (context) => const AgentHomeScreen(),
        '/assisted-pay': (context) => const AssistedPayScreen(),
      },
    );
  }
}
