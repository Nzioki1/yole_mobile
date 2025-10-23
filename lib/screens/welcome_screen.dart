import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router_types.dart'; // for RouteNames
import '../l10n/app_localizations.dart';
import '../widgets/language_toggle.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Brand colors / gradients
    const bgTop = Color(0xFF0D1222);
    const bgBottom = Color(0xFF0A0E1A);
    const buttonGradStart = Color(0xFF3E8BFF);
    const buttonGradEnd = Color(0xFF7B4DFF);

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language toggle at top
              Padding(
                padding: const EdgeInsets.only(top: 16, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LanguageToggle(
                      isDark: true,
                      fontSize: 14,
                      textColor: Colors.white70,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- Image card ---
                        Container(
                          width: 224,
                          height: 224,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  'https://images.unsplash.com/photo-1655720360377-b97f6715e1ae?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwbW9iaWxlJTIwbW9uZXklMjB0cmFuc2FjdGlvbiUyMHBob25lJTIwc2VuZGluZ3xlbnwxfHx8fDE3NTc1ODY0ODZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
                                  width: 224,
                                  height: 224,
                                  fit: BoxFit.cover,
                                ),
                                // Subtle purple overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF6F5CFF)
                                            .withOpacity(0.22),
                                        const Color(0xFF2A2E5A)
                                            .withOpacity(0.22),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // --- App title ---
                        Text(
                          'YOLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- Headline ---
                        Text(
                          l10n.quickAndConvenient,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // --- Subtitle ---
                        Text(
                          l10n.sendAndReceiveMoney,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            color: Colors.white.withOpacity(0.78),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // --- Get started (navigates to Create Account) ---
                        _GradientButton(
                          borderRadius: 24,
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(RouteNames.register);
                          },
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [buttonGradStart, buttonGradEnd],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              l10n.getStarted,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // --- Sign-in link ---
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            children: [
                              TextSpan(text: l10n.alreadyHaveAccount),
                              TextSpan(
                                text: l10n.signIn,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4DA3FF),
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context)
                                        .pushNamed(RouteNames.login);
                                  },
                              ),
                            ],
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
    );
  }
}

/// Local gradient button (kept private to this file to avoid extra imports).
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.child,
    required this.gradient,
    this.borderRadius = 24,
    this.onPressed,
  });

  final Widget child;
  final LinearGradient gradient;
  final double borderRadius;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
