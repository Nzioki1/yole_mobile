import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'create_account_screen.dart';
import 'yole_theme.dart';
import 'yole_localization.dart';

/// Example app showing how to use the Create Account Screen
/// with proper theming and localization
class YoleApp extends StatefulWidget {
  const YoleApp({super.key});

  @override
  State<YoleApp> createState() => _YoleAppState();
}

class _YoleAppState extends State<YoleApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLE',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: YoleTheme.lightTheme,
      darkTheme: YoleTheme.darkTheme,
      themeMode: _themeMode,
      
      // Localization configuration
      locale: _locale,
      supportedLocales: YoleLocalizations.supportedLocales,
      localizationsDelegates: const [
        YoleLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Navigation
      home: CreateAccountScreenExample(
        onThemeChanged: (ThemeMode mode) {
          setState(() {
            _themeMode = mode;
          });
        },
        onLocaleChanged: (Locale locale) {
          setState(() {
            _locale = locale;
          });
        },
      ),
    );
  }
}

/// Example wrapper showing Create Account Screen with navigation
class CreateAccountScreenExample extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLocaleChanged;

  const CreateAccountScreenExample({
    super.key,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLE Demo'),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          
          // Language toggle
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: onLocaleChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Locale('en'),
                child: Row(
                  children: [
                    Text('🇺🇸'),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Locale('fr'),
                child: Row(
                  children: [
                    Text('🇫🇷'),
                    SizedBox(width: 8),
                    Text('Français'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CreateAccountScreen(
        onBackPressed: () {
          Navigator.of(context).pop();
        },
        onCreateAccount: () {
          _showSuccessDialog(context);
        },
        onSignInPressed: () {
          _showSignInDialog(context);
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.success),
        content: const Text('Account creation would proceed here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.signIn),
        content: const Text('Sign in screen would appear here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }
}

/// Main entry point
void main() {
  runApp(const YoleApp());
}

/// Example showing how to integrate with form validation
class CreateAccountWithValidation extends StatefulWidget {
  const CreateAccountWithValidation({super.key});

  @override
  State<CreateAccountWithValidation> createState() => _CreateAccountWithValidationState();
}

class _CreateAccountWithValidationState extends State<CreateAccountWithValidation> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    return CreateAccountScreen(
      onBackPressed: () => Navigator.of(context).pop(),
      onCreateAccount: () {
        if (_validateForm()) {
          _submitForm();
        }
      },
      onSignInPressed: () {
        // Navigate to sign in
      },
    );
  }

  bool _validateForm() {
    final l10n = context.l10n;
    
    // Email validation
    if (_emailController.text.isEmpty) {
      _showError(l10n.fieldRequired);
      return false;
    }
    
    if (!_isValidEmail(_emailController.text)) {
      _showError(l10n.invalidEmail);
      return false;
    }
    
    // Name validation
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      _showError(l10n.fieldRequired);
      return false;
    }
    
    // Password validation
    if (_passwordController.text.length < 8) {
      _showError(l10n.passwordTooShort);
      return false;
    }
    
    // Country validation
    if (_selectedCountry == null) {
      _showError(l10n.fieldRequired);
      return false;
    }
    
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _submitForm() {
    // Handle form submission
    print('Form submitted with:');
    print('Email: ${_emailController.text}');
    print('Name: ${_firstNameController.text} ${_lastNameController.text}');
    print('Country: $_selectedCountry');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}