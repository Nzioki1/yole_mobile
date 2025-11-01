import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simplified API service that provides easy-to-use methods
/// Returns: {success: bool, data: dynamic, error: String?}
class SimpleApiService {
  static const String baseUrl = 'https://yolepesa.masterpiecefusion.com/api';
  static const String apiKey =
      '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';

  /// Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Accept': 'application/x.yole.v1+json',
      'X-API-Key': apiKey,
      'Content-Type': 'application/json',
    };

    // Note: We use the existing StorageService from providers
    // For simplicity, we'll get token from the API service directly
    return headers;
  }

  /// Add bearer token to headers
  static Map<String, String> _addBearerToken(
      Map<String, String> headers, String token) {
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // 1. Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 2. Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String passwordConfirmation,
    required String country,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/register');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'email': email,
          'name': name,
          'surname': surname,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'country': country,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 3. Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = Uri.parse('$baseUrl/password/forgot?email=$email');
      final headers = await _getHeaders();

      final response = await http.post(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 4. Get Status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final url = Uri.parse('$baseUrl/status');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 5. Get Countries
  static Future<Map<String, dynamic>> getCountries() async {
    try {
      final url = Uri.parse('$baseUrl/countries');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 6. Refresh Token
  static Future<Map<String, dynamic>> refreshToken(String currentToken) async {
    try {
      final url = Uri.parse('$baseUrl/refresh-token');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, currentToken);

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Token refresh failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 7. My Profile
  static Future<Map<String, dynamic>> getMyProfile(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 8. Send Email Verification
  static Future<Map<String, dynamic>> sendEmailVerification(
      String token) async {
    try {
      final url = Uri.parse('$baseUrl/email/verification-notification');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 9. Logout
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final url = Uri.parse('$baseUrl/logout');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'data': 'Logged out successfully'};
      } else {
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 10. Get Charges
  static Future<Map<String, dynamic>> getCharges({
    required String token,
    required double amount,
    required String currency,
    required String recipientCountry,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/charges');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'amount': amount.toString(),
          'currency': currency,
          'recipient_country': recipientCountry,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 11. Get Service Charge
  static Future<Map<String, dynamic>> getServiceCharge(String token) async {
    try {
      final url = Uri.parse('$baseUrl/yole-charges');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 12. Transaction Status
  static Future<Map<String, dynamic>> getTransactionStatus({
    required String token,
    required String orderTrackingId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/transaction/status');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'order_tracking_id': orderTrackingId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 13. Send Money
  static Future<Map<String, dynamic>> sendMoney({
    required String token,
    required double sendingAmount,
    required String recipientCountry,
    required String phoneNumber,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/send-money');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'sending_amount': sendingAmount.toString(),
          'recipient_country': recipientCountry,
          'phone_number': phoneNumber,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 14. Get Transactions
  static Future<Map<String, dynamic>> getTransactions(String token) async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 15. Send SMS OTP
  static Future<Map<String, dynamic>> sendSmsOtp({
    required String token,
    required String phoneCode,
    required String phone,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/sms/send-otp');
      var headers = await _getHeaders();
      headers = _addBearerToken(headers, token);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'phone_code': phoneCode,
          'phone': phone,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 16. Validate KYC
  static Future<Map<String, dynamic>> validateKyc({
    required String token,
    required String phoneNumber,
    required String otpCode,
    required String idNumber,
    required File idPhoto,
    required File passportPhoto,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/validate-kyc');
      var headers = await _getHeaders();
      headers['Authorization'] = 'Bearer $token';
      headers.remove(
          'Content-Type'); // Let multipart request set its own content-type

      var request = http.MultipartRequest('POST', url);

      // Add headers (remove Content-Type)
      request.headers.addAll(headers);

      // Add fields
      request.fields['phone_number'] = phoneNumber;
      request.fields['otp_code'] = otpCode;
      request.fields['id_number'] = idNumber;

      // Add files
      request.files.add(await http.MultipartFile.fromPath(
        'id_photo',
        idPhoto.path,
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'passport_photo',
        passportPhoto.path,
      ));

      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(responseData)};
      } else {
        return {'success': false, 'error': responseData};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Helper method to handle responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return {'success': true, 'data': data};
      } catch (e) {
        return {'success': true, 'data': response.body};
      }
    } else if (response.statusCode == 401) {
      return {'success': false, 'error': 'Unauthorized - Token may be expired'};
    } else if (response.statusCode == 403) {
      return {
        'success': false,
        'error': 'Forbidden - Insufficient permissions'
      };
    } else {
      return {'success': false, 'error': response.body};
    }
  }
}
