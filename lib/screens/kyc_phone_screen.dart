import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

/// KYC Phone Screen - Phone number verification step
/// Maintains pixel-perfect fidelity to the original Figma design
class KYCPhoneScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSendOTP;
  final VoidCallback? onBack;
  final String locale;
  final bool isDarkTheme;

  const KYCPhoneScreen({
    super.key,
    this.onSendOTP,
    this.onBack,
    this.locale = 'en',
    this.isDarkTheme = false,
  });

  @override
  ConsumerState<KYCPhoneScreen> createState() => _KYCPhoneScreenState();
}

class _KYCPhoneScreenState extends ConsumerState<KYCPhoneScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '';
  bool _isLoading = false;

  late AnimationController _animationController;
  late AnimationController _iconController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Prioritize African countries at the top, followed by others alphabetically
  final List<Map<String, String>> _countryCodes = [
    // African countries first
    {
      'code': '+243',
      'country': 'CD',
      'flag': '🇨🇩',
      'name': 'Democratic Republic of Congo'
    },
    {'code': '+233', 'country': 'GH', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+254', 'country': 'KE', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+234', 'country': 'NG', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+27', 'country': 'ZA', 'flag': '🇿🇦', 'name': 'South Africa'},
    {'code': '+255', 'country': 'TZ', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+256', 'country': 'UG', 'flag': '🇺🇬', 'name': 'Uganda'},
    // Other countries alphabetically
    {'code': '+32', 'country': 'BE', 'flag': '🇧🇪', 'name': 'Belgium'},
    {'code': '+1', 'country': 'CA', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+33', 'country': 'FR', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸', 'name': 'United States'},
  ];

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

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _iconController.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Map<String, String>? get _selectedCountryData {
    return _countryCodes
        .where((country) =>
            '${country['code']}-${country['country']}' == _selectedCountryCode)
        .firstOrNull;
  }

  Future<void> _handleSendOTP() async {
    if (_phoneController.text.isEmpty || _selectedCountryCode.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    // Simulate sending OTP
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (widget.onSendOTP != null) {
        widget.onSendOTP!();
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.kycOtp);
      }
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
                        l10n.phoneVerification,
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
                        l10n.stepXofY(1, 4),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '25%',
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
                    value: 0.25,
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
                              // Phone Icon
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
                                    Icons.phone,
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
                                      l10n.enterPhoneNumber,
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
                                      l10n.weWillSendVerificationCode,
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

                              // Form
                              Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : theme.colorScheme.outline
                                            .withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Country Code Selector
                                    Text(
                                      l10n.country,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedCountryCode.isEmpty
                                          ? null
                                          : _selectedCountryCode,
                                      decoration: InputDecoration(
                                        hintText: l10n.selectYourCountry,
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
                                      ),
                                      dropdownColor: isDark
                                          ? const Color(0xFF19173D)
                                          : theme.colorScheme.surface,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                      items: _countryCodes.map((country) {
                                        return DropdownMenuItem<String>(
                                          value:
                                              '${country['code']}-${country['country']}',
                                          child: Row(
                                            children: [
                                              Text(
                                                country['flag']!,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  country['name']!,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                country['code']!,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.6)
                                                      : theme
                                                          .colorScheme.onSurface
                                                          .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCountryCode = value ?? '';
                                        });
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Phone Number
                                    Text(
                                      l10n.phoneNumber,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (_selectedCountryData != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.05)
                                                  : theme.colorScheme.outline
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white
                                                        .withOpacity(0.2)
                                                    : theme.colorScheme.outline,
                                              ),
                                            ),
                                            child: Text(
                                              _selectedCountryData!['code']!,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? Colors.white
                                                    : theme
                                                        .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        if (_selectedCountryData != null)
                                          const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            enabled:
                                                _selectedCountryData != null,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : theme.colorScheme.onSurface,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: l10n.phonePlaceholder,
                                              hintStyle: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                        .withOpacity(0.5)
                                                    : theme
                                                        .colorScheme.onSurface
                                                        .withOpacity(0.5),
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.05)
                                                  : theme.inputDecorationTheme
                                                      .fillColor,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : theme
                                                          .colorScheme.outline,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : theme
                                                          .colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Info
                                    Text(
                                      l10n.standardMessageRates,
                                      style: TextStyle(
                                        fontSize: 12,
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
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: GradientButton(
                              onPressed: (_phoneController.text.isNotEmpty &&
                                      _selectedCountryCode.isNotEmpty &&
                                      !_isLoading)
                                  ? _handleSendOTP
                                  : null,
                              enabled: _phoneController.text.isNotEmpty &&
                                  _selectedCountryCode.isNotEmpty &&
                                  !_isLoading,
                              child: _isLoading
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
                                      l10n.sendVerificationCode,
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
