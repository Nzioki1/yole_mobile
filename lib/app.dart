import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme.dart';
import 'core/i18n/generated/l10n.dart';

class YoleApp extends StatelessWidget {
  const YoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.current.appTitle,
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).appTitle)),
      body: Center(child: Text(S.of(context).helloWorld)),
    );
  }
}