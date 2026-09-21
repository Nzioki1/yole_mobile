import 'package:flutter/material.dart';
import 'screens/agent_login_screen.dart';
import 'screens/agent_home_screen.dart';
import 'screens/assisted_pay_screen.dart';

/// Poste Finance teal — matches customer app primary.
const Color kPosteTeal = Color(0xFF00ACAC);

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPosteTeal,
          primary: kPosteTeal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPosteTeal,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPosteTeal,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPosteTeal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AgentLoginScreen(),
      routes: {
        '/home': (context) => const AgentHomeScreen(),
        '/assisted-pay': (context) => const AssistedPayScreen(),
      },
    );
  }
}
