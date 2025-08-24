import 'package:dio/dio.dart';
import 'models.dart';

class RecipientsApi {
  final Dio dio;
  RecipientsApi(this.dio);

  Future<Response<dynamic>> fetchRecipients({
    int page = 1,
    String? query,
  }) {
    final queryParams = <String, dynamic>{
      'page': page,
    };
    
    if (query != null && query.isNotEmpty) {
      queryParams['search'] = query;
    }
    
    return dio.get('recipients', queryParameters: queryParams);
  }

  Future<Response<dynamic>> addRecipient(AddRecipientRequest request) {
    return dio.post('recipients', data: request.toJson());
  }

  Future<Response<dynamic>> fetchCountries() {
    return dio.get('countries');
  }
}