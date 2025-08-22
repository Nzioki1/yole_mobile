import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<Response<dynamic>> login(String email, String password) {
    return dio.post('/auth/login', data: {'email': email, 'password': password});
  }

  Future<Response<dynamic>> signup(String email, String password) {
    return dio.post('/auth/signup', data: {'email': email, 'password': password});
  }
}