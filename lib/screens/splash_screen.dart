import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../widgets/sparkles_core.dart';
import '../providers/global_locale_provider.dart';
import '../widgets/yole_logo.dart';

/// ======================= API (1:1 with your React props) =======================
/// - variant: 'dark' | 'light'
/// - sparklesEnabled: toggle for the sparkle layer
/// - locale: 'en' | 'fr' (added so you can switch tagline + labels easily)
/// - onGetStarted/onLogin/onLanguage: callbacks that mirror setCurrentView('...')
enum SplashVariant { dark, light }

/// Public wrapper expected by routers: `const SplashScreen()`
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(currentLocaleProvider);
    final localeService = ref.watch(globalLocaleServiceProvider);

    return SplashScreenFlutter(
      variant: isDark ? SplashVariant.dark : SplashVariant.light,
      sparklesEnabled: true,
      locale: currentLocale.languageCode,
      onGetStarted: () => Navigator.pushReplacementNamed(context, '/welcome'),
      onLogin: () => Navigator.pushReplacementNamed(context, '/login'),
      onLanguage: () => localeService.toggleLanguage(),
    );
  }
}

class SplashScreenFlutter extends ConsumerWidget {
  final SplashVariant variant;
  final bool sparklesEnabled;
  final String locale;
  final VoidCallback? onGetStarted;
  final VoidCallback? onLogin;
  final VoidCallback? onLanguage;

  const SplashScreenFlutter({
    super.key,
    this.variant = SplashVariant.dark,
    this.sparklesEnabled = true,
    this.locale = 'en',
    this.onGetStarted,
    this.onLogin,
    this.onLanguage,
  });

  bool get _isDark => variant == SplashVariant.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = _isDark;
    final l10n = AppLocalizations.of(context)!;
    final gradient = isDark
        ? const [Color(0xFF0B0F19), Color(0xFF19173D)]
        : const [Color(0xFFF8FAFC), Colors.white];

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (matches Tailwind bg-gradient-to-b)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
              ),
            ),
          ),

          // Sparkle layer - behind content, toggleable (absolute inset-0, pointer-events-none)
          if (sparklesEnabled)
            const Positioned.fill(
              child: IgnorePointer(
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
            ),

          // Main content (relative z-10) - "Three-section balanced layout"
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Top Section - Equal air space above logo (flex-1 min-h-[80px])
                  const Expanded(child: _MinHeightBox(minHeight: 80)),

                  // Top Third - YOLE Logo/Title (motion.fade + slide)
                  _FadeSlideIn(
                    durationMs: 800,
                    beginOffset: const Offset(0, 30),
                    child: Center(
                      child: YoleLogo(
                        isDarkTheme: isDark,
                        height: 80.0,
                      ),
                    ),
                  ),

                  // Middle Section - Tagline + CTAs (space-y-8 pt-8 max-w-sm mx-auto)
                  _FadeSlideIn(
                    delayMs: 300,
                    durationMs: 600,
                    beginOffset: const Offset(0, 20),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32), // pt-8
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 384), // max-w-sm
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Tagline
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: 320), // max-w-xs
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  child: Text(
                                    l10n.sendMoneyDescription,
                                    key: ValueKey(l10n.sendMoneyDescription),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                      letterSpacing: 0.2,
                                      fontFamily:
                                          'Inter', // Clean, readable sans-serif
                                      color: isDark
                                          ? Colors.white.withOpacity(
                                              0.70) // text-white/70
                                          : const Color(
                                              0xFF475569), // text-slate-600
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: 20 + 16), // space-y-5 + pt-4

                              // Primary Get Started — w-full h-12 rounded-2xl gradient
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: _GradientButton(
                                  text: l10n.getStarted,
                                  onPressed: onGetStarted,
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF3B82F6), // from-[#3B82F6]
                                      Color(0xFF8B5CF6), // to-[#8B5CF6]
                                    ],
                                  ),
                                  elevation: 10,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Secondary Log In — ghost
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: TextButton(
                                  onPressed: onLogin,
                                  style: TextButton.styleFrom(
                                    overlayColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.80)
                                            : const Color(
                                                0xFF334155), // text-slate-700
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
                  ),

                  // Bottom Section — equal air space below language selector
                  const Expanded(child: _MinHeightBox(minHeight: 80)),

                  // Language Selector — anchored bottom center (pb-8)
                  _FadeIn(
                    delayMs: 800,
                    durationMs: 600,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32), // pb-8
                      child: TextButton(
                        onPressed: onLanguage,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          overlayColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              child: Builder(
                                builder: (context) {
                                  final currentLocale =
                                      ref.watch(currentLocaleProvider);
                                  final localeCode = currentLocale.languageCode;
                                  return Text(
                                    localeCode == 'en' ? '🇺🇸' : '🇫🇷',
                                    key: ValueKey(localeCode),
                                    style: const TextStyle(fontSize: 16),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              child: Builder(
                                builder: (context) {
                                  final currentLocale =
                                      ref.watch(currentLocaleProvider);
                                  final localeCode = currentLocale.languageCode;
                                  return Text(
                                    localeCode == 'en'
                                        ? l10n.english
                                        : l10n.french,
                                    key: ValueKey(localeCode == 'en'
                                        ? l10n.english
                                        : l10n.french),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.90)
                                          : const Color(
                                              0xFF64748B), // text-slate-500->700 hover
                                    ),
                                  );
                                },
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
          ),
        ],
      ),
    );
  }
}

/// ============================= Helpers / animations =============================

class _MinHeightBox extends StatelessWidget {
  final double minHeight;
  const _MinHeightBox({required this.minHeight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => ConstrainedBox(
        constraints:
            BoxConstraints(minHeight: minHeight, maxHeight: c.maxHeight),
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int durationMs;
  final int delayMs;
  final Offset beginOffset;
  const _FadeSlideIn({
    required this.child,
    this.durationMs = 800,
    this.delayMs = 0,
    this.beginOffset = const Offset(0, 30),
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.durationMs));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide =
        Tween(begin: Offset(0, widget.beginOffset.dy / 100), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;
  final int durationMs;
  final int delayMs;
  const _FadeIn({required this.child, this.durationMs = 600, this.delayMs = 0});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.durationMs));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: widget.child);
}

/// ============================= Gradient Button =============================
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final BorderRadius borderRadius;
  final LinearGradient gradient;
  final double elevation;

  const _GradientButton({
    required this.text,
    required this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.gradient =
        const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
    this.elevation = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: borderRadius,
      color: Colors.transparent,
      child: Ink(
        decoration:
            BoxDecoration(gradient: gradient, borderRadius: borderRadius),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
