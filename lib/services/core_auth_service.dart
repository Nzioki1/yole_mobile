import '../models/api/auth_response.dart';
import '../providers/auth_provider.dart';
import 'core_api_service.dart';
import 'offline_demo_repository.dart';
import 'storage_service.dart';

/// Authentication service using CoreApiService (mock NestJS backend)
class CoreAuthService implements AuthServiceInterface {
  final CoreApiService _api;
  final StorageService _storage;

  CoreAuthService({
    required CoreApiService api,
    required StorageService storage,
  })  : _api = api,
        _storage = storage;

  static const bool _offlineDemo =
      bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false);

  /// Login user
  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      // Offline demo: authenticate against shared universe seed — no HTTP.
      final response = _offlineDemo
          ? OfflineDemoRepository.instance.login(email: email, password: password)
          : await _api.login(email: email, password: password);
      if (_offlineDemo) {
        await _api.setAccessToken(response['accessToken'] as String);
      }
      
      // CoreApiService already sets the token internally
      // Extract user data from response
      final accessToken = response['accessToken'] as String;
      final customer = response['customer'] as Map<String, dynamic>;
      
      // Create UserProfile from customer data
      final user = UserProfile(
        id: customer['id'] as String,
        email: customer['email'] as String,
        name: customer['firstName'] as String? ?? '',
        surname: customer['lastName'] as String? ?? '',
        phone: customer['phoneE164'] as String?,
        country: 'CD', // Default, not returned by mock API
        isEmailVerified: true, // Mock backend doesn't track this yet
        isPhoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to storage
      await _storage.saveAccessToken(accessToken, 3600); // 1 hour default
      await _storage.saveUserProfile(user);
      await _storage.saveLastLogin();
      
      return AuthResponse(
        accessToken: accessToken,
        refreshToken: null, // Mock backend doesn't provide refresh tokens yet
        tokenType: 'bearer',
        expiresIn: 3600,
        user: user,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Register new user
  @override
  Future<AuthResponse> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String passwordConfirmation,
    required String country,
  }) async {
    try {
      final Map<String, dynamic> response;
      if (_offlineDemo) {
        response = OfflineDemoRepository.instance.register(
          email: email,
          password: password,
          firstName: name,
          lastName: surname,
          phoneE164: null,
        );
        await _api.setAccessToken(response['accessToken'] as String);
      } else {
        response = await _api.register(
          email: email,
          password: password,
          firstName: name,
          lastName: surname,
          phoneE164: null, // Optional for mock backend
        );
      }
      
      // CoreApiService already sets the token internally
      // Extract user data from response
      final accessToken = response['accessToken'] as String;
      final customer = response['customer'] as Map<String, dynamic>;
      
      // Create UserProfile from customer data
      final user = UserProfile(
        id: customer['id'] as String,
        email: customer['email'] as String,
        name: customer['firstName'] as String? ?? name,
        surname: customer['lastName'] as String? ?? surname,
        phone: customer['phoneE164'] as String?,
        country: country,
        isEmailVerified: true, // Mock backend doesn't track this yet
        isPhoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to storage
      await _storage.saveAccessToken(accessToken, 3600); // 1 hour default
      await _storage.saveUserProfile(user);
      await _storage.saveLastLogin();
      
      return AuthResponse(
        accessToken: accessToken,
        refreshToken: null, // Mock backend doesn't provide refresh tokens yet
        tokenType: 'bearer',
        expiresIn: 3600,
        user: user,
      );
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Logout user
  @override
  Future<void> logout() async {
    if (_offlineDemo) {
      OfflineDemoRepository.instance.clearSession();
    }
    await _api.clearAccessToken();
    await _storage.clearTokens();
    await _storage.deleteUserProfile();
  }

  /// Refresh token (not supported by mock backend yet)
  @override
  Future<String> refreshToken() async {
    throw UnimplementedError('Token refresh not implemented in mock backend');
  }

  /// Get user profile
  @override
  Future<UserProfile> getProfile() async {
    // Return from storage since mock backend doesn't have a /me endpoint yet
    final user = await _storage.getUserProfile();
    if (user == null) {
      throw Exception('No user profile found');
    }
    return user;
  }

  /// Check if user is authenticated
  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user from storage
  @override
  Future<UserProfile?> getCurrentUser() async {
    return await _storage.getUserProfile();
  }

  /// Initialize authentication from stored data
  @override
  Future<bool> initializeAuth() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return false;
      
      // Check if token is expired
      if (await _storage.isTokenExpired()) {
        await logout();
        return false;
      }
      
      // Set token in CoreApiService
      await _api.setAccessToken(token);
      
      // Verify we have user profile
      final user = await _storage.getUserProfile();
      return user != null;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Check authentication status
  @override
  Future<bool> checkAuthStatus() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return false;
      
      // Check if token is expired
      if (await _storage.isTokenExpired()) {
        // Mock backend doesn't support refresh yet, so just logout
        await logout();
        return false;
      }
      
      // Set token in CoreApiService
      await _api.setAccessToken(token);
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Send password reset email (not implemented in mock backend)
  @override
  Future<void> sendPasswordReset(String email) async {
    throw UnimplementedError('Password reset not implemented in mock backend');
  }
}
