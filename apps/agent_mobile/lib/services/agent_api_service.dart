import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Agent API Service for YOLE NestJS backend
class AgentApiService {
  static const String defaultBaseUrl = 'http://10.0.2.2:3000';
  
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _agentId;

  AgentApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl),
        _client = client ?? http.Client(),
        _storage = const FlutterSecureStorage();

  Future<void> init() async {
    _agentId = await _storage.read(key: 'agent_id');
  }

  Future<void> setAgentId(String agentId) async {
    _agentId = agentId;
    await _storage.write(key: 'agent_id', value: agentId);
  }

  Future<void> clearAgentId() async {
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

  /// Get agent info (need to add endpoint to backend)
  Future<Map<String, dynamic>> getAgentInfo(String agentId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/admin/agents/$agentId'),
      headers: {
        'X-Admin-API-Key': 'dev-admin-key',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Get agent info failed: ${response.body}');
    }
  }

  /// Get agent's float wallet balances
  Future<Map<String, dynamic>> getFloatBalances() async {
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
      return jsonDecode(response.body);
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
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/agent/customers'),
      headers: _getHeaders(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
        if (phoneE164 != null) 'phoneE164': phoneE164,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
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
      return jsonDecode(response.body);
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
      return jsonDecode(response.body);
    } else {
      throw Exception('Cash-out failed: ${response.body}');
    }
  }
}
