import 'dart:io';
import 'package:http/http.dart' as http;

/// Custom HTTP client that bypasses SSL certificate verification
/// WARNING: This should only be used for testing with development servers
class UnsafeHttpClient extends http.BaseClient {
  final HttpClient _inner = HttpClient();

  UnsafeHttpClient() {
    // Bypass SSL certificate verification
    _inner.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      print(
          '⚠️ WARNING: Bypassing SSL certificate verification for $host:$port');
      return true; // Accept all certificates
    };
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final request_ = await _inner.openUrl(request.method, request.url);

    // Set headers
    request.headers.forEach((key, value) {
      request_.headers.set(key, value);
    });

    // Set body if present
    if (request is http.Request && request.body.isNotEmpty) {
      request_.write(request.body);
    }

    final response = await request_.close();
    final bytes = await response.expand((chunk) => chunk).toList();

    // Convert headers to Map<String, String>
    final Map<String, String> headers = {};
    response.headers.forEach((key, values) {
      headers[key] = values.join(',');
    });

    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
