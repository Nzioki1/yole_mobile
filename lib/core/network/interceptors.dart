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
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Set Accept header from dotenv with safety check
    String? apiAccept;
    try {
      apiAccept = dotenv.env['API_ACCEPT'];
    } catch (e) {
      print('Warning: Could not access dotenv for API_ACCEPT, using default');
      apiAccept = 'application/x.yole.v1+json';
    }
    if (apiAccept != null && apiAccept.isNotEmpty) {
      options.headers[HttpHeaders.acceptHeader] = apiAccept;
    }

    // Set X-API-Key header from dotenv with safety check
    String? authHeader;
    try {
      authHeader = dotenv.env['AUTH_HEADER'];
    } catch (e) {
      print('Warning: Could not access dotenv for AUTH_HEADER, using default');
      authHeader = '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';
    }
    if (authHeader != null && authHeader.isNotEmpty) {
      options.headers['X-API-Key'] = authHeader;
    }

    // Set User-Agent from package_info_plus
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      options.headers['User-Agent'] =
          '${packageInfo.appName} - ${packageInfo.packageName}/${packageInfo.version}+${packageInfo.buildNumber} - Dart/${Platform.version} - OS: ${Platform.operatingSystem}/${Platform.operatingSystemVersion}';
    } catch (e) {
      print('Warning: Could not set User-Agent header: $e');
    }

    // Final header log
    print('🔐 AuthInterceptor: Final headers: ${options.headers}');

    // Set content-type for FormData requests
    if (options.data is FormData) {
      options.headers[HttpHeaders.contentTypeHeader] = 'multipart/form-data';
      print('🔐 AuthInterceptor: Set Content-Type to multipart/form-data');
    }

    // Add Authorization header only for protected routes
    if (!isAuthFreeRoute(options.path)) {
      try {
        final token = await AuthTokenStore.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
          print('🔐 AuthInterceptor: Added Authorization header');
        } else {
          print('🔐 AuthInterceptor: No valid token available');
        }
      } catch (e) {
        print('🔐 AuthInterceptor: Error getting token: $e');
      }
    } else {
      print('🔐 AuthInterceptor: ${options.path} is auth-free, skipping token');
    }

    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String error = "";

    // Enhanced error logging for debugging
    print('🔐 ErrorInterceptor: ===== ERROR DETAILS =====');
    print('🔐 ErrorInterceptor: Error type: ${err.type}');
    print('🔐 ErrorInterceptor: Error message: ${err.message}');
    print('🔐 ErrorInterceptor: Response status: ${err.response?.statusCode}');
    print('🔐 ErrorInterceptor: Response data: ${err.response?.data}');
    print('🔐 ErrorInterceptor: Request URL: ${err.requestOptions.uri}');
    print('🔐 ErrorInterceptor: Request method: ${err.requestOptions.method}');
    print(
      '🔐 ErrorInterceptor: Request headers: ${err.requestOptions.headers}',
    );
    print('🔐 ErrorInterceptor: Request data: ${err.requestOptions.data}');
    print('🔐 ErrorInterceptor: ========================');

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
  return normalizedPath.contains('login') ||
      normalizedPath.contains('register') ||
      normalizedPath.contains('refresh-token') ||
      normalizedPath.contains('password/forgot') ||
      normalizedPath.contains('email/verification-notification') ||
      normalizedPath.contains('sms/send-otp') ||
      normalizedPath.contains('validate-kyc');
}
