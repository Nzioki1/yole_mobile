import 'package:shared_preferences/shared_preferences.dart';

class KYCService {
  static const String _kycCompletedKey = 'kyc_completed';
  static const String _kycStepKey = 'kyc_step';

  /// Check if user has completed KYC
  static Future<bool> isKYCCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kycCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark KYC as completed
  static Future<void> markKYCCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kycCompletedKey, true);
      await prefs.setInt(_kycStepKey, 4); // All steps completed
    } catch (e) {
      print('Error marking KYC completed: $e');
    }
  }

  /// Get current KYC step
  static Future<int> getKYCStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kycStepKey) ?? 1;
    } catch (e) {
      return 1;
    }
  }

  /// Update KYC step
  static Future<void> updateKYCStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kycStepKey, step);
    } catch (e) {
      print('Error updating KYC step: $e');
    }
  }

  /// Reset KYC progress
  static Future<void> resetKYC() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kycCompletedKey);
      await prefs.remove(_kycStepKey);
    } catch (e) {
      print('Error resetting KYC: $e');
    }
  }

  /// Check if user needs KYC (first-time Google user)
  static Future<bool> needsKYC() async {
    final isCompleted = await isKYCCompleted();
    return !isCompleted;
  }
}

