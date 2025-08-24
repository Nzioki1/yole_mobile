import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'interceptors.dart';

class DioClient {
  final Dio dio;

  DioClient({List<Interceptor>? extraInterceptors})
      : dio = Dio(BaseOptions(
          baseUrl: dotenv.env['API_BASE_URL'] ?? '',
          receiveDataWhenStatusError: true,
        )) {
    dio.interceptors.addAll([
      AppLogInterceptor(),
      AuthInterceptor(),
      ErrorInterceptor(),
      if (extraInterceptors != null) ...extraInterceptors,
    ]);
  }
}