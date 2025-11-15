import 'dart:convert';
import 'package:http/http.dart' as http;

/// API endpoint validation result
class ApiValidationResult {
  final String name;
  final String endpoint;
  final String method;
  final bool requiresAuth;
  final int statusCode;
  final int responseTimeMs;
  final String? error;
  final Map<String, dynamic>? responseBody;
  final DateTime timestamp;

  ApiValidationResult({
    required this.name,
    required this.endpoint,
    required this.method,
    required this.requiresAuth,
    required this.statusCode,
    required this.responseTimeMs,
    this.error,
    this.responseBody,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUp => statusCode >= 200 && statusCode < 300;
  bool get isAuthIssue => statusCode == 401;
  bool get isDown => !isUp && !isAuthIssue;

  String get statusEmoji {
    if (isUp) return '✅ UP';
    if (isAuthIssue) return '⚠️ AUTH ISSUE';
    return '❌ DOWN';
  }
}

/// Service to validate YOLE API endpoints
class ApiValidator {
  static const String baseUrl = 'https://yolepesa.masterpiecefusion.com/api';
  static const String apiKey =
      '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';

  final http.Client _client = http.Client();

  // Test data
  final String testEmail = 'test@yole.com';
  final String testPassword = 'Test';
  final String testPhoneCode = '+254';
  final String testPhone = '0700000000';
  final String testAmount = '10';
  final String testCurrency = 'USD';
  final String testCountry = 'Kenya';
  final String testCountryCode = 'KE';

  String? _accessToken;
  String? _refreshToken;

  /// Validate all API endpoints
  Future<List<ApiValidationResult>> validateAll() async {
    print('🔍 Starting API validation...\n');

    final results = <ApiValidationResult>[];

    // Test public endpoints first
    results.add(await _testStatus());
    await _delay();

    results.add(await _testGetCountries());
    await _delay();

    results.add(await _testLogin());
    await _delay();

    results.add(await _testRegister());
    await _delay();

    results.add(await _testForgotPassword());
    await _delay();

    // Test protected endpoints (need token from login)
    if (_accessToken != null) {
      results.add(await _testMyProfile());
      await _delay();

      results.add(await _testRefreshToken());
      await _delay();

      results.add(await _testSendEmailVerification());
      await _delay();

      results.add(
          await _testRequestBodyEndpoint('Get Charges', 'POST', '/charges', {
        'amount': testAmount,
        'currency': testCurrency,
        'recipient_country': testCountryCode,
      }));
      await _delay();

      results.add(await _testRequestBodyEndpoint(
          'Get Service Charge', 'POST', '/yole-charges', null));
      await _delay();

      results.add(await _testRequestBodyEndpoint(
          'Transaction Status', 'POST', '/transaction/status', {
        'order_tracking_id': 'test_order_id',
      }));
      await _delay();

      results.add(
          await _testRequestBodyEndpoint('Send Money', 'POST', '/send-money', {
        'sending_amount': testAmount,
        'recipient_country': testCountryCode,
        'phone_number': testPhone,
      }));
      await _delay();

      results.add(await _testGetTransactions());
      await _delay();

      results.add(await _testRequestBodyEndpoint(
          'Validate KYC', 'POST', '/validate-kyc', {
        'phone_number': testPhone,
        'otp_code': '12345',
        'id_number': '1234567',
      }));
      await _delay();

      results.add(await _testRequestBodyEndpoint(
          'Send SMS OTP', 'POST', '/sms/send-otp', {
        'phone_code': testPhoneCode,
        'phone': testPhone,
      }));

      // Test logout last
      results.add(await _testLogout());
    }

    print('\n✅ Validation complete!\n');
    return results;
  }

  /// Make HTTP request and measure response time
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final startTime = DateTime.now();

    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = <String, String>{
        'Accept': 'application/x.yole.v1+json',
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
        ...?headers,
      };

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders).timeout(
                const Duration(seconds: 10),
              );
          break;
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(
                const Duration(seconds: 10),
              );
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }

