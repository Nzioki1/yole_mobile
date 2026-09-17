import 'package:flutter/material.dart';
import 'screens/agent_login_screen.dart';
import 'screens/agent_home_screen.dart';
import 'widgets/offline_demo_banner.dart';

void main() {
  runApp(const AgentApp());
}

class AgentApp extends StatelessWidget {
  const AgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poste Finance Agent',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AgentLoginScreen(),
      routes: {
        '/home': (context) => const AgentHomeScreen(),
      },
      builder: (context, child) {
        return OfflineDemoBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
