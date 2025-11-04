import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'unsafe_http_client.dart';
import 'storage_service.dart';

/// Base API service for YOLE backend integration
class YoleApiService {
  static const String baseUrl = 'https://yolepesa.masterpiecefusion.com/api';
  static const String apiKey =
      '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';

  final http.Client _client;
  String? _authToken;

  YoleApiService({
    http.Client? client,
    required StorageService storage,
  }) : _client = client ?? UnsafeHttpClient();

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Base request method with common headers
  Future<http.Response> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool useFormData = false,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Prepare headers
    final headers = <String, String>{
      'Accept': 'application/x.yole.v1+json',
      'X-API-Key': apiKey,
    };

    // Set Content-Type based on request type
    // Note: For form data, we'll let http package set it automatically
    // when body is Map<String, String>
    if (!useFormData) {
      headers['Content-Type'] = 'application/json';
    }

    // Add authorization header if required
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Make request with timeout
    http.Response response;
    try {
      Future<http.Response> requestFuture;
      switch (method.toUpperCase()) {
        case 'GET':
          requestFuture = _client.get(uri, headers: headers);
          break;
        case 'POST':
          // Use form data for auth endpoints, JSON for others
          if (useFormData && body != null) {
            // Convert Map<String, dynamic> to URL-encoded form data string
            // Properly handle null values and URL-encode all values
            final formPairs = <String>[];
            body.forEach((key, value) {
              if (value != null) {
                final encodedKey = Uri.encodeComponent(key.toString());
                final encodedValue = Uri.encodeComponent(value.toString());
                formPairs.add('$encodedKey=$encodedValue');
              }
            });
            final formDataString = formPairs.join('&');

            // Set Content-Type header for form data
            final formHeaders = Map<String, String>.from(headers);
            formHeaders['Content-Type'] = 'application/x-www-form-urlencoded';

            // Add logging for debugging
            print('=== REQUEST DEBUG ===');
            print('URL: $uri');
            print('Method: POST (Form Data)');
            print('Headers: $formHeaders');
            print('Form Data (encoded): $formDataString');
            
            // Send URL-encoded form data as string body
            requestFuture = _client.post(uri, headers: formHeaders, body: formDataString);
          } else {
            requestFuture = _client.post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
          }
          break;
        case 'PUT':
          requestFuture = _client.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          requestFuture = _client.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      response = await requestFuture.timeout(
        timeout ?? const Duration(seconds: 30),
        onTimeout: () {
          final timeoutSeconds = (timeout ?? const Duration(seconds: 30)).inSeconds;
          print('Request timeout: $method $endpoint (${timeoutSeconds}s)');
          throw TimeoutException('Request timed out after $timeoutSeconds seconds');
        },
      );

      print(
          'API Response: ${method} $endpoint - Status: ${response.statusCode}');
      if (response.statusCode >= 400) {
        print('Response Body: ${response.body}');
      }
    } catch (e) {
      print('Network error details: $e');
      print('Error type: ${e.runtimeType}');
      print('Endpoint: $method $endpoint');
      rethrow;
    }

    // Handle common error responses
    if (response.statusCode == 401) {
      throw YoleApiException('Unauthorized - Please login again', 401);
    } else if (response.statusCode == 403) {
      throw YoleApiException('Forbidden - Insufficient permissions', 403);
    } else if (response.statusCode == 404) {
      throw YoleApiException('Not found - Resource does not exist', 404);
    } else if (response.statusCode == 422) {
      // 422 Unprocessable Entity - validation error
      try {
        final errorBody = jsonDecode(response.body);
        
        // Extract detailed error message
        String errorMessage;
        
        // Check for nested error structure
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'].toString();
        } else if (errorBody['error'] != null) {
          errorMessage = errorBody['error'].toString();
        } else if (errorBody['errors'] != null) {
          // Handle Laravel-style validation errors
          final errors = errorBody['errors'];
          if (errors is Map) {
            final errorList = <String>[];
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorList.add('${key}: ${value.first}');
              } else if (value is String) {
                errorList.add('${key}: $value');
              }
            });
            errorMessage = errorList.isNotEmpty 
                ? errorList.join('\n')
                : 'Validation error. Please check your input.';
          } else {
            errorMessage = errors.toString();
          }
        } else {
          errorMessage = 'Validation error. Please check your input.';
        }
        
        // Log detailed error for debugging
        print('=== 422 VALIDATION ERROR ===');
        print('Endpoint: $method $endpoint');
        print('Response Body: ${response.body}');
        print('Extracted Error: $errorMessage');
        
        throw YoleApiException(errorMessage, 422);
      } catch (e) {
        if (e is YoleApiException) rethrow;
        
        // If JSON decode fails, log raw response
        print('=== 422 ERROR (JSON decode failed) ===');
        print('Endpoint: $method $endpoint');
        print('Raw Response: ${response.body}');
        print('Error: $e');
        
        throw YoleApiException(
            'Validation error. Please check your input.', 422);
      }
    } else if (response.statusCode >= 500) {
      throw YoleApiException(
          'Server error - Please try again later', response.statusCode);
    }

    return response;
  }

  /// GET request
  Future<http.Response> get(String endpoint,
      {bool requiresAuth = false, Duration? timeout}) async {
    return _request('GET', endpoint, requiresAuth: requiresAuth, timeout: timeout);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool useFormData = false,
  }) async {
    return _request('POST', endpoint,
        body: body, requiresAuth: requiresAuth, useFormData: useFormData);
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    return _request('PUT', endpoint, body: body, requiresAuth: requiresAuth);
  }

  /// DELETE request
  Future<http.Response> delete(String endpoint,
      {bool requiresAuth = false}) async {
    return _request('DELETE', endpoint, requiresAuth: requiresAuth);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null;

  /// Get current auth token
  String? get authToken => _authToken;

  /// Get user profile
  Future<http.Response> getProfile() async {
    return get('/me', requiresAuth: true);
  }

  /// Send email verification
  Future<http.Response> sendEmailVerification() async {
    return post('/email/verification-notification', requiresAuth: true);
  }

  /// Get charges for a transaction
  Future<http.Response> getCharges({
    required String amount,
    required String currency,
    required String recipientCountry,
  }) async {
    return post('/charges',
        body: {
          'amount': amount,
          'currency': currency,
          'recipient_country': recipientCountry,
        },
        requiresAuth: true);
  }

  /// Get Yole service charges
  Future<http.Response> getYoleCharges() async {
    return post('/yole-charges', requiresAuth: true);
  }

  /// Get transaction status
  Future<http.Response> getTransactionStatus(String orderTrackingId) async {
    return post('/transaction/status',
        body: {
          'order_tracking_id': orderTrackingId,
        },
        requiresAuth: true);
  }

  /// Send money
  Future<http.Response> sendMoney({
    required String sendingAmount,
    required String recipientCountry,
    required String phoneNumber,
  }) async {
    return post('/send-money',
        body: {
          'sending_amount': sendingAmount,
          'recipient_country': recipientCountry,
          'phone_number': phoneNumber,
        },
        requiresAuth: true);
  }

  /// Send money with PesaPal integration
  /// Supports multiple payment methods: 'pesapal' or 'mobile_money'
  Future<http.Response> sendMoneyWithPesaPal({
    required double sendingAmount,
    required String recipientCountry,
    required String phoneNumber,
    required String paymentMethod,
  }) async {
    return post('/send-money',
        body: {
          'sending_amount': sendingAmount.toString(),
          'recipient_country': recipientCountry,
          'phone_number': phoneNumber,
          'payment_method': paymentMethod, // 'pesapal' or 'mobile_money'
        },
        requiresAuth: true);
  }

  /// Get transactions list
  Future<http.Response> getTransactions() async {
    return get('/transactions', requiresAuth: true);
  }

  /// POST request with multipart form data (for file uploads)
  Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, String>? files,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Prepare headers
    final headers = <String, String>{
      'Accept': 'application/x.yole.v1+json',
      'X-API-Key': apiKey,
    };

    // Add authorization header if required
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Create multipart request
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    // Add form fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add files
    if (files != null) {
      for (final entry in files.entries) {
        if (entry.value.isNotEmpty) {
          // Check if file exists
          final file = http.MultipartFile.fromPath(entry.key, entry.value);
          request.files.add(await file);
        }
      }
    }

    try {
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Longer timeout for file uploads
        onTimeout: () {
          print('Multipart request timeout: $endpoint');
          throw TimeoutException('File upload timed out after 60 seconds');
        },
      );

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);

      print('API Response: POST (multipart) $endpoint - Status: ${response.statusCode}');
      if (response.statusCode >= 400) {
        print('Response Body: ${response.body}');
      }

      // Handle common error responses
      if (response.statusCode == 401) {
        throw YoleApiException('Unauthorized - Please login again', 401);
      } else if (response.statusCode == 403) {
        throw YoleApiException('Forbidden - Insufficient permissions', 403);
      } else if (response.statusCode == 404) {
        throw YoleApiException('Not found - Resource does not exist', 404);
      } else if (response.statusCode >= 500) {
        throw YoleApiException(
            'Server error - Please try again later', response.statusCode);
      }

      return response;
    } catch (e) {
      print('Multipart request error: $e');
      print('Error type: ${e.runtimeType}');
      print('Endpoint: POST (multipart) $endpoint');
      if (e is YoleApiException) rethrow;
      if (e is TimeoutException) rethrow;
      throw YoleApiException('File upload failed: $e');
    }
  }

  /// Validate KYC with multipart file upload
  Future<http.Response> validateKyc({
    required String phoneNumber,
    required String otpCode,
    required String idNumber,
    String? idPhotoPath,
    String? passportPhotoPath,
  }) async {
    final fields = <String, String>{
      'phone_number': phoneNumber,
      'otp_code': otpCode,
      'id_number': idNumber,
    };

    final files = <String, String>{};
    if (idPhotoPath != null && idPhotoPath.isNotEmpty) {
      files['id_photo'] = idPhotoPath;
    }
    if (passportPhotoPath != null && passportPhotoPath.isNotEmpty) {
      files['passport_photo'] = passportPhotoPath;
    }

    return postMultipart(
      '/validate-kyc',
      fields: fields,
      files: files,
      requiresAuth: true,
    );
  }

  /// Send SMS OTP
  Future<http.Response> sendSmsOtp({
    required String phoneCode,
    required String phone,
  }) async {
    return post('/sms/send-otp',
        body: {
          'phone_code': phoneCode,
          'phone': phone,
        },
        requiresAuth: true);
  }

  /// Get countries list
  Future<http.Response> getCountries() async {
    return get('/countries');
  }

  /// Get API status
  Future<http.Response> getStatus() async {
    return get('/status');
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// YOLE API exception
class YoleApiException implements Exception {
  final String message;
  final int? statusCode;

  const YoleApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'YoleApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
