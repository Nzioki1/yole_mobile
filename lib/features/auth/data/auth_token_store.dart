import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpirationKey = 'token_expiration';

  static Future<void> saveToken(
    String token, {
    String? refreshToken,
    String? expiration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    if (expiration != null) {
      await prefs.setString(_tokenExpirationKey, expiration);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> getTokenExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenExpirationKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpirationKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isTokenExpired() async {
    final expiration = await getTokenExpiration();
    if (expiration == null) return true;

    try {
      final expirationTime = int.parse(expiration);
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return currentTime >= expirationTime;
    } catch (e) {
      return true;
    }
  }
}
