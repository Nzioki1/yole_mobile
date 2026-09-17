import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Core API Service for YOLE NestJS backend
class CoreApiService {
  // Configurable via --dart-define
  static const String defaultBaseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // For iOS simulator: http://localhost:3000
  // For physical device: http://<your-ip>:3000
  
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _accessToken;

  CoreApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl),
        _client = client ?? http.Client(),
        _storage = const FlutterSecureStorage();

  /// Initialize - load token from secure storage
  Future<void> init() async {
    _accessToken = await _storage.read(key: 'access_token');
  }

  /// Set access token
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await _storage.write(key: 'access_token', value: token);
  }

  /// Clear access token
  Future<void> clearAccessToken() async {
    _accessToken = null;
    await _storage.delete(key: 'access_token');
  }

  /// Get headers with auth if available
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }

  /// Auth: Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneE164,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/register'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phoneE164 != null) 'phoneE164': phoneE164,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setAccessToken(data['accessToken']);
      return data;
    } else {
      throw Exception('Register failed: ${response.body}');
    }
  }

  /// Auth: Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setAccessToken(data['accessToken']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  /// OTP: Request
  Future<void> requestOtp({required String phoneE164}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/otp/request'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({'phoneE164': phoneE164}),
    );

    if (response.statusCode != 200) {
      throw Exception('Request OTP failed: ${response.body}');
    }
  }

  /// OTP: Verify
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/otp/verify'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'phoneE164': phoneE164,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Verify OTP failed: ${response.body}');
    }
  }

  /// PIN: Check if user has PIN set
  Future<bool> hasPin() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/auth/pin/has'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasPin'] == true;
    } else {
      return false;
    }
  }

  /// PIN: Set transaction PIN
  Future<void> setPin({required String pin}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/pin/set'),
      headers: _getHeaders(),
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode != 200) {
      throw Exception('Set PIN failed: ${response.body}');
    }
  }

  /// PIN: Verify transaction PIN
  Future<bool> verifyPin({required String pin}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/pin/verify'),
      headers: _getHeaders(),
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// Limits: Get customer limits
  Future<Map<String, dynamic>> getMyLimits() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/me/limits'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get limits failed: ${response.body}');
    }
  }

  /// Notifications: Get all notifications
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/notifications'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get notifications: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Notifications: Get unread count
  Future<int> getUnreadNotificationsCount() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/notifications/unread-count'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get unread count: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }

  /// Notifications: Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/notifications/$notificationId/read'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.body}');
    }
  }

  /// Notifications: Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/notifications/mark-all-read'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all as read: ${response.body}');
    }
  }

  /// Wallets: Get my wallets
  Future<Map<String, dynamic>> getMyWallets() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/wallets/me'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get wallets failed: ${response.body}');
    }
  }

  /// Payments: Quote
  Future<Map<String, dynamic>> quotePayment({
    required String type,
    required String currency,
    required String amountMinor,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/payments/quote'),
      headers: _getHeaders(),
      body: jsonEncode({
        'type': type,
        'currency': currency,
        'amountMinor': amountMinor,
        if (metadata != null) 'metadata': metadata,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Quote payment failed: ${response.body}');
    }
  }

  /// Payments: Confirm with idempotency
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
  }) async {
    final idempotencyKey = const Uuid().v4();
    final headers = _getHeaders();
    headers['Idempotency-Key'] = idempotencyKey;

    final response = await _client.post(
      Uri.parse('$baseUrl/v1/payments/confirm'),
      headers: headers,
      body: jsonEncode({'paymentId': paymentId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Confirm payment failed: ${response.body}');
    }
  }

  /// Payments: List
  Future<List<dynamic>> listPayments() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/payments'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('List payments failed: ${response.body}');
    }
  }

  /// Payments: Get single payment by ID
  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/payments/$paymentId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Get payment failed: ${response.body}');
    }
  }

  /// Credit: Check eligibility
  Future<Map<String, dynamic>> checkCreditEligibility({
    required String type,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/credit/eligibility/$type'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Check eligibility failed: ${response.body}');
    }
  }

  /// Credit: Request loan
  Future<Map<String, dynamic>> requestLoan({
    required String type,
    required String principalMinor,
    required String currency,
    required int termMonths,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/credit/loans'),
      headers: _getHeaders(),
      body: jsonEncode({
        'type': type,
        'principalMinor': principalMinor,
        'currency': currency,
        'termMonths': termMonths,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Request loan failed: ${response.body}');
    }
  }

  /// Cards: Issue
  Future<Map<String, dynamic>> issueCard({
    required String walletPocketId,
    required String currency,
    required String dailyLimitMinor,
    required String monthlyLimitMinor,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/cards'),
      headers: _getHeaders(),
      body: jsonEncode({
        'walletPocketId': walletPocketId,
        'currency': currency,
        'dailyLimitMinor': dailyLimitMinor,
        'monthlyLimitMinor': monthlyLimitMinor,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Issue card failed: ${response.body}');
    }
  }

  /// Cards: List
  Future<List<dynamic>> listCards() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/cards'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('List cards failed: ${response.body}');
    }
  }

  /// Remittance: Quote inbound
  Future<Map<String, dynamic>> quoteInboundRemittance({
    required String amountMinor,
    required String currency,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/remittance/inbound/quote'),
      headers: _getHeaders(),
      body: jsonEncode({
        'amountMinor': amountMinor,
        'currency': currency,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Quote remittance failed: ${response.body}');
    }
  }

  /// FX: Get rates
  Future<List<dynamic>> getFxRates() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/fx/rates'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Get FX rates failed: ${response.body}');
    }
  }

  /// FX: Convert
  Future<Map<String, dynamic>> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required String fromAmountMinor,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/fx/convert'),
      headers: _getHeaders(),
      body: jsonEncode({
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'fromAmountMinor': fromAmountMinor,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Convert currency failed: ${response.body}');
    }
  }
}
