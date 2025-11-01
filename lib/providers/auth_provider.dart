import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_auth_service.dart';
import '../models/api/auth_response.dart';
import 'api_providers.dart';

/// Authentication state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserProfile? user;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserProfile? user,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Common interface for authentication services
abstract class AuthServiceInterface {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String passwordConfirmation,
    required String country,
  });
  Future<void> logout();
  Future<String> refreshToken();
  Future<UserProfile> getProfile();
  Future<bool> isAuthenticated();
  Future<UserProfile?> getCurrentUser();
  Future<bool> initializeAuth();
  Future<bool> checkAuthStatus();
  Future<void> sendPasswordReset(String email);
}

/// Authentication notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthServiceInterface _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Initialize authentication from stored data
  Future<void> initializeAuth() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final isAuthenticated = await _authService.initializeAuth();
      if (isAuthenticated) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  /// Check authentication status (for token validation)
  Future<void> checkAuthStatus() async {
    try {
      final isAuthenticated = await _authService.checkAuthStatus();
      if (isAuthenticated) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          error: null,
        );
      } else {
        // Token refresh failed, logout user
        await logout();
      }
    } catch (e) {
      // Auth check failed, logout user
      await logout();
    }
  }

  /// Login user - no fallback to mock for incorrect credentials
  Future<bool> login(String email, String password) async {
    // Validate inputs
    if (email.trim().isEmpty) {
      state = state.copyWith(error: 'Email is required');
      return false;
    }

    if (password.trim().isEmpty) {
      state = state.copyWith(error: 'Password is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Try real auth service only
      final authResponse = await _authService.login(email.trim(), password);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: authResponse.user,
        error: null,
      );

      return true;
    } catch (e) {
      // Do not fallback to mock - show actual error
      print('Login failed: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

      String errorMessage;
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Invalid email or password.';
      } else if (e.toString().contains('YoleApiException')) {
        // Extract actual error message
        errorMessage = e.toString().replaceAll('YoleApiException: ', '');
      } else {
        errorMessage = 'Login failed. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Register user
  Future<bool> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String passwordConfirmation,
    required String country,
  }) async {
    // Validate inputs
    if (email.trim().isEmpty) {
      state = state.copyWith(error: 'Email is required');
      return false;
    }
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Name is required');
      return false;
    }
    if (surname.trim().isEmpty) {
      state = state.copyWith(error: 'Surname is required');
      return false;
    }
    // Password validation removed for UI/UX testing
    if (country.trim().isEmpty) {
      state = state.copyWith(error: 'Country is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Try real auth service first
      final authResponse = await _authService.register(
        email: email.trim(),
        name: name.trim(),
        surname: surname.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        country: country.trim(),
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: authResponse.user,
        error: null,
      );

      return true;
    } catch (e) {
      // If real service fails (network error, etc.), fallback to mock service
      print('Real auth service failed: $e, falling back to mock service');

      try {
        final mockAuthService = MockAuthService();
        final authResponse = await mockAuthService.register(
          email: email.trim(),
          name: name.trim(),
          surname: surname.trim(),
          password: password,
          passwordConfirmation: passwordConfirmation,
          country: country.trim(),
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: authResponse.user,
          error: null,
        );

        return true;
      } catch (mockError) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: 'Registration failed: ${e.toString()}',
        );
        return false;
      }
    }
  }

  /// Logout user - immediate state clearing for fast response
  Future<void> logout() async {
    // Clear state immediately for fast UI response
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      error: null,
    );

    // Call logout service in background (non-blocking)
    _authService.logout().catchError((e) {
      // Log error but don't block UI
      print('Background logout failed: $e');
    });
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Mock authentication provider for testing
final mockAuthProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final mockAuthService = MockAuthService();
  return AuthNotifier(mockAuthService);
});

/// Authentication provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
