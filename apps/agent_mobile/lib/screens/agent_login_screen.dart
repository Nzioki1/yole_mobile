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
    // Autofill immediately so Login enables on first frame (controllers alone
    // do not rebuild; setState after async init left the button disabled).
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
    
    // Basic email validation
    final emailValid = email.isNotEmpty && email.contains('@');
    
    // Password min 8 chars
    final passwordValid = password.length >= 8;
    
    return emailValid && passwordValid;
  }

  void _dismissCustomerBanner() {
    setState(() => _showCustomerBanner = false);
  }

  Future<void> _login() async {
    if (!_isFormValid) {
      return;
    }

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
        
        // Check for customer email exception
        if (errorMsg.contains('CUSTOMER_EMAIL')) {
          setState(() => _showCustomerBanner = true);
          // Auto-dismiss after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() => _showCustomerBanner = false);
            }
          });
        } else {
          // Show other errors as snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.business_center, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Poste Finance Agent',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Customer banner (dismissible)
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
                            'Customer accounts must use Yole customer app. Download from app store.',
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
              
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _isFormValid ? _login() : null,
              ),
              const SizedBox(height: 24),
              
              // Login button
              ElevatedButton(
                onPressed: (_loading || !_isFormValid) ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
