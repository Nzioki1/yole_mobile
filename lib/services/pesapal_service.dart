import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_request_model.dart';
import 'yole_api_service.dart';
import 'storage_service.dart';
import 'unsafe_http_client.dart';

/// PesaPal API service for handling payments
/// FORCE SANDBOX MODE - This service is locked to sandbox during development
class PesaPalService {
  // FORCE SANDBOX MODE - Remove production toggle during dev
  static const String baseUrl = 'https://cybqa.pesapal.com/pesapalv3';

  // Sandbox credentials (from PesaPal documentation)
  static const String consumerKey = 'qkio1BGGYAXTu2JOfm7XSXNruoZsrqEW';
  static const String consumerSecret = 'osGQ364R49cXKeOYSpaOnT++rHs=';

  // Callback URLs
  static const String callbackUrl = 'https://yole.app/payment/callback';
  static const String cancelUrl = 'https://yole.app/payment/cancel';
  static const String ipnUrl = 'https://yole.app/payment/ipn';

  String? _accessToken;
  DateTime? _tokenExpiry;
  String? _ipnId; // Cache IPN ID
  final StorageService _storage = StorageService();
  final http.Client _httpClient =
      UnsafeHttpClient(); // Bypass SSL verification for sandbox

  // Remove isProduction parameter entirely - always sandbox
  PesaPalService();

  /// Get access token for API authentication
  Future<String> getAccessToken() async {
    // Return cached token if still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      print('Using cached PesaPal sandbox token');
      return _accessToken!;
    }

