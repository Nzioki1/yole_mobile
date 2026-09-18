import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:yole_mobile/services/biometric_auth_service.dart';
import 'package:yole_mobile/services/storage_service.dart';
import 'package:yole_mobile/models/biometric_unlock_payload.dart';

// Test double for StorageService
class TestStorageService extends StorageService {
  final Map<String, String> _data = {};

  @override
  Future<bool> getBiometricEnabled() async {
    return _data['biometric_enabled'] == 'true';
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    _data['biometric_enabled'] = enabled.toString();
  }

  @override
  Future<String?> getBiometricUnlockPayload() async {
    return _data['biometric_unlock_payload'];
  }

  @override
  Future<void> saveBiometricUnlockPayload(String jsonPayload) async {
    _data['biometric_unlock_payload'] = jsonPayload;
  }

  @override
  Future<void> clearBiometricData() async {
    _data.remove('biometric_enabled');
    _data.remove('biometric_unlock_payload');
  }
}

void main() {
  group('BiometricAuthService', () {
    late TestStorageService testStorage;
    late BiometricAuthService service;

    setUp(() {
      testStorage = TestStorageService();
      service = BiometricAuthService(
        storageService: testStorage,
        // LocalAuthentication cannot be easily mocked in unit tests
        // These tests focus on storage logic only
      );
    });

    test('isEnabled returns false by default', () async {
      expect(await service.isEnabled(), isFalse);
    });

    test('setEnabled persists enabled state', () async {
      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);

      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);
    });

    test('saveUnlockPayload and getUnlockPayload round-trip', () async {
      final payload = BiometricUnlockPayload(
        email: 'test@example.com',
        password: 'password123',
        transactionPin: '123456',
      );

      await service.saveUnlockPayload(payload);
      final retrieved = await service.getUnlockPayload();

      expect(retrieved, isNotNull);
      expect(retrieved!.email, payload.email);
      expect(retrieved.password, payload.password);
      expect(retrieved.transactionPin, payload.transactionPin);
    });

    test('clearUnlock removes enabled flag and payload', () async {
      await service.setEnabled(true);
      await service.saveUnlockPayload(
        BiometricUnlockPayload(
          email: 'test@example.com',
          password: 'pass',
          transactionPin: '123456',
        ),
      );

      await service.clearUnlock();

      expect(await service.isEnabled(), isFalse);
      expect(await service.getUnlockPayload(), isNull);
    });

    test('getUnlockPayload returns null when no payload stored', () async {
      expect(await service.getUnlockPayload(), isNull);
    });
  });

  group('BiometricUnlockPayload', () {
    test('fromJson and toJson round-trip', () {
      final original = BiometricUnlockPayload(
        email: 'user@example.com',
        password: 'secret',
        transactionPin: '654321',
      );

      final json = original.toJson();
      final decoded = BiometricUnlockPayload.fromJson(json);

      expect(decoded.email, original.email);
      expect(decoded.password, original.password);
      expect(decoded.transactionPin, original.transactionPin);
    });

    test('fromJsonString handles invalid JSON gracefully', () {
      expect(BiometricUnlockPayload.fromJsonString(null), isNull);
      expect(BiometricUnlockPayload.fromJsonString(''), isNull);
      expect(BiometricUnlockPayload.fromJsonString('invalid'), isNull);
    });
  });
}
