import 'dart:convert';
import 'package:http/http.dart' as http;
import 'unsafe_http_client.dart';
import 'storage_service.dart';
import 'yole_api_service.dart';

/// HTTP client wrapper with automatic token management and refresh
class AuthenticatedHttpClient {
  static const String baseUrl = 'https://yolepesa.masterpiecefusion.com/api';
  static const String apiKey =
      '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';
  static const String acceptHeader = 'application/x.yole.v1+json';

  final http.Client _client;
  final StorageService _storage;
  final YoleApiService _apiService;

  // Protected endpoints that require authentication
  static const Set<String> _protectedEndpoints = {
    '/me',
    '/logout',
    '/email/verification-notification',
    '/send-money',
    '/transactions',
    '/charges',
    '/yole-charges',
    '/transaction/status',
    '/validate-kyc',
    '/sms/send-otp',
    '/refresh-token',
  };

  AuthenticatedHttpClient({
    http.Client? client,
    required StorageService storage,
    required YoleApiService apiService,
  })  : _client = client ?? UnsafeHttpClient(),
        _storage = storage,
        _apiService = apiService;

  /// Check if endpoint requires authentication
  bool _isProtectedEndpoint(String endpoint) {
    return _protectedEndpoints
        .any((protected) => endpoint.startsWith(protected));
  }

  /// Get current access token
  Future<String?> _getAccessToken() async {
    return await _storage.getAccessToken();
  }

  /// Refresh access token using refresh token
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw YoleApiException('No refresh token available');
      }

      final response = await _makeRequest(
        'POST',
        '/refresh-token',
        additionalHeaders: {
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int? ?? 3600;

        // Save new token with expiry
        await _storage.saveAccessToken(newAccessToken, expiresIn);
        _apiService.setAuthToken(newAccessToken);

        return newAccessToken;
      } else {
        throw YoleApiException('Token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      // If refresh fails, clear all tokens
      await _storage.clearTokens();
      _apiService.clearAuthToken();
      throw YoleApiException('Token refresh failed: $e');
    }
  }

  /// Make HTTP request with automatic token management
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    bool retryOnAuthFailure = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final isProtected = _isProtectedEndpoint(endpoint);

    // Prepare headers
    final headers = <String, String>{
      'Accept': acceptHeader,
      'X-API-Key': apiKey,
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    // Add authorization header for protected endpoints
    if (isProtected) {
      final accessToken = await _getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    // Make request
    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    // Handle 401 Unauthorized - try to refresh token
    if (response.statusCode == 401 && isProtected && retryOnAuthFailure) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          // Retry the request with new token
          headers['Authorization'] = 'Bearer $newToken';

          switch (method.toUpperCase()) {
            case 'GET':
              response = await _client.get(uri, headers: headers);
              break;
            case 'POST':
              response = await _client.post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PUT':
              response = await _client.put(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'DELETE':
              response = await _client.delete(uri, headers: headers);
              break;
          }
        }
      } catch (e) {
        // Refresh failed, return original 401 response
        throw YoleApiException(
            'Authentication failed: Token refresh unsuccessful', 401);
      }
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
  }

  /// GET request
  Future<http.Response> get(String endpoint) async {
    return _makeRequest('GET', endpoint);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _makeRequest('POST', endpoint, body: body);
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _makeRequest('PUT', endpoint, body: body);
  }

  /// DELETE request
  Future<http.Response> delete(String endpoint) async {
    return _makeRequest('DELETE', endpoint);
  }

  /// POST request with form data (for file uploads, etc.)
  Future<http.Response> postFormData(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, String>? files,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final isProtected = _isProtectedEndpoint(endpoint);

    // Prepare headers
    final headers = <String, String>{
      'Accept': acceptHeader,
      'X-API-Key': apiKey,
    };

    // Add authorization header for protected endpoints
    if (isProtected) {
      final accessToken = await _getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
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
        request.files
            .add(await http.MultipartFile.fromPath(entry.key, entry.value));
      }
    }

    // Send request
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    // Handle 401 Unauthorized - try to refresh token
    if (response.statusCode == 401 && isProtected) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          // Retry the request with new token
          headers['Authorization'] = 'Bearer $newToken';

          final retryRequest = http.MultipartRequest('POST', uri);
          retryRequest.headers.addAll(headers);
          if (fields != null) retryRequest.fields.addAll(fields);
          if (files != null) {
            for (final entry in files.entries) {
              retryRequest.files.add(
                  await http.MultipartFile.fromPath(entry.key, entry.value));
            }
          }

          final retryStreamedResponse = await _client.send(retryRequest);
          return await http.Response.fromStream(retryStreamedResponse);
        }
      } catch (e) {
        throw YoleApiException(
            'Authentication failed: Token refresh unsuccessful', 401);
      }
    }

    return response;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getAccessToken();
    if (token == null) return false;

    // Check if token is expired
    return !(await _storage.isTokenExpired());
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
