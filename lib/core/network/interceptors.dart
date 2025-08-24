import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../features/auth/data/auth_token_store.dart';

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

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Set Accept header from dotenv (no hard-coded fallback)
    final apiAccept = dotenv.env['API_ACCEPT'];
    if (apiAccept != null && apiAccept.isNotEmpty) {
      options.headers[HttpHeaders.acceptHeader] = apiAccept;
    }

    // Set X-API-Key header from dotenv (no hard-coded fallback)
    final authHeader = dotenv.env['AUTH_HEADER'];
    if (authHeader != null && authHeader.isNotEmpty) {
      options.headers['X-API-Key'] = authHeader;
    }

    // Set User-Agent from package_info_plus
    final packageInfo = await PackageInfo.fromPlatform();
    options.headers['User-Agent'] = 
        '${packageInfo.appName} - ${packageInfo.packageName}/${packageInfo.version}+${packageInfo.buildNumber} - Dart/${Platform.version} - OS: ${Platform.operatingSystem}/${Platform.operatingSystemVersion}';

    // Set content-type only if data is FormData
    if (options.data is FormData) {
      options.headers[HttpHeaders.contentTypeHeader] = 'multipart/form-data';
    }

    // Add Authorization header only for protected routes
    if (!isAuthFreeRoute(options.path)) {
      final token = await AuthTokenStore.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String error = "";
    switch (err.type) {
      case DioExceptionType.cancel:
        error = 'Request to API server was cancelled';
        break;
      case DioExceptionType.connectionTimeout:
        error = 'Connection to API server timed out';
        break;
      case DioExceptionType.receiveTimeout:
        error = 'Receive timeout in connection with API server';
        break;
      case DioExceptionType.sendTimeout:
        error = 'Send timeout in connection with API server';
        break;
      case DioExceptionType.badResponse:
        if (err.response!.data != null) {
          if (err.response!.data is String) {
            error = '${err.response!.statusCode}: ${err.response!.data}';
          } else {
            error = err.response!.data['message'] ?? 'Bad response';
          }
          if (err.response!.statusCode == 404 && err.response!.data is String) {
            error = '${err.response!.statusCode} Page not found.';
          }
          if (err.response!.statusCode == 500 && err.response!.data is String) {
            error = '${err.response!.statusCode} Internal server error.';
          }
          if (err.response!.statusCode == 401) {
            error = 'Unauthenticated';
          }
          if (err.response!.statusCode == 403) {
            error = 'Unauthorized';
          }
        } else {
          error = 'Received invalid status code: ${err.response!.statusCode}';
        }
        break;
      case DioExceptionType.unknown:
        error = 'Connection to API server failed due to internet connection';
        break;
      case DioExceptionType.badCertificate:
        error = 'Bad certificate Identified!';
        break;
      case DioExceptionType.connectionError:
        error = 'Connection Error Occurred!';
        break;
    }
    final errorHandler = err.copyWith(error: error);
    handler.next(errorHandler);
  }
}

/// Returns true for any login/register/refresh endpoints used in Yole-old
bool isAuthFreeRoute(String path) {
  final normalizedPath = path.toLowerCase();
  return normalizedPath.contains('/login') || 
         normalizedPath.contains('/register') || 
         normalizedPath.contains('/refresh-token') ||
         normalizedPath.contains('/password/forgot') ||
         normalizedPath.contains('/email/verification-notification') ||
         normalizedPath.contains('/sms/send-otp') ||
         normalizedPath.contains('/validate-kyc');
}