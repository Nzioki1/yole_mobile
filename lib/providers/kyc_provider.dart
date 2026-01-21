import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/kyc_service.dart';
import 'api_providers.dart';

/// State for OTP sending operation
///
/// Tracks the lifecycle of an OTP send request:
/// - [isLoading]: Whether OTP is currently being sent to the API
/// - [isSent]: Whether OTP was successfully sent
/// - [error]: Error message if send operation failed
class OtpSendState {
  final bool isLoading;
  final bool isSent;
  final String? error;

  const OtpSendState({
    this.isLoading = false,
    this.isSent = false,
    this.error,
  });

  OtpSendState copyWith({
    bool? isLoading,
    bool? isSent,
    String? error,
  }) {
    return OtpSendState(
      isLoading: isLoading ?? this.isLoading,
      isSent: isSent ?? this.isSent,
      error: error ?? this.error,
    );
  }

  /// Returns true if state is in a terminal state (either success or error)
  bool get isTerminal => !isLoading;
}

/// State for KYC submission operation
///
/// Tracks the lifecycle of a KYC submission request:
/// - [isLoading]: Whether KYC is currently being submitted
/// - [isSubmitted]: Whether KYC was successfully submitted
/// - [response]: API response data on successful submission
/// - [error]: Error message if submission failed
class KycSubmissionState {
  final bool isLoading;
  final bool isSubmitted;
  final Map<String, dynamic>? response;
  final String? error;

  const KycSubmissionState({
    this.isLoading = false,
    this.isSubmitted = false,
    this.response,
    this.error,
  });

  KycSubmissionState copyWith({
    bool? isLoading,
    bool? isSubmitted,
    Map<String, dynamic>? response,
    String? error,
  }) {
    return KycSubmissionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      response: response ?? this.response,
      error: error ?? this.error,
    );
  }

  /// Returns true if state is in a terminal state (either success or error)
  bool get isTerminal => !isLoading;
}

/// Notifier for OTP sending operation
///
/// Handles sending OTP to user's phone number via SMS API
/// Uses [KycService] to interact with the backend API
class OtpSendNotifier extends StateNotifier<OtpSendState> {
  final KycService _kycService;

  OtpSendNotifier(this._kycService) : super(const OtpSendState());

  /// Sends OTP to the specified phone number
  ///
  /// Parameters:
  /// - [phoneCode]: Country code (e.g., '+1', '+44')
  /// - [phone]: Phone number without country code
  ///
  /// Returns true if OTP was sent successfully, false otherwise
  /// State is updated automatically with loading/error states
  Future<bool> sendOtp({
    required String phoneCode,
    required String phone,
  }) async {
    // Validate inputs
    if (phoneCode.isEmpty || phone.isEmpty) {
      _setError('Invalid phone number provided');
      return false;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call API via service layer
      await _kycService.sendOtp(
        phoneCode: phoneCode,
        phone: phone,
      );

      // Update state on success
      state = state.copyWith(
        isLoading: false,
        isSent: true,
        error: null,
      );
      return true;
    } catch (e) {
      // Handle and map errors
      _setError(_mapErrorMessage(e));
      return false;
    }
  }

  /// Maps exceptions to user-friendly error messages
  String _mapErrorMessage(Object exception) {
    final errorStr = exception.toString();

    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please check your internet and try again.';
    } else if (errorStr.contains('SocketException')) {
      return 'Network connection failed. Please check your internet.';
    } else if (errorStr.contains('Network') || errorStr.contains('Connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('YoleApiException')) {
      // Extract API error message
      return errorStr.replaceAll('YoleApiException: ', '').trim();
    } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return 'Your session has expired. Please log in again.';
    } else if (errorStr.contains('429') || errorStr.contains('Too Many Requests')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    } else if (errorStr.contains('400') || errorStr.contains('Bad Request')) {
      return 'Invalid phone number. Please check and try again.';
    } else {
      return 'Failed to send OTP. Please try again.';
    }
  }

  /// Sets error state with given message
  void _setError(String message) {
    state = state.copyWith(
      isLoading: false,
      isSent: false,
      error: message,
    );
  }

  /// Clears the current error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Resets state to initial/idle state
  void reset() {
    state = const OtpSendState();
  }
}

/// Notifier for KYC submission operation
///
/// Handles submission of complete KYC verification including:
/// - Phone number and OTP verification
/// - ID number validation
/// - Document uploads (ID photo, passport photo)
///
/// Uses [KycService] to interact with the backend API
class KycSubmissionNotifier extends StateNotifier<KycSubmissionState> {
  final KycService _kycService;

  KycSubmissionNotifier(this._kycService) : super(const KycSubmissionState());

