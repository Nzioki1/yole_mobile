import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yole_mobile/features/auth/data/auth_repository.dart';
import 'package:yole_mobile/features/auth/data/auth_api.dart';
import 'package:yole_mobile/features/auth/data/models.dart';
import 'package:yole_mobile/core/network/failure.dart';
import 'package:yole_mobile/features/auth/data/i_auth_token_store.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([AuthApi, IAuthTokenStore])
void main() {
  group('AuthRepository', () {
    late AuthRepository repository;
    late MockAuthApi mockApi;
    late MockIAuthTokenStore mockTokenStore;

    setUp(() {
      mockApi = MockAuthApi();
      mockTokenStore = MockIAuthTokenStore();
      repository = AuthRepository(mockApi, tokenStore: mockTokenStore);
    });

    group('login', () {
      test('should return user and save token on successful login', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        final response = Response(
          data: {
            'id': '123',
            'email': email,
            'access_token': 'test_token',
            'expires_in': '3600',
            'kyc_submitted': 1,
            'kyc_validated': 1,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.login(any)).thenAnswer((_) async => response);
        when(mockTokenStore.saveToken(any, expiration: anyNamed('expiration')))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.login(email, password);

        // Assert
        expect(result.email, equals(email));
        expect(result.id, equals('123'));
        expect(result.kycStatus, equals(KycStatus.kycVerified));
        
        verify(mockApi.login(any)).called(1);
        verify(mockTokenStore.saveToken('test_token', expiration: '3600')).called(1);
      });

      test('should throw NetworkFailure on 401 response', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrong_password';
        
        final response = Response(
          data: {'message': 'Invalid credentials'},
          statusCode: 401,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.login(any)).thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.login(email, password),
          throwsA(isA<NetworkFailure>()),
        );
        
        verify(mockApi.login(any)).called(1);
        verifyNever(mockTokenStore.saveToken(any, expiration: anyNamed('expiration')));
      });

      test('should throw NetworkFailure on non-200 response', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        final response = Response(
          data: {'message': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.login(any)).thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.login(email, password),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('should throw NetworkFailure on DioException', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        final dioException = DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        );

        when(mockApi.login(any)).thenThrow(dioException);

        // Act & Assert
        expect(
          () => repository.login(email, password),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('register', () {
      test('should return user and save token on successful registration', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const name = 'Test User';
        const phoneNumber = '+1234567890';
        
        final response = Response(
          data: {
            'id': '123',
            'email': email,
            'access_token': 'test_token',
            'expires_in': '3600',
            'kyc_submitted': 0,
            'kyc_validated': 0,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.register(any)).thenAnswer((_) async => response);
        when(mockTokenStore.saveToken(any, expiration: anyNamed('expiration')))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.register(email, password, name, phoneNumber);

        // Assert
        expect(result.email, equals(email));
        expect(result.id, equals('123'));
        expect(result.kycStatus, equals(KycStatus.kycPending));
        
        verify(mockApi.register(any)).called(1);
        verify(mockTokenStore.saveToken('test_token', expiration: '3600')).called(1);
      });

      test('should throw NetworkFailure on registration failure', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const name = 'Test User';
        const phoneNumber = '+1234567890';
        
        final response = Response(
          data: {'message': 'Email already exists'},
          statusCode: 422,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApi.register(any)).thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => repository.register(email, password, name, phoneNumber),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });

    group('logout', () {
      test('should clear token', () async {
        // Arrange
        when(mockTokenStore.clearToken()).thenAnswer((_) async {});

        // Act
        await repository.logout();

        // Assert
        verify(mockTokenStore.clearToken()).called(1);
      });
    });

    group('isAuthenticated', () {
      test('should return true when token exists', () async {
        // Arrange
        when(mockTokenStore.hasToken()).thenAnswer((_) async => true);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, isTrue);
        verify(mockTokenStore.hasToken()).called(1);
      });

      test('should return false when no token exists', () async {
        // Arrange
        when(mockTokenStore.hasToken()).thenAnswer((_) async => false);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, isFalse);
        verify(mockTokenStore.hasToken()).called(1);
      });
    });
  });
}
