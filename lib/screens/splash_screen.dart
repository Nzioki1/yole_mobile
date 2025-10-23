// lib/screens/splash_screen.dart
// Clean splash with SparklesCore background + responsive YoleLogo
// Safe animations (no TweenAnimationBuilder.delay), well-formed layout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../widgets/sparkles_core.dart';
import '../widgets/yole_logo.dart';
import '../providers/global_locale_provider.dart';

enum SplashVariant { dark, light }

class SplashScreen extends ConsumerWidget {
  final SplashVariant variant;
  final bool sparklesEnabled;
  final String locale;
  final void Function(String view)? onSetCurrentView;

  const SplashScreen({
    super.key,
    this.variant = SplashVariant.dark,
    this.sparklesEnabled = true,
    this.locale = 'en',
    this.onSetCurrentView,
  });

  bool get _isDark => variant == SplashVariant.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = _isDark;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(currentLocaleProvider);
    final localeService = ref.watch(globalLocaleServiceProvider);
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          if (sparklesEnabled)
            const Positioned.fill(
              child: SparklesCore(
                backgroundColor: Colors.transparent,
                particleColor: Colors.white,
                minSize: 1,
                maxSize: 3,
                speed: 0.8,
                particleDensity: 120,
                enablePushOnTap: true,
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 0),
                  duration: const Duration(milliseconds: 800),
                  offsetY: 30,
                  child: const Center(child: YoleLogo()),
                ),
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 600),
                  offsetY: 20,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              child: Text(
                                l10n.sendMoneyDescription,
                                key: ValueKey(l10n.sendMoneyDescription),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF8B5CF6)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: kElevationToShadow[6],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/welcome');
                                  },
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child,
                                        Animation<double> animation) {
                                      return FadeTransition(
                                          opacity: animation, child: child);
                                    },
                                    child: Text(
                                      l10n.getStarted,
                                      key: ValueKey(l10n.getStarted),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF334155),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  child: Text(
                                    l10n.logIn,
                                    key: ValueKey(l10n.logIn),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.8)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _FadeIn(
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: TextButton(
                      onPressed: () {
                        localeService.toggleLanguage();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        foregroundColor:
                            isDark ? Colors.white70 : const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              currentLocale.languageCode == 'fr'
                                  ? '🇫🇷'
                                  : '🇺🇸',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            child: Text(
                              currentLocale.languageCode == 'fr'
                                  ? l10n.french
                                  : l10n.english,
                              key: ValueKey(currentLocale.languageCode == 'fr'
                                  ? l10n.french
                                  : l10n.english),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreenWithContext extends ConsumerWidget {
  final bool sparklesEnabled;
  final void Function(String view)? onSetCurrentView;

  const SplashScreenWithContext({
    super.key,
    this.sparklesEnabled = true,
    this.onSetCurrentView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final variant = brightness == Brightness.dark
        ? SplashVariant.dark
        : SplashVariant.light;

    return SplashScreen(
      variant: variant,
      sparklesEnabled: sparklesEnabled,
      onSetCurrentView:
          onSetCurrentView ?? (view) => debugPrint('setCurrentView: $view'),
    );
  }
}

// ===== Helpers: simple, safe animations =====

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const _FadeSlideIn({
    required this.child,
    required this.delay,
    required this.duration,
    this.offsetY = 20,
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const _FadeIn({
    required this.child,
    required this.delay,
    required this.duration,
  });

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        return Opacity(opacity: v, child: child);
      },
      child: widget.child,
    );
  }
}
