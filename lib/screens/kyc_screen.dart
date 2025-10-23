import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/status_chip.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

/// KYC Screen - Know Your Customer verification screen
/// Maintains pixel-perfect fidelity to the original Figma design
class KYCScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onBack;
  final String locale;
  final bool isDarkTheme;

  const KYCScreen({
    super.key,
    this.onComplete,
    this.onBack,
    this.locale = 'en',
    this.isDarkTheme = false,
  });

  @override
  ConsumerState<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends ConsumerState<KYCScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1;
  final int _totalSteps = 3;

  final Map<String, bool> _uploadedDocs = {
    'idDocument': false,
    'selfie': false,
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _progress => (_currentStep / _totalSteps);

  void _handleNext() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      // Complete KYC
      HapticFeedback.lightImpact();
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.kycPhone);
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      HapticFeedback.lightImpact();
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _handleDocumentUpload(String type) {
    setState(() {
      _uploadedDocs[type] = true;
    });
    HapticFeedback.lightImpact();
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 1:
        return true;
      case 2:
        return _uploadedDocs['idDocument'] == true;
      case 3:
        return _uploadedDocs['selfie'] == true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDarkTheme || theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF19173D) : Colors.white,
      body: Column(
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
                    onPressed: _handleBack,
                    icon: Icon(
                      Icons.arrow_back,
                      color:
                          isDark ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.kycVerification,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
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
                      l10n.stepXofY(_currentStep, _totalSteps),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${(_progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : theme.colorScheme.outline.withOpacity(0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 100), // Space for floating button
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildStepContent(isDark, theme),
                ),
              ),
            ),
          ),

          // Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF19173D) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: GradientButton(
                onPressed: _canContinue ? _handleNext : null,
                enabled: _canContinue,
                child: Text(
                  _currentStep == _totalSteps ? l10n.done : l10n.continueButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isDark, ThemeData theme) {
    switch (_currentStep) {
      case 1:
        return _buildIntroStep(isDark, theme);
      case 2:
        return _buildDocumentUploadStep(isDark, theme);
      case 3:
        return _buildSelfieStep(isDark, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep(bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 32),

        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_outlined,
            size: 32,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          l10n.identityVerification,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          l10n.verifyIdentityDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),

        const SizedBox(height: 32),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.whatYouNeed,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                l10n.governmentId,
                l10n.clearPhoto,
                l10n.timeRequired,
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withOpacity(0.9)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadStep(bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isUploaded = _uploadedDocs['idDocument'] == true;

    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          l10n.documentUpload,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.uploadClearPhoto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              if (isUploaded) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 32,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.documentUploadedSuccess,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 12),
                StatusChip(
                  text: l10n.verified,
                  variant: StatusChipVariant.success,
                ),
              ] else ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : theme.colorScheme.outline.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.upload_outlined,
                    size: 32,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    GradientButton(
                      onPressed: () => _handleDocumentUpload('idDocument'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(l10n.takePhoto),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _handleDocumentUpload('idDocument'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white : theme.colorScheme.primary,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : theme.colorScheme.primary,
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.uploadFromGallery),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (!isUploaded) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.makeSureDocument,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  l10n.clearlyVisible,
                  l10n.showFourCorners,
                  l10n.notExpired,
                ].map((requirement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $requirement',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelfieStep(bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isUploaded = _uploadedDocs['selfie'] == true;

    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          l10n.selfieVerification,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.takeSelfieInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              if (isUploaded) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 32,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.selfieCapturedSuccess,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 12),
                StatusChip(
                  text: l10n.verified,
                  variant: StatusChipVariant.success,
                ),
              ] else ...[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : theme.colorScheme.outline.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 48,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  onPressed: () => _handleDocumentUpload('selfie'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt,
                          size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(l10n.takeSelfie),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isUploaded) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.forBestResults,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  l10n.lookAtCamera,
                  l10n.removeGlasses,
                  l10n.ensureGoodLighting,
                ].map((instruction) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $instruction',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
