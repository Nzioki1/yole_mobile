import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/status_chip.dart';
import '../providers/app_provider.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

class KYCSelfieScreen extends ConsumerStatefulWidget {
  const KYCSelfieScreen({super.key});

  @override
  ConsumerState<KYCSelfieScreen> createState() => _KYCSelfieScreenState();
}

class _KYCSelfieScreenState extends ConsumerState<KYCSelfieScreen>
    with TickerProviderStateMixin {
  bool selfieCaptured = false;
  bool isCapturing = false;
  late AnimationController _animationController;
  late AnimationController _captureController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _captureController = AnimationController(
      duration: const Duration(seconds: 2),
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

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _captureController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _captureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);
    final appNotifier = ref.read(appProvider.notifier);

    return Scaffold(
      backgroundColor:
          appState.isDark ? const Color(0xFF19173d) : theme.colorScheme.surface,
      body: Container(
        decoration: appState.isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173d)],
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(appState, appNotifier),
              _buildProgress(appState),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildContent(appState),
                      ),
                      if (selfieCaptured)
                        _buildContinueButton(appState, appNotifier),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppState appState, AppNotifier appNotifier) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appState.isDark
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: appState.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent,
            ),
          ),
          Expanded(
            child: Text(
              l10n.selfieVerification,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appState.isDark ? Colors.white : null,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgress(AppState appState) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.stepXofY(4, 4),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appState.isDark
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '100%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appState.isDark ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: appState.isDark
                ? Colors.white.withOpacity(0.1)
                : theme.colorScheme.onSurface.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppState appState) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header Content
            _buildHeaderContent(appState, theme),
            const SizedBox(height: 48),

            // Selfie Capture Interface
            _buildSelfieInterface(appState, theme),

            // Instructions
            if (!selfieCaptured) ...[
              const SizedBox(height: 32),
              _buildInstructions(appState, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent(AppState appState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          Text(
            l10n.takeSelfie,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: appState.isDark ? Colors.white : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.takeSelfieSoWeCanVerify,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: appState.isDark
                  ? Colors.white.withOpacity(0.7)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieInterface(AppState appState, ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              if (selfieCaptured)
                _buildSuccessState(appState, theme)
              else
                _buildCaptureInterface(appState, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(AppState appState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: const Icon(
            Icons.check,
            size: 48,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.selfieCapturedSuccess,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        StatusChip(
          text: l10n.verified,
          variant: StatusChipVariant.success,
        ),
      ],
    );
  }

  Widget _buildCaptureInterface(AppState appState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Camera Preview Area
        Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            color: appState.isDark
                ? Colors.white.withOpacity(0.05)
                : theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: appState.isDark
                  ? Colors.white.withOpacity(0.2)
                  : theme.dividerColor,
              width: 4,
              style: BorderStyle.solid,
            ),
          ),
          child: isCapturing
              ? _buildCapturingState(appState, theme)
              : _buildIdleState(appState, theme),
        ),
        const SizedBox(height: 24),

        // Capture Button
        if (!isCapturing)
          GradientButton(
            onPressed: _handleCaptureSelfie,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l10n.takeSelfie,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCapturingState(AppState appState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _rotationAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 4,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appState.isDark
                        ? Colors.white.withOpacity(0.2)
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.capturing,
            style: theme.textTheme.bodySmall?.copyWith(
              color: appState.isDark
                  ? Colors.white.withOpacity(0.7)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState(AppState appState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 64,
            color: appState.isDark
                ? Colors.white.withOpacity(0.4)
                : theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.positionYourFaceInFrame,
            style: theme.textTheme.bodySmall?.copyWith(
              color: appState.isDark
                  ? Colors.white.withOpacity(0.6)
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(AppState appState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final instructions = [
      l10n.lookAtCamera,
      l10n.removeGlasses,
      l10n.ensureGoodLighting,
      l10n.keepYourFaceCentered,
    ];

    return AnimatedOpacity(
      opacity: selfieCaptured ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 600),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
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
                l10n.forBestResults,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: appState.isDark
                      ? Colors.white.withOpacity(0.8)
                      : theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              ...instructions.map((instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: appState.isDark
                                ? Colors.white.withOpacity(0.6)
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            instruction,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: appState.isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(AppState appState, AppNotifier appNotifier) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedOpacity(
      opacity: selfieCaptured ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: GradientButton(
        onPressed: selfieCaptured
            ? () => Navigator.pushNamed(context, RouteNames.kycSuccess)
            : null,
        child: Text(
          l10n.completeVerificationButton,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _handleCaptureSelfie() {
    setState(() {
      isCapturing = true;
    });

    _captureController.forward();

    // Simulate selfie capture
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isCapturing = false;
          selfieCaptured = true;
        });
        _captureController.reset();
      }
    });
  }
}
