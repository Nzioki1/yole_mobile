import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing theme preference persistence
class ThemeStorageService {
  static const String _themeKey = 'theme_mode';
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';

  /// Save theme preference to storage
  static Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      isDarkMode ? _darkTheme : _lightTheme,
    );
  }

  /// Load theme preference from storage
  static Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString(_themeKey);

    // Default to dark theme if no preference is saved
    return themeMode != _lightTheme;
  }

  /// Clear theme preference (useful for testing)
  static Future<void> clearThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}





