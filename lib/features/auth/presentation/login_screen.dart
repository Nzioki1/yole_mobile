import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/generated/l10n.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/biometric_preferences.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _showingBiometricPrompt = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Check if biometric login is available and enabled
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final isEnabled = await BiometricPreferences.isBiometricEnabled();

      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
      });

      // If biometric login is enabled, show the prompt automatically
      if (isEnabled && isAvailable) {
        _showBiometricLogin();
      }
    } catch (e) {
      print('🔐 Error checking biometric availability: $e');
    }
  }

  /// Show biometric login prompt
  Future<void> _showBiometricLogin() async {
    if (_showingBiometricPrompt) return;

    setState(() {
      _showingBiometricPrompt = true;
    });

    try {
      print('🔐 Showing biometric login prompt...');
      final result = await BiometricService.authenticate();

      if (result) {
        print(
          '🔐 Biometric authentication successful, proceeding with login...',
        );
        // Get saved credentials and proceed with login
        final savedEmail = await BiometricPreferences.getSavedEmail();
        if (savedEmail != null && savedEmail.isNotEmpty) {
          // Use saved email and proceed with biometric login
          _email.text = savedEmail;
          // For biometric login, we'll use a special authentication flow
          _proceedWithBiometricLogin(savedEmail);
        } else {
          // Fallback to manual login
          _showManualLoginForm();
        }
      } else {
        print('🔐 Biometric authentication failed or cancelled');
        _showManualLoginForm();
      }
    } catch (e) {
      print('🔐 Biometric authentication error: $e');
      _showManualLoginForm();
    } finally {
      setState(() {
        _showingBiometricPrompt = false;
      });
    }
  }

  /// Proceed with biometric login using saved credentials
  void _proceedWithBiometricLogin(String email) {
    // For now, we'll use a test password since we're in development
    // In production, this would use the actual saved password or a secure token
    final notifier = ref.read(authProvider.notifier);
    notifier.login(email, 'test'); // Using test password for biometric login
  }

  /// Show manual login form
  void _showManualLoginForm() {
    setState(() {
      // The form is already visible, just ensure biometric prompt is hidden
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    // Listen for authentication state changes in build method
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && !previous!.isAuthenticated) {
        print(
          '🔍 LoginScreen: Authentication state changed to authenticated, navigating to dashboard...',
        );
        // Use a small delay to ensure state is fully updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.go('/home');
          }
        });
      }
    });

    // Add debug logging
    print(
      '🔍 LoginScreen: Current state - isAuthenticated: ${state.isAuthenticated}, loading: ${state.loading}, error: ${state.error}',
    );

    // Simple test version to isolate issues
    return Scaffold(
      appBar: AppBar(
        title: Text(t.login),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors
            .grey[100], // Add background color to see if screen is rendering
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Test text to see if basic rendering works
              const Text(
                'Yole Mobile Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Simple form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          print(
                            '🔍 LoginScreen: Login button pressed with email: ${_email.text}',
                          );
                          notifier.login(_email.text, _password.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Signup link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/signup');
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Biometric login button (only show if biometric is available and enabled)
              if (_biometricAvailable && _biometricEnabled) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showingBiometricPrompt
                      ? null
                      : _showBiometricLogin,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(
                    _showingBiometricPrompt
                        ? 'Authenticating...'
                        : 'Login with Biometrics',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Or enter your credentials below:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],

              // Debug info
              if (state.loading)
                const Text(
                  'Logging in...',
                  style: TextStyle(color: Colors.blue),
                ),
              if (state.isAuthenticated)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green[100],
                  child: const Text(
                    '✅ AUTHENTICATED! Should redirect to dashboard...',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Text(
                    '❌ Error: ${state.error!.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Add manual navigation test button
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  print('🔍 LoginScreen: Manual navigation button pressed');
                  // Test manual navigation to see if router works
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('🔧 Test: Go to Dashboard'),
              ),

              // Add current state display for debugging
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue[50],
                child: Column(
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Loading: ${state.loading}'),
                    Text('Authenticated: ${state.isAuthenticated}'),
                    Text('Has User: ${state.user != null}'),
                    if (state.user != null)
                      Text('User Email: ${state.user!.email}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
