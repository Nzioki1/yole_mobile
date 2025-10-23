import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router_types.dart';
import '../widgets/yole_logo.dart';
import '../widgets/gradient_button.dart';
import '../l10n/app_localizations.dart';

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
  bool _showPassword = false;
  String? _countryCode;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
                ),
              )
            : null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 384),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: isDark ? Colors.white : Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          l10n.createAccount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 24),
                    YoleLogo(isDarkTheme: isDark, height: 64),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      l10n.joinYoleToday,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.createAccountDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFF94A3B8).withOpacity(0.3),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LabeledField(
                              label: l10n.email,
                              isDark: isDark,
                              child: TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                    isDark, l10n.emailPlaceholder),
                                validator: _validateEmail,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: l10n.firstName,
                              isDark: isDark,
                              child: TextFormField(
                                controller: _firstNameCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                    isDark, l10n.firstNamePlaceholder),
                                validator: _validateRequired,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: l10n.lastName,
                              isDark: isDark,
                              child: TextFormField(
                                controller: _lastNameCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                    isDark, l10n.lastNamePlaceholder),
                                validator: _validateRequired,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: l10n.password,
                              isDark: isDark,
                              child: TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.done,
                                decoration: _inputDecoration(
                                  isDark,
                                  l10n.passwordPlaceholder,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B),
                                    ),
                                    onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                                  ),
                                ),
                                validator: _validatePassword,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: l10n.country,
                              isDark: isDark,
                              child: DropdownButtonFormField<String>(
                                value: _countryCode,
                                decoration: _inputDecoration(
                                    isDark, l10n.selectYourCountry),
                                icon: Icon(Icons.keyboard_arrow_down,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF64748B)),
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
                            const SizedBox(height: 28),
                            GradientButton(
                              height: 48,
                              borderRadius: 16,
                              onPressed: _onCreateAccount,
                              child: Text(
                                l10n.createAccount,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FooterSignIn(
                      isDark: isDark,
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

  void _onCreateAccount() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pushReplacementNamed(context, RouteNames.emailVerification);
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

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty)
      return AppLocalizations.of(context)!.passwordRequired;
    if (v.length < 6)
      return AppLocalizations.of(context)!.useAtLeast6Characters;
    return null;
  }

  InputDecoration _inputDecoration(bool isDark, String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white54 : const Color(0xFF64748B)),
      filled: true,
      fillColor:
          isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white24
                : const Color(0xFF94A3B8).withOpacity(0.3)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// Label wrapper
class _LabeledField extends StatelessWidget {
  const _LabeledField(
      {required this.label, required this.isDark, required this.child});
  final String label;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: isDark
                ? Colors.white.withOpacity(0.9)
                : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 48, child: child),
      ],
    );
  }
}

// Footer sign-in
class _FooterSignIn extends StatelessWidget {
  const _FooterSignIn({required this.isDark, required this.onTap});
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.alreadyHaveAccount,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                l10n.signIn,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4DA3FF)),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
