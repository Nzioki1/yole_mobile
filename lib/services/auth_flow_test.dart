import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'storage_service.dart';
import 'yole_api_service.dart';
import 'auth_service.dart';
import 'http_client.dart';

/// Test class to verify the authentication flow
class AuthFlowTest {
  final StorageService _storage = StorageService();
  late YoleApiService _apiService;
  late AuthService _authService;
  late AuthenticatedHttpClient _httpClient;

  AuthFlowTest() {
    _apiService = YoleApiService(storage: _storage);
    _authService = AuthService(api: _apiService, storage: _storage);
    _httpClient = AuthenticatedHttpClient(
      storage: _storage,
      apiService: _apiService,
    );
  }

  /// Test the complete authentication flow
  Future<void> testAuthFlow() async {
    print('🧪 Starting Authentication Flow Test...\n');

    try {
      // Step 1: Test login
      print('1️⃣ Testing login...');
      final loginResult = await _testLogin();
      if (!loginResult) {
        print('❌ Login test failed');
        return;
      }
      print('✅ Login successful\n');

      // Step 2: Test protected request
      print('2️⃣ Testing protected request...');
      final protectedResult = await _testProtectedRequest();
      if (!protectedResult) {
        print('❌ Protected request test failed');
        return;
      }
      print('✅ Protected request successful\n');

      // Step 3: Test token refresh
      print('3️⃣ Testing token refresh...');
      final refreshResult = await _testTokenRefresh();
      if (!refreshResult) {
        print('❌ Token refresh test failed');
        return;
      }
      print('✅ Token refresh successful\n');

      // Step 4: Test logout
      print('4️⃣ Testing logout...');
      final logoutResult = await _testLogout();
      if (!logoutResult) {
        print('❌ Logout test failed');
        return;
      }
      print('✅ Logout successful\n');

      print('🎉 All authentication flow tests passed!');
    } catch (e) {
      print('❌ Authentication flow test failed: $e');
    }
  }

  /// Test login functionality
  Future<bool> _testLogin() async {
    try {
      // Use a test email (this will use mock service if real API fails)
      await _authService.login('test@example.com', 'password123');

      // Check if tokens are stored
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();
      final isExpired = await _storage.isTokenExpired();

      print('   Access token stored: ${accessToken != null}');
      print('   Refresh token stored: ${refreshToken != null}');
      print('   Token expired: $isExpired');

      return accessToken != null && refreshToken != null && !isExpired;
    } catch (e) {
      print('   Login error: $e');
      return false;
    }
  }

  /// Test protected request
  Future<bool> _testProtectedRequest() async {
    try {
      // Test getting user profile
      final response = await _apiService.getProfile();
      print('   Profile request status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('   Profile data received: ${data.keys.join(', ')}');
        return true;
      }

      return false;
    } catch (e) {
      print('   Protected request error: $e');
      return false;
    }
  }

  /// Test token refresh
  Future<bool> _testTokenRefresh() async {
    try {
      // Get current token
      final oldToken = await _storage.getAccessToken();
      print('   Old token: ${oldToken?.substring(0, 20)}...');

      // Refresh token
      final newToken = await _authService.refreshToken();
      print('   New token: ${newToken.substring(0, 20)}...');

      // Check if token changed
      final tokenChanged = oldToken != newToken;
      print('   Token changed: $tokenChanged');

      return tokenChanged;
    } catch (e) {
      print('   Token refresh error: $e');
      return false;
    }
  }

  /// Test logout
  Future<bool> _testLogout() async {
    try {
      // Check if authenticated before logout
      final wasAuthenticated = await _storage.isLoggedIn();
      print('   Was authenticated before logout: $wasAuthenticated');

      // Perform logout
      await _authService.logout();

      // Check if tokens are cleared
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();
      final isAuthenticated = await _storage.isLoggedIn();

      print('   Access token after logout: ${accessToken != null}');
      print('   Refresh token after logout: ${refreshToken != null}');
      print('   Is authenticated after logout: $isAuthenticated');

      return accessToken == null && refreshToken == null && !isAuthenticated;
    } catch (e) {
      print('   Logout error: $e');
      return false;
    }
  }

  /// Test token expiry checking
  Future<void> testTokenExpiry() async {
    print('🧪 Testing Token Expiry Logic...\n');

    try {
      // Login first
      await _authService.login('test@example.com', 'password123');

      // Check initial token status
      final isExpired = await _storage.isTokenExpired();
      final expiryTime = await _storage.getTokenExpiry();

      print('   Token expired: $isExpired');
      print('   Expiry time: $expiryTime');

      // Simulate token expiry by setting a past expiry time
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      await _storage.saveTokenExpiry(pastTime);

      final isExpiredAfter = await _storage.isTokenExpired();
      print('   Token expired after setting past time: $isExpiredAfter');

      print('✅ Token expiry test completed');
    } catch (e) {
      print('❌ Token expiry test failed: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _httpClient.dispose();
    _apiService.dispose();
  }
}

/// Run the authentication flow test
Future<void> runAuthFlowTest() async {
  final test = AuthFlowTest();

  try {
    await test.testAuthFlow();
    await test.testTokenExpiry();
  } finally {
    test.dispose();
  }
}
