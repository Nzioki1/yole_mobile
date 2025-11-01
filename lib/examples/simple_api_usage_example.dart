import 'dart:io';
import 'package:flutter/material.dart';
import '../services/simple_api_service.dart';

/// Example widget showing how to use SimpleApiService
/// This demonstrates the simple interface requested
class SimpleApiUsageExample extends StatefulWidget {
  @override
  _SimpleApiUsageExampleState createState() => _SimpleApiUsageExampleState();
}

class _SimpleApiUsageExampleState extends State<SimpleApiUsageExample> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _resultMessage = '';
  String? _accessToken;
  bool _isLoggedIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Example: Login user
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    // Use SimpleApiService - clean and simple!
    final result = await SimpleApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;

      if (result['success'] == true) {
        // Extract token from response
        final data = result['data'] as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;
        _isLoggedIn = true;
        _resultMessage =
            'Login successful! Token: ${_accessToken?.substring(0, 20)}...';
      } else {
        _resultMessage = 'Login failed: ${result['error']}';
      }
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_resultMessage),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  /// Example: Get user profile
  Future<void> _getProfile() async {
    if (_accessToken == null) {
      setState(() {
        _resultMessage = 'Please login first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await SimpleApiService.getMyProfile(_accessToken!);

    setState(() {
      _isLoading = false;

      if (result['success'] == true) {
        _resultMessage = 'Profile data: ${result['data']}';
        print('Profile data: ${result['data']}');
      } else {
        _resultMessage = 'Failed to get profile: ${result['error']}';

        // Check if token expired
        if (result['error'].contains('Unauthorized')) {
          _handleTokenExpired();
        }
      }
    });
  }

  /// Example: Handle token expiration
  Future<void> _handleTokenExpired() async {
    // Try to refresh token if available
    if (_accessToken != null) {
      final refreshResult = await SimpleApiService.refreshToken(_accessToken!);

      if (refreshResult['success'] == true) {
        // Update token and retry
        final data = refreshResult['data'] as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;

        // Retry the profile request
        await _getProfile();
      } else {
        // Redirect to login
        setState(() {
          _isLoggedIn = false;
          _accessToken = null;
          _resultMessage = 'Session expired. Please login again.';
        });
      }
    }
  }

  /// Example: Get countries
  Future<void> _getCountries() async {
    setState(() {
      _isLoading = true;
    });

    final result = await SimpleApiService.getCountries();

    setState(() {
      _isLoading = false;

      if (result['success'] == true) {
        _resultMessage = 'Countries loaded successfully';
        print('Countries: ${result['data']}');
      } else {
        _resultMessage = 'Failed to get countries: ${result['error']}';
      }
    });
  }

  /// Example: Logout
  Future<void> _logout() async {
    if (_accessToken == null) {
      setState(() {
        _isLoggedIn = false;
        _accessToken = null;
        _resultMessage = 'Logged out';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await SimpleApiService.logout(_accessToken!);

    setState(() {
      _isLoading = false;
      _isLoggedIn = false;
      _accessToken = null;
      _resultMessage = result['success'] == true
          ? 'Logged out successfully'
          : 'Logout error';
    });
  }

  /// Example: Get transactions
  Future<void> _getTransactions() async {
    if (_accessToken == null) {
      setState(() {
        _resultMessage = 'Please login first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await SimpleApiService.getTransactions(_accessToken!);

    setState(() {
      _isLoading = false;

      if (result['success'] == true) {
        _resultMessage = 'Transactions loaded';
        print('Transactions: ${result['data']}');
      } else {
        _resultMessage = 'Failed to get transactions: ${result['error']}';
      }
    });
  }

  /// Example: Send SMS OTP
  Future<void> _sendSmsOtp() async {
    if (_accessToken == null) {
      setState(() {
        _resultMessage = 'Please login first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await SimpleApiService.sendSmsOtp(
      token: _accessToken!,
      phoneCode: '+254',
      phone: '0700000000',
    );

    setState(() {
      _isLoading = false;

      if (result['success'] == true) {
        _resultMessage = 'SMS OTP sent successfully';
      } else {
        _resultMessage = 'Failed to send SMS: ${result['error']}';
      }
    });
  }

  /// Example: Get system status
  Future<void> _getStatus() async {
    setState(() {
      _isLoading = true;
    });

    final result = await SimpleApiService.getStatus();

    setState(() {
      _isLoading = false;

      if (result['success'] == true) {
        _resultMessage = 'System status: ${result['data']}';
      } else {
        _resultMessage = 'Failed to get status: ${result['error']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple API Usage Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Login Section
            if (!_isLoggedIn) ...[
              const Text(
                'Login',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ],

            // Authenticated Section
            if (_isLoggedIn) ...[
              Text(
                'Logged in as: ${_emailController.text}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _logout,
                child: const Text('Logout'),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Public API Examples
            const Text(
              'Public APIs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _getStatus,
              child: const Text('Get Status'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _getCountries,
              child: const Text('Get Countries'),
            ),

            if (_isLoggedIn) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Protected API Examples
              const Text(
                'Protected APIs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _getProfile,
                child: const Text('Get My Profile'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _getTransactions,
                child: const Text('Get Transactions'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendSmsOtp,
                child: const Text('Send SMS OTP'),
              ),
            ],

            // Result Message
            if (_resultMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_resultMessage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



