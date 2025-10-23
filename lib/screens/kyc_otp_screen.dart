import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

/// KYC OTP Screen - One-time password verification step
/// Maintains pixel-perfect fidelity to the original Figma design
class KYCOTPScreen extends ConsumerStatefulWidget {
  final VoidCallback? onVerifyOTP;
  final VoidCallback? onBack;
  final String locale;
  final bool isDarkTheme;
  final String? phoneNumber;

  const KYCOTPScreen({
    super.key,
    this.onVerifyOTP,
    this.onBack,
    this.locale = 'en',
    this.isDarkTheme = false,
    this.phoneNumber,
  });

  @override
  ConsumerState<KYCOTPScreen> createState() => _KYCOTPScreenState();
}

class _KYCOTPScreenState extends ConsumerState<KYCOTPScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  int _countdown = 60;
  bool _canResend = false;
  Timer? _timer;

  late AnimationController _animationController;
  late AnimationController _iconController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconController = AnimationController(
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

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _startCountdown();
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _iconController.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown <= 1) {
          _canResend = true;
          _countdown = 0;
          _timer?.cancel();
        } else {
          _countdown--;
        }
      });
    });
  }

  void _handleOtpChange(int index, String value) {
    if (value.length > 1) return; // Prevent multiple characters

    _otpControllers[index].text = value;

    // Auto-focus next input
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    setState(() {}); // Update UI for button state
  }

  Future<void> _handleVerifyOTP() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isVerifying = true;
    });

    HapticFeedback.lightImpact();

    // Simulate verification
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
      if (widget.onVerifyOTP != null) {
        widget.onVerifyOTP!();
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.kycIdCapture);
      }
    }
  }

  void _handleResendOTP() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    _startCountdown();
    HapticFeedback.lightImpact();
  }

  bool get _isOtpComplete {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDarkTheme || theme.brightness == Brightness.dark;
    final phoneNumber = widget.phoneNumber ?? '+1 (555) 123-4567';

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
                        l10n.enterOTPCode,
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

            // Progress
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.stepXofY(2, 4),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '50%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : theme.colorScheme.outline.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Top Section - Icon & Content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Message Icon
                              ScaleTransition(
                                scale: _scaleAnimation,
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
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : null,
                                    borderRadius: BorderRadius.circular(40),
                                    border: isDark
                                        ? Border.all(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: const Icon(
                                    Icons.message,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Content
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.enterSixDigitCode,
                                      textAlign: TextAlign.center,
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
                                      l10n.enterSixDigitCodeWeSentTo(
                                          phoneNumber),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.7)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // OTP Input
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Container(
                                    margin: EdgeInsets.only(
                                      right: index < 5 ? 12 : 0,
                                    ),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: TextFormField(
                                        controller: _otpControllers[index],
                                        focusNode: _otpFocusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : theme.colorScheme.onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: _otpControllers[index]
                                                      .text
                                                      .isNotEmpty
                                                  ? const Color(0xFF3B82F6)
                                                  : (isDark
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : theme
                                                          .colorScheme.outline),
                                              width: 2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: _otpControllers[index]
                                                      .text
                                                      .isNotEmpty
                                                  ? const Color(0xFF3B82F6)
                                                  : (isDark
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : theme
                                                          .colorScheme.outline),
                                              width: 2,
                                            ),
                                          ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(12)),
                                            borderSide: BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) =>
                                            _handleOtpChange(index, value),
                                        onTap: () {
                                          // Clear field on tap for better UX
                                          _otpControllers[index].selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: _otpControllers[index]
                                                    .text
                                                    .length),
                                          );
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 32),

                              // Resend section
                              Column(
                                children: [
                                  Text(
                                    l10n.didntReceiveCode,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.6)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _canResend ? _handleResendOTP : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: _canResend
                                          ? Text(
                                              l10n.resend,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? const Color(0xFF3B82F6)
                                                    : theme.colorScheme.primary,
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.3)
                                                      : theme
                                                          .colorScheme.onSurface
                                                          .withOpacity(0.3),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${_countdown}s',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.3)
                                                        : theme.colorScheme
                                                            .onSurface
                                                            .withOpacity(0.3),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Section - Actions
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: GradientButton(
                              onPressed: (_isOtpComplete && !_isVerifying)
                                  ? _handleVerifyOTP
                                  : null,
                              enabled: _isOtpComplete && !_isVerifying,
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      l10n.verifyCode,
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
          ],
        ),
      ),
    );
  }
}
