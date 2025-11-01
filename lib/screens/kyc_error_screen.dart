import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/yole_logo.dart';
import '../providers/app_provider.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

enum KYCErrorType { document, selfie, general }

class KYCErrorScreen extends ConsumerStatefulWidget {
  final KYCErrorType errorType;
  final VoidCallback? onRetry;

  const KYCErrorScreen({
    super.key,
    this.errorType = KYCErrorType.general,
    this.onRetry,
  });

  @override
  ConsumerState<KYCErrorScreen> createState() => _KYCErrorScreenState();
}

class _KYCErrorScreenState extends ConsumerState<KYCErrorScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _iconController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;

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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Delay icon animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    return Scaffold(
      body: Container(
        decoration: appState.isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173d)],
                ),
              )
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFEF2F2), Color(0xFFFED7AA)],
                ),
              ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                _buildLogo(),
                Expanded(child: _buildErrorContent(appState, theme)),
                _buildActions(appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: const Padding(
          padding: EdgeInsets.only(top: 32),
          child: YoleLogo(height: 64),
        ),
      ),
    );
  }

  Widget _buildErrorContent(AppState appState, ThemeData theme) {
    final errorContent = _getErrorContent(appState);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            ScaleTransition(
              scale: _iconScaleAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: appState.isDark
                      ? theme.colorScheme.error.withOpacity(0.2)
                      : theme.colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appState.isDark
                        ? theme.colorScheme.error.withOpacity(0.3)
                        : theme.colorScheme.error.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Error Content
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  Text(
                    errorContent['title'] as String,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appState.isDark ? Colors.white : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorContent['subtitle'] as String,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: appState.isDark
                          ? Colors.white.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Suggestions
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 600),
                    child: _buildSuggestions(appState, theme,
                        errorContent['suggestions'] as List<String>),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(
      AppState appState, ThemeData theme, List<String> suggestions) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appState.isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tipsForSuccess,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: appState.isDark
                  ? Colors.white.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appState.isDark
                              ? Colors.white.withOpacity(0.6)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActions(AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          // Retry Button
          GradientButton(
            onPressed: _handleRetry,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l10n.retry,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact Support
          OutlinedButton(
            onPressed: _handleContactSupport,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(
                color: appState.isDark
                    ? Colors.white.withOpacity(0.2)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              l10n.contactSupport,
            ),
          ),
          const SizedBox(height: 16),

          // Back to Login
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, RouteNames.home),
            child: Text(
              l10n.backToLogin,
              style: TextStyle(
                color: appState.isDark
                    ? Colors.white.withOpacity(0.6)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getErrorContent(AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.errorType) {
      case KYCErrorType.document:
        return {
          'title': l10n.documentVerificationFailed,
          'subtitle': l10n.documentVerificationFailedSubtitle,
          'suggestions': [
            l10n.ensureAllCornersVisible,
            l10n.takePhotoGoodLighting,
            l10n.makeSureDocumentNotBlurry,
            l10n.checkDocumentNotExpired,
          ],
        };
      case KYCErrorType.selfie:
        return {
          'title': l10n.selfieVerificationFailed,
          'subtitle': l10n.selfieVerificationFailedSubtitle,
          'suggestions': [
            l10n.lookDirectlyAtCamera,
            l10n.removeGlassesHatsCoverings,
            l10n.ensureFaceWellLitCentered,
            l10n.makeSureMatchPersonInId,
          ],
        };
      default:
        return {
          'title': l10n.verificationFailed,
          'subtitle': l10n.verificationFailedSubtitle,
          'suggestions': [
            l10n.checkInternetConnection,
            l10n.ensureAllInformationAccurate,
            l10n.tryAgainInFewMinutes,
          ],
        };
    }
  }

  void _handleRetry() {
    final appNotifier = ref.read(appProvider.notifier);

    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      // Default retry behavior - go back to appropriate step
      switch (widget.errorType) {
        case KYCErrorType.document:
          appNotifier.setCurrentView('kyc-id-capture');
          break;
        case KYCErrorType.selfie:
          appNotifier.setCurrentView('kyc-selfie');
          break;
        default:
          appNotifier.setCurrentView('kyc-phone');
          break;
      }
    }
  }

  void _handleContactSupport() {
    final l10n = AppLocalizations.of(context)!;
    // In a real app, this would open support chat or email
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.supportComingSoon,
        ),
      ),
    );
  }
}
