import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'interceptors.dart';

class DioClient {
  final Dio dio;

  DioClient({List<Interceptor>? extraInterceptors})
    : dio = Dio(
        BaseOptions(baseUrl: _getBaseUrl(), receiveDataWhenStatusError: true),
      ) {
    dio.interceptors.addAll([
      AppLogInterceptor(),
      AuthInterceptor(),
      ErrorInterceptor(),
      if (extraInterceptors != null) ...extraInterceptors,
    ]);
  }

  static String _getBaseUrl() {
    try {
      return dotenv.env['SERVER_URL'] ??
          'https://yolepesa.masterpiecefusion.com/api/';
    } catch (e) {
      print('Warning: Could not access dotenv, using default base URL');
      return 'https://yolepesa.masterpiecefusion.com/api/';
    }
  }
}
