import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Language provider for managing app locale state
final localeProvider =
    StateProvider<Locale>((ref) => const Locale('en')); // Default to English

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en'));

  void setLanguage(String languageCode) {
    state = Locale(languageCode);
  }

  void toggleLanguage() {
    state =
        state.languageCode == 'en' ? const Locale('fr') : const Locale('en');
  }

  bool get isEnglish => state.languageCode == 'en';
  bool get isFrench => state.languageCode == 'fr';

  String get currentLanguageCode => state.languageCode;
}

final languageNotifier = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

// Helper function to get current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageNotifier);
});
