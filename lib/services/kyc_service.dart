import 'dart:convert';
import 'yole_api_service.dart';
import 'offline_demo_repository.dart';
import '../models/api/error_response.dart';

/// KYC service for handling KYC verification operations
class KycService {
  /// Offline demo gate — set via `--dart-define=OFFLINE_DEMO=true`.
  /// When true, [sendOtp]/[submitKyc] delegate to [OfflineDemoRepository]
  /// (no HTTP). Unit-test the repository KYC path; exercising this branch
  /// requires compiling with OFFLINE_DEMO=true.
  static const bool offlineDemo =
      bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false);

  final YoleApiService _api;

  KycService({required YoleApiService api}) : _api = api;

  /// Build E.164 from phoneCode + local phone (ensure leading +).
  static String toE164({required String phoneCode, required String phone}) {
    final code = phoneCode.trim();
    final local = phone.trim().replaceAll(RegExp(r'[^\d]'), '');
    final withPlus = code.startsWith('+') ? code : '+$code';
    return '$withPlus$local';
  }

  /// Ensure a phone string is E.164 (leading +). Digits-only inputs get +.
  static String ensureE164(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('+')) return trimmed;
    return '+${trimmed.replaceAll(RegExp(r'[^\d]'), '')}';
  }

  /// Send SMS OTP to phone number
  Future<void> sendOtp({
    required String phoneCode,
    required String phone,
  }) async {
    if (offlineDemo) {
      final phoneE164 = toE164(phoneCode: phoneCode, phone: phone);
      OfflineDemoRepository.instance.requestOtp(phoneE164: phoneE164);
      return;
    }

    try {
      final response = await _api.sendSmsOtp(
        phoneCode: phoneCode,
        phone: phone,
      );

      if (response.statusCode != 200) {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to send OTP: $e');
    }
  }

  /// Validate KYC with all required documents
  Future<Map<String, dynamic>> submitKyc({
    required String phoneNumber,
    required String otpCode,
    required String idNumber,
    String? idPhotoPath,
    String? passportPhotoPath,
  }) async {
    if (offlineDemo) {
      final phoneE164 = ensureE164(phoneNumber);
      try {
        OfflineDemoRepository.instance.verifyOtp(
          phoneE164: phoneE164,
          code: otpCode,
        );
        final result = OfflineDemoRepository.instance.submitKyc(
          phoneE164: phoneE164,
          idNumber: idNumber,
        );
        return {
          'success': true,
          'data': result,
        };
      } catch (e) {
        if (e is YoleApiException) rethrow;
        final msg = e.toString();
        if (msg.contains('Not authenticated') ||
            msg.contains('no current customer') ||
            msg.contains('_requireCustomer')) {
          throw YoleApiException(
            'Offline KYC requires a logged-in customer. '
            'Please login or register first (offline register sets the session).',
          );
        }
        throw YoleApiException('Failed to submit KYC: $e');
      }
    }

    try {
      final response = await _api.validateKyc(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
        idNumber: idNumber,
        idPhotoPath: idPhotoPath,
        passportPhotoPath: passportPhotoPath,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to submit KYC: $e');
    }
  }
}
