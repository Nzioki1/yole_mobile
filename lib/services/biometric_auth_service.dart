import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';
import '../models/biometric_unlock_payload.dart';

/// Biometric authentication service wrapping local_auth + secure storage
class BiometricAuthService {
  final LocalAuthentication _localAuth;
  final StorageService _storageService;

  BiometricAuthService({
    LocalAuthentication? localAuth,
    StorageService? storageService,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storageService = storageService ?? StorageService();

  /// Check if device can check biometrics (hardware + enrollment)
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user with biometric prompt.
  /// Returns false if the user cancels or biometrics are unavailable.
  /// Throws nothing — callers treat false as failure/cancel.
  Future<bool> authenticate({required String reason}) async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        return false;
      }
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      // Common when MainActivity is not FlutterFragmentActivity, or no enrolled biometrics.
      // ignore: avoid_print
      print('BiometricAuthService.authenticate error: $e');
      return false;
    }
  }

  /// Check if biometric unlock is enabled
  Future<bool> isEnabled() async {
    return await _storageService.getBiometricEnabled();
  }

  /// Set biometric enabled flag
  Future<void> setEnabled(bool value) async {
    await _storageService.setBiometricEnabled(value);
  }

  /// Get unlock payload from secure storage
  Future<BiometricUnlockPayload?> getUnlockPayload() async {
    final jsonString = await _storageService.getBiometricUnlockPayload();
    return BiometricUnlockPayload.fromJsonString(jsonString);
  }

  /// Save unlock payload to secure storage
  Future<void> saveUnlockPayload(BiometricUnlockPayload payload) async {
    await _storageService.saveBiometricUnlockPayload(payload.toJsonString());
  }

  /// Clear all biometric unlock data (on logout or disable)
  Future<void> clearUnlock() async {
    await _storageService.clearBiometricData();
  }
}
