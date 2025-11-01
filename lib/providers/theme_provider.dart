import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_storage_service.dart';

/// Theme state class
class ThemeState {
  final bool isDarkMode;
  final bool isInitialized;

  const ThemeState({
    required this.isDarkMode,
    this.isInitialized = false,
  });

  ThemeState copyWith({
    bool? isDarkMode,
    bool? isInitialized,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Theme notifier that handles persistence
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState(isDarkMode: true)) {
    _initializeTheme();
  }

  /// Initialize theme from storage
  Future<void> _initializeTheme() async {
    try {
      final savedTheme = await ThemeStorageService.loadThemeMode();
      state = state.copyWith(
        isDarkMode: savedTheme,
        isInitialized: true,
      );
    } catch (e) {
      // If loading fails, use default dark theme
      state = state.copyWith(
        isDarkMode: true,
        isInitialized: true,
      );
    }
  }

  /// Toggle theme and save to storage
  Future<void> toggleTheme() async {
    final newTheme = !state.isDarkMode;

    // Update state immediately for fast UI response
    state = state.copyWith(isDarkMode: newTheme);

    // Save to storage in background
    ThemeStorageService.saveThemeMode(newTheme).catchError((e) {
      print('Failed to save theme preference: $e');
    });
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDarkMode) async {
    // Update state immediately for fast UI response
    state = state.copyWith(isDarkMode: isDarkMode);

    // Save to storage in background
    ThemeStorageService.saveThemeMode(isDarkMode).catchError((e) {
      print('Failed to save theme preference: $e');
    });
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Convenience provider for just the theme mode boolean
final isDarkModeProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.isDarkMode;
});





