import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'offline_demo_repository.dart';

/// Core API Service for YOLE NestJS backend
class CoreApiService {
  /// Offline demo gate — set via `--dart-define=OFFLINE_DEMO=true`.
  static const bool offlineDemo =
      bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false);

  OfflineDemoRepository get _offline => OfflineDemoRepository.instance;

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
    if (offlineDemo) {
      _offline.clearSession();
    }
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
    if (offlineDemo) {
      final data = _offline.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneE164: phoneE164,
      );
      await setAccessToken(data['accessToken'] as String);
      return data;
    }
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
    if (offlineDemo) {
      final data = _offline.login(email: email, password: password);
      await setAccessToken(data['accessToken'] as String);
      return data;
    }
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
    if (offlineDemo) {
      _offline.requestOtp(phoneE164: phoneE164);
      return;
    }
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
    if (offlineDemo) {
      return _offline.verifyOtp(phoneE164: phoneE164, code: code);
    }
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
    if (offlineDemo) {
      return _offline.hasPin();
    }
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
    if (offlineDemo) {
      _offline.setPin(pin: pin);
      return;
    }
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
    if (offlineDemo) {
      return _offline.verifyPin(pin: pin);
    }
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
    if (offlineDemo) {
      return _offline.getMyLimits();
    }
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
    if (offlineDemo) {
      return _offline.getNotifications();
    }
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
    if (offlineDemo) {
      return _offline.getUnreadNotificationsCount();
    }
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
    if (offlineDemo) {
      _offline.markNotificationAsRead(notificationId);
      return;
    }
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
    if (offlineDemo) {
      _offline.markAllNotificationsAsRead();
      return;
    }
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
    if (offlineDemo) {
      return _offline.getMyWallets();
    }
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
    if (offlineDemo) {
      return _offline.quotePayment(
        type: type,
        currency: currency,
        amountMinor: amountMinor,
        metadata: metadata,
      );
    }
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
    if (offlineDemo) {
      return _offline.confirmPayment(paymentId: paymentId);
    }
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
    if (offlineDemo) {
      return _offline.listPayments();
    }
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
    if (offlineDemo) {
      return _offline.getPayment(paymentId);
    }
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
    if (offlineDemo) {
      return _offline.checkCreditEligibility(type: type);
    }
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
    if (offlineDemo) {
      return _offline.requestLoan(
        type: type,
        principalMinor: principalMinor,
        currency: currency,
        termMonths: termMonths,
      );
    }
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

  /// Credit: List loans
  Future<List<dynamic>> listLoans() async {
    if (offlineDemo) {
      return _offline.listLoans();
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/credit/loans'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['loans'] as List? ?? []);
    } else {
      throw Exception('List loans failed: ${response.body}');
    }
  }

  /// Credit: Get loan detail
  Future<Map<String, dynamic>> getLoan(String loanId) async {
    if (offlineDemo) {
      return _offline.getLoan(loanId);
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/credit/loans/$loanId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get loan failed: ${response.body}');
    }
  }

  /// Cards: Issue
  Future<Map<String, dynamic>> issueCard({
    required String walletPocketId,
    required String currency,
    required String dailyLimitMinor,
    required String monthlyLimitMinor,
  }) async {
    if (offlineDemo) {
      return _offline.issueCard(
        walletPocketId: walletPocketId,
        currency: currency,
        dailyLimitMinor: dailyLimitMinor,
        monthlyLimitMinor: monthlyLimitMinor,
      );
    }
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
    if (offlineDemo) {
      return _offline.listCards();
    }
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

  /// Cards: Get detail
  Future<Map<String, dynamic>> getCard(String cardId) async {
    if (offlineDemo) {
      return _offline.getCard(cardId);
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/cards/$cardId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get card failed: ${response.body}');
    }
  }

  /// Cards: Freeze
  Future<Map<String, dynamic>> freezeCard(String cardId) async {
    if (offlineDemo) {
      return _offline.freezeCard(cardId);
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/cards/$cardId/freeze'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Freeze card failed: ${response.body}');
    }
  }

  /// Cards: Activate
  Future<Map<String, dynamic>> activateCard(String cardId) async {
    if (offlineDemo) {
      return _offline.activateCard(cardId);
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/cards/$cardId/activate'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Activate card failed: ${response.body}');
    }
  }

  /// Cards: Block
  Future<Map<String, dynamic>> blockCard(String cardId) async {
    if (offlineDemo) {
      return _offline.blockCard(cardId);
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/cards/$cardId/block'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Block card failed: ${response.body}');
    }
  }

  /// Cards: Update limits
  Future<Map<String, dynamic>> updateCardLimits({
    required String cardId,
    required String dailyLimitMinor,
    required String monthlyLimitMinor,
  }) async {
    if (offlineDemo) {
      return _offline.updateCardLimits(
        cardId: cardId,
        dailyLimitMinor: dailyLimitMinor,
        monthlyLimitMinor: monthlyLimitMinor,
      );
    }
    final response = await _client.patch(
      Uri.parse('$baseUrl/v1/cards/$cardId/limits'),
      headers: _getHeaders(),
      body: jsonEncode({
        'dailyLimitMinor': dailyLimitMinor,
        'monthlyLimitMinor': monthlyLimitMinor,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Update card limits failed: ${response.body}');
    }
  }

  /// Cards: List transactions
  Future<List<dynamic>> getCardTransactions(String cardId) async {
    if (offlineDemo) {
      return _offline.getCardTransactions(cardId);
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/cards/$cardId/transactions'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['transactions'] as List? ?? []);
    } else {
      throw Exception('Get card transactions failed: ${response.body}');
    }
  }

  /// Remittance: Quote inbound
  Future<Map<String, dynamic>> quoteInboundRemittance({
    required String amountMinor,
    required String currency,
  }) async {
    if (offlineDemo) {
      return _offline.quoteInboundRemittance(
        amountMinor: amountMinor,
        currency: currency,
      );
    }
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
      throw Exception('Quote inbound remittance failed: ${response.body}');
    }
  }

  /// Remittance: Confirm inbound
  Future<Map<String, dynamic>> confirmInboundRemittance(String quoteId) async {
    if (offlineDemo) {
      return _offline.confirmInboundRemittance(quoteId);
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/remittance/inbound/$quoteId/confirm'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Confirm inbound remittance failed: ${response.body}');
    }
  }

  /// Remittance: Quote outbound
  Future<Map<String, dynamic>> quoteOutboundRemittance({
    required String amountMinor,
    required String currency,
  }) async {
    if (offlineDemo) {
      return _offline.quoteOutboundRemittance(
        amountMinor: amountMinor,
        currency: currency,
      );
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/remittance/outbound/quote'),
      headers: _getHeaders(),
      body: jsonEncode({
        'amountMinor': amountMinor,
        'currency': currency,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Quote outbound remittance failed: ${response.body}');
    }
  }

  /// Remittance: List
  Future<List<dynamic>> listRemittances() async {
    if (offlineDemo) {
      return _offline.listRemittances();
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/remittance'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['remittances'] as List? ?? []);
    } else {
      throw Exception('List remittances failed: ${response.body}');
    }
  }

  /// FX: Get rates
  Future<List<dynamic>> getFxRates() async {
    if (offlineDemo) {
      return _offline.getFxRates();
    }
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
    if (offlineDemo) {
      return _offline.convertCurrency(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        fromAmountMinor: fromAmountMinor,
      );
    }
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

  // ---------------------------------------------------------------------------
  // Savings Goals (Poste Finance)
  // ---------------------------------------------------------------------------

  /// List savings goals
  Future<List<dynamic>> listSavingsGoals() async {
    if (offlineDemo) {
      return _offline.listSavingsGoals();
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/savings/goals'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['goals'] as List? ?? []);
    } else {
      throw Exception('List savings goals failed: ${response.body}');
    }
  }

  /// Get savings goal by ID
  Future<Map<String, dynamic>> getSavingsGoal(String goalId) async {
    if (offlineDemo) {
      return _offline.getSavingsGoal(goalId);
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/savings/goals/$goalId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get savings goal failed: ${response.body}');
    }
  }

  /// Create savings goal
  Future<Map<String, dynamic>> createSavingsGoal({
    required String name,
    required String targetMinor,
    required String currency,
    bool autoDepositEnabled = false,
    String? autoDepositMinor,
  }) async {
    if (offlineDemo) {
      return _offline.createSavingsGoal(
        name: name,
        targetMinor: targetMinor,
        currency: currency,
        autoDepositEnabled: autoDepositEnabled,
        autoDepositMinor: autoDepositMinor,
      );
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/savings/goals'),
      headers: _getHeaders(),
      body: jsonEncode({
        'name': name,
        'targetMinor': targetMinor,
        'currency': currency,
        'autoDepositEnabled': autoDepositEnabled,
        if (autoDepositMinor != null) 'autoDepositMinor': autoDepositMinor,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Create savings goal failed: ${response.body}');
    }
  }

  /// Add money to savings goal
  Future<Map<String, dynamic>> addMoneyToGoal({
    required String goalId,
    required String amountMinor,
    required String pin,
  }) async {
    if (offlineDemo) {
      return _offline.addMoneyToGoal(
        goalId: goalId,
        amountMinor: amountMinor,
        pin: pin,
      );
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/savings/goals/$goalId/deposit'),
      headers: _getHeaders(),
      body: jsonEncode({
        'amountMinor': amountMinor,
        'pin': pin,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Add money to goal failed: ${response.body}');
    }
  }

  // ---------------------------------------------------------------------------
  // Insurance (offline demo only this sprint)
  // ---------------------------------------------------------------------------

  /// Get insurance products
  Future<List<Map<String, dynamic>>> getInsuranceProducts() async {
    if (offlineDemo) {
      return _offline.listInsuranceProducts();
    }
    // Future: real API call
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Get customer insurance policies
  Future<List<Map<String, dynamic>>> getInsurancePolicies(String customerId) async {
    if (offlineDemo) {
      return _offline.listInsurancePolicies(customerId);
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Activate insurance policy
  Future<Map<String, dynamic>> activateInsurance({
    required String customerId,
    required String productId,
    required String premiumMode,
    String? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required String deductFrom,
  }) async {
    if (offlineDemo) {
      return _offline.activateInsurancePolicy(
        customerId: customerId,
        productId: productId,
        premiumMode: premiumMode,
        fixedSchedule: fixedSchedule,
        fixedMinor: fixedMinor,
        percentBps: percentBps,
        deductFrom: deductFrom,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Update insurance policy
  Future<Map<String, dynamic>> updateInsurance({
    required String policyId,
    required String premiumMode,
    String? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required String deductFrom,
  }) async {
    if (offlineDemo) {
      return _offline.updateInsurancePolicy(
        policyId: policyId,
        premiumMode: premiumMode,
        fixedSchedule: fixedSchedule,
        fixedMinor: fixedMinor,
        percentBps: percentBps,
        deductFrom: deductFrom,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Deactivate insurance policy
  Future<void> deactivateInsurance(String policyId) async {
    if (offlineDemo) {
      _offline.deactivateInsurancePolicy(policyId);
      return;
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Preview insurance premiums for a transaction
  Future<List<Map<String, dynamic>>> previewInsurancePremiums({
    required String customerId,
    required String rail,
    required int principalMinor,
  }) async {
    if (offlineDemo) {
      return _offline.previewInsurancePremiums(
        customerId: customerId,
        rail: rail,
        principalMinor: principalMinor,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Collect insurance premiums after payment success
  Future<List<Map<String, dynamic>>> collectInsurancePremiums({
    required String customerId,
    required String rail,
    required int principalMinor,
    required String parentTransactionId,
  }) async {
    if (offlineDemo) {
      return _offline.collectInsurancePremiums(
        customerId: customerId,
        rail: rail,
        principalMinor: principalMinor,
        parentTransactionId: parentTransactionId,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }
}
