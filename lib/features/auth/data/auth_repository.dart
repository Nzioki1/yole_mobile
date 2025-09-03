import 'package:dio/dio.dart';
import '../../../core/network/failure_mapper.dart';
import '../../../core/network/failure.dart';
import 'models.dart';
import 'auth_api.dart';

import 'i_auth_token_store.dart';
import 'token_store_adapter.dart';

class AuthRepository {
  final AuthApi api;
  final IAuthTokenStore _tokenStore;

  AuthRepository(this.api, {IAuthTokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStoreAdapter();

  Future<User> login(String email, String password) async {
    try {
      print('🔍 AuthRepository: Starting login for email: $email');
      final request = LoginRequest(email: email, password: password);
      final response = await api.login(request);

      print('🔍 AuthRepository: Login response status: ${response.statusCode}');
      print('🔍 AuthRepository: Login response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map) {
          print(
            '🔍 AuthRepository: Response data is not a Map, throwing FormatException',
          );
          throw const FormatException('Unexpected response format');
        }

        final token = AuthToken.fromJson(data as Map<String, dynamic>);
        print(
          '🔍 AuthRepository: Token parsed successfully: ${token.value.substring(0, 20)}...',
        );

        await _tokenStore.saveToken(
          token.value,
          refreshToken: token.refreshToken,
          expiration: token.expiration,
        );
        print('🔍 AuthRepository: Token saved to storage');

        // Create a minimal user object since the API response doesn't contain user data
        // We'll use the email from the login request and create a basic user
        final user = User(
          id: '0', // We don't have an ID from the response, use string '0'
          email: email, // Use the email from the login request
          kycStatus: (data['kyc_submitted'] == 1 && data['kyc_validated'] == 1)
              ? KycStatus.kycVerified
              : KycStatus.kycPending,
        );
        print('🔍 AuthRepository: User created successfully: ${user.email}');
        return user;
      } else {
        print(
          '🔍 AuthRepository: Login failed with status: ${response.statusCode}',
        );
        throw const NetworkFailure('Login failed');
      }
    } catch (e) {
      print('🔍 AuthRepository: Login error: $e');
      throw FailureMapper.fromAny(e);
    }
  }

  Future<User> register(
    String email,
    String password,
    String name,
    String phoneNumber,
  ) async {
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );
      final response = await api.register(request);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map)
          throw const FormatException('Unexpected response format');

        final token = AuthToken.fromJson(data as Map<String, dynamic>);
        await _tokenStore.saveToken(token.value, expiration: token.expiration);

        return User.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        throw const ValidationFailure('Validation error');
      } else {
        throw const NetworkFailure('Registration failed');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final response = await api.sendEmailVerification();
      if (response.statusCode != 200) {
        throw const NetworkFailure('Failed to send email verification');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await api.forgotPassword(email);
      if (response.statusCode != 200) {
        throw const NetworkFailure('Failed to send password reset email');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<String?> refreshToken() async {
    try {
      final response = await api.refreshToken();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map)
          throw const FormatException('Unexpected response format');

        final token = AuthToken.fromJson(data as Map<String, dynamic>);
        await _tokenStore.saveToken(token.value, expiration: token.expiration);
        return token.value;
      } else {
        throw const NetworkFailure('Token refresh failed');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<void> logout() async => _tokenStore.clearToken();

  Future<bool> isAuthenticated() async {
    try {
      final hasToken = await _tokenStore.hasToken();
      if (!hasToken) {
        print('🔍 AuthRepository: No token found, not authenticated');
        return false;
      }

      final isExpired = await _tokenStore.isTokenExpired();
      if (isExpired) {
        print(
          '🔍 AuthRepository: Token is expired, clearing and not authenticated',
        );
        await _tokenStore.clearToken();
        return false;
      }

      print('🔍 AuthRepository: Token is valid, user is authenticated');
      return true;
    } catch (e) {
      print('🔍 AuthRepository: Error checking authentication: $e');
      // Clear token on error to be safe
      await _tokenStore.clearToken();
      return false;
    }
  }
}
