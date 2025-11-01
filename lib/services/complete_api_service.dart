import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://yolepesa.masterpiecefusion.com/api';
  static const String apiKey =
      '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';

  // Token management
  static String? _accessToken;
  static String? _refreshToken;

  static Future<void> init() async {
    await _loadTokens();
  }

  static Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    print('📦 Loaded tokens from storage');
  }

  static Future<void> _saveTokens(
      String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    print('💾 Saved tokens to storage');
  }

  static Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    print('🗑️ Cleared tokens from storage');
  }

  // Headers with automatic token management
  static Future<Map<String, String>> _getHeaders(
      {bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Accept': 'application/x.yole.v1+json',
      'X-API-Key': apiKey,
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  // Automatic token refresh and retry logic
  static Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    // First attempt
    var response = await requestFn();

    // If token expired, refresh and retry
    if (response.statusCode == 401 && _refreshToken != null) {
      print('🔄 Token expired, attempting refresh...');

      final refreshSuccess = await _refreshAccessToken();
      if (refreshSuccess) {
        // Retry with new token
        response = await requestFn();
      }
    }

    return response;
  }

  static Future<bool> _refreshAccessToken() async {
    try {
      final url = Uri.parse('$baseUrl/refresh-token');
      final headers = await _getHeaders(includeAuth: false);

      // Use refresh token for authorization
      if (_refreshToken != null) {
        headers['Authorization'] = 'Bearer $_refreshToken';
      }

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'] ?? _refreshToken;

        if (newAccessToken != null) {
          await _saveTokens(newAccessToken, newRefreshToken!);
          print('✅ Token refreshed successfully');
          return true;
        }
      }
    } catch (e) {
      print('❌ Token refresh failed: $e');
    }

    // Refresh failed, clear tokens and force re-login
    await _clearTokens();
    return false;
  }

  // 1. LOGIN - Get access token
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final headers = await _getHeaders(includeAuth: false);

      final response = await http.post(
        url,
        headers: headers,
        body: {
          'email': email,
          'password': password,
        },
      );

      print('Login Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        if (accessToken != null) {
          await _saveTokens(accessToken, refreshToken ?? accessToken);
          return {'success': true, 'data': data};
        }
      }

      return {
        'success': false,
        'error': 'Login failed: ${response.statusCode}',
        'details': response.body
      };
    } catch (e) {
      return {'success': false, 'error': 'Exception: $e'};
    }
  }

  // 2. REFRESH TOKEN
  static Future<Map<String, dynamic>> refreshToken() async {
    final success = await _refreshAccessToken();
    return {'success': success};
  }

  // 3. PROTECTED ENDPOINTS (with auto token refresh)

  // Get My Profile
  static Future<Map<String, dynamic>> getMyProfile() async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/me');
      final headers = await _getHeaders();
      return await http.get(url, headers: headers);
    });
  }

  // Get Charges
  static Future<Map<String, dynamic>> getCharges(
      double amount, String currency, String recipientCountry) async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/charges');
      final headers = await _getHeaders();
      return await http.post(
        url,
        headers: headers,
        body: {
          'amount': amount.toString(),
          'currency': currency,
          'recipient_country': recipientCountry,
        },
      );
    });
  }

  // Get Service Charge
  static Future<Map<String, dynamic>> getServiceCharge() async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/yole-charges');
      final headers = await _getHeaders();
      return await http.post(url, headers: headers);
    });
  }

  // Transaction Status
  static Future<Map<String, dynamic>> getTransactionStatus(
      String orderTrackingId) async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/transaction/status');
      final headers = await _getHeaders();
      return await http.post(
        url,
        headers: headers,
        body: {'order_tracking_id': orderTrackingId},
      );
    });
  }

  // Send Money
  static Future<Map<String, dynamic>> sendMoney(
      double sendingAmount, String recipientCountry, String phoneNumber) async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/send-money');
      final headers = await _getHeaders();
      return await http.post(
        url,
        headers: headers,
        body: {
          'sending_amount': sendingAmount.toString(),
          'recipient_country': recipientCountry,
          'phone_number': phoneNumber,
        },
      );
    });
  }

  // Get Transactions
  static Future<Map<String, dynamic>> getTransactions() async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/transactions');
      final headers = await _getHeaders();
      return await http.get(url, headers: headers);
    });
  }

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/logout');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        await _clearTokens();
      }
      return response;
    });
  }

  // PUBLIC ENDPOINTS (no auth required)

  // Get Status
  static Future<Map<String, dynamic>> getStatus() async {
    final url = Uri.parse('$baseUrl/status');
    final headers = await _getHeaders(includeAuth: false);
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // Get Countries
  static Future<Map<String, dynamic>> getCountries() async {
    final url = Uri.parse('$baseUrl/countries');
    final headers = await _getHeaders(includeAuth: false);
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/password/forgot?email=$email');
    final headers = await _getHeaders(includeAuth: false);
    final response = await http.post(url, headers: headers);
    return _handleResponse(response);
  }

  // Register
  static Future<Map<String, dynamic>> register(
      String email,
      String name,
      String surname,
      String password,
      String passwordConfirmation,
      String country) async {
    final url = Uri.parse('$baseUrl/register');
    final headers = await _getHeaders(includeAuth: false);
    final response = await http.post(
      url,
      headers: headers,
      body: {
        'email': email,
        'name': name,
        'surname': surname,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'country': country,
      },
    );
    return _handleResponse(response);
  }

  // Send Email Verification
  static Future<Map<String, dynamic>> sendEmailVerification() async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/email/verification-notification');
      final headers = await _getHeaders();
      return await http.post(url, headers: headers);
    });
  }

  // Send SMS OTP
  static Future<Map<String, dynamic>> sendSmsOtp(
      String phoneCode, String phone) async {
    return await _makeProtectedCall(() async {
      final url = Uri.parse('$baseUrl/sms/send-otp');
      final headers = await _getHeaders();
      return await http.post(
        url,
        headers: headers,
        body: {
          'phone_code': phoneCode,
          'phone': phone,
        },
      );
    });
  }

  // Helper method for protected calls with auto-retry
  static Future<Map<String, dynamic>> _makeProtectedCall(
    Future<http.Response> Function() requestFn,
  ) async {
    final response = await _makeAuthenticatedRequest(requestFn);
    return _handleResponse(response);
  }

  // Response handler
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication required'};
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'Access forbidden - KYC may be required',
          'data': data
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'details': data
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Parse error: $e'};
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    await _loadTokens();
    return _accessToken != null;
  }

  // Get current token (for debugging)
  static String? getCurrentToken() {
    return _accessToken;
  }
}
