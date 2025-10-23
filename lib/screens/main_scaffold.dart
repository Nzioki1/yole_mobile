import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/main_bottom_navigation.dart';
import '../providers/app_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final int currentIndex;
  final String? title;

  const MainScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
    this.title,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        if (widget.currentIndex != 0) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        break;
      case 1:
        if (widget.currentIndex != 1) {
          Navigator.pushReplacementNamed(context, '/transactions');
        }
        break;
      case 2:
        if (widget.currentIndex != 2) {
          Navigator.pushReplacementNamed(context, '/favorites');
        }
        break;
      case 3:
        if (widget.currentIndex != 3) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    return Scaffold(
      backgroundColor: appState.isDark ? null : Colors.white,
      body: Container(
        decoration: appState.isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
                ),
              )
            : null,
        child: Column(
          children: [
            if (widget.title != null) _buildAppBar(theme, appState),
            Expanded(child: widget.body),
            MainBottomNavigation(
              currentIndex: widget.currentIndex,
              onTap: _onBottomNavTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, AppState appState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: appState.isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: appState.isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios,
                color: appState.isDark ? Colors.white : Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                widget.title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: appState.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
