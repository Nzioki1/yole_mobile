import 'package:dio/dio.dart';
import 'models.dart';

class TransferApi {
  final Dio dio;
  TransferApi(this.dio);

  // Mock Payment Simulation - Card Selection
  Future<Response<dynamic>> createPesapalTestPayment(
    PesapalOrderRequest request,
  ) {
    print('🔍 TransferApi: Creating mock payment simulation');
    print('🔍 TransferApi: Request data: ${request.toJson()}');

    // Simulate a successful mock payment response
    // This will trigger the card selection flow
    return Future.value(
      Response(
        data: {
          'success': true,
          'requires_card_selection': true,
          'available_cards': [
            {
              'id': 'card_1',
              'type': 'Visa',
              'last4': '1234',
              'balance': 5000.0,
              'currency': 'USD',
              'name': 'Primary Card',
            },
            {
              'id': 'card_2',
              'type': 'Mastercard',
              'last4': '5678',
              'balance': 2500.0,
              'currency': 'USD',
              'name': 'Secondary Card',
            },
            {
              'id': 'card_3',
              'type': 'Visa',
              'last4': '9012',
              'balance': 10000.0,
              'currency': 'USD',
              'name': 'Business Card',
            },
          ],
          'message': 'Please select a card to complete the transaction',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
  }

  // Original API methods (kept for compatibility)
  Future<Response<dynamic>> quoteTransfer(QuoteRequest request) {
    return dio.post('yole-charges', data: request.toJson());
  }

  Future<Response<dynamic>> createTransfer(TransferRequest request) {
    // Convert to FormData to match Postman collection requirements
    final formData = FormData.fromMap(request.toJson());

    // Debug logging
    print('🔍 TransferApi: createTransfer called');
    print('🔍 TransferApi: Request data: ${request.toJson()}');
    print('🔍 TransferApi: FormData fields: ${formData.fields}');
    print('🔍 TransferApi: FormData files: ${formData.files}');

    return dio.post('send-money', data: formData);
  }

  Future<Response<dynamic>> confirmTransfer(String orderTrackingId) {
    return dio.post(
      'send-money/confirm',
      data: {'order_tracking_id': orderTrackingId},
    );
  }

  Future<Response<dynamic>> transactionStatus(
    TransactionStatusRequest request,
  ) {
    // Convert to FormData to match Postman collection requirements
    final formData = FormData.fromMap(request.toJson());
    return dio.post('transaction/status', data: formData);
  }

  Future<Response<dynamic>> listTransactions() {
    return dio.get('transactions');
  }

  // Get charges (matches "Get Charges" endpoint)
  Future<Response<dynamic>> getCharges(QuoteRequest request) {
    // Convert to FormData to match Postman collection requirements
    final formData = FormData.fromMap(request.toJson());
    return dio.post('charges', data: formData);
  }

  // Get API status (matches "Get Status" endpoint)
  Future<Response<dynamic>> getStatus() {
    return dio.get('status');
  }

  // Enhanced Pesapal integration
  Future<Response<dynamic>> createPesapalOrder(PesapalOrderRequest request) {
    return dio.post('pesapal/order', data: request.toJson());
  }

  Future<Response<dynamic>> getPesapalOrderStatus(String orderTrackingId) {
    return dio.get('pesapal/order/$orderTrackingId/status');
  }

  Future<Response<dynamic>> registerPesapalWebhook(WebhookRequest request) {
    return dio.post('pesapal/webhook', data: request.toJson());
  }

  Future<Response<dynamic>> getPesapalPaymentMethods() {
    return dio.get('pesapal/payment-methods');
  }

  Future<Response<dynamic>> validatePhoneNumber(
    String phoneNumber,
    String countryCode,
  ) {
    return dio.post(
      'validate/phone',
      data: {'phone_number': phoneNumber, 'country_code': countryCode},
    );
  }
}