      final duration = DateTime.now().difference(startTime);
      response.duration = duration; // Store duration for validation result
      return response;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      // Return error response with duration
      final errorResponse = http.Response('{"error": "${e.toString()}"}', 0);
      errorResponse.duration = duration;
      return errorResponse;
    }
  }

  /// Test Status endpoint
  Future<ApiValidationResult> _testStatus() async {
    print('Testing GET /status...');
    try {
      final response = await _makeRequest('GET', '/status');
      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Get Status',
        endpoint: '/status',
        method: 'GET',
        requiresAuth: false,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 ? 'Unexpected status code' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Get Status',
        endpoint: '/status',
        method: 'GET',
        requiresAuth: false,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Get Countries endpoint
  Future<ApiValidationResult> _testGetCountries() async {
    print('Testing GET /countries...');
    try {
      final response = await _makeRequest('GET', '/countries');
      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Get Countries',
        endpoint: '/countries',
        method: 'GET',
        requiresAuth: false,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 ? 'Unexpected status code' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Get Countries',
        endpoint: '/countries',
        method: 'GET',
        requiresAuth: false,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Login endpoint
  Future<ApiValidationResult> _testLogin() async {
    print('Testing POST /login...');
    try {
      final response = await _makeRequest('POST', '/login', body: {
        'email': testEmail,
        'password': testPassword,
      });

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      if (response.statusCode == 200 && responseBody != null) {
        _accessToken = responseBody['access_token'] as String?;
        _refreshToken = responseBody['refresh_token'] as String?;
        print('  ✅ Login successful, token obtained');
      }

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Login',
        endpoint: '/login',
        method: 'POST',
        requiresAuth: false,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 ? 'Login failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Login',
        endpoint: '/login',
        method: 'POST',
        requiresAuth: false,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Register endpoint
  Future<ApiValidationResult> _testRegister() async {
    print('Testing POST /register...');
    try {
      // Use unique email to avoid conflicts
      final uniqueEmail =
          'validator_${DateTime.now().millisecondsSinceEpoch}@test.com';

      final response = await _makeRequest('POST', '/register', body: {
        'email': uniqueEmail,
        'name': 'Test',
        'surname': 'User',
        'password': testPassword,
        'password_confirmation': testPassword,
        'country': testCountry,
      });

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Register',
        endpoint: '/register',
        method: 'POST',
        requiresAuth: false,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 201 ? 'Registration failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Register',
        endpoint: '/register',
        method: 'POST',
        requiresAuth: false,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Forgot Password endpoint
  Future<ApiValidationResult> _testForgotPassword() async {
    print('Testing POST /password/forgot...');
    try {
      final response =
          await _makeRequest('POST', '/password/forgot?email=$testEmail');

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Forgot Password',
        endpoint: '/password/forgot',
        method: 'POST',
        requiresAuth: false,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        error: response.statusCode != 200 ? 'Password reset failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Forgot Password',
        endpoint: '/password/forgot',
        method: 'POST',
        requiresAuth: false,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test My Profile endpoint
  Future<ApiValidationResult> _testMyProfile() async {
    print('Testing GET /me...');
    try {
      final response = await _makeRequest(
        'GET',
        '/me',
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'My Profile',
        endpoint: '/me',
        method: 'GET',
        requiresAuth: true,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 ? 'Profile fetch failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'My Profile',
        endpoint: '/me',
        method: 'GET',
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Refresh Token endpoint
  Future<ApiValidationResult> _testRefreshToken() async {
    print('Testing POST /refresh-token...');
    if (_refreshToken == null) {
      print('  ⚠️  No refresh token available');
      return ApiValidationResult(
        name: 'Refresh Token',
        endpoint: '/refresh-token',
        method: 'POST',
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: 'No refresh token available',
      );
    }

    try {
      final response = await _makeRequest(
        'POST',
        '/refresh-token',
        headers: {
          'Authorization': 'Bearer $_refreshToken',
        },
      );

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Refresh Token',
        endpoint: '/refresh-token',
        method: 'POST',
        requiresAuth: true,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 ? 'Token refresh failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Refresh Token',
        endpoint: '/refresh-token',
        method: 'POST',
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Send Email Verification endpoint
  Future<ApiValidationResult> _testSendEmailVerification() async {
    print('Testing POST /email/verification-notification...');
    try {
      final response = await _makeRequest(
        'POST',
        '/email/verification-notification',
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Send Email Verification',
        endpoint: '/email/verification-notification',
        method: 'POST',
        requiresAuth: true,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        error: response.statusCode != 200 ? 'Email verification failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Send Email Verification',
        endpoint: '/email/verification-notification',
        method: 'POST',
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Get Transactions endpoint
  Future<ApiValidationResult> _testGetTransactions() async {
    print('Testing GET /transactions...');
    try {
      final response = await _makeRequest(
        'GET',
        '/transactions',
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Get Transactions',
        endpoint: '/transactions',
        method: 'GET',
        requiresAuth: true,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 ? 'Transactions fetch failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Get Transactions',
        endpoint: '/transactions',
        method: 'GET',
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test Logout endpoint
  Future<ApiValidationResult> _testLogout() async {
    print('Testing POST /logout...');
    try {
      final response = await _makeRequest(
        'POST',
        '/logout',
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: 'Logout',
        endpoint: '/logout',
        method: 'POST',
        requiresAuth: true,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        error: response.statusCode != 200 ? 'Logout failed' : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: 'Logout',
        endpoint: '/logout',
        method: 'POST',
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Test endpoint with request body
  Future<ApiValidationResult> _testRequestBodyEndpoint(
    String name,
    String method,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    print('Testing $method $endpoint...');
    try {
      final response = await _makeRequest(
        method,
        endpoint,
        body: body,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      final responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;

      print('  Status: ${response.statusCode}');
      return ApiValidationResult(
        name: name,
        endpoint: endpoint,
        method: method,
        requiresAuth: true,
        statusCode: response.statusCode,
        responseTimeMs: (response.duration?.inMilliseconds).toInt(),
        responseBody: responseBody,
        error: response.statusCode != 200 && response.statusCode != 201
            ? 'Request failed'
            : null,
      );
    } catch (e) {
      return ApiValidationResult(
        name: name,
        endpoint: endpoint,
        method: method,
        requiresAuth: true,
        statusCode: 0,
        responseTimeMs: 0,
        error: e.toString(),
      );
    }
  }

  /// Add delay between requests to avoid rate limiting
  Future<void> _delay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Extension to store duration in Response
extension ResponseDuration on http.Response {
  static final Map<int, Duration> _durations = {};

  Duration? get duration => _durations[hashCode];
  set duration(Duration? value) {
    if (value != null) {
      _durations[hashCode] = value;
    } else {
      _durations.remove(hashCode);
    }
  }
}

/// Extension to cast nullable int
extension NullableInt on int? {
  int toInt() => this ?? 0;
}
