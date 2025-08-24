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
      final request = LoginRequest(email: email, password: password);
      final response = await api.login(request);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map) throw const FormatException('Unexpected response format');

        final token = AuthToken.fromJson(data as Map<String, dynamic>);
        await _tokenStore.saveToken(token.value, expiration: token.expiration);

        return User.fromJson(data as Map<String, dynamic>);
      } else {
        throw const NetworkFailure('Login failed');
      }
    } catch (e) {
      throw FailureMapper.fromAny(e);
    }
  }

  Future<User> register(String email, String password, String name, String phoneNumber) async {
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
        if (data is! Map) throw const FormatException('Unexpected response format');

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
        if (data is! Map) throw const FormatException('Unexpected response format');

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

  Future<bool> isAuthenticated() async => _tokenStore.hasToken();
}
