import 'package:dio/dio.dart';
import 'models.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<Response<dynamic>> login(LoginRequest request) {
    return dio.post('login', data: FormData.fromMap(request.toJson()));
  }

  Future<Response<dynamic>> register(RegisterRequest request) {
    return dio.post('register', data: FormData.fromMap(request.toJson()));
  }

  Future<Response<dynamic>> sendEmailVerification() {
    return dio.post('email/verification-notification', data: {});
  }

  Future<Response<dynamic>> forgotPassword(String email) {
    return dio.post('password/forgot?email=$email', data: {});
  }

  Future<Response<dynamic>> refreshToken() {
    return dio.post('refresh-token', data: {});
  }

  Future<Response<dynamic>> refreshTokenWithToken(String refreshToken) {
    return dio.post('refresh-token', data: {'refresh_token': refreshToken});
  }

  // Additional endpoints from Postman collection
  Future<Response<dynamic>> logout() {
    return dio.post('logout', data: {});
  }

  Future<Response<dynamic>> getMyProfile() {
    return dio.get('me');
  }

  Future<Response<dynamic>> validateKyc(ValidateKycRequest request) {
    return dio.post('validate-kyc', data: FormData.fromMap(request.toJson()));
  }

  Future<Response<dynamic>> sendSmsOtp(SendSmsOtpRequest request) {
    return dio.post('sms/send-otp', data: FormData.fromMap(request.toJson()));
  }
}
