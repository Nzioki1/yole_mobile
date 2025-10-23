import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/yole_logo.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

/// Email Verification Screen - Email confirmation screen
/// Maintains pixel-perfect fidelity to the original Figma design
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onResendEmail;
  final String locale;
  final bool isDarkTheme;
  final String? email;

  const EmailVerificationScreen({
    super.key,
    this.onContinue,
    this.onBack,
    this.onResendEmail,
    this.locale = 'en',
    this.isDarkTheme = false,
    this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;
  int _countdown = 0;
  Timer? _timer;

  late AnimationController _animationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Delay icon animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _iconAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconAnimationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleResendEmail() async {
    if (_isResending || _countdown > 0) return;

    setState(() {
      _isResending = true;
      _countdown = 60;
    });

    HapticFeedback.lightImpact();

    // Simulate sending email
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      // Start countdown
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_countdown <= 1) {
              _countdown = 0;
              timer.cancel();
            } else {
              _countdown--;
            }
          });
        } else {
          timer.cancel();
        }
      });

      widget.onResendEmail?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDarkTheme || theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF19173D) : Colors.white,
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
                ),
              )
            : const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.emailVerification,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Top Section - Logo & Illustration
                    Expanded(
                      flex: 2,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              YoleLogo(
                                height: 64,
                                isDarkTheme: isDark,
                              ),

                              const SizedBox(height: 32),

                              // Email Icon
                              AnimatedBuilder(
                                animation: _iconScaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _iconScaleAnimation.value,
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        gradient: isDark
                                            ? null
                                            : const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF8B5CF6)
                                                ],
                                              ),
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : null,
                                        borderRadius: BorderRadius.circular(48),
                                        border: isDark
                                            ? Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: const Icon(
                                        Icons.mail_outline,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 32),

                              // Content
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.verifyEmail,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.enterVerificationCode,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.7)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.weSentVerificationLink,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Section - Actions
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Column(
                              children: [
                                // Continue button (for demo purposes)
                                GradientButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (widget.onContinue != null) {
                                      widget.onContinue!();
                                    } else {
                                      Navigator.pushReplacementNamed(
                                          context, RouteNames.kyc);
                                    }
                                  },
                                  child: Text(
                                    l10n.continueButton,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Resend email section
                                Column(
                                  children: [
                                    Text(
                                      l10n.didntReceiveEmail,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: _isResending || _countdown > 0
                                          ? null
                                          : _handleResendEmail,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        child: _isResending
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        isDark
                                                            ? const Color(
                                                                0xFF3B82F6)
                                                            : theme.colorScheme
                                                                .primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    l10n.sending,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: (_isResending ||
                                                              _countdown > 0)
                                                          ? (isDark
                                                              ? Colors.white
                                                                  .withOpacity(
                                                                      0.3)
                                                              : theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.3))
                                                          : (isDark
                                                              ? const Color(
                                                                  0xFF3B82F6)
                                                              : theme
                                                                  .colorScheme
                                                                  .primary),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                _countdown > 0
                                                    ? '${l10n.resendIn} ${_countdown}s'
                                                    : l10n
                                                        .resendVerificationEmail,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: (_isResending ||
                                                          _countdown > 0)
                                                      ? (isDark
                                                          ? Colors.white
                                                              .withOpacity(0.3)
                                                          : theme.colorScheme
                                                              .onSurface
                                                              .withOpacity(0.3))
                                                      : (isDark
                                                          ? const Color(
                                                              0xFF3B82F6)
                                                          : theme.colorScheme
                                                              .primary),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Back to register
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.wrongEmail,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        if (widget.onBack != null) {
                                          widget.onBack!();
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text(
                                        l10n.goBack,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF3B82F6)
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}
