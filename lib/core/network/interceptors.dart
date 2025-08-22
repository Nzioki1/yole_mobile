import 'package:dio/dio.dart';

class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[REQ] ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[ERR] ${err.response?.statusCode} ${err.message}');
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[RES] ${response.statusCode} ${response.realUri}');
    super.onResponse(response, handler);
  }
}