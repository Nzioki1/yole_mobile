import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'offline_agent_repository.dart';

/// Agent API Service for YOLE NestJS backend.
///
/// When `--dart-define=OFFLINE_DEMO=true`, every public method routes through
/// [OfflineAgentRepository] and never issues HTTP.
class AgentApiService {
  /// Offline demo gate — set via `--dart-define=OFFLINE_DEMO=true`.
  static const bool offlineDemo =
      bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false);

  OfflineAgentRepository get _offline => OfflineAgentRepository.instance;

  static const String defaultBaseUrl = 'http://10.0.2.2:3000';

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _agentId;

  AgentApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: defaultBaseUrl,
            ),
        _client = client ?? http.Client(),
        _storage = const FlutterSecureStorage();

  Future<void> init() async {
    _agentId = await _storage.read(key: 'agent_id');
    if (offlineDemo && _agentId != null && _agentId!.isNotEmpty) {
      try {
        _offline.setAgentId(_agentId!);
      } catch (_) {
        // Stale stored id — ignore; getAgentInfo will fail clearly.
      }
    }
  }

  Future<void> setAgentId(String agentId) async {
    if (offlineDemo) {
      _offline.setAgentId(agentId);
    }
    _agentId = agentId;
    await _storage.write(key: 'agent_id', value: agentId);
  }

  Future<void> clearAgentId() async {
    if (offlineDemo) {
      _offline.clearSession();
    }
    _agentId = null;
    await _storage.delete(key: 'agent_id');
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_agentId != null) {
      headers['X-Agent-Id'] = _agentId!;
    }

    return headers;
  }

  /// Email-based login with password validation (Phase 2).
  /// Routes agent vs customer emails, validates password.
  /// On success, sets agent session and returns agent info.
  /// Throws:
  /// - Exception('CUSTOMER_EMAIL') for customer emails
  /// - Exception('Invalid password') for wrong password
  /// - Exception('Agent not found') for unknown email
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (offlineDemo) {
      final agent = _offline.loginByEmail(email: email, password: password);
      _agentId = agent['id'] as String;
      await _storage.write(key: 'agent_id', value: _agentId);
      return agent;
    }

    // Online mode: implement backend login endpoint when available
    throw UnimplementedError('Online agent login not yet implemented');
  }

  /// Get agent info (need to add endpoint to backend)
  Future<Map<String, dynamic>> getAgentInfo(String agentId) async {
    if (offlineDemo) {
      return _offline.getAgentInfo(agentId);
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/admin/agents/$agentId'),
      headers: {
        'X-Admin-API-Key': 'dev-admin-key',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Get agent info failed: ${response.body}');
    }
  }

  /// Get agent's float wallet balances
  Future<Map<String, dynamic>> getFloatBalances() async {
    if (offlineDemo) {
      if (_agentId == null) throw Exception('Not logged in');
      _offline.setAgentId(_agentId!);
      return _offline.getFloatBalances();
    }
    if (_agentId == null) throw Exception('Not logged in');

    final agent = await getAgentInfo(_agentId!);
    final floatWalletId = agent['floatWalletId'];

    // Get wallet pockets
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/admin/wallets/$floatWalletId'),
      headers: {
        'X-Admin-API-Key': 'dev-admin-key',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Get float balances failed: ${response.body}');
    }
  }

  /// Enroll customer
  Future<Map<String, dynamic>> enrollCustomer({
    required String firstName,
    required String lastName,
    required String password,
    String? phoneE164,
    String? email,
    String? idNumber,
    String? idType,
  }) async {
    if (offlineDemo) {
      if (_agentId == null) throw Exception('Not logged in');
      _offline.setAgentId(_agentId!);
      return _offline.enrollCustomer(
        firstName: firstName,
        lastName: lastName,
        password: password,
        phoneE164: phoneE164,
        email: email,
        idNumber: idNumber,
        idType: idType,
      );
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/agent/customers'),
      headers: _getHeaders(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
        if (phoneE164 != null) 'phoneE164': phoneE164,
        if (email != null) 'email': email,
        if (idNumber != null) 'idNumber': idNumber,
        if (idType != null) 'idType': idType,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Enroll customer failed: ${response.body}');
    }
  }

  /// Cash-in
  Future<Map<String, dynamic>> cashIn({
    required String customerId,
    required String amountMinor,
    required String currency,
  }) async {
    if (offlineDemo) {
      if (_agentId == null) throw Exception('Not logged in');
      _offline.setAgentId(_agentId!);
      return _offline.cashIn(
        customerId: customerId,
        amountMinor: amountMinor,
        currency: currency,
      );
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/agent/cash-in'),
      headers: _getHeaders(),
      body: jsonEncode({
        'customerId': customerId,
        'amountMinor': amountMinor,
        'currency': currency,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Cash-in failed: ${response.body}');
    }
  }

  /// Cash-out
  Future<Map<String, dynamic>> cashOut({
    required String customerId,
    required String amountMinor,
    required String currency,
  }) async {
    if (offlineDemo) {
      if (_agentId == null) throw Exception('Not logged in');
      _offline.setAgentId(_agentId!);
      return _offline.cashOut(
        customerId: customerId,
        amountMinor: amountMinor,
        currency: currency,
      );
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/agent/cash-out'),
      headers: _getHeaders(),
      body: jsonEncode({
        'customerId': customerId,
        'amountMinor': amountMinor,
        'currency': currency,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Cash-out failed: ${response.body}');
    }
  }

  /// Get today's commission summary
  Future<Map<String, dynamic>> getCommissionSummaryToday() async {
    if (offlineDemo) {
      if (_agentId == null) throw Exception('Not logged in');
      _offline.setAgentId(_agentId!);
      return _offline.commissionSummaryToday();
    }
    throw UnimplementedError('Online commission summary not yet implemented');
  }
}
