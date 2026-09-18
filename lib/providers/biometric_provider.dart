import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_auth_service.dart';
import '../services/storage_service.dart';

/// Biometric auth service provider
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(
    storageService: StorageService(),
  );
});
