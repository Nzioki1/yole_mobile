import 'package:flutter/material.dart';
import '../services/complete_api_service.dart';

class ApiTestScreen extends StatefulWidget {
  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'test@yole.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Test');
  String _log = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ApiService.init();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    _addLog('App initialized - Logged in: $isLoggedIn');

    if (isLoggedIn) {
      _addLog(
          'Current token: ${ApiService.getCurrentToken()?.substring(0, 30)}...');
      await _testProtectedEndpoints();
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    _addLog('🔐 Attempting login...');

    final result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _addLog('✅ Login successful!');
      _addLog('Token: ${ApiService.getCurrentToken()?.substring(0, 30)}...');
      await _testProtectedEndpoints();
    } else {
      _addLog('❌ Login failed: ${result['error']}');
    }
  }

  Future<void> _testProtectedEndpoints() async {
    _addLog('\n🚀 Testing protected endpoints...');

    // Test profile first
    final profile = await ApiService.getMyProfile();
    _addLog('Profile: ${profile['success'] ? '✅' : '❌ ${profile['error']}'}');

    if (profile['success']) {
      // Test other endpoints
      final charges = await ApiService.getCharges(10.0, 'USD', 'KE');
      _addLog('Charges: ${charges['success'] ? '✅' : '❌ ${charges['error']}'}');

      final serviceCharge = await ApiService.getServiceCharge();
      _addLog(
          'Service Charge: ${serviceCharge['success'] ? '✅' : '❌ ${serviceCharge['error']}'}');

      final transactions = await ApiService.getTransactions();
      _addLog(
          'Transactions: ${transactions['success'] ? '✅' : '❌ ${transactions['error']}'}');
    }
  }

  Future<void> _refreshTokenManually() async {
    _addLog('\n🔄 Manually refreshing token...');
    final result = await ApiService.refreshToken();
    _addLog(result['success'] ? '✅ Token refreshed' : '❌ Refresh failed');
    _addLog('New token: ${ApiService.getCurrentToken()?.substring(0, 30)}...');
  }

  Future<void> _testPublicEndpoints() async {
    _addLog('\n🌐 Testing public endpoints...');

    final status = await ApiService.getStatus();
    _addLog('Status: ${status['success'] ? '✅' : '❌'}');

    final countries = await ApiService.getCountries();
    _addLog('Countries: ${countries['success'] ? '✅' : '❌'}');
  }

  Future<void> _logout() async {
    _addLog('\n🚪 Logging out...');
    await ApiService.logout();
    _addLog('✅ Logged out successfully');
    setState(() {});
  }

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  void _clearLog() {
    setState(() {
      _log = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yole Pesa API Tester'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Login Form
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    SizedBox(height: 10),
                    _isLoading
                        ? CircularProgressIndicator()
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _login,
                                  child: Text('Login'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _logout,
                                  child: Text('Logout'),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testPublicEndpoints,
                    child: Text('Test Public'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testProtectedEndpoints,
                    child: Text('Test Protected'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshTokenManually,
                    child: Text('Refresh Token'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _clearLog,
                    child: Text('Clear Log'),
                  ),
                ],
              ),
            ),

            // Log Output
            SizedBox(height: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _log.isEmpty ? 'Logs will appear here...' : _log,
                      style: TextStyle(fontFamily: 'Monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
