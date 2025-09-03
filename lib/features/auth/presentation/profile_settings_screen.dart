import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/biometric_preferences.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController(text: 'Test');
  final _lastNameController = TextEditingController(text: 'User');
  final _emailController = TextEditingController(text: 'test@yole.com');
  final _phoneController = TextEditingController(text: '+254 700 000 000');

  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  final List<String> _languages = ['English', 'Swahili', 'French', 'Spanish'];
  final List<String> _currencies = ['USD', 'KES', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Load biometric state from preferences
  Future<void> _loadBiometricState() async {
    try {
      final isEnabled = await BiometricPreferences.isBiometricEnabled();
      setState(() {
        _biometricEnabled = isEnabled;
      });
    } catch (e) {
      print('🔐 Error loading biometric state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 32),

              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: 16),
              _buildPersonalInfoSection(),
              const SizedBox(height: 32),

              // Security Settings Section
              _buildSectionHeader('Security & Privacy', Icons.security),
              const SizedBox(height: 16),
              _buildSecuritySection(),
              const SizedBox(height: 32),

              // Preferences Section
              _buildSectionHeader('Preferences', Icons.settings),
              const SizedBox(height: 16),
              _buildPreferencesSection(),
              const SizedBox(height: 32),

              // Account Actions Section
              _buildSectionHeader('Account Actions', Icons.account_circle),
              const SizedBox(height: 16),
              _buildAccountActionsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Change Photo Button
          TextButton.icon(
            onPressed: _changeProfilePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Photo'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Change Password
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _changePassword,
            ),
            const Divider(),

            // Two-Factor Authentication
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Add an extra layer of security'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  setState(() {
                    // Toggle 2FA state
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('2FA ${value ? 'enabled' : 'disabled'}'),
                      backgroundColor: value ? Colors.green : Colors.orange,
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // Biometric Authentication Setup
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Authentication Setup'),
              subtitle: const Text(
                'Enable fingerprint or face ID for app login',
              ),
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    try {
                      // First run comprehensive diagnosis
                      print('🔐 Running biometric diagnosis...');
                      final diagnosis =
                          await BiometricService.diagnoseBiometricSetup();
                      print('🔐 Diagnosis result: $diagnosis');

                      // Check if biometric is available
                      final isAvailable =
                          await BiometricService.isBiometricAvailable();
                      if (!isAvailable) {
                        String errorMessage =
                            diagnosis['issue'] ??
                            'Biometric authentication not available on this device';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 8),
                          ),
                        );
                        return;
                      }

                      // Test biometric authentication with detailed feedback
                      final testResult =
                          await BiometricService.testBiometricAuthentication();
                      print('🔐 Test result: $testResult');

                      if (testResult['success'] == true) {
                        // Enable biometric login and save credentials
                        await BiometricPreferences.setBiometricEnabled(true);
                        await BiometricPreferences.saveCredentials(
                          _emailController.text,
                          'biometric_enabled', // We'll use a special marker for biometric login
                        );

                        setState(() {
                          _biometricEnabled = true;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Biometric login enabled successfully! You can now use fingerprint/face ID to log in.',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      } else {
                        // Check for specific FragmentActivity error
                        String errorMsg =
                            testResult['error'] ??
                            'Biometric authentication failed. Please try again.';

                        if (errorMsg.contains('no_fragment_activity') ||
                            errorMsg.contains(
                              'requires activity to be a fragmentActivity',
                            )) {
                          // Show specific solution for FragmentActivity error
                          _showFragmentActivityErrorDialog();
                          return;
                        }

                        // Show detailed error information from test result
                        // Add diagnosis information
                        if (diagnosis.containsKey('issue')) {
                          errorMsg =
                              '${errorMsg}\n\nDiagnosis: ${diagnosis['issue']}';
                        }

                        // Add more context if available
                        if (testResult['details'] != null) {
                          final details =
                              testResult['details'] as Map<String, dynamic>;
                          if (details.containsKey('error')) {
                            errorMsg =
                                '${errorMsg}\n\nDetails: ${details['error']}';
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 12),
                          ),
                        );
                      }
                    } catch (e) {
                      print('🔐 Biometric setup error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Biometric setup failed: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } else {
                    // Disable biometric login and clear credentials
                    await BiometricPreferences.setBiometricEnabled(false);
                    await BiometricPreferences.clearSavedCredentials();

                    setState(() {
                      _biometricEnabled = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biometric login disabled. You will need to enter your password to log in.',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Notifications
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive transaction alerts'),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            const Divider(),

            // Dark Mode
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch to dark theme'),
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dark mode ${value ? 'enabled' : 'disabled'}',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // Language
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectLanguage,
            ),
            const Divider(),

            // Currency
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Currency'),
              subtitle: Text(_selectedCurrency),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectCurrency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Export Data
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export Data'),
              subtitle: const Text('Download your transaction history'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _exportData,
            ),
            const Divider(),

            // Privacy Policy
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              subtitle: const Text('Read our privacy policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _viewPrivacyPolicy,
            ),
            const Divider(),

            // Terms of Service
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              subtitle: const Text('Read our terms of service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _viewTermsOfService,
            ),
            const Divider(),

            // Delete Account
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Permanently delete your account'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.red,
              ),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfilePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: const Text('Select a new profile photo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile photo updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Select Photo'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectCurrency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _currencies.map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Your transaction data will be exported to CSV format.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Data exported successfully! Check your downloads folder.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _viewPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Yole Mobile respects your privacy and is committed to protecting your personal information. '
            'We collect only the information necessary to provide our services and never share your data with third parties. '
            'Your financial information is encrypted and stored securely.',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _viewTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Yole Mobile, you agree to our terms of service. '
            'This includes responsible use of our platform, compliance with local laws, '
            'and understanding that we provide financial services subject to regulatory requirements. '
            'We reserve the right to modify these terms with appropriate notice.',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion request submitted. You will receive a confirmation email within 24 hours.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Close the profile settings screen after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Close the current screen to return to dashboard
          Navigator.of(context).pop();
        }
      });
    }
  }

  /// Show dialog explaining FragmentActivity error and providing solutions
  void _showFragmentActivityErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Biometric Setup Issue'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The biometric authentication cannot be enabled from this screen due to a technical limitation.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '📱 What\'s happening:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• This screen doesn\'t have the right Android context for biometric prompts',
              ),
              Text(
                '• The system needs a FragmentActivity to show biometric dialogs',
              ),
              SizedBox(height: 16),
              Text(
                '✅ Solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. Go to the main dashboard and try enabling biometrics from there',
              ),
              Text('2. Restart the app and try again'),
              Text('3. Enable biometrics from your device settings first'),
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
              // Navigate to dashboard to try biometrics there
              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }
}
