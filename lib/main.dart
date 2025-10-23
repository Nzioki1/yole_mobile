import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'app_router.dart';
import 'providers/global_locale_provider.dart';

// Global theme provider - true = dark, false = light
final themeProvider = StateProvider<bool>((ref) => true);

// Global navigator key for forcing navigation stack rebuild
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: YoleApp(),
    ),
  );
}

class YoleApp extends ConsumerWidget {
  const YoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final localeService = ref.watch(globalLocaleServiceProvider);

    // Initialize the locale service if not already initialized
    if (!localeService.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        localeService.initialize();
      });
    }

    // Debug print to verify theme and locale changes
    print('🎨 THEME CHANGED: ${isDarkMode ? 'DARK' : 'LIGHT'}');
    print('🌐 LOCALE CHANGED: ${currentLocale.languageCode}');

    return MaterialApp(
      key: ValueKey(currentLocale
          .languageCode), // Force complete rebuild on locale change
      navigatorKey: navigatorKey, // Global navigator key for stack rebuild
      title: 'Yole',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
      ],
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      onGenerateRoute: AppRouter.onGenerateRoute,
      // Add this to ensure proper theme propagation
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Prevent text scaling issues
          ),
          child: child!,
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      primaryColor: const Color(0xFF4DA3FF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4DA3FF),
        secondary: Color(0xFF7B4DFF),
        surface: Colors.white,
        background: Color(0xFFF7F8FC),
        onSurface: Colors.black,
        onBackground: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F8FC),
        elevation: 0,
        foregroundColor: Colors.black,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        displayMedium:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        displaySmall:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        headlineMedium:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        headlineSmall:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        titleMedium:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        titleSmall:
            TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
        labelLarge: TextStyle(color: Colors.black87),
        labelMedium: TextStyle(color: Colors.black87),
        labelSmall: TextStyle(color: Colors.black54),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E1230),
      primaryColor: const Color(0xFF4DA3FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4DA3FF),
        secondary: Color(0xFF7B4DFF),
        surface: Color(0xFF11163A),
        background: Color(0xFF0E1230),
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E1230),
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF11163A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2B2F58)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        displayMedium:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        displaySmall:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineMedium:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        headlineSmall:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        titleMedium:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall:
            TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white60),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white60),
      ),
    );
  }
}
