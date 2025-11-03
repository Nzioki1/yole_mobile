import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/yole_logo.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Forgot Password Screen - Password reset screen
/// Maintains pixel-perfect fidelity to the original Figma design
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSendResetLink;
  final VoidCallback? onBackToLogin;
  final bool isDarkTheme;

  const ForgotPasswordScreen({
    super.key,
    this.onSendResetLink,
    this.onBackToLogin,
    this.isDarkTheme = false,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _step = 'request'; // 'request' or 'success'
  bool _isLoading = false;

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
    _emailController.dispose();
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    // Call password reset API
    final success = await ref.read(authProvider.notifier).sendPasswordReset(
          _emailController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        setState(() {
          _step = 'success';
        });

        // Restart animations for success state
        _animationController.reset();
        _iconAnimationController.reset();
        _animationController.forward();

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _iconAnimationController.forward();
          }
        });

        widget.onSendResetLink?.call();
      } else {
        // Show error message
        final error = ref.read(authProvider).error;
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _handleBackToLogin() {
    HapticFeedback.lightImpact();
    if (widget.onBackToLogin != null) {
      widget.onBackToLogin!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDarkTheme || theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF19173D) : Colors.white,
      resizeToAvoidBottomInset: true,
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
                      onPressed: _handleBackToLogin,
                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.resetPassword,
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

            // Content - Now scrollable
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: _step == 'request'
                    ? _buildRequestStep(isDark, theme)
                    : _buildSuccessStep(isDark, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStep(bool isDark, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 32),
            // Top Section - Logo & Content
            FadeTransition(
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

                    // Mail Icon
                    AnimatedBuilder(
                      animation: _iconScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
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
                              color:
                                  isDark ? Colors.white.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(40),
                              border: isDark
                                  ? Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: const Icon(
                              Icons.mail_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Content
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.enterEmailToReset,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!
                                .weWillSendInstructions,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: isDark
                                  ? const EdgeInsets.all(24)
                                  : EdgeInsets.zero,
                              decoration: isDark
                                  ? BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.emailAddress,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: l10n.emailPlaceholder,
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : theme.colorScheme.onSurface
                                                  .withOpacity(0.5),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : theme
                                                .inputDecorationTheme.fillColor,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.2)
                                                : theme.colorScheme.outline,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.2)
                                                : theme.colorScheme.outline,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF3B82F6),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 16),
                                      ),
                                      validator: (value) {
                                        final l10n =
                                            AppLocalizations.of(context)!;
                                        if (value == null || value.isEmpty) {
                                          return l10n.pleaseEnterEmail;
                                        }
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                            .hasMatch(value)) {
                                          return l10n.pleaseEnterValidEmail;
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) =>
                                          _handleSendResetLink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bottom Section - Actions
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final l10n = AppLocalizations.of(context)!;
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        GradientButton(
                          onPressed: _isLoading ? null : _handleSendResetLink,
                          enabled:
                              !_isLoading && _emailController.text.isNotEmpty,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  l10n.sendResetLink,
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.rememberPassword,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleBackToLogin,
                              child: Text(
                                l10n.signIn,
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
        );
      },
    );
  }

  Widget _buildSuccessStep(bool isDark, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 32),
            // Success State
            FadeTransition(
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

                    // Success Icon
                    AnimatedBuilder(
                      animation: _iconScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF10B981).withOpacity(0.2)
                                  : const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(48),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF10B981).withOpacity(0.3)
                                    : const Color(0xFF10B981).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Content
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.checkYourEmail,
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
                            AppLocalizations.of(context)!
                                .checkEmailResetInstructions,
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
                            AppLocalizations.of(context)!.followLinkToReset,
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

            const SizedBox(height: 32),

            // Bottom Actions
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final l10n = AppLocalizations.of(context)!;
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        GradientButton(
                          onPressed: _handleBackToLogin,
                          child: Text(
                            l10n.backToLogin,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Try again
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _step = 'request';
                                  _emailController.clear();
                                });
                                _animationController.reset();
                                _iconAnimationController.reset();
                                _animationController.forward();
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _iconAnimationController.forward();
                                  }
                                });
                              },
                              child: Text(
                                l10n.tryAgain,
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
        );
      },
    );
  }
}
