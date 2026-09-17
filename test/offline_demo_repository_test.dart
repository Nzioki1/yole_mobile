import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/services/offline_demo_repository.dart';

void main() {
  test("walletsFor('cust_kasee') length 2", () {
    final repo = OfflineDemoRepository.createFresh();
    expect(repo.walletsFor('cust_kasee'), hasLength(2));
  });

  test("login as seeded kasee then getMyWallets has CDF and USD with non-zero USD", () {
    final repo = OfflineDemoRepository.createFresh();
    
    // Login with seeded kasee credentials from universe.json
    final loginResult = repo.login(
      email: 'jp.kabila@gmail.com',
      password: 'Password1!',
    );
    
    expect(loginResult['customer']['id'], equals('cust_kasee'));
    expect(loginResult['accessToken'], isNotNull);
    
    // Get wallets for logged-in customer
    final walletsResponse = repo.getMyWallets();
    final wallets = walletsResponse['wallets'] as List;
    
    expect(wallets, hasLength(2));
    
    // Find CDF and USD wallets
    final cdfWallet = wallets.firstWhere((w) => w['currency'] == 'CDF');
    final usdWallet = wallets.firstWhere((w) => w['currency'] == 'USD');
    
    expect(cdfWallet, isNotNull);
    expect(usdWallet, isNotNull);
    
    // Verify USD has non-zero balance (seed has 15000 minor = $150.00)
    expect(int.parse(usdWallet['availableMinor'] as String), greaterThan(0));
    expect(int.parse(usdWallet['ledgerMinor'] as String), greaterThan(0));
  });

  test("confirmPayment W2W USD debits wallet by amount+fee and lists payment", () {
    final repo = OfflineDemoRepository.createFresh();
    
    // Login as kasee
    repo.login(
      email: 'jp.kabila@gmail.com',
      password: 'Password1!',
    );
    
    // Get initial wallet balance
    final initialWallets = repo.getMyWallets();
    final initialUsdWallet = (initialWallets['wallets'] as List)
        .firstWhere((w) => w['currency'] == 'USD');
    final initialBalance = int.parse(initialUsdWallet['availableMinor'] as String);
    
    // Quote a W2W payment (50 USD = 5000 minor)
    final quote = repo.quotePayment(
      type: 'W2W',
      currency: 'USD',
      amountMinor: '5000',
      metadata: {'destRef': 'cust_jp_kabila'},
    );
    
    final paymentId = quote['paymentId'] as String;
    final amount = int.parse(quote['amountMinor'] as String);
    final fee = int.parse(quote['feeMinor'] as String);
    final totalDebit = amount + fee;
    
    expect(amount, equals(5000));
    expect(fee, greaterThan(0)); // Fee should be calculated
    
    // Confirm the payment
    final confirmedPayment = repo.confirmPayment(paymentId: paymentId);
    
    expect(confirmedPayment['status'], equals('POSTED'));
    expect(confirmedPayment['customerId'], equals('cust_kasee'));
    expect(confirmedPayment['currency'], equals('USD'));
    
    // Verify wallet was debited by amount + fee
    final updatedWallets = repo.getMyWallets();
    final updatedUsdWallet = (updatedWallets['wallets'] as List)
        .firstWhere((w) => w['currency'] == 'USD');
    final updatedBalance = int.parse(updatedUsdWallet['availableMinor'] as String);
    
    expect(updatedBalance, equals(initialBalance - totalDebit));
    
    // Verify payment appears in list
    final payments = repo.listPayments();
    final ourPayment = payments.firstWhere((p) => p['id'] == paymentId);
    
    expect(ourPayment['status'], equals('POSTED'));
    expect(ourPayment['type'], equals('W2W'));
  });

  test("createFresh resets session mutations", () {
    final repo1 = OfflineDemoRepository.createFresh();
    
    // Login and make a payment
    repo1.login(
      email: 'jp.kabila@gmail.com',
      password: 'Password1!',
    );
    
    final quote1 = repo1.quotePayment(
      type: 'W2W',
      currency: 'USD',
      amountMinor: '2000',
    );
    repo1.confirmPayment(paymentId: quote1['paymentId'] as String);
    
    // Get wallet after payment
    final walletsAfterPayment = repo1.getMyWallets();
    final usdWalletAfter = (walletsAfterPayment['wallets'] as List)
        .firstWhere((w) => w['currency'] == 'USD');
    final balanceAfterPayment = int.parse(usdWalletAfter['availableMinor'] as String);
    
    // Create a fresh instance - should reset all mutations
    final repo2 = OfflineDemoRepository.createFresh();
    
    // Session should be cleared (not logged in)
    expect(repo2.currentCustomerId, isNull);
    
    // Login again with fresh repo
    repo2.login(
      email: 'jp.kabila@gmail.com',
      password: 'Password1!',
    );
    
    // Wallet should be back to original seed balance
    final freshWallets = repo2.getMyWallets();
    final freshUsdWallet = (freshWallets['wallets'] as List)
        .firstWhere((w) => w['currency'] == 'USD');
    final freshBalance = int.parse(freshUsdWallet['availableMinor'] as String);
    
    // Fresh balance should be greater than after payment (mutations reset)
    expect(freshBalance, greaterThan(balanceAfterPayment));
    // Should be back to seed value of 15000
    expect(freshBalance, equals(15000));
  });

  /// DEM-01 KYC/OTP offline path (KycService delegates here when OFFLINE_DEMO).
  test('KYC OTP flow: login → requestOtp → verifyOtp → submitKyc PENDING_REVIEW',
      () {
    final repo = OfflineDemoRepository.createFresh();

    final login = repo.login(
      email: 'jp.kabila@gmail.com',
      password: 'Password1!',
    );
    expect(login['accessToken'], isNotEmpty);
    expect(repo.currentCustomerId, 'cust_kasee');

    const phoneE164 = '+243990000001';
    repo.requestOtp(phoneE164: phoneE164);

    final verified = repo.verifyOtp(
      phoneE164: phoneE164,
      code: OfflineDemoRepository.demoOtp, // 123456
    );
    expect(verified['verified'], isTrue);

    final result = repo.submitKyc(
      phoneE164: phoneE164,
      idNumber: 'ID-DEMO-001',
    );
    expect(result['success'], isTrue);
    expect(result['kyc'], isA<Map>());
    expect(result['kyc']['status'], 'PENDING_REVIEW');
  });

  test('submitKyc without session throws clear auth error', () {
    final repo = OfflineDemoRepository.createFresh();
    // Fresh repo has no current customer
    expect(repo.currentCustomerId, isNull);
    expect(
      () => repo.submitKyc(phoneE164: '+243990000001', idNumber: 'X'),
      throwsA(
        predicate(
          (e) =>
              e is Exception &&
              e.toString().contains('Not authenticated'),
        ),
      ),
    );
  });
}
