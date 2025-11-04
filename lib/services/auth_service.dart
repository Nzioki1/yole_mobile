import 'dart:convert';
import 'package:http/http.dart' as http;
import 'yole_api_service.dart';
import 'storage_service.dart';
import '../models/api/auth_response.dart';
import '../models/api/error_response.dart';
import '../providers/auth_provider.dart';

/// Authentication service for YOLE backend
class AuthService implements AuthServiceInterface {
  final YoleApiService _api;
  final StorageService _storage;

  AuthService({
    required YoleApiService api,
    required StorageService storage,
  })  : _api = api,
        _storage = storage;

  /// Login user - password required
  Future<AuthResponse> login(String email, String password) async {
    try {
      // Validate inputs before sending
      if (email.trim().isEmpty) {
        throw YoleApiException('Email is required', 422);
      }
      if (password.isEmpty) {
        throw YoleApiException('Password is required', 422);
      }

      // Password is required for login
      final Map<String, dynamic> body = {
        'email': email.trim(),
        'password': password,
      };

      final response = await _api.post('/login', body: body, useFormData: true);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

        // Store tokens with expiry and user data
        await _storage.saveAccessToken(
            authResponse.accessToken, authResponse.expiresIn);
        if (authResponse.refreshToken != null) {
          await _storage.saveRefreshToken(authResponse.refreshToken!);
        }

        // Set token in API service
        _api.setAuthToken(authResponse.accessToken);

        // Check if login response already has valid user data
        if (authResponse.user.isValid) {
          // Login response has valid user data - use it and skip /me call
          await _storage.saveUserProfile(authResponse.user);
          await _storage.saveLastLogin();
          
          // Return immediately with user data from login response
          return authResponse;
        } else {
          // Login response doesn't have valid user data - fetch from /me endpoint
          // But do it in background (non-blocking) to return login immediately
          await _storage.saveUserProfile(authResponse.user);
          await _storage.saveLastLogin();
          
          // Fetch full profile in background (non-blocking)
          Future.microtask(() async {
            try {
              final user = await getProfile();
              await _storage.saveUserProfile(user);
            } catch (e) {
              // Log error but don't block login
              print('Warning: Could not fetch user profile in background: $e');
            }
          });
          
          // Return immediately with user data from login response
          return authResponse;
        }
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Login failed: $e');
    }
  }

  /// Register new user - password required
  Future<AuthResponse> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String passwordConfirmation,
    required String country,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'email': email,
        'name': name,
        'surname': surname,
        'country': country,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      final response =
          await _api.post('/register', body: body, useFormData: true);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

        // Store tokens with expiry and user data
        await _storage.saveAccessToken(
            authResponse.accessToken, authResponse.expiresIn);
        if (authResponse.refreshToken != null) {
          await _storage.saveRefreshToken(authResponse.refreshToken!);
        }
        await _storage.saveUserProfile(authResponse.user);
        await _storage.saveLastLogin();

        // Set token in API service
        _api.setAuthToken(authResponse.accessToken);

        return authResponse;
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Registration failed: $e');
    }
  }

  /// Logout user - clear local data immediately, API call in background
  Future<void> logout() async {
    // Clear local data immediately for fast response
    await _storage.clearTokens();
    await _storage.deleteUserProfile();
    _api.clearAuthToken();

    // Call logout API in background (non-blocking)
    if (_api.isAuthenticated) {
      _api.post('/logout', requiresAuth: true).catchError((e) {
        // Log error but don't block UI
        print('Background logout API call failed: $e');
        return http.Response(
            '', 500); // Return a dummy response to satisfy the type
      });
    }
  }

  /// Refresh authentication token
  Future<String> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw YoleApiException('No refresh token available');
      }

      final response = await _api.post('/refresh-token', body: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int? ?? 3600;

        // Update stored token with expiry
        await _storage.saveAccessToken(newAccessToken, expiresIn);
        _api.setAuthToken(newAccessToken);

        return newAccessToken;
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Token refresh failed: $e');
    }
  }

  /// Get user profile with shorter timeout for faster response
  Future<UserProfile> getProfile({Duration? timeout}) async {
    try {
      // Use shorter timeout for profile calls (5 seconds default)
      final response = await _api.get('/me', 
        requiresAuth: true,
        timeout: timeout ?? const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final user = UserProfile.fromJson(jsonDecode(response.body));

        // Update stored profile
        await _storage.saveUserProfile(user);

        return user;
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get profile: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storage.isLoggedIn() && _api.isAuthenticated;
  }

  /// Get current user profile from storage
  Future<UserProfile?> getCurrentUser() async {
    return await _storage.getUserProfile();
  }

  /// Check authentication status
  Future<bool> checkAuthStatus() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return false;

      // Check if token is expired
      if (await _storage.isTokenExpired()) {
        // Try to refresh token
        try {
          await refreshToken();
          return true;
        } catch (e) {
          // Refresh failed, clear tokens
          await _storage.clearTokens();
          _api.clearAuthToken();
          return false;
        }
      }

      // Token is valid, set it in API service
      _api.setAuthToken(token);
      return true;
    } catch (e) {
      await _storage.clearTokens();
      _api.clearAuthToken();
      return false;
    }
  }

  /// Initialize authentication from stored data
  Future<bool> initializeAuth() async {
    try {
      final isAuthenticated = await checkAuthStatus();
      if (isAuthenticated) {
        // Verify token is still valid by getting profile
        await getProfile();
        return true;
      }
      return false;
    } catch (e) {
      // Token is invalid, clear it
      await logout();
      return false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      final response = await _api.post('/password/forgot', body: {
        'email': email,
      });

      if (response.statusCode != 200) {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Password reset failed: $e');
    }
  }
}
