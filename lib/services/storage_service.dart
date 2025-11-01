import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api/auth_response.dart';

/// Secure storage service for tokens and user data
class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userProfileKey = 'user_profile';
  static const String _lastLoginKey = 'last_login';

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  /// Save access token with expiry
  Future<void> saveAccessToken(String token, int expiresInSeconds) async {
    await _storage.write(key: _authTokenKey, value: token);
    final expiryTime = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.millisecondsSinceEpoch.toString());
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(DateTime expiryTime) async {
    await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.millisecondsSinceEpoch.toString());
  }

  /// Get token expiry timestamp
  Future<DateTime?> getTokenExpiry() async {
    final timestamp = await _storage.read(key: _tokenExpiryKey);
    if (timestamp == null) return null;

    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiryTime = await getTokenExpiry();
    if (expiryTime == null) return true;

    // Add 5 minute buffer to refresh before actual expiry
    final bufferTime = expiryTime.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(bufferTime);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Clear all authentication tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final json = jsonEncode(profile.toJson());
    await _storage.write(key: _userProfileKey, value: json);
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    final json = await _storage.read(key: _userProfileKey);
    if (json == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return UserProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile() async {
    await _storage.delete(key: _userProfileKey);
  }

  /// Save last login timestamp
  Future<void> saveLastLogin() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _lastLoginKey, value: timestamp);
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLogin() async {
    final timestamp = await _storage.read(key: _lastLoginKey);
    if (timestamp == null) return null;

    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    } catch (e) {
      return null;
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
