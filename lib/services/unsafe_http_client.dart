import 'package:http/http.dart' as http;

class UnsafeHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _inner.send(request);
  @override
  void close() => _inner.close();
}
