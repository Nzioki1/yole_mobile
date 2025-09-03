import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';

class KycApi {
  final Dio _dio;

  KycApi(this._dio);

  Future<Response> sendSmsOtp(String phoneCode, String phone) async {
    // For testing, use mock response instead of real API call
    // This avoids authentication issues during development
    print('🔍 KycApi: Mock SMS OTP sent to ${phoneCode}${phone}');

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Return mock successful response
    return Response(
      requestOptions: RequestOptions(path: ApiEndpoints.SEND_SMS_OTP),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'OTP sent successfully',
        'data': {
          'otp': '123456', // Mock OTP for testing
        },
      },
    );
  }

  Future<Response> validateKyc({
    required String phoneNumber,
    required String otpCode,
    required String idNumber,
    required String idPhoto,
    required String passportPhoto,
  }) async {
    // For testing, use mock response instead of real API call
    // This avoids authentication issues during development
    print(
      '🔍 KycApi: Mock KYC validation for phone: $phoneNumber, ID: $idNumber',
    );

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock successful response
    return Response(
      requestOptions: RequestOptions(path: ApiEndpoints.VALIDATE_KYC),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'KYC validation completed successfully',
        'data': {
          'kyc_status': 'completed',
          'verification_id': 'KYC_${DateTime.now().millisecondsSinceEpoch}',
        },
      },
    );
  }
}
