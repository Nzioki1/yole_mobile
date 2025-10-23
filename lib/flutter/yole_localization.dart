import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class YoleLocalization {
  const YoleLocalization();

  static const LocalizationsDelegate<YoleLocalization> delegate =
      _YoleLocalizationDelegate();

  // Static fields expected by main.dart
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('fr', 'FR'),
  ];

  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supported,
  ) {
    if (locale == null) return supported.first;
    return supported.firstWhere(
      (l) => l.languageCode == locale.languageCode,
      orElse: () => supported.first,
    );
  }

  // Example strings (expand as needed)
  String get helloWorld => 'Hello World';
}

class _YoleLocalizationDelegate
    extends LocalizationsDelegate<YoleLocalization> {
  const _YoleLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<YoleLocalization> load(Locale locale) async {
    return const YoleLocalization();
  }

  @override
  bool shouldReload(_YoleLocalizationDelegate old) => false;
}
