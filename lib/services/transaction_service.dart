import 'dart:convert';
import 'yole_api_service.dart';
import '../models/api/charges_response.dart';
import '../models/api/send_money_response.dart';
import '../models/api/transaction_status_response.dart';
import '../models/api/transaction.dart';
import '../models/api/error_response.dart';

/// Transaction service for YOLE backend
class TransactionService {
  final YoleApiService _api;

  TransactionService({required YoleApiService api}) : _api = api;

  /// Get transaction fees
  Future<ChargesResponse> getCharges({
    required double amount,
    required String currency,
    required String recipientCountry,
  }) async {
    try {
      final response = await _api.post('/charges',
          body: {
            'amount': amount.toString(),
            'currency': currency,
            'recipient_country': recipientCountry,
          },
          requiresAuth: true);

      if (response.statusCode == 200) {
        return ChargesResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get charges: $e');
    }
  }

  /// Get YOLE service charges (alternative endpoint)
  Future<ChargesResponse> getYoleCharges({
    required double amount,
    required String currency,
    required String recipientCountry,
  }) async {
    try {
      final response = await _api.post('/yole-charges',
          body: {
            'amount': amount.toString(),
            'currency': currency,
            'recipient_country': recipientCountry,
          },
          requiresAuth: true);

      if (response.statusCode == 200) {
        return ChargesResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get YOLE charges: $e');
    }
  }

  /// Send money
  Future<SendMoneyResponse> sendMoney({
    required double sendingAmount,
    required String recipientCountry,
    required String phoneNumber,
  }) async {
    try {
      final response = await _api.post('/send-money',
          body: {
            'sending_amount': sendingAmount.toString(),
            'recipient_country': recipientCountry,
            'phone_number': phoneNumber,
          },
          requiresAuth: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SendMoneyResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to send money: $e');
    }
  }

  /// Check transaction status
  Future<TransactionStatusResponse> checkStatus(String orderTrackingId) async {
    try {
      final response = await _api.post('/transaction/status',
          body: {
            'order_tracking_id': orderTrackingId,
          },
          requiresAuth: true);

      if (response.statusCode == 200) {
        return TransactionStatusResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to check transaction status: $e');
    }
  }

  /// Get transaction history
  Future<List<Transaction>> getTransactions({
    int? page,
    int? limit,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final uri = Uri.parse('${YoleApiService.baseUrl}/transactions').replace(
        queryParameters: queryParams,
      );

      final response = await _api.get(
          '/transactions${uri.query.isNotEmpty ? '?${uri.query}' : ''}',
          requiresAuth: true);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle different response formats
        List<dynamic> transactions;
        if (responseData is List) {
          // Direct list response
          transactions = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Map with 'data' key
          final data = responseData['data'];
          transactions = data is List ? data : [];
        } else {
          // Unexpected format
          print('Unexpected transactions response format: $responseData');
          transactions = [];
        }

        return transactions.map((json) => Transaction.fromJson(json)).toList();
      } else {
        try {
          final error = ErrorResponse.fromJson(jsonDecode(response.body));
          throw YoleApiException(error.formattedMessage, response.statusCode);
        } catch (e) {
          // If error parsing fails, provide helpful message
          final statusMessage = response.statusCode == 500
              ? 'Server error. Please try again later.'
              : 'Failed to load transactions (Status: ${response.statusCode})';
          throw YoleApiException(statusMessage, response.statusCode);
        }
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get transactions: $e');
    }
  }

  /// Get single transaction by ID
  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response =
          await _api.get('/transactions/$transactionId', requiresAuth: true);

      if (response.statusCode == 200) {
        return Transaction.fromJson(jsonDecode(response.body));
      } else {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to get transaction: $e');
    }
  }

  /// Cancel transaction
  Future<void> cancelTransaction(String transactionId) async {
    try {
      final response = await _api.post('/transactions/$transactionId/cancel',
          requiresAuth: true);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = ErrorResponse.fromJson(jsonDecode(response.body));
        throw YoleApiException(error.formattedMessage, response.statusCode);
      }
    } catch (e) {
      if (e is YoleApiException) rethrow;
      throw YoleApiException('Failed to cancel transaction: $e');
    }
  }
}
