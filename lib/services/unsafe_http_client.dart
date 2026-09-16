import 'package:http/http.dart' as http;

/// Web-safe HTTP client (no dart:io) for Chrome demo.
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
