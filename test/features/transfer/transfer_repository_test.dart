import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yole_mobile/features/transfer/data/transfer_repository.dart';
import 'package:yole_mobile/features/transfer/data/transfer_api.dart';
import 'package:yole_mobile/features/transfer/data/models.dart';
import 'package:yole_mobile/core/network/failure.dart';

import 'transfer_repository_test.mocks.dart';

@GenerateMocks([TransferApi])
void main() {
  group('TransferRepository', () {
    late TransferRepository repository;
    late MockTransferApi mockApi;

    setUp(() {
      mockApi = MockTransferApi();
      repository = TransferRepository(mockApi);
    });

    group('quoteTransfer', () {
      test('should return quote on successful request', () async {
        // Arrange
        final response = Response(
          data: {
            'charges': 0.05,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.quoteTransfer(any))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.quoteTransfer('100', 'USD', 'CD');

        // Assert
        expect(result.amount, equals(100.0));
        expect(result.currency, equals('USD'));
        expect(result.charges, equals(0.05));
        expect(result.totalCost, equals(105.0));
        expect(result.recipientCountry, equals('CD'));
        
        verify(mockApi.quoteTransfer(any)).called(1);
      });

      test('should throw NetworkFailure on non-200 response', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.quoteTransfer(any))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.quoteTransfer('100', 'USD', 'CD'),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('createTransfer', () {
      test('should return transfer redirect on successful creation', () async {
        // Arrange
        final response = Response(
          data: {
            'order_tracking_id': 'TRX-123456789',
            'redirect_url': 'https://payment.gateway.com/pay',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.createTransfer(any))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.createTransfer('100', 'CD', '+1234567890');

        // Assert
        expect(result.orderTrackingId, equals('TRX-123456789'));
        expect(result.redirectUrl, equals('https://payment.gateway.com/pay'));
        
        verify(mockApi.createTransfer(any)).called(1);
      });

      test('should throw NetworkFailure on creation failure', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Insufficient funds'},
          statusCode: 400,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.createTransfer(any))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.createTransfer('100', 'CD', '+1234567890'),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('should throw NetworkFailure on DioException', () async {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        );

        when(mockApi.createTransfer(any))
            .thenThrow(dioException);

        // Act & Assert
        expect(
          () => repository.createTransfer('100', 'CD', '+1234567890'),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('confirmTransfer', () {
      test('should return transfer on successful confirmation', () async {
        // Arrange
        final response = Response(
          data: {
            'id': '1',
            'order_tracking_id': 'TRX-123456789',
            'amount': 100.0,
            'currency': 'USD',
            'status': 'confirmed',
            'created_at': '2024-01-01T00:00:00Z',
            'recipient_phone': '+1234567890',
            'recipient_country': 'CD',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.confirmTransfer(any))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.confirmTransfer('TRX-123456789');

        // Assert
        expect(result.id, equals('1'));
        expect(result.orderTrackingId, equals('TRX-123456789'));
        expect(result.amount, equals(100.0));
        expect(result.status, equals('confirmed'));
        
        verify(mockApi.confirmTransfer('TRX-123456789')).called(1);
      });

      test('should throw NetworkFailure on confirmation failure', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Transfer not found'},
          statusCode: 404,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.confirmTransfer(any))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.confirmTransfer('TRX-123456789'),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('transactionStatus', () {
      test('should return status on successful request', () async {
        // Arrange
        final response = Response(
          data: {
            'transaction_status': 'completed',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.transactionStatus(any))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.transactionStatus('TRX-123456789');

        // Assert
        expect(result, equals('completed'));
        
        verify(mockApi.transactionStatus(any)).called(1);
      });

      test('should return empty string on missing status', () async {
        // Arrange
        final response = Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.transactionStatus(any))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.transactionStatus('TRX-123456789');

        // Assert
        expect(result, equals(''));
      });
    });

    group('listTransactions', () {
      test('should return transactions list on successful request', () async {
        // Arrange
        final response = Response(
          data: {
            'data': {
              'sent': [
                {
                  'recipient': '+1234567890',
                  'currency': 'USD',
                  'amount': 100.0,
                  'status': 'completed',
                  'date': '2024-01-01T00:00:00Z',
                  'sender': {
                    'name': 'John Doe',
                    'phone_number': '+0987654321',
                  },
                },
              ],
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.listTransactions())
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.listTransactions();

        // Assert
        expect(result.length, equals(1));
        expect(result[0].recipient, equals('+1234567890'));
        expect(result[0].amount, equals(100.0));
        expect(result[0].status, equals('completed'));
        expect(result[0].sender?.name, equals('John Doe'));
        
        verify(mockApi.listTransactions()).called(1);
      });

      test('should return empty list on no transactions', () async {
        // Arrange
        final response = Response(
          data: {
            'data': {
              'sent': [],
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.listTransactions())
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.listTransactions();

        // Assert
        expect(result, isEmpty);
      });

      test('should throw NetworkFailure on non-200 response', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.listTransactions())
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.listTransactions(),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });
  });
}
