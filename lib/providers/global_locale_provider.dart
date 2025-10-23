import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/global_locale_service.dart';

/// Provider for the global locale service
final globalLocaleServiceProvider =
    ChangeNotifierProvider<GlobalLocaleService>((ref) {
  return GlobalLocaleService();
});

/// Provider for the current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  final service = ref.watch(globalLocaleServiceProvider);
  return service.currentLocale;
});

/// Provider for the current language code
final currentLanguageCodeProvider = Provider<String>((ref) {
  final service = ref.watch(globalLocaleServiceProvider);
  return service.currentLanguageCode;
});

/// Provider to check if service is initialized
final isLocaleServiceInitializedProvider = Provider<bool>((ref) {
  final service = ref.watch(globalLocaleServiceProvider);
  return service.isInitialized;
});
