import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../router_types.dart'; // for RouteNames
import '../l10n/app_localizations.dart';
import '../widgets/yole_logo.dart';
import '../providers/theme_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDarkMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;

        // Fixed sizes for consistent layout
        final imageSize = (screenWidth * 0.45).clamp(160.0, 240.0);
        final horizontalPadding = (screenWidth * 0.06).clamp(20.0, 40.0);

        // Fixed typography sizes
        final titleFontSize = 24.0;
        final subtitleFontSize = 16.0;
        final buttonFontSize = 18.0;
        final linkFontSize = 15.0;

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
                        const SizedBox(height: 40),

                        // --- Image card ---
                        Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.35),
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
                                CachedNetworkImage(
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1655720360377-b97f6715e1ae?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwbW9iaWxlJTIwbW9uZXklMjB0cmFuc2FjdGlvbiUyMHBob25lJTIwc2VuZGluZ3xlbnwxfHx8fDE3NTc1ODY0ODZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color:
                                        theme.cardTheme.color?.withOpacity(0.3),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color:
                                        theme.cardTheme.color?.withOpacity(0.3),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.5),
                                      size: 48,
                                    ),
                                  ),
                                ),
                                // Subtle purple overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary
                                            .withOpacity(0.22),
                                        theme.colorScheme.secondary
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

                        const SizedBox(height: 32),

                        // --- YOLE Logo ---
                        YoleLogo(
                          isDarkTheme: isDark,
                          height: 48.0,
                        ),

                        const SizedBox(height: 24),

                        // --- Headline ---
                        Text(
                          l10n.quickAndConvenient,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // --- Subtitle ---
                        Text(
                          l10n.sendAndReceiveMoney,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            height: 1.45,
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.78),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- Get started (navigates to Create Account) ---
                        SizedBox(
                          height: 56.0,
                          width: double.infinity,
                          child: _GradientButton(
                            borderRadius: 24,
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(RouteNames.register);
                            },
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary
                              ],
                            ),
                            child: Center(
                              child: Text(
                                l10n.getStarted,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- Sign-in link (ALWAYS VISIBLE) ---
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: linkFontSize,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.8),
                            ),
                            children: [
                              TextSpan(text: l10n.alreadyHaveAccount),
                              TextSpan(
                                text: l10n.signIn,
                                style: TextStyle(
                                  fontSize: linkFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
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

                        const SizedBox(height: 40),
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
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.35),
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
