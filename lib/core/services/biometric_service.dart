import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      print('🔐 canCheckBiometrics: $canCheckBiometrics');
      print('🔐 isDeviceSupported: $isDeviceSupported');
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('🔐 Biometric availability check error: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('🔐 Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      print('🔐 Get available biometrics error: $e');
      return [];
    }
  }

  /// Get biometric type as string
  static String getBiometricTypeString(List<BiometricType> biometrics) {
    print('🔐 Processing biometric types: $biometrics');

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Strong Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Weak Biometric';
    }

    print('🔐 No specific biometric type found, returning generic');
    return 'Biometric';
  }

  /// Authenticate using biometrics
  static Future<bool> authenticate() async {
    try {
      print('🔐 Starting biometric authentication...');

      // Get available biometrics first
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('🔐 Available biometrics for authentication: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        print('🔐 No biometrics available for authentication');
        return false;
      }

      // Try different authentication options
      // First try with biometricOnly: true
      try {
        print('🔐 Attempting biometric-only authentication...');
        final result = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: false,
          ),
        );
        print('🔐 Biometric-only authentication result: $result');
        return result;
      } catch (e) {
        print('🔐 Biometric-only authentication failed: $e');

        // Try with biometricOnly: false as fallback
        try {
          print('🔐 Attempting fallback authentication...');
          final result = await _localAuth.authenticate(
            localizedReason: 'Please authenticate to enable biometric login',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: false,
            ),
          );
          print('🔐 Fallback authentication result: $result');
          return result;
        } catch (e2) {
          print('🔐 Fallback authentication also failed: $e2');
          return false;
        }
      }
    } catch (e) {
      print('🔐 Biometric authentication error: $e');
      print('🔐 Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('🔐 Device support check error: $e');
      return false;
    }
  }

  /// Get detailed biometric status for debugging
  static Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      // Additional checks
      bool hasHardware = false;
      try {
        hasHardware = await _localAuth.isDeviceSupported();
      } catch (e) {
        print('🔐 Hardware check failed: $e');
      }

      return {
        'canCheckBiometrics': canCheckBiometrics,
        'isDeviceSupported': isDeviceSupported,
        'availableBiometrics': availableBiometrics
            .map((e) => e.toString())
            .toList(),
        'hasBiometrics': availableBiometrics.isNotEmpty,
        'hasHardware': hasHardware,
        'biometricCount': availableBiometrics.length,
        'canAuthenticate': canCheckBiometrics && availableBiometrics.isNotEmpty,
      };
    } catch (e) {
      print('🔐 Status check failed: $e');
      return {
        'error': e.toString(),
        'canCheckBiometrics': false,
        'isDeviceSupported': false,
        'availableBiometrics': [],
        'hasBiometrics': false,
        'hasHardware': false,
        'biometricCount': 0,
        'canAuthenticate': false,
      };
    }
  }

  /// Comprehensive diagnostic method to check biometric setup
  static Future<Map<String, dynamic>> diagnoseBiometricSetup() async {
    try {
      print('🔐 Running comprehensive biometric diagnosis...');

      final results = <String, dynamic>{};

      // Check basic device support
      try {
        results['deviceSupported'] = await _localAuth.isDeviceSupported();
        print('🔐 Device supported: ${results['deviceSupported']}');
      } catch (e) {
        results['deviceSupported'] = false;
        results['deviceSupportError'] = e.toString();
        print('🔐 Device support check failed: $e');
      }

      // Check if we can check biometrics
      try {
        results['canCheckBiometrics'] = await _localAuth.canCheckBiometrics;
        print('🔐 Can check biometrics: ${results['canCheckBiometrics']}');
      } catch (e) {
        results['canCheckBiometrics'] = false;
        results['canCheckError'] = e.toString();
        print('🔐 Can check biometrics failed: $e');
      }

      // Get available biometrics
      try {
        final biometrics = await _localAuth.getAvailableBiometrics();
        results['availableBiometrics'] = biometrics
            .map((e) => e.toString())
            .toList();
        results['biometricCount'] = biometrics.length;
        print('🔐 Available biometrics: ${results['availableBiometrics']}');
      } catch (e) {
        results['availableBiometrics'] = [];
        results['biometricCount'] = 0;
        results['biometricsError'] = e.toString();
        print('🔐 Get biometrics failed: $e');
      }

      // Test if we can actually show a prompt (this is the key test)
      try {
        print('🔐 Testing if we can actually show a biometric prompt...');
        results['canShowPrompt'] = false;
        results['promptTestError'] = null;

        // Try to show a simple prompt
        final promptResult = await _localAuth.authenticate(
          localizedReason: 'Testing biometric prompt',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: false,
          ),
        );

        results['canShowPrompt'] = true;
        results['promptTestResult'] = promptResult;
        print('🔐 Prompt test successful: $promptResult');
      } catch (e) {
        results['canShowPrompt'] = false;
        results['promptTestError'] = e.toString();
        print('🔐 Prompt test failed: $e');
        print('🔐 Error type: ${e.runtimeType}');
      }

      // Determine the issue based on all tests
      if (!results['deviceSupported']) {
        results['issue'] = 'Device does not support biometric authentication';
      } else if (!results['canCheckBiometrics']) {
        results['issue'] = 'Cannot check biometrics - may need device setup';
      } else if (results['biometricCount'] == 0) {
        results['issue'] = 'No biometric sensors found or configured';
      } else if (!results['canShowPrompt']) {
        if (results['promptTestError']?.contains('no_fragment_acitivity') ==
            true) {
          results['issue'] =
              'Android Fragment/Activity issue - biometric prompt needs proper context. Try enabling from main screen or restart app.';
          results['solution'] =
              'This is a common Android issue. The biometric prompt needs to be called from a proper Android Activity context.';
        } else {
          results['issue'] =
              'Biometrics available but cannot show prompt - ${results['promptTestError']}';
        }
      } else {
        results['issue'] = 'Biometrics working - authentication may be failing';
      }

      return results;
    } catch (e) {
      return {'diagnosisError': e.toString(), 'issue': 'Diagnosis failed: $e'};
    }
  }

  /// Check for common Android biometric issues
  static Future<Map<String, dynamic>> checkAndroidBiometricIssues() async {
    try {
      print('🔐 Checking for Android-specific biometric issues...');

      final issues = <String, dynamic>{};

      // Check if device has biometric hardware
      try {
        final hasHardware = await _localAuth.isDeviceSupported();
        issues['hasHardware'] = hasHardware;
        print('🔐 Has biometric hardware: $hasHardware');
      } catch (e) {
        issues['hasHardware'] = false;
        issues['hardwareError'] = e.toString();
      }

      // Check if biometrics are enrolled
      try {
        final biometrics = await _localAuth.getAvailableBiometrics();
        issues['hasEnrolledBiometrics'] = biometrics.isNotEmpty;
        issues['enrolledCount'] = biometrics.length;
        print('🔐 Has enrolled biometrics: ${biometrics.isNotEmpty}');
        print('🔐 Enrolled count: ${biometrics.length}');
      } catch (e) {
        issues['hasEnrolledBiometrics'] = false;
        issues['enrollmentError'] = e.toString();
      }

      // Check if we can authenticate
      try {
        final canAuth = await _localAuth.canCheckBiometrics;
        issues['canAuthenticate'] = canAuth;
        print('🔐 Can authenticate: $canAuth');
      } catch (e) {
        issues['canAuthenticate'] = false;
        issues['authError'] = e.toString();
      }

      // Determine the most likely issue
      if (!issues['hasHardware']) {
        issues['mainIssue'] = 'Device does not have biometric hardware';
      } else if (!issues['hasEnrolledBiometrics']) {
        issues['mainIssue'] =
            'No biometrics enrolled - go to device Settings > Security > Biometrics to set up';
      } else if (!issues['canAuthenticate']) {
        issues['mainIssue'] =
            'Cannot authenticate - may need device restart or biometric re-enrollment';
      } else {
        issues['mainIssue'] =
            'Hardware and enrollment OK - authentication should work';
      }

      return issues;
    } catch (e) {
      return {
        'checkError': e.toString(),
        'mainIssue': 'Failed to check Android issues: $e',
      };
    }
  }

  /// Check if we're in a proper context for biometric authentication
  static Future<Map<String, dynamic>> checkContextForBiometrics() async {
    try {
      print('🔐 Checking context for biometric authentication...');

      final contextInfo = <String, dynamic>{};

      // Try to get basic biometric info to test context
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        contextInfo['canCheckBiometrics'] = canCheck;
        print('🔐 Can check biometrics in current context: $canCheck');
      } catch (e) {
        contextInfo['canCheckBiometrics'] = false;
        contextInfo['contextError'] = e.toString();
        print('🔐 Context check failed: $e');
      }

      // Try to get available biometrics to test context
      try {
        final biometrics = await _localAuth.getAvailableBiometrics();
        contextInfo['canGetBiometrics'] = biometrics.isNotEmpty;
        contextInfo['biometricCount'] = biometrics.length;
        print(
          '🔐 Can get biometrics in current context: ${biometrics.isNotEmpty}',
        );
      } catch (e) {
        contextInfo['canGetBiometrics'] = false;
        contextInfo['getBiometricsError'] = e.toString();
        print('🔐 Get biometrics in context failed: $e');
      }

      // Determine context status
      if (contextInfo['canCheckBiometrics'] == true &&
          contextInfo['canGetBiometrics'] == true) {
        contextInfo['contextStatus'] =
            'Good - ready for biometric authentication';
        contextInfo['canAuthenticate'] = true;
      } else {
        contextInfo['contextStatus'] =
            'Poor - biometric authentication may fail';
        contextInfo['canAuthenticate'] = false;
        contextInfo['recommendation'] =
            'Try enabling biometrics from the main dashboard screen instead of profile settings';
      }

      return contextInfo;
    } catch (e) {
      return {
        'contextCheckError': e.toString(),
        'contextStatus': 'Failed to check context: $e',
        'canAuthenticate': false,
      };
    }
  }

  /// Test biometric authentication with detailed feedback
  static Future<Map<String, dynamic>> testBiometricAuthentication() async {
    try {
      print('🔐 Testing biometric authentication...');

      final status = await getBiometricStatus();
      print('🔐 Initial status: $status');

      if (!status['hasBiometrics']) {
        return {
          'success': false,
          'error': 'No biometric sensors available',
          'details': status,
        };
      }

      // First, try to just check if we can get the prompt
      print('🔐 Testing if biometric prompt can appear...');
      try {
        final canPrompt = await _localAuth.canCheckBiometrics;
        print('🔐 Can prompt for biometrics: $canPrompt');

        if (!canPrompt) {
          return {
            'success': false,
            'error':
                'Device cannot prompt for biometrics - may need setup in device settings',
            'details': status,
            'canPrompt': false,
          };
        }
      } catch (e) {
        print('🔐 Prompt check failed: $e');
      }

      // Try a simple prompt test first (without requiring authentication)
      print('🔐 Testing biometric prompt appearance...');
      try {
        final promptTest = await _localAuth.authenticate(
          localizedReason: 'Testing biometric prompt - please cancel this',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: false,
          ),
        );
        print('🔐 Prompt test result: $promptTest');

        // If we get here, the prompt appeared (even if cancelled)
        return {
          'success': true,
          'error': null,
          'details': status,
          'promptAppeared': true,
          'promptResult': promptTest,
          'message':
              'Biometric prompt appeared successfully! You can now enable the feature.',
        };
      } catch (promptError) {
        print('🔐 Prompt test failed: $promptError');

        // Try authentication with detailed error capture
        try {
          final result = await authenticate();
          print('🔐 Authentication completed with result: $result');

          return {
            'success': result,
            'error': result
                ? null
                : 'Authentication failed - user may have cancelled or authentication was unsuccessful',
            'details': status,
            'authenticationResult': result,
          };
        } catch (authError) {
          print('🔐 Authentication threw exception: $authError');
          print('🔐 Exception type: ${authError.runtimeType}');

          return {
            'success': false,
            'error': 'Authentication exception: $authError',
            'details': status,
            'exception': authError.toString(),
            'exceptionType': authError.runtimeType.toString(),
          };
        }
      }
    } catch (e) {
      print('🔐 Test setup failed: $e');
      return {
        'success': false,
        'error': 'Test setup failed: $e',
        'details': null,
        'setupError': e.toString(),
      };
    }
  }

  /// Comprehensive debug method for biometric authentication
  static Future<Map<String, dynamic>> debugBiometricAuthentication() async {
    print('🔐 🔍 STARTING COMPREHENSIVE BIOMETRIC DEBUG...');

    final debugInfo = <String, dynamic>{};
    final steps = <String>[];

    try {
      // Step 1: Check device support
      print('🔐 🔍 Step 1: Checking device support...');
      steps.add('Step 1: Device support check');

      try {
        final deviceSupported = await _localAuth.isDeviceSupported();
        debugInfo['deviceSupported'] = deviceSupported;
        print('🔐 🔍 Device supported: $deviceSupported');

        if (!deviceSupported) {
          debugInfo['step1Error'] =
              'Device does not support biometric authentication';
          return debugInfo;
        }
      } catch (e) {
        debugInfo['step1Error'] = e.toString();
        print('🔐 🔍 Step 1 failed: $e');
        return debugInfo;
      }

      // Step 2: Check if we can check biometrics
      print('🔐 🔍 Step 2: Checking if we can check biometrics...');
      steps.add('Step 2: Can check biometrics');

      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        debugInfo['canCheckBiometrics'] = canCheck;
        print('🔐 🔍 Can check biometrics: $canCheck');

        if (!canCheck) {
          debugInfo['step2Error'] =
              'Cannot check biometrics - may need device setup';
          return debugInfo;
        }
      } catch (e) {
        debugInfo['step2Error'] = e.toString();
        print('🔐 🔍 Step 2 failed: $e');
        return debugInfo;
      }

      // Step 3: Get available biometrics
      print('🔐 🔍 Step 3: Getting available biometrics...');
      steps.add('Step 3: Get available biometrics');

      try {
        final biometrics = await _localAuth.getAvailableBiometrics();
        debugInfo['availableBiometrics'] = biometrics
            .map((e) => e.toString())
            .toList();
        debugInfo['biometricCount'] = biometrics.length;
        print(
          '🔐 🔍 Available biometrics: ${debugInfo['availableBiometrics']}',
        );
        print('🔐 🔍 Biometric count: ${debugInfo['biometricCount']}');

        if (biometrics.isEmpty) {
          debugInfo['step3Error'] =
              'No biometrics available - may need enrollment';
          return debugInfo;
        }
      } catch (e) {
        debugInfo['step3Error'] = e.toString();
        print('🔐 🔍 Step 3 failed: $e');
        return debugInfo;
      }

      // Step 4: Test prompt appearance
      print('🔐 🔍 Step 4: Testing prompt appearance...');
      steps.add('Step 4: Test prompt appearance');

      try {
        print('🔐 🔍 Attempting to show biometric prompt...');

        // Try different authentication options to see what works
        print('🔐 🔍 Trying biometricOnly: true...');
        try {
          final promptResult = await _localAuth.authenticate(
            localizedReason:
                'Debug: Testing biometric prompt - please authenticate or cancel',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: false,
            ),
          );

          debugInfo['promptAppeared'] = true;
          debugInfo['promptResult'] = promptResult;
          debugInfo['methodUsed'] = 'biometricOnly: true';
          print(
            '🔐 🔍 Prompt appeared successfully with biometricOnly: true! Result: $promptResult',
          );

          if (promptResult) {
            debugInfo['finalResult'] =
                'SUCCESS - Biometric authentication worked!';
            debugInfo['success'] = true;
          } else {
            debugInfo['finalResult'] =
                'FAILED - User cancelled or authentication unsuccessful';
            debugInfo['success'] = false;
          }
        } catch (e1) {
          print('🔐 🔍 biometricOnly: true failed: $e1');

          // Try with biometricOnly: false
          print('🔐 🔍 Trying biometricOnly: false...');
          try {
            final promptResult2 = await _localAuth.authenticate(
              localizedReason:
                  'Debug: Testing biometric prompt (fallback) - please authenticate or cancel',
              options: const AuthenticationOptions(
                biometricOnly: false,
                stickyAuth: false,
              ),
            );

            debugInfo['promptAppeared'] = true;
            debugInfo['promptResult'] = promptResult2;
            debugInfo['methodUsed'] = 'biometricOnly: false (fallback)';
            print(
              '🔐 🔍 Prompt appeared successfully with biometricOnly: false! Result: $promptResult2',
            );

            if (promptResult2) {
              debugInfo['finalResult'] =
                  'SUCCESS - Biometric authentication worked with fallback!';
              debugInfo['success'] = true;
            } else {
              debugInfo['finalResult'] =
                  'FAILED - User cancelled or authentication unsuccessful (fallback)';
              debugInfo['success'] = false;
            }
          } catch (e2) {
            print('🔐 🔍 biometricOnly: false also failed: $e2');

            // Both methods failed
            debugInfo['promptAppeared'] = false;
            debugInfo['step4Error'] = 'Both authentication methods failed';
            debugInfo['errorType'] = 'Multiple failures';
            debugInfo['error1'] = e1.toString();
            debugInfo['error2'] = e2.toString();
            debugInfo['errorType1'] = e1.runtimeType.toString();
            debugInfo['errorType2'] = e2.runtimeType.toString();

            print('🔐 🔍 Step 4 failed: Both methods failed');
            print('🔐 🔍 Error 1: $e1 (${e1.runtimeType})');
            print('🔐 🔍 Error 2: $e2 (${e2.runtimeType})');

            // Try to categorize the errors
            if (e1.toString().contains('no_fragment_activity') ||
                e2.toString().contains('no_fragment_activity')) {
              debugInfo['errorCategory'] = 'FragmentActivity issue';
            } else if (e1.toString().contains('authentication') ||
                e2.toString().contains('authentication')) {
              debugInfo['errorCategory'] = 'Authentication issue';
            } else if (e1.toString().contains('permission') ||
                e2.toString().contains('permission')) {
              debugInfo['errorCategory'] = 'Permission issue';
            } else if (e1.toString().contains('timeout') ||
                e2.toString().contains('timeout')) {
              debugInfo['errorCategory'] = 'Timeout issue';
            } else {
              debugInfo['errorCategory'] = 'Unknown issue';
            }
          }
        }
      } catch (e) {
        debugInfo['promptAppeared'] = false;
        debugInfo['step4Error'] = e.toString();
        debugInfo['errorType'] = e.runtimeType.toString();
        print('🔐 🔍 Step 4 failed with outer exception: $e');
        print('🔐 🔍 Error type: ${e.runtimeType}');

        // Try to categorize the error
        if (e.toString().contains('no_fragment_activity')) {
          debugInfo['errorCategory'] = 'FragmentActivity issue';
        } else if (e.toString().contains('authentication')) {
          debugInfo['errorCategory'] = 'Authentication issue';
        } else if (e.toString().contains('permission')) {
          debugInfo['errorCategory'] = 'Permission issue';
        } else {
          debugInfo['errorCategory'] = 'Unknown issue';
        }
      }

      debugInfo['stepsCompleted'] = steps;
      debugInfo['debugComplete'] = true;
    } catch (e) {
      debugInfo['debugError'] = e.toString();
      print('🔐 🔍 Debug process failed: $e');
    }

    print('🔐 🔍 COMPREHENSIVE DEBUG COMPLETE');
    print('🔐 🔍 Final debug info: $debugInfo');

    return debugInfo;
  }
}
