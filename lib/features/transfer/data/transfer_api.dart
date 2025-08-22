import 'package:dio/dio.dart';

class TransferApi {
  final Dio dio;
  TransferApi(this.dio);

  Future<Response<dynamic>> send(String recipientId, num amount) {
    return dio.post('/transfer', data: {'recipientId': recipientId, 'amount': amount});
  }
}