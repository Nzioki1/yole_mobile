import 'package:dio/dio.dart';
import 'interceptors.dart';

class DioClient {
  final Dio dio;

  DioClient(String baseUrl, {List<Interceptor>? extraInterceptors})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.addAll([
      AppLogInterceptor(),
      if (extraInterceptors != null) ...extraInterceptors,
    ]);
  }
}