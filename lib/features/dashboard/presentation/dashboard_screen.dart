import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/data/auth_token_store.dart';
import '../../auth/presentation/auth_providers.dart';
import 'balance_screen.dart';
import '../../transfer/presentation/transfer_step1_screen.dart';
import '../../transfer/presentation/transaction_history_screen.dart';
import '../../transfer/presentation/payment_methods_screen.dart';
import '../../auth/presentation/profile_settings_screen.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/kyc_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yole Mobile Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                print('🔍 Dashboard: Logout button pressed');

                // Get the auth notifier
                final authNotifier = ref.read(authProvider.notifier);

                // Call the proper logout method
                await authNotifier.logout();

                print('🔍 Dashboard: Logout completed, navigating to login');

                // Navigate to login using GoRouter
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                print('🔍 Dashboard: Logout error: $e');

                // Fallback: clear token manually and navigate
                try {
                  await AuthTokenStore.clearToken();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (fallbackError) {
                  print(
                    '🔍 Dashboard: Fallback logout also failed: $fallbackError',
                  );

                  // Last resort: show error and try to navigate
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );

                    // Force navigation
                    context.go('/login');
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Yole Mobile!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your mobile money solution',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Build: ${DateTime.now().millisecondsSinceEpoch}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Send Money',
                    Icons.send,
                    Colors.blue,
                    () async {
                      // Check KYC status before allowing money transfer
                      final kycCompleted = await KYCService.isKYCCompleted();
                      if (!kycCompleted) {
                        if (context.mounted) {
                          _showKYCRequiredDialog(context);
                        }
                        return;
                      }

                      // KYC completed, allow money transfer
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TransferStep1Screen(),
                          ),
                        );
                      }
                    },
                  ),

                  _buildFeatureCard(
                    context,
                    'Transaction History',
                    Icons.history,
                    Colors.purple,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const TransactionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Payment Methods',
                    Icons.payment,
                    Colors.indigo,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Profile Settings',
                    Icons.settings,
                    Colors.teal,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKYCRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.orange),
            SizedBox(width: 8),
            Text('KYC Verification Required'),
          ],
        ),
        content: const Text(
          'You need to complete KYC verification before you can send money. '
          'This is required for security and compliance purposes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to KYC verification
              context.go('/kyc-verification');
            },
            child: const Text('Complete KYC'),
          ),
        ],
      ),
    );
  }

  /// Enable biometrics from dashboard context (which should work better)
  Future<void> _enableBiometricsFromDashboard(BuildContext context) async {
    try {
      // Run comprehensive debug instead of simple diagnosis
      print('🔐 🔍 Starting comprehensive biometric debug from dashboard...');
      final debugResult = await BiometricService.debugBiometricAuthentication();
      print('🔐 🔍 Dashboard debug result: $debugResult');

      // Check if debug completed successfully
      if (debugResult['debugComplete'] != true) {
        if (context.mounted) {
          _showBiometricErrorDialog(
            context,
            'Biometric debug failed - check console for details',
            debugResult,
          );
        }
        return;
      }

      // Check if we got a successful authentication
      if (debugResult['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication enabled successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check if prompt appeared but authentication failed
      if (debugResult['promptAppeared'] == true &&
          debugResult['success'] == false) {
        if (context.mounted) {
          _showBiometricFailureDialog(context, debugResult, debugResult);
        }
        return;
      }

      // Check if prompt failed to appear
      if (debugResult['promptAppeared'] == false) {
        if (context.mounted) {
          _showDetailedDebugDialog(context, debugResult);
        }
        return;
      }

      // Fallback - show debug results
      if (context.mounted) {
        _showBiometricErrorDialog(
          context,
          'Biometric setup completed with unexpected result',
          debugResult,
        );
      }
    } catch (e) {
      print('🔐 🔍 Biometric debug error: $e');
      if (context.mounted) {
        _showBiometricErrorDialog(context, 'Biometric debug failed: $e', {
          'error': e.toString(),
        });
      }
    }
  }

  /// Show detailed biometric error dialog
  void _showBiometricErrorDialog(
    BuildContext context,
    String message,
    Map<String, dynamic> details,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Biometric Setup Issue'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '📊 Technical Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...details.entries.map(
                  (entry) => Text('• ${entry.key}: ${entry.value}'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  /// Show biometric failure dialog with solutions
  void _showBiometricFailureDialog(
    BuildContext context,
    Map<String, dynamic> diagnosis,
    Map<String, dynamic> contextInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Biometric Authentication Failed'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The biometric prompt appeared but authentication was unsuccessful.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '📱 Possible reasons:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• You cancelled the biometric prompt'),
              const Text('• The biometric didn\'t match (wrong finger/face)'),
              const Text('• Device biometric sensor issue'),
              const Text('• Biometric not properly enrolled'),
              const SizedBox(height: 16),
              if (diagnosis.isNotEmpty) ...[
                const Text(
                  '🔍 Diagnosis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• ${diagnosis['issue'] ?? 'Unknown issue'}'),
              ],
              if (contextInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '📊 Context Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• ${contextInfo['contextStatus'] ?? 'Unknown status'}'),
              ],
              const SizedBox(height: 16),
              const Text(
                '✅ Solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Try again with the correct biometric'),
              const Text('2. Check device biometric settings'),
              const Text('3. Re-enroll your biometric in device settings'),
              const Text('4. Restart your device and try again'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Try again
              _enableBiometricsFromDashboard(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Show detailed debug results dialog
  void _showDetailedDebugDialog(
    BuildContext context,
    Map<String, dynamic> debugResult,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 🔍 Biometric Debug Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comprehensive biometric authentication debug results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Step results
              if (debugResult['stepsCompleted'] != null) ...[
                const Text(
                  '📋 Steps Completed:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(debugResult['stepsCompleted'] as List<String>).map(
                  (step) => Text('• $step'),
                ),
                const SizedBox(height: 16),
              ],

              // Device support
              if (debugResult['deviceSupported'] != null) ...[
                Text(
                  '📱 Device Support: ${debugResult['deviceSupported'] ? '✅ Yes' : '❌ No'}',
                ),
                const SizedBox(height: 8),
              ],

              // Can check biometrics
              if (debugResult['canCheckBiometrics'] != null) ...[
                Text(
                  '🔍 Can Check Biometrics: ${debugResult['canCheckBiometrics'] ? '✅ Yes' : '❌ No'}',
                ),
                const SizedBox(height: 8),
              ],

              // Available biometrics
              if (debugResult['availableBiometrics'] != null) ...[
                Text(
                  '👆 Available Biometrics: ${debugResult['availableBiometrics'].join(', ')}',
                ),
                const SizedBox(height: 8),
              ],

              // Prompt status
              if (debugResult['promptAppeared'] != null) ...[
                Text(
                  '💬 Prompt Appeared: ${debugResult['promptAppeared'] ? '✅ Yes' : '❌ No'}',
                ),
                const SizedBox(height: 8),
              ],

              // Method used
              if (debugResult['methodUsed'] != null) ...[
                Text('⚙️ Method Used: ${debugResult['methodUsed']}'),
                const SizedBox(height: 8),
              ],

              // Final result
              if (debugResult['finalResult'] != null) ...[
                Text('🎯 Final Result: ${debugResult['finalResult']}'),
                const SizedBox(height: 8),
              ],

              // Errors
              if (debugResult['step1Error'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '❌ Step 1 Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(debugResult['step1Error']),
              ],

              if (debugResult['step2Error'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  '❌ Step 2 Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(debugResult['step2Error']),
              ],

              if (debugResult['step3Error'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  '❌ Step 3 Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(debugResult['step3Error']),
              ],

              if (debugResult['step4Error'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  '❌ Step 4 Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(debugResult['step4Error']),
              ],

              // Error details
              if (debugResult['error1'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  '❌ Error 1:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(debugResult['error1']),
                Text('Type: ${debugResult['errorType1'] ?? 'Unknown'}'),
              ],

              if (debugResult['error2'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  '❌ Error 2:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(debugResult['error2']),
                Text('Type: ${debugResult['errorType2'] ?? 'Unknown'}'),
              ],

              // Error category
              if (debugResult['errorCategory'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '🏷️ Error Category:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(debugResult['errorCategory']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Try again
              _enableBiometricsFromDashboard(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
