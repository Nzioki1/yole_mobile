import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

/// Global locale service that manages language state across the entire app
/// Uses ChangeNotifier for proper state management and SharedPreferences for persistence
class GlobalLocaleService extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';

  Locale _currentLocale = const Locale('en'); // Default to English
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isFrench => _currentLocale.languageCode == 'fr';

  /// Initialize the service and load saved locale from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      if (savedLocale != null) {
        _currentLocale = Locale(savedLocale);
      } else {
        _currentLocale = const Locale('en'); // Default to English
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If there's an error, use default locale
      _currentLocale = const Locale('en');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change the locale and save to SharedPreferences
  Future<void> changeLocale(Locale newLocale) async {
    if (_currentLocale == newLocale) return;

    _currentLocale = newLocale;
    notifyListeners();

    // Note: Removed navigation stack clearing as it caused black screen
    // The MaterialApp will rebuild automatically due to ValueKey(currentLocale.languageCode)
    // and all Consumer widgets will rebuild due to notifyListeners()

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);
    } catch (e) {
      // If saving fails, the change is still applied in memory
      print('Failed to save locale preference: $e');
    }
  }

  /// Toggle between English and French
  Future<void> toggleLanguage() async {
    final newLocale = _currentLocale.languageCode == 'en'
        ? const Locale('fr')
        : const Locale('en');
    await changeLocale(newLocale);
  }

  /// Set language by code
  Future<void> setLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    await changeLocale(newLocale);
  }
}
