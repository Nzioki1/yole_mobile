import 'package:dio/dio.dart';

class RecipientsApi {
  final Dio dio;
  RecipientsApi(this.dio);

  Future<Response<dynamic>> list() => dio.get('/recipients');
}