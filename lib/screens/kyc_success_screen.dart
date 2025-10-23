import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/yole_logo.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

/// KYC Success Screen - Verification completion screen
/// Maintains pixel-perfect fidelity to the original Figma design
class KYCSuccessScreen extends ConsumerStatefulWidget {
  final VoidCallback? onContinue;
  final String locale;
  final bool isDarkTheme;

  const KYCSuccessScreen({
    super.key,
    this.onContinue,
    this.locale = 'en',
    this.isDarkTheme = false,
  });

  @override
  ConsumerState<KYCSuccessScreen> createState() => _KYCSuccessScreenState();
}

class _KYCSuccessScreenState extends ConsumerState<KYCSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _iconController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _sparkleRotation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _sparkleRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _glowController.repeat(reverse: true);
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    HapticFeedback.lightImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDarkTheme || theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
                ),
              )
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF0FDF4), Color(0xFFF0F7FF)],
                ),
              ),
        child: Stack(
          children: [
            // Animated background elements for dark theme
            if (isDark) ..._buildBackgroundSparkles(),

            // Main content
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Top Section - Logo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: YoleLogo(
                            height: 64,
                            isDarkTheme: isDark,
                          ),
                        ),
                      ),
                    ),

                    // Middle Section - Success Content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Success Icon with Animation
                              SizedBox(
                                width: 128,
                                height: 128,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow ring
                                    AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 0.9 +
                                              (0.1 * _glowAnimation.value),
                                          child: Container(
                                            width: 128,
                                            height: 128,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark
                                                  ? const Color(0xFF10B981)
                                                      .withOpacity(0.2)
                                                  : const Color(0xFF10B981)
                                                      .withOpacity(0.1),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF10B981)
                                                        .withOpacity(0.3)
                                                    : const Color(0xFF10B981)
                                                        .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // Main success icon
                                    ScaleTransition(
                                      scale: _iconScaleAnimation,
                                      child: Container(
                                        width: 128,
                                        height: 128,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? const Color(0xFF10B981)
                                                  .withOpacity(0.3)
                                              : const Color(0xFF10B981),
                                          border: isDark
                                              ? Border.all(
                                                  color: const Color(0xFF10B981)
                                                      .withOpacity(0.5),
                                                  width: 2,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10B981)
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    // Sparkle effects
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: AnimatedBuilder(
                                        animation: _sparkleRotation,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: _sparkleRotation.value *
                                                2 *
                                                3.14159,
                                            child: Icon(
                                              Icons.auto_awesome,
                                              size: 32,
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.6)
                                                  : const Color(0xFFFBBF24),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    Positioned(
                                      bottom: -8,
                                      left: -8,
                                      child: AnimatedBuilder(
                                        animation: _sparkleRotation,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: -_sparkleRotation.value *
                                                2 *
                                                3.14159,
                                            child: Icon(
                                              Icons.auto_awesome,
                                              size: 24,
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.4)
                                                  : const Color(0xFFFCD34D),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Success Content
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.verificationSuccessful,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      l10n.youAreAllSet,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.7)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                        height: 1.5,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Benefits/Features
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.youCanNow,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.6)
                                                : theme.colorScheme.onSurface
                                                    .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildFeatureItem(
                                              l10n.sendMoneyToDRC,
                                              isDark,
                                            ),
                                            _buildFeatureItem(
                                              l10n.trackYourTransactions,
                                              isDark,
                                            ),
                                            _buildFeatureItem(
                                              l10n.manageYourFavorites,
                                              isDark,
                                            ),
                                            _buildFeatureItem(
                                              l10n.accessYourAccountSecurely,
                                              isDark,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Section - CTA
                    Column(
                      children: [
                        GradientButton(
                          onPressed: _handleContinue,
                          height: 56,
                          child: Text(
                            l10n.continueButton,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Welcome message
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Text(
                                l10n.welcomeToYole,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '✓ ',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundSparkles() {
    return List.generate(8, (index) {
      return AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Positioned(
            left: (index * 13.0 + 10) % 100,
            top: (index * 17.0 + 15) % 100,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * _glowAnimation.value),
                  child: Transform.scale(
                    scale: 1.0 + (0.5 * _glowAnimation.value),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.2 + (0.6 * _glowAnimation.value)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
}
