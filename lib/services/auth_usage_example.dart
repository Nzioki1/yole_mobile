import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import 'yole_api_service.dart';
import 'auth_service.dart';
import 'http_client.dart';
import '../providers/api_providers.dart';

/// Example of how to use the new token-based authentication system
class AuthUsageExample {
  final ProviderContainer _container = ProviderContainer();

  late final StorageService _storage;
  late final YoleApiService _apiService;
  late final AuthService _authService;
  late final AuthenticatedHttpClient _httpClient;

  AuthUsageExample() {
    _storage = _container.read(storageServiceProvider);
    _apiService = _container.read(yoleApiServiceProvider);
    _authService = _container.read(authServiceProvider);
    _httpClient = AuthenticatedHttpClient(
      storage: _storage,
      apiService: _apiService,
    );
  }

  /// Example: Login user
  Future<void> loginUser() async {
    try {
      print('🔐 Logging in user...');

      final authResponse = await _authService.login(
        'user@example.com',
        'password123',
      );

      print('✅ Login successful!');
      print('   Access token: ${authResponse.accessToken.substring(0, 20)}...');
      print('   Token expires in: ${authResponse.expiresIn} seconds');
      print('   User: ${authResponse.user.fullName}');
    } catch (e) {
      print('❌ Login failed: $e');
    }
  }

  /// Example: Make authenticated API calls
  Future<void> makeAuthenticatedCalls() async {
    try {
      print('📡 Making authenticated API calls...');

      // Get user profile
      final profileResponse = await _apiService.getProfile();
      print('   Profile status: ${profileResponse.statusCode}');

      // Get transactions
      final transactionsResponse = await _apiService.getTransactions();
      print('   Transactions status: ${transactionsResponse.statusCode}');

      // Get countries
      final countriesResponse = await _apiService.getCountries();
      print('   Countries status: ${countriesResponse.statusCode}');

      print('✅ All API calls completed successfully!');
    } catch (e) {
      print('❌ API calls failed: $e');
    }
  }

  /// Example: Check authentication status
  Future<void> checkAuthStatus() async {
    try {
      print('🔍 Checking authentication status...');

      final isAuthenticated = await _authService.checkAuthStatus();
      print('   Is authenticated: $isAuthenticated');

      if (isAuthenticated) {
        final user = await _authService.getCurrentUser();
        print('   Current user: ${user?.fullName}');

        final isTokenExpired = await _storage.isTokenExpired();
        print('   Token expired: $isTokenExpired');
      }
    } catch (e) {
      print('❌ Auth status check failed: $e');
    }
  }

  /// Example: Handle token refresh
  Future<void> handleTokenRefresh() async {
    try {
      print('🔄 Handling token refresh...');

      final oldToken = await _storage.getAccessToken();
      print('   Old token: ${oldToken?.substring(0, 20)}...');

      final newToken = await _authService.refreshToken();
      print('   New token: ${newToken.substring(0, 20)}...');

      print('✅ Token refreshed successfully!');
    } catch (e) {
      print('❌ Token refresh failed: $e');
      // If refresh fails, user will be automatically logged out
    }
  }

  /// Example: Logout user
  Future<void> logoutUser() async {
    try {
      print('🚪 Logging out user...');

      await _authService.logout();

      final isAuthenticated = await _storage.isLoggedIn();
      print('   Is authenticated after logout: $isAuthenticated');

      print('✅ Logout successful!');
    } catch (e) {
      print('❌ Logout failed: $e');
    }
  }

  /// Example: Using the HTTP client directly
  Future<void> useHttpClientDirectly() async {
    try {
      print('🌐 Using HTTP client directly...');

      // The HTTP client automatically handles token injection and refresh
      final response = await _httpClient.get('/me');
      print('   Profile response status: ${response.statusCode}');

      final countriesResponse = await _httpClient.get('/countries');
      print('   Countries response status: ${countriesResponse.statusCode}');

      print('✅ HTTP client calls completed!');
    } catch (e) {
      print('❌ HTTP client calls failed: $e');
    }
  }

  /// Example: Complete authentication flow
  Future<void> runCompleteFlow() async {
    print('🚀 Running complete authentication flow...\n');

    // Step 1: Login
    await loginUser();
    print('');

    // Step 2: Check auth status
    await checkAuthStatus();
    print('');

    // Step 3: Make authenticated calls
    await makeAuthenticatedCalls();
    print('');

    // Step 4: Use HTTP client directly
    await useHttpClientDirectly();
    print('');

    // Step 5: Handle token refresh
    await handleTokenRefresh();
    print('');

    // Step 6: Logout
    await logoutUser();
    print('');

    print('🎉 Complete authentication flow finished!');
  }

  /// Clean up resources
  void dispose() {
    _httpClient.dispose();
    _apiService.dispose();
    _container.dispose();
  }
}

/// Run the usage example
Future<void> runAuthUsageExample() async {
  final example = AuthUsageExample();

  try {
    await example.runCompleteFlow();
  } finally {
    example.dispose();
  }
}



