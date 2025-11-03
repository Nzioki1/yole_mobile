import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/kyc_service.dart';
import 'api_providers.dart';

/// State for OTP sending
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
}

/// State for KYC submission
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
}

/// Notifier for OTP sending
class OtpSendNotifier extends StateNotifier<OtpSendState> {
  final KycService _kycService;

  OtpSendNotifier(this._kycService) : super(const OtpSendState());

  Future<bool> sendOtp({
    required String phoneCode,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _kycService.sendOtp(
        phoneCode: phoneCode,
        phone: phone,
      );

      state = state.copyWith(
        isLoading: false,
        isSent: true,
        error: null,
      );
      return true;
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('YoleApiException')) {
        errorMessage = e.toString().replaceAll('YoleApiException: ', '');
      } else {
        errorMessage = 'Failed to send OTP. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        isSent: false,
        error: errorMessage,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const OtpSendState();
  }
}

/// Notifier for KYC submission
class KycSubmissionNotifier extends StateNotifier<KycSubmissionState> {
  final KycService _kycService;

  KycSubmissionNotifier(this._kycService) : super(const KycSubmissionState());

  Future<bool> submitKyc({
    required String phoneNumber,
    required String otpCode,
    required String idNumber,
    String? idPhotoPath,
    String? passportPhotoPath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _kycService.submitKyc(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
        idNumber: idNumber,
        idPhotoPath: idPhotoPath,
        passportPhotoPath: passportPhotoPath,
      );

      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        response: result['data'],
        error: null,
      );
      return true;
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('YoleApiException')) {
        errorMessage = e.toString().replaceAll('YoleApiException: ', '');
      } else {
        errorMessage = 'Failed to submit KYC. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        isSubmitted: false,
        error: errorMessage,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const KycSubmissionState();
  }
}

/// Provider for KycService
final kycServiceProvider = Provider<KycService>((ref) {
  final api = ref.watch(yoleApiServiceProvider);
  return KycService(api: api);
});

/// Provider for OTP sending
final otpSendProvider =
    StateNotifierProvider<OtpSendNotifier, OtpSendState>((ref) {
  final kycService = ref.watch(kycServiceProvider);
  return OtpSendNotifier(kycService);
});

/// Provider for KYC submission
final kycSubmissionProvider =
    StateNotifierProvider<KycSubmissionNotifier, KycSubmissionState>((ref) {
  final kycService = ref.watch(kycServiceProvider);
  return KycSubmissionNotifier(kycService);
});

