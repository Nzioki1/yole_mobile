import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../router_types.dart';

class YoleBottomNav extends StatelessWidget {
  const YoleBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (currentIndex != 0) {
          Navigator.of(context).pushReplacementNamed(RouteNames.home);
        }
        break;
      case 1:
        if (currentIndex != 1) {
          Navigator.of(context).pushReplacementNamed(RouteNames.transactions);
        }
        break;
      case 2:
        if (currentIndex != 2) {
          Navigator.of(context).pushReplacementNamed(RouteNames.favorites);
        }
        break;
      case 3:
        if (currentIndex != 3) {
          Navigator.of(context).pushReplacementNamed(RouteNames.profile);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF0F1426) : Colors.white,
        selectedItemColor: const Color(0xFF3E8BFF),
        unselectedItemColor: isDark ? Colors.white60 : Colors.black45,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (i) => _go(context, i),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: AppLocalizations.of(context)!.history),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              label: AppLocalizations.of(context)!.favorites),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: AppLocalizations.of(context)!.profile),
        ],
      ),
    );
  }
}
