import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router_types.dart';
import '../widgets/yole_logo.dart';
import '../widgets/gradient_button.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/register_spacing.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _countryCode;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: RegisterSpacing.screenPX,
                vertical: RegisterSpacing.headerPY),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: RegisterSpacing.contentMaxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: theme.appBarTheme.foregroundColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          l10n.createAccount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.appBarTheme.titleTextStyle?.color,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: RegisterSpacing.inputPRIcon),
                      ],
                    ),

                    const SizedBox(height: RegisterSpacing.logoMB),
                    YoleLogo(
                      isDarkTheme: isDark,
                      height: RegisterSpacing.logoH,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                    const SizedBox(height: RegisterSpacing.logoMB),

                    // Title
                    Text(
                      l10n.joinYoleToday,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: RegisterSpacing.subtitleMB),
                    Text(
                      l10n.createAccountDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                          RegisterSpacing.cardPX,
                          RegisterSpacing.cardPT,
                          RegisterSpacing.cardPX,
                          RegisterSpacing.cardPB),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius:
                            BorderRadius.circular(RegisterSpacing.cardRadius),
                        border: Border.all(
                          color: theme.cardTheme.shape is RoundedRectangleBorder
                              ? (theme.cardTheme.shape
                                      as RoundedRectangleBorder)
                                  .side
                                  .color
                              : theme.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LabeledField(
                              label: l10n.email,
                              child: TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration:
                                    _inputDecoration(l10n.emailPlaceholder),
                                validator: _validateEmail,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: RegisterSpacing.stackGap),
                            _LabeledField(
                              label: l10n.firstName,
                              child: TextFormField(
                                controller: _firstNameCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration:
                                    _inputDecoration(l10n.firstNamePlaceholder),
                                validator: _validateRequired,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: RegisterSpacing.stackGap),
                            _LabeledField(
                              label: l10n.lastName,
                              child: TextFormField(
                                controller: _lastNameCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration:
                                    _inputDecoration(l10n.lastNamePlaceholder),
                                validator: _validateRequired,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: RegisterSpacing.stackGap),
                            _LabeledField(
                              label: l10n.password,
                              child: TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.done,
                                decoration: _inputDecoration(
                                  l10n.passwordPlaceholder,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: RegisterSpacing.pwdIcon,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.7),
                                    ),
                                    onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                                  ),
                                ),
                                // Password validation removed for UI/UX testing
                                validator: (value) => null,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: RegisterSpacing.stackGap),
                            _LabeledField(
                              label: l10n.confirmPassword,
                              child: TextFormField(
                                controller: _confirmPasswordCtrl,
                                obscureText: !_showConfirmPassword,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  l10n.confirmPassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: RegisterSpacing.pwdIcon,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.7),
                                    ),
                                    onPressed: () => setState(() =>
                                        _showConfirmPassword =
                                            !_showConfirmPassword),
                                  ),
                                ),
                                validator: (value) => null,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: RegisterSpacing.stackGap),
                            _LabeledField(
                              label: l10n.country,
                              child: DropdownButtonFormField<String>(
                                value: _countryCode,
                                decoration:
                                    _inputDecoration(l10n.selectYourCountry),
                                icon: Icon(Icons.keyboard_arrow_down,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.7)),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'KE', child: Text('🇰🇪 Kenya')),
                                  DropdownMenuItem(
                                      value: 'NG', child: Text('🇳🇬 Nigeria')),
                                  DropdownMenuItem(
                                      value: 'GH', child: Text('🇬🇭 Ghana')),
                                  DropdownMenuItem(
                                      value: 'UG', child: Text('🇺🇬 Uganda')),
                                  DropdownMenuItem(
                                      value: 'TZ',
                                      child: Text('🇹🇿 Tanzania')),
                                  DropdownMenuItem(
                                      value: 'ZA',
                                      child: Text('🇿🇦 South Africa')),
                                  DropdownMenuItem(
                                      value: 'CD', child: Text('🇨🇩 DRC')),
                                  DropdownMenuItem(
                                      value: 'FR', child: Text('🇫🇷 France')),
                                  DropdownMenuItem(
                                      value: 'DE', child: Text('🇩🇪 Germany')),
                                  DropdownMenuItem(
                                      value: 'US',
                                      child: Text('🇺🇸 United States')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _countryCode = v),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.pleaseSelectCountry
                                    : null,
                              ),
                            ),
                            const SizedBox(
                                height: RegisterSpacing.ctaSectionPT),
                            GradientButton(
                              height: RegisterSpacing.ctaBtnH,
                              borderRadius: RegisterSpacing.cardRadius,
                              onPressed: _onCreateAccount,
                              child: Text(
                                l10n.createAccount,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: RegisterSpacing.footerPB),
                    _FooterSignIn(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, RouteNames.login),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCreateAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Attempt registration with auth provider
        final success = await ref.read(authProvider.notifier).register(
              email: _emailCtrl.text.trim(),
              name: _firstNameCtrl.text.trim(),
              surname: _lastNameCtrl.text.trim(),
              password: _passwordCtrl.text.trim(),
              passwordConfirmation: _passwordCtrl.text.trim(),
              country: _countryCode ?? 'CD',
            );

        if (success && mounted) {
          // Navigate to email verification on successful registration
          Navigator.pushNamed(context, RouteNames.emailVerification);
        }
      } catch (e) {
        // Show error message if registration fails
        if (mounted) {
          final errorTheme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: $e'),
              backgroundColor: errorTheme.colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String? _validateRequired(String? v) => (v == null || v.trim().isEmpty)
      ? AppLocalizations.of(context)!.thisFieldRequired
      : null;
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty)
      return AppLocalizations.of(context)!.emailRequired;
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(v.trim()))
      return AppLocalizations.of(context)!.enterValidEmail;
    return null;
  }

  // Password validation removed for UI/UX testing
  // String? _validatePassword(String? v) {
  //   if (v == null || v.isEmpty)
  //     return AppLocalizations.of(context)!.passwordRequired;
  //   if (v.length < 6)
  //     return AppLocalizations.of(context)!.useAtLeast6Characters;
  //   return null;
  // }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 16,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ??
                theme.dividerColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: theme.inputDecorationTheme.focusedBorder?.borderSide.color ??
                theme.colorScheme.primary,
            width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// Label wrapper
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: RegisterSpacing.labelToInputGap),
        child,
      ],
    );
  }
}

// Footer sign-in
class _FooterSignIn extends StatelessWidget {
  const _FooterSignIn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.alreadyHaveAccount,
            style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                l10n.signIn,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
