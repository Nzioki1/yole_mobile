import 'package:dio/dio.dart';
import 'models.dart';

class TransferApi {
  final Dio dio;
  TransferApi(this.dio);

  Future<Response<dynamic>> quoteTransfer(QuoteRequest request) {
    return dio.post('yole-charges', data: request.toJson());
  }

  Future<Response<dynamic>> createTransfer(TransferRequest request) {
    return dio.post('send-money', data: request.toJson());
  }

  Future<Response<dynamic>> confirmTransfer(String orderTrackingId) {
    return dio.post('send-money/confirm', data: {
      'order_tracking_id': orderTrackingId,
    });
  }

  Future<Response<dynamic>> transactionStatus(TransactionStatusRequest request) {
    return dio.post('transaction/status', data: request.toJson());
  }

  Future<Response<dynamic>> listTransactions() {
    return dio.get('transactions');
  }
}