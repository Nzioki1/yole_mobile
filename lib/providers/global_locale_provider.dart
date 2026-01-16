import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Consolidated locale provider using StateNotifier with persistence.
// This preserves the public provider names used across the codebase while
// switching the implementation from ChangeNotifier -> StateNotifier.

class LanguageNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'selected_locale';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LanguageNotifier() : super(const Locale('en'));

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_localeKey);
      if (saved != null) {
        state = Locale(saved);
      } else {
        state = const Locale('en');
      }
    } catch (_) {
      state = const Locale('en');
    }
    _isInitialized = true;
  }

  Future<void> setLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    if (state == newLocale) return;
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
    } catch (_) {
      // ignore
    }
  }

  Future<void> toggleLanguage() async {
    await setLanguage(state.languageCode == 'en' ? 'fr' : 'en');
  }

  String get currentLanguageCode => state.languageCode;
  bool get isEnglish => state.languageCode == 'en';
  bool get isFrench => state.languageCode == 'fr';
}

/// Primary StateNotifier provider for the app locale state
final globalLocaleNotifierProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final notifier = LanguageNotifier();
  // Optionally initialize immediately; callers can also call initialize().
  notifier.initialize();
  return notifier;
});

/// Backwards-compatible provider name: exposes the notifier instance so code
/// that previously used `ref.read(globalLocaleServiceProvider)` to call
/// methods like `toggleLanguage()` keeps working with minimal changes.
final globalLocaleServiceProvider = Provider<LanguageNotifier>((ref) {
  return ref.read(globalLocaleNotifierProvider.notifier);
});

/// Current locale (kept as a Provider for explicitness)
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(globalLocaleNotifierProvider);
});

/// Current language code
final currentLanguageCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(globalLocaleNotifierProvider);
  return locale.languageCode;
});

/// Whether the notifier has finished initialization (loaded from storage)
final isLocaleServiceInitializedProvider = Provider<bool>((ref) {
  // Access notifier to check initialization flag
  final notifier = ref.watch(globalLocaleServiceProvider);
  return notifier.isInitialized;
});
