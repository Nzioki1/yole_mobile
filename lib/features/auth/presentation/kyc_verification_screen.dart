import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/i18n/generated/l10n.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/utils/validators.dart';
import '../data/kyc_api.dart';
import '../../../core/services/kyc_service.dart';
import '../../../core/providers.dart';

class KYCVerificationScreen extends ConsumerStatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  ConsumerState<KYCVerificationScreen> createState() =>
      _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends ConsumerState<KYCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCode = TextEditingController(text: '+254');
  final _phone = TextEditingController();
  final _otpCode = TextEditingController();
  final _idNumber = TextEditingController();

  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // KYC related
  File? _idPhoto;
  File? _passportPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _phoneCode.dispose();
    _phone.dispose();
    _otpCode.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 24),

              // Step content
              Expanded(child: _buildCurrentStep()),

              // Navigation buttons
              _buildNavigationButtons(),

              // Error and success messages
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $_currentStep of 3',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final isCompleted = index < _currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getStepTitle(_currentStep),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Phone Verification';
      case 2:
        return 'KYC Verification';
      case 3:
        return 'Complete';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildPhoneVerificationStep();
      case 2:
        return _buildKYCStep();
      case 3:
        return _buildCompletionStep();
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  Widget _buildPhoneVerificationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify your phone number',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _phoneCode,
                  decoration: const InputDecoration(
                    labelText: 'Country Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.required,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.required,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Send OTP Code',
            onPressed: _isLoading ? null : _sendOtpCode,
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _otpCode,
            decoration: const InputDecoration(
              labelText: 'Enter OTP Code',
              border: OutlineInputBorder(),
            ),
            validator: Validators.required,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildKYCStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete KYC Verification',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _idNumber,
          decoration: const InputDecoration(
            labelText: 'ID Number',
            border: OutlineInputBorder(),
          ),
          validator: Validators.required,
        ),
        const SizedBox(height: 24),

        // ID Photo
        _buildPhotoSection('ID Photo', _idPhoto, () => _pickImage(true)),
        const SizedBox(height: 16),

        // Passport Photo (Selfie)
        _buildPhotoSection(
          'Passport Photo (Selfie)',
          _passportPhoto,
          () => _pickImage(false),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(String title, File? photo, VoidCallback onPick) {
    // Determine if this is a passport photo (selfie) or ID photo
    final bool isPassportPhoto = title.toLowerCase().contains('selfie');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Add description for passport photo
        if (isPassportPhoto)
          const Text(
            'Please take a clear selfie photo using your front camera',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (isPassportPhoto) const SizedBox(height: 8),

        if (photo != null) ...[
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(photo, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
        ],

        ElevatedButton.icon(
          onPressed: onPick,
          icon: Icon(
            photo != null
                ? Icons.edit
                : (isPassportPhoto ? Icons.camera_front : Icons.photo_library),
          ),
          label: Text(
            photo != null
                ? 'Change $title'
                : (isPassportPhoto ? 'Take Selfie' : 'Pick $title'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: photo != null ? Colors.orange : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 24),
          Text(
            'KYC Verification Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Your account has been verified. You can now use all features including money transfers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1 && _currentStep < 3)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _previousStep,
              child: const Text('Previous'),
            ),
          ),

        if (_currentStep > 1 && _currentStep < 3) const SizedBox(width: 16),

        Expanded(
          child: PrimaryButton(
            label: _getButtonLabel(),
            onPressed: _isLoading ? null : _handleCurrentStep,
          ),
        ),
      ],
    );
  }

  String _getButtonLabel() {
    switch (_currentStep) {
      case 1:
        return 'Verify Phone';
      case 2:
        return 'Complete KYC';
      case 3:
        return 'Go to Dashboard';
      default:
        return 'Next';
    }
  }

  Future<void> _handleCurrentStep() async {
    switch (_currentStep) {
      case 1:
        await _handlePhoneVerification();
        break;
      case 2:
        await _handleKYCVerification();
        break;
      case 3:
        _goToDashboard();
        break;
    }
  }

  Future<void> _sendOtpCode() async {
    if (_phone.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final kycApi = ref.read(kycApiProvider);
      await kycApi.sendSmsOtp(_phoneCode.text, _phone.text);

      setState(() {
        _successMessage = 'OTP code sent to ${_phoneCode.text}${_phone.text}';
        _isLoading = false;
      });

      // Clear success message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePhoneVerification() async {
    if (_otpCode.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For now, we'll simulate OTP verification
      // In production, this would call the actual OTP verification API
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _successMessage = 'Phone verification successful!';
        _currentStep = 2;
        _isLoading = false;
      });

      // Clear success message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Phone verification failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleKYCVerification() async {
    if (_idNumber.text.isEmpty || _idPhoto == null || _passportPhoto == null) {
      setState(() {
        _errorMessage = 'Please fill all required fields and upload photos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final kycApi = ref.read(kycApiProvider);
      await kycApi.validateKyc(
        phoneNumber: '${_phoneCode.text}${_phone.text}',
        otpCode: _otpCode.text,
        idNumber: _idNumber.text,
        idPhoto: _idPhoto!.path,
        passportPhoto: _passportPhoto!.path,
      );

      // Mark KYC as completed
      await KYCService.markKYCCompleted();

      setState(() {
        _successMessage = 'KYC verification completed successfully!';
        _currentStep = 3;
        _isLoading = false;
      });

      // Clear success message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'KYC verification failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(bool isIdPhoto) async {
    try {
      // For ID photo: use gallery, for passport photo: use camera (selfie)
      final ImageSource source = isIdPhoto
          ? ImageSource.gallery
          : ImageSource.camera;
      final String actionText = isIdPhoto ? 'pick' : 'take';

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        preferredCameraDevice:
            CameraDevice.front, // Use front camera for selfie
      );

      if (image != null) {
        setState(() {
          if (isIdPhoto) {
            _idPhoto = File(image.path);
          } else {
            _passportPhoto = File(image.path);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to ${isIdPhoto ? 'pick' : 'take'} image: $e';
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
        _successMessage = null;
      });
    }
  }

  void _goToDashboard() {
    context.go('/home');
  }
}
