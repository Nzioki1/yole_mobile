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
}