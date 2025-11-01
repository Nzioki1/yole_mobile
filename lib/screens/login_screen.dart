import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/yole_logo.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    required this.postLoginRoute, // e.g. '/home'
    required this.signUpRoute, // e.g. '/create-account'
    required this.forgotPasswordRoute, // e.g. '/forgot-password'
  });

  final String postLoginRoute;
  final String signUpRoute;
  final String forgotPasswordRoute;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDarkMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final horizontalPadding = (screenWidth * 0.06).clamp(20.0, 40.0);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: theme.appBarTheme.foregroundColor),
              onPressed: () => Navigator.maybePop(context),
            ),
            centerTitle: true,
            title: Text(
              l10n.logIn,
              style: TextStyle(
                  color: theme.appBarTheme.titleTextStyle?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),

                        // Prominent YOLE Logo - Much larger and dominant
                        YoleLogo(
                          isDarkTheme: isDark,
                          height:
                              80.0, // Increased from 48 to 80 for prominence
                        ),

                        const SizedBox(height: 24),

                        // Welcome back title - Secondary emphasis
                        Text(
                          l10n.welcomeBack,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.displayLarge?.color,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Sign in subtitle - Description text
                        Text(
                          l10n.signInToYoleAccount,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Error message display
                        if (authState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      theme.colorScheme.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: theme.colorScheme.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close,
                                      color: theme.colorScheme.error, size: 18),
                                  onPressed: () => ref
                                      .read(authProvider.notifier)
                                      .clearError(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Email field - Enhanced visibility
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.email,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 16,
                              ),
                              validator: (value) => null,
                              decoration: InputDecoration(
                                hintText: l10n.emailPlaceholder,
                                filled: true,
                                fillColor: isDark
                                    ? theme.cardColor.withOpacity(0.3)
                                    : Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                hintStyle: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Password field - Enhanced visibility
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.password,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _pwdCtrl,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 16,
                              ),
                              validator: (value) => null,
                              decoration: InputDecoration(
                                hintText: l10n.passwordHint,
                                filled: true,
                                fillColor: isDark
                                    ? theme.cardColor.withOpacity(0.3)
                                    : Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                hintStyle: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withOpacity(0.7),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(widget.forgotPasswordRoute),
                            child: Text(
                              l10n.forgotPassword,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Horizontal divider line
                        Container(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.3),
                        ),

                        const SizedBox(height: 24),

                        // Log In button - Enhanced prominence
                        SizedBox(
                          height:
                              48, // Reduced height to match LoginSpacing.loginBtnH
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: authState.isLoading
                                ? null
                                : () => _handleLogin(context),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        l10n.logIn,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Sign up link - Enhanced visibility
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.8),
                            ),
                            children: [
                              TextSpan(text: l10n.dontHaveAccount),
                              TextSpan(
                                text: l10n.signUp,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.of(context)
                                      .pushNamed(widget.signUpRoute),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    // Form validation bypassed for UI/UX testing
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }

    // Attempt login
    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _pwdCtrl.text,
        );

    if (success && mounted) {
      // Navigate to main app on successful login
      Navigator.of(context)
          .pushNamedAndRemoveUntil(widget.postLoginRoute, (route) => false);
    }
    // Error handling is done in the provider and displayed in the UI
  }
}