    print('=== GETTING PESAPAL SANDBOX TOKEN ===');

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/Auth/RequestToken'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'consumer_key': consumerKey,
          'consumer_secret': consumerSecret,
        }),
      );

      print('Token Response Status: ${response.statusCode}');
      print('Token Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['token'];
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        print('✓ Sandbox token obtained successfully');
        return _accessToken!;
      } else {
        throw PesaPalException(
            'Failed to get sandbox token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw PesaPalException('Error getting sandbox token: $e');
    }
  }

  /// Register and cache IPN URL - STRICT: no fallbacks
  Future<String> _getOrRegisterIPN() async {
    // Return cached IPN if exists
    if (_ipnId != null) {
      print('Using cached IPN: $_ipnId');
      return _ipnId!;
    }

    print('=== REGISTERING PESAPAL IPN ===');
    final token = await getAccessToken();

    try {
      // Step 1: Try to get existing IPN first
      try {
        final existingIPNs = await _getIPNList();
        if (existingIPNs.isNotEmpty) {
          _ipnId = existingIPNs.first;
          print('✓ Using existing IPN: $_ipnId');
          return _ipnId!;
        }
      } catch (e) {
        print('Could not get existing IPN list, will register new one: $e');
      }

      // Step 2: Register new IPN
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/URLSetup/RegisterIPN'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'url': ipnUrl,
          'ipn_notification_type': 'GET',
        }),
      );

      print('IPN Registration Status: ${response.statusCode}');
      print('IPN Registration Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ipnId = data['ipn_id'] as String;
        print('✓ Registered new IPN: $_ipnId');
        return _ipnId!;
      } else {
        throw PesaPalException(
            'Failed to register IPN: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is PesaPalException) rethrow;
      throw PesaPalException('Unable to obtain IPN id: $e');
    }
  }

  /// Submit order request to PesaPal
  Future<PesaPalOrderResponse> submitOrderRequest({
    required TransactionRequest transaction,
    required String userEmail,
  }) async {
    print('═══════════════════════════════════════════════');
    print('🚀 PESAPAL SANDBOX ORDER REQUEST START');
    print('═══════════════════════════════════════════════');
    print('📦 Transaction Data:');
    print('   Amount: ${transaction.totalAmount}');
    print('   Currency: ${transaction.currency}');
    print('   Recipient: ${transaction.recipient}');
    print('   Phone: ${transaction.recipientPhone}');
    print('   Country: ${transaction.recipientCountry}');
    print('   Email: $userEmail');

    // Step 1: Get access token
    print('\n📍 STEP 1: Getting PesaPal access token...');
    String token;
    try {
      token = await getAccessToken();
      print('✅ STEP 1 SUCCESS: Token obtained');
    } catch (e) {
      print('❌ STEP 1 FAILED: Token error - $e');
      rethrow;
    }

    // Step 2: Get or register IPN
    print('\n📍 STEP 2: Getting/Registering IPN...');
    String ipnId;
    try {
      ipnId = await _getOrRegisterIPN();
      print('✅ STEP 2 SUCCESS: IPN = $ipnId');
    } catch (e) {
      print('❌ STEP 2 FAILED: IPN error - $e');
      rethrow;
    }

    // Step 3: Get charges from backend
    print('\n📍 STEP 3: Fetching charges from YOLE backend...');
    Map<String, dynamic> charges;
    try {
      charges = await _calculateCharges(
        amount: transaction.amount,
        currency: transaction.currency,
        recipientCountry: transaction.recipientCountry ?? 'KE',
      );
      print('✅ STEP 3 SUCCESS: Charges received');
      print('   Charges response: $charges');
    } catch (e) {
      print('❌ STEP 3 FAILED: Charges API error - $e');
      rethrow;
    }

    // Extract local amount - support multiple response shapes
    print('\n📍 STEP 4: Extracting local amount/currency...');
    final num? amt = (charges['local_amount'] as num?) ??
        (charges['amount_local'] as num?) ??
        (charges['totalAmount'] as num?);

    // Extract local currency - support multiple response shapes
    final String? cur = (charges['local_currency'] as String?) ??
        (charges['currency_local'] as String?) ??
        (charges['feeCurrency'] as String?);

    if (amt == null) {
      print('❌ STEP 4 FAILED: No local amount in response');
      throw PesaPalException(
          'Backend charges response missing local amount. Response: $charges');
    }

    // Use local currency from backend if provided, else use country mapping
    final String localCurrency = (cur != null && cur.isNotEmpty)
        ? cur
        : _getCurrencyForCountry(transaction.recipientCountry ?? 'KE');

    final double localAmount = amt.toDouble();

    print('✅ STEP 4 SUCCESS:');
    print('   Local Amount: $localAmount');
    print('   Local Currency: $localCurrency');

    // Step 5: Normalize phone
    print('\n📍 STEP 5: Normalizing phone number...');
    String normalizedPhone;
    try {
      normalizedPhone = _normalizePhoneNumber(
        transaction.recipientPhone ?? '',
        transaction.recipientCountry ?? 'KE',
      );
      print('✅ STEP 5 SUCCESS: Phone normalized to $normalizedPhone');
    } catch (e) {
      print('❌ STEP 5 FAILED: Phone normalization error - $e');
      rethrow;
    }

    final merchantReference =
        'YOLE_SANDBOX_${DateTime.now().millisecondsSinceEpoch}';

    // Step 6: Prepare order payload
    print('\n📍 STEP 6: Preparing order payload...');
    final orderData = {
      'id': merchantReference,
      'currency': localCurrency,
      'amount': localAmount,
      'description': 'Send money to ${transaction.recipient}',
      'callback_url': callbackUrl,
      'cancellation_url': cancelUrl,
      'notification_id': ipnId,
      'billing_address': {
        'phone_number': normalizedPhone,
        'email_address': userEmail,
        'country_code': (transaction.recipientCountry ?? 'CD').toUpperCase(),
        'first_name': transaction.recipient.split(' ').first,
        'last_name': transaction.recipient.split(' ').length > 1
            ? transaction.recipient.split(' ').skip(1).join(' ')
            : '',
        'line_1': '',
        'line_2': '',
        'city': '',
        'state': '',
        'postal_code': '',
        'zip_code': '',
      },
    };

    print('✅ STEP 6 SUCCESS: Order payload prepared');
    print('📤 Order payload:');
    print('   Merchant Ref: $merchantReference');
    print('   Amount: $localAmount $localCurrency');
    print('   IPN ID: $ipnId');
    print('   Full payload: ${jsonEncode(orderData)}');

    // Step 7: Submit to PesaPal
    print('\n📍 STEP 7: Submitting order to PesaPal...');
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/Transactions/SubmitOrderRequest'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      print('📥 PesaPal API Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orderResponse = PesaPalOrderResponse.fromJson(data);
        print('\n✅ STEP 7 SUCCESS: Order submitted!');
        print('═══════════════════════════════════════════════');
        print('🎉 ORDER TRACKING ID: ${orderResponse.orderTrackingId}');
        print('📋 MERCHANT REF: ${orderResponse.merchantReference}');
        print('🔗 REDIRECT URL: ${orderResponse.redirectUrl}');
        print('═══════════════════════════════════════════════');
        return orderResponse;
      } else {
        print('❌ STEP 7 FAILED: Non-200 response');
        final errorBody = response.body;
        throw PesaPalException(
            'Submit order failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ STEP 7 FAILED: Exception during submission');
      if (e is PesaPalException) rethrow;
      throw PesaPalException('Error submitting sandbox order: $e');
    }
  }

  /// Map recipient country (ISO-2) to expected transaction currency
  String _getCurrencyForCountry(String countryCode) {
    const Map<String, String> countryCurrencyMap = {
      'KE': 'KES', // Kenya
      'UG': 'UGX', // Uganda
      'TZ': 'TZS', // Tanzania
      'RW': 'RWF', // Rwanda
      'CD': 'CDF', // DR Congo
    };
    return countryCurrencyMap[countryCode.toUpperCase()] ?? 'USD';
  }

  /// Call YOLE backend to compute charges/localized totals - REQUIRED
  Future<Map<String, dynamic>> _calculateCharges({
    required double amount,
    required String currency,
    required String recipientCountry,
  }) async {
    print('=== CALLING YOLE CHARGES API ===');
    print('Amount: $amount $currency for $recipientCountry');

    final token = await _storage.getToken();
    final uri = Uri.parse('${YoleApiService.baseUrl}/charges');
    final headers = <String, String>{
      'Accept': 'application/x.yole.v1+json',
      'X-API-Key': YoleApiService.apiKey,
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'amount': amount,
      'currency': currency,
      'recipient_country': recipientCountry,
    });

    try {
      final resp = await http.post(uri, headers: headers, body: body);
      print('Charges API status: ${resp.statusCode}');
      print('Charges API body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        print('✓ Charges API success');
        return data;
      } else {
        throw PesaPalException(
            'Failed to get charges: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      if (e is PesaPalException) rethrow;
      throw PesaPalException('Failed to get charges: $e');
    }
  }

  /// Convert national number to E.164 using country defaults - validates format
  String _normalizePhoneNumber(String phone, String countryCode) {
    final trimmed = phone.replaceAll(RegExp(r'\s+'), '');

    String e164Phone;

    // If already E.164, validate and return
    if (trimmed.startsWith('+')) {
      e164Phone = trimmed;
    } else {
      // Map country code to dial code
      final Map<String, String> dial = {
        'KE': '+254',
        'UG': '+256',
        'TZ': '+255',
        'RW': '+250',
        'CD': '+243',
      };
      final cc = dial[countryCode.toUpperCase()] ?? '';

      if (cc.isEmpty) {
        throw PesaPalException(
            'Invalid country code for phone normalization: $countryCode');
      }

      // Remove leading 0 if present (national format)
      final local = trimmed.startsWith('0') ? trimmed.substring(1) : trimmed;
      e164Phone = '$cc$local';
    }

    // Validate E.164 format: + followed by 9-15 digits
    final e164Regex = RegExp(r'^\+\d{9,15}$');
    if (!e164Regex.hasMatch(e164Phone)) {
      throw PesaPalException(
          'Invalid phone number format: $e164Phone (expected E.164: +XXXXXXXXX)');
    }

    print('Normalized phone: $phone -> $e164Phone');
    return e164Phone;
  }

  /// Get transaction status from PesaPal
  Future<PesaPalTransactionStatus> getTransactionStatus(
      String orderTrackingId) async {
    print('=== GETTING PESAPAL TRANSACTION STATUS ===');
    print('Order Tracking ID: $orderTrackingId');

    final token = await getAccessToken();

    try {
      final response = await _httpClient.get(
        Uri.parse(
            '$baseUrl/api/Transactions/GetTransactionStatus?orderTrackingId=$orderTrackingId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status Response Code: ${response.statusCode}');
      print('Status Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PesaPalTransactionStatus.fromJson(data);
      } else {
        throw PesaPalException(
            'Failed to get transaction status: ${response.statusCode}');
      }
    } catch (e) {
      throw PesaPalException('Error getting transaction status: $e');
    }
  }

  /// Get list of registered IPN URLs
  Future<List<String>> _getIPNList() async {
    final token = await getAccessToken();

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/URLSetup/GetIpnList'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ipnList = List<String>.from(data['ipn_list'] ?? []);
        print('Found ${ipnList.length} registered IPN(s)');
        return ipnList;
      } else {
        throw PesaPalException(
            'Failed to get IPN list: ${response.statusCode}');
      }
    } catch (e) {
      throw PesaPalException('Error getting IPN list: $e');
    }
  }

  /// Test sandbox connection
  Future<bool> testSandboxConnection() async {
    try {
      print('=== TESTING PESAPAL SANDBOX CONNECTION ===');
      await getAccessToken();
      print('✓ Sandbox token obtained successfully');
      return true;
    } catch (e) {
      print('✗ Sandbox connection failed: $e');
      return false;
    }
  }

  /// Generate payment URL for redirect
  String generatePaymentUrl(String redirectUrl) {
    return redirectUrl;
  }

  /// Validate IPN callback signature (for webhook verification)
  bool validateIPNSignature({
    required String orderTrackingId,
    required String orderMerchantReference,
    required String orderNotificationType,
    required String signature,
  }) {
    // PesaPal IPN signature validation
    // This is a simplified version - in production, implement proper signature validation
    final expectedSignature = _generateIPNSignature(
      orderTrackingId: orderTrackingId,
      orderMerchantReference: orderMerchantReference,
      orderNotificationType: orderNotificationType,
    );

    return signature == expectedSignature;
  }

  String _generateIPNSignature({
    required String orderTrackingId,
    required String orderMerchantReference,
    required String orderNotificationType,
  }) {
    final data =
        '$orderTrackingId|$orderMerchantReference|$orderNotificationType';
    final key = utf8.encode(consumerSecret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
}

/// PesaPal API exception
class PesaPalException implements Exception {
  final String message;
  const PesaPalException(this.message);

  @override
  String toString() => 'PesaPalException: $message';
}
