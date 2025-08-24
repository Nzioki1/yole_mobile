import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yole_mobile/features/recipients/data/recipients_repository.dart';
import 'package:yole_mobile/features/recipients/data/recipients_api.dart';
import 'package:yole_mobile/features/recipients/data/models.dart';
import 'package:yole_mobile/core/network/failure.dart';

import 'recipients_repository_test.mocks.dart';

@GenerateMocks([RecipientsApi])
void main() {
  group('RecipientsRepository', () {
    late RecipientsRepository repository;
    late MockRecipientsApi mockApi;

    setUp(() {
      mockApi = MockRecipientsApi();
      repository = RecipientsRepository(mockApi);
    });

    group('fetchRecipients', () {
      test('should return recipients response on successful fetch', () async {
        // Arrange
        final response = Response(
          data: {
            'data': [
              {
                'id': '1',
                'name': 'John Doe',
                'phone_number': '+1234567890',
                'country_code': 'US',
                'account': 'US123456789',
                'created_at': '2024-01-01T00:00:00Z',
              },
              {
                'id': '2',
                'name': 'Jane Smith',
                'phone_number': '+0987654321',
                'country_code': 'UK',
                'account': 'UK987654321',
                'created_at': '2024-01-02T00:00:00Z',
              },
            ],
            'current_page': 1,
            'last_page': 2,
            'total': 10,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.fetchRecipients(page: 1, query: null))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.fetchRecipients();

        // Assert
        expect(result.data.length, equals(2));
        expect(result.currentPage, equals(1));
        expect(result.totalPages, equals(2));
        expect(result.totalItems, equals(10));
        expect(result.data[0].name, equals('John Doe'));
        expect(result.data[0].phoneNumber, equals('+1234567890'));
        expect(result.data[1].name, equals('Jane Smith'));
        
        verify(mockApi.fetchRecipients(page: 1, query: null)).called(1);
      });

      test('should return recipients with search query', () async {
        // Arrange
        final response = Response(
          data: {
            'data': [
              {
                'id': '1',
                'name': 'John Doe',
                'phone_number': '+1234567890',
                'country_code': 'US',
              },
            ],
            'current_page': 1,
            'last_page': 1,
            'total': 1,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.fetchRecipients(page: 1, query: 'John'))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.fetchRecipients(query: 'John');

        // Assert
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('John Doe'));
        
        verify(mockApi.fetchRecipients(page: 1, query: 'John')).called(1);
      });

      test('should throw NetworkFailure on non-200 response', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.fetchRecipients(page: 1, query: null))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.fetchRecipients(),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('should throw NetworkFailure on DioException', () async {
        // Arrange
        final dioException = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        );

        when(mockApi.fetchRecipients(page: 1, query: null))
            .thenThrow(dioException);

        // Act & Assert
        expect(
          () => repository.fetchRecipients(),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('addRecipient', () {
      test('should return recipient on successful creation', () async {
        // Arrange
        final response = Response(
          data: {
            'id': '3',
            'name': 'New Recipient',
            'phone_number': '+1111111111',
            'country_code': 'CA',
            'account': 'CA111111111',
            'created_at': '2024-01-03T00:00:00Z',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.addRecipient(any))
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.addRecipient(
          'New Recipient',
          '+1111111111',
          'CA',
        );

        // Assert
        expect(result.id, equals('3'));
        expect(result.name, equals('New Recipient'));
        expect(result.phoneNumber, equals('+1111111111'));
        expect(result.countryCode, equals('CA'));
        
        verify(mockApi.addRecipient(any)).called(1);
      });

      test('should throw NetworkFailure on creation failure', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Phone number already exists'},
          statusCode: 422,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.addRecipient(any))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.addRecipient('Test', '+1111111111', 'US'),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });

    group('fetchCountries', () {
      test('should return countries list on successful fetch', () async {
        // Arrange
        final response = Response(
          data: {
            'data': [
              {
                'name': 'United States',
                'dialCode': '+1',
                'isoCode': 'US',
              },
              {
                'name': 'United Kingdom',
                'dialCode': '+44',
                'isoCode': 'UK',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.fetchCountries())
            .thenAnswer((_) async => response);

        // Act
        final result = await repository.fetchCountries();

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('United States'));
        expect(result[0].dialCode, equals('+1'));
        expect(result[0].isoCode, equals('US'));
        expect(result[1].name, equals('United Kingdom'));
        
        verify(mockApi.fetchCountries()).called(1);
      });

      test('should throw NetworkFailure on unexpected response format', () async {
        // Arrange
        final response = Response(
          data: {'countries': []}, // Wrong format
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.fetchCountries())
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.fetchCountries(),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('should throw NetworkFailure on non-200 response', () async {
        // Arrange
        final response = Response(
          data: {'message': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.fetchCountries())
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.fetchCountries(),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });
  });
}