  /// Submits complete KYC verification data
  ///
  /// Parameters:
  /// - [phoneNumber]: User's phone number with country code
  /// - [otpCode]: OTP code received via SMS (6 digits)
  /// - [idNumber]: User's ID/passport number
  /// - [idPhotoPath]: Optional path to ID document photo
  /// - [passportPhotoPath]: Optional path to passport photo
  ///
  /// Returns true if submission was successful, false otherwise
  /// API response is stored in state.response on success
  Future<bool> submitKyc({
    required String phoneNumber,
    required String otpCode,
    required String idNumber,
    String? idPhotoPath,
    String? passportPhotoPath,
  }) async {
    // Validate required inputs
    if (phoneNumber.isEmpty || otpCode.isEmpty || idNumber.isEmpty) {
      _setError('Missing required information. Please fill in all fields.');
      return false;
    }

    // Validate OTP format (should be 6 digits)
    if (!_isValidOtp(otpCode)) {
      _setError('Invalid OTP format. Please enter a 6-digit code.');
      return false;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call API via service layer
      final result = await _kycService.submitKyc(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
        idNumber: idNumber,
        idPhotoPath: idPhotoPath,
        passportPhotoPath: passportPhotoPath,
      );

      // Update state on success
      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        response: result['data'],
        error: null,
      );
      return true;
    } catch (e) {
      // Handle and map errors
      _setError(_mapErrorMessage(e));
      return false;
    }
  }

  /// Validates OTP format (6 digits)
  bool _isValidOtp(String otp) {
    return otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp);
  }

  /// Maps exceptions to user-friendly error messages
  String _mapErrorMessage(Object exception) {
    final errorStr = exception.toString();

    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please check your internet and try again.';
    } else if (errorStr.contains('SocketException')) {
      return 'Network connection failed. Please check your internet.';
    } else if (errorStr.contains('Network') || errorStr.contains('Connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('YoleApiException')) {
      // Extract API error message
      return errorStr.replaceAll('YoleApiException: ', '').trim();
    } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return 'Your session has expired. Please log in again.';
    } else if (errorStr.contains('400') || errorStr.contains('Bad Request')) {
      return 'Invalid information provided. Please check and try again.';
    } else if (errorStr.contains('422') || errorStr.contains('Unprocessable')) {
      return 'Invalid OTP or ID information. Please verify and try again.';
    } else {
      return 'Failed to submit KYC. Please try again.';
    }
  }

  /// Sets error state with given message
  void _setError(String message) {
    state = state.copyWith(
      isLoading: false,
      isSubmitted: false,
      error: message,
    );
  }

  /// Clears the current error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Resets state to initial/idle state
  void reset() {
    state = const KycSubmissionState();
  }
}

/// Provider for [KycService] instance
///
/// Provides access to KYC service which handles:
/// - OTP sending via SMS API
/// - KYC validation and document upload
///
/// Dependencies:
/// - [yoleApiServiceProvider]: API client for backend communication
final kycServiceProvider = Provider<KycService>((ref) {
  final api = ref.watch(yoleApiServiceProvider);
  return KycService(api: api);
});

/// Provider for OTP sending state and operations
///
/// Usage:
/// ```dart
/// final state = ref.watch(otpSendProvider);
/// await ref.read(otpSendProvider.notifier).sendOtp(
///   phoneCode: '+1',
///   phone: '5551234567',
/// );
/// ```
///
/// Watch the state to react to changes:
/// - [OtpSendState.isLoading]: Show loading indicator
/// - [OtpSendState.isSent]: OTP successfully sent
/// - [OtpSendState.error]: Display error message
final otpSendProvider = StateNotifierProvider<OtpSendNotifier, OtpSendState>((ref) {
  final kycService = ref.watch(kycServiceProvider);
  return OtpSendNotifier(kycService);
});

/// Provider for KYC submission state and operations
///
/// Usage:
/// ```dart
/// final state = ref.watch(kycSubmissionProvider);
/// await ref.read(kycSubmissionProvider.notifier).submitKyc(
///   phoneNumber: '+15551234567',
///   otpCode: '123456',
///   idNumber: 'A12345678',
///   idPhotoPath: '/path/to/id.jpg',
///   passportPhotoPath: '/path/to/passport.jpg',
/// );
/// ```
///
/// Watch the state to react to changes:
/// - [KycSubmissionState.isLoading]: Show loading indicator
/// - [KycSubmissionState.isSubmitted]: KYC successfully submitted
/// - [KycSubmissionState.response]: API response data
/// - [KycSubmissionState.error]: Display error message
final kycSubmissionProvider = StateNotifierProvider<KycSubmissionNotifier, KycSubmissionState>((ref) {
  final kycService = ref.watch(kycServiceProvider);
  return KycSubmissionNotifier(kycService);
});
