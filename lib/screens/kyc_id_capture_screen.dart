import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/gradient_button.dart';
import '../widgets/status_chip.dart';
import '../providers/app_provider.dart';
import '../router_types.dart';

enum DocumentType { nationalId, passport }

class KYCIdCaptureScreen extends ConsumerStatefulWidget {
  const KYCIdCaptureScreen({super.key});

  @override
  ConsumerState<KYCIdCaptureScreen> createState() => _KYCIdCaptureScreenState();
}

class _KYCIdCaptureScreenState extends ConsumerState<KYCIdCaptureScreen>
    with TickerProviderStateMixin {
  DocumentType? selectedDocType;
  Map<String, bool> uploadedSides = {'front': false, 'back': false};
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
      begin: const Offset(0, 0.3),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: Column(
                    children: [
                      _buildHeaderContent(appState),
                      const SizedBox(height: 32),
                      if (selectedDocType == null)
                        _buildDocumentTypeSelection(appState)
                      else
                        _buildDocumentUploadInterface(appState),
                    ],
                  ),
                ),
              ),
              if (selectedDocType != null) _buildContinueButton(appState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppState appState, AppNotifier appNotifier) {
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
              appState.locale == 'en'
                  ? 'ID Verification'
                  : 'Vérification d\'identité',
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appState.locale == 'en' ? 'Step 3 of 4' : 'Étape 3 sur 4',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appState.isDark
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '75%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appState.isDark ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.75,
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

  Widget _buildHeaderContent(AppState appState) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Text(
              appState.locale == 'en'
                  ? 'Upload your ID document'
                  : 'Téléchargez votre document d\'identité',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: appState.isDark ? Colors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              appState.locale == 'en'
                  ? 'Take a clear photo of your ID.'
                  : 'Prenez une photo claire de votre pièce d\'identité.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: appState.isDark
                    ? Colors.white.withOpacity(0.7)
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelection(AppState appState) {
    final theme = Theme.of(context);

    final documentTypes = [
      {
        'id': DocumentType.nationalId,
        'icon': Icons.credit_card,
        'title': appState.locale == 'en'
            ? 'National ID'
            : 'Carte d\'identité nationale',
        'subtitle': appState.locale == 'en'
            ? 'Government-issued ID card'
            : 'Carte d\'identité officielle',
        'requiresBothSides': true,
      },
      {
        'id': DocumentType.passport,
        'icon': Icons.description,
        'title': appState.locale == 'en' ? 'Passport' : 'Passeport',
        'subtitle': appState.locale == 'en'
            ? 'International passport'
            : 'Passeport international',
        'requiresBothSides': false,
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.locale == 'en'
                  ? 'Select document type:'
                  : 'Sélectionnez le type de document :',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: appState.isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 16),
            ...documentTypes.map((docType) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => _handleDocumentTypeSelect(
                          docType['id'] as DocumentType),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: appState.isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : theme.colorScheme.primary
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                docType['icon'] as IconData,
                                size: 24,
                                color: appState.isDark
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    docType['title'] as String,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          appState.isDark ? Colors.white : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    docType['subtitle'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: appState.isDark
                                          ? Colors.white.withOpacity(0.6)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appState.isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : theme.dividerColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadInterface(AppState appState) {
    final theme = Theme.of(context);
    final docType = selectedDocType!;
    final docTypeName = docType == DocumentType.nationalId
        ? (appState.locale == 'en'
            ? 'National ID'
            : 'Carte d\'identité nationale')
        : (appState.locale == 'en' ? 'Passport' : 'Passeport');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Selected Document Type Header
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    selectedDocType = null;
                    uploadedSides = {'front': false, 'back': false};
                  }),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: appState.isDark
                        ? Colors.white.withOpacity(0.05)
                        : theme.colorScheme.onSurface.withOpacity(0.05),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  docTypeName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appState.isDark ? Colors.white : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Front Side Upload
            _buildUploadCard(
              appState,
              appState.locale == 'en' ? 'Front side' : 'Recto',
              'front',
            ),
            const SizedBox(height: 16),

            // Back Side Upload (only for National ID)
            if (docType == DocumentType.nationalId) ...[
              _buildUploadCard(
                appState,
                appState.locale == 'en' ? 'Back side' : 'Verso',
                'back',
              ),
              const SizedBox(height: 24),
            ],

            // Requirements
            _buildRequirements(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(AppState appState, String title, String side) {
    final theme = Theme.of(context);
    final isUploaded = uploadedSides[side] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: appState.isDark ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 20),
            if (isUploaded) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  size: 32,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appState.locale == 'en'
                    ? 'Document uploaded successfully!'
                    : 'Document téléchargé avec succès !',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StatusChip(
                text: appState.locale == 'en' ? 'Verified' : 'Vérifié',
                variant: StatusChipVariant.success,
              ),
            ] else ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: appState.isDark
                      ? Colors.white.withOpacity(0.1)
                      : theme.colorScheme.onSurface.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.file_upload_outlined,
                  size: 32,
                  color: appState.isDark
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  GradientButton(
                    onPressed: () => _handleDocumentUpload(side),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          appState.locale == 'en'
                              ? 'Take Photo'
                              : 'Prendre une photo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _handleDocumentUpload(side),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          appState.locale == 'en'
                              ? 'Upload from Gallery'
                              : 'Télécharger depuis la galerie',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirements(AppState appState) {
    final theme = Theme.of(context);

    final requirements = [
      appState.locale == 'en'
          ? 'Is clearly visible and not blurry'
          : 'Est clairement visible et pas flou',
      appState.locale == 'en'
          ? 'Shows all four corners'
          : 'Montre les quatre coins',
      appState.locale == 'en' ? 'Is not expired' : 'N\'est pas expiré',
      appState.locale == 'en' ? 'Has good lighting' : 'A un bon éclairage',
    ];

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
            appState.locale == 'en'
                ? 'Make sure your document:'
                : 'Assurez-vous que votre document :',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: appState.isDark
                  ? Colors.white.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((requirement) => Padding(
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
                        requirement,
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

  Widget _buildContinueButton(AppState appState) {
    final isComplete = _isDocumentUploadComplete();

    return Container(
      padding: const EdgeInsets.all(24),
      child: GradientButton(
        onPressed: isComplete
            ? () =>
                Navigator.pushReplacementNamed(context, RouteNames.kycSelfie)
            : null,
        child: Text(
          appState.locale == 'en' ? 'Continue' : 'Continuer',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _handleDocumentTypeSelect(DocumentType type) {
    setState(() {
      selectedDocType = type;
      uploadedSides = {'front': false, 'back': false};
    });
  }

  void _handleDocumentUpload(String side) {
    // Mock file upload - in real app, integrate with camera/gallery
    setState(() {
      uploadedSides[side] = true;
    });
  }

  bool _isDocumentUploadComplete() {
    if (selectedDocType == null) return false;
    if (!uploadedSides['front']!) return false;
    if (selectedDocType == DocumentType.nationalId && !uploadedSides['back']!) {
      return false;
    }
    return true;
  }
}
