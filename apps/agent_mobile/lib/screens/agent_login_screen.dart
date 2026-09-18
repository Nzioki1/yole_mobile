import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = AgentApiService();
  bool _loading = false;
  bool _showCustomerBanner = false;

  @override
  void initState() {
    super.initState();
    // Autofill immediately so Login enables on first frame.
    _emailController.text = 'agent001@postefinance-agents.cd';
    _passwordController.text = 'Password1!';
    _api.init();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailValid = email.isNotEmpty && email.contains('@');
    final passwordValid = password.length >= 8;
    return emailValid && passwordValid;
  }

  void _dismissCustomerBanner() {
    setState(() => _showCustomerBanner = false);
  }

  Future<void> _login() async {
    if (!_isFormValid) return;

    setState(() {
      _loading = true;
      _showCustomerBanner = false;
    });

    try {
      await _api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('CUSTOMER_EMAIL')) {
          setState(() => _showCustomerBanner = true);
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) setState(() => _showCustomerBanner = false);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login failed: ${e.toString().replaceAll('Exception: ', '')}',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/brand/poste-finance-logo.png',
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'Agent',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_showCustomerBanner)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Customer accounts must use the Poste Finance customer app.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _dismissCustomerBanner,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showCustomerBanner) const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _isFormValid ? _login() : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_loading || !_isFormValid) ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
