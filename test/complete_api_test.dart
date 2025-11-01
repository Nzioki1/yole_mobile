import 'package:flutter_test/flutter_test.dart';
import '../lib/services/complete_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete API Service Tests', () {
    setUp(() async {
      await ApiService.init();
    });

    test('Test login with test@yole.com', () async {
      print('\n🔐 Testing login...');

      final result = await ApiService.login('test@yole.com', 'Test');

      print('Login result: ${result['success']}');

      if (result['success']) {
        print('✅ Login successful');
        print('Token: ${ApiService.getCurrentToken()?.substring(0, 30)}...');
        expect(ApiService.getCurrentToken(), isNotNull);
      } else {
        print('❌ Login failed: ${result['error']}');
      }
    });

    test('Test public endpoints', () async {
      print('\n🌐 Testing public endpoints...');

      // Test status
      final status = await ApiService.getStatus();
      print('Status: ${status['success'] ? '✅' : '❌'}');

      // Test countries
      final countries = await ApiService.getCountries();
      print('Countries: ${countries['success'] ? '✅' : '❌'}');
    });

    test('Test protected endpoints', () async {
      print('\n🔒 Testing protected endpoints...');

      // First login
      final loginResult = await ApiService.login('test@yole.com', 'Test');

      if (!loginResult['success']) {
        print('❌ Cannot test protected endpoints without login');
        return;
      }

      // Test profile
      final profile = await ApiService.getMyProfile();
      print(
          'My Profile: ${profile['success'] ? '✅' : '❌ ${profile['error']}'}');

      // Test charges
      final charges = await ApiService.getCharges(10.0, 'USD', 'KE');
      print('Charges: ${charges['success'] ? '✅' : '❌ ${charges['error']}'}');

      // Test service charge
      final serviceCharge = await ApiService.getServiceCharge();
      print(
          'Service Charge: ${serviceCharge['success'] ? '✅' : '❌ ${serviceCharge['error']}'}');

      // Test transactions
      final transactions = await ApiService.getTransactions();
      print(
          'Transactions: ${transactions['success'] ? '✅' : '❌ ${transactions['error']}'}');

      // Test email verification
      final emailVerify = await ApiService.sendEmailVerification();
      print(
          'Email Verification: ${emailVerify['success'] ? '✅' : '❌ ${emailVerify['error']}'}');

      // Test SMS OTP
      final smsOtp = await ApiService.sendSmsOtp('+254', '0711223344');
      print('SMS OTP: ${smsOtp['success'] ? '✅' : '❌ ${smsOtp['error']}'}');
    });

    test('Test token refresh', () async {
      print('\n🔄 Testing token refresh...');

      // First login
      final loginResult = await ApiService.login('test@yole.com', 'Test');

      if (!loginResult['success']) {
        print('❌ Cannot test token refresh without login');
        return;
      }

      final refreshResult = await ApiService.refreshToken();
      print('Token Refresh: ${refreshResult['success'] ? '✅' : '❌'}');
    });
  });
}
