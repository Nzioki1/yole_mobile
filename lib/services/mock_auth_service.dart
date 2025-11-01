import '../models/api/auth_response.dart';
import '../providers/auth_provider.dart';

/// Mock authentication service for testing when backend is unavailable
class MockAuthService implements AuthServiceInterface {
  /// Mock login - always succeeds for testing (password optional)
  Future<AuthResponse> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate inputs (password is optional for UI/UX testing)
    if (email.trim().isEmpty) {
      throw Exception('Email is required');
    }
    // Password validation removed for UI/UX testing

    // Mock successful login
    return AuthResponse(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: UserProfile(
        id: '1',
        email: email,
        name: 'Test',
        surname: 'User',
        country: 'CD',
        phone: '+243123456789',
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Mock register - always succeeds for testing
  Future<AuthResponse> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String passwordConfirmation,
    required String country,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate inputs (password optional for UI/UX testing)
    if (email.trim().isEmpty) {
      throw Exception('Email is required');
    }
    if (name.trim().isEmpty) {
      throw Exception('Name is required');
    }
    if (surname.trim().isEmpty) {
      throw Exception('Surname is required');
    }
    // Password validation removed for UI/UX testing
    if (country.trim().isEmpty) {
      throw Exception('Country is required');
    }

    // Mock successful registration
    return AuthResponse(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: UserProfile(
        id: '1',
        email: email,
        name: name,
        surname: surname,
        country: country,
        phone: '+243123456789',
        isEmailVerified: false,
        isPhoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Mock logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Mock token refresh
  Future<String> refreshToken() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Mock get profile
  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return UserProfile(
      id: '1',
      email: 'test@yole.com',
      name: 'Test',
      surname: 'User',
      country: 'CD',
      phone: '+243123456789',
      isEmailVerified: true,
      isPhoneVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Mock check if authenticated
  Future<bool> isAuthenticated() async {
    return true;
  }

  /// Mock get current user
  Future<UserProfile?> getCurrentUser() async {
    return UserProfile(
      id: '1',
      email: 'test@yole.com',
      name: 'Test',
      surname: 'User',
      country: 'CD',
      phone: '+243123456789',
      isEmailVerified: true,
      isPhoneVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Mock initialize auth - return false to prevent auto-login
  Future<bool> initializeAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return false; // Changed to false to prevent automatic login
  }

  /// Mock check auth status
  Future<bool> checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Mock send password reset
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
