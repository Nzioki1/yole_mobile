import 'dart:convert';
import 'yole_api_service.dart';
import '../models/api/error_response.dart';

/// KYC service for handling KYC verification operations
class KycService {
  final YoleApiService _api;

  KycService({required YoleApiService api}) : _api = api;

  /// Send SMS OTP to phone number
  Future<void> sendOtp({
    required String phoneCode,
    required String phone,
  }) async {
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

