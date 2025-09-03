import 'package:shared_preferences/shared_preferences.dart';

class BiometricPreferences {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable biometric authentication
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      // Handle error
    }
  }

  /// Save user credentials for biometric login
  static Future<void> saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedEmailKey, email);
      await prefs.setString(_savedPasswordKey, password);
    } catch (e) {
      // Handle error
    }
  }

  /// Get saved email
  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedEmailKey);
    } catch (e) {
      return null;
    }
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedPasswordKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if credentials are saved
  static Future<bool> hasSavedCredentials() async {
    try {
      final email = await getSavedEmail();
      final password = await getSavedPassword();
      return email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear saved credentials
  static Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
    } catch (e) {
      // Handle error
    }
  }
}
