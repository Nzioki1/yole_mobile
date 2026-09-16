import 'package:http/http.dart' as http;

/// HTTP client wrapper. Previously used dart:io to bypass TLS for
/// local/dev servers; that breaks on web, so we use the standard client.
/// WARNING: Do not add certificate bypass here for production.
class UnsafeHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
