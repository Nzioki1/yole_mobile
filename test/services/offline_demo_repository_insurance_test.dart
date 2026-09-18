import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/services/offline_demo_repository.dart';

void main() {
  group('OfflineDemoRepository insurance methods', () {
    late OfflineDemoRepository repo;

    setUp(() {
      repo = OfflineDemoRepository.createFresh();
      // Login as cust_kasee (pre-seeded customer)
      repo.login(
        email: 'jp.kabila@gmail.com',
        password: 'Password1!',
      );
    });

    test('listInsuranceProducts returns 5 products', () {
      final products = repo.listInsuranceProducts();
      expect(products.length, 5);
      expect(products[0]['id'], 'health_hosp');
      expect(products[0]['nameFr'], 'Santé hospitalisation');
    });

    test('listInsurancePolicies returns pre-seeded policy for cust_kasee', () {
      final policies = repo.listInsurancePolicies('cust_kasee');
      expect(policies.length, 1);
      expect(policies[0]['productId'], 'health_hosp');
      expect(policies[0]['active'], true);
      expect(policies[0]['fixedMinor'], 250000);
    });

    test('activateInsurancePolicy creates new policy', () {
      final policy = repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'accident',
        premiumMode: 'FIXED',
        fixedSchedule: 'PER_TXN',
        fixedMinor: 100000,
        deductFrom: 'BOTH',
      );

      expect(policy['productId'], 'accident');
      expect(policy['active'], true);
      expect(policy['fixedMinor'], 100000);

      final policies = repo.listInsurancePolicies('cust_kasee');
      expect(policies.length, 2);
    });

    test('activateInsurancePolicy updates existing active policy', () {
      // Pre-seeded: health_hosp FIXED MONTHLY 250000 BOTH
      final updatedPolicy = repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'health_hosp',
        premiumMode: 'FIXED',
        fixedSchedule: 'MONTHLY',
        fixedMinor: 300000, // Changed from 250000
        deductFrom: 'BILL', // Changed from BOTH
      );

      expect(updatedPolicy['fixedMinor'], 300000);
      expect(updatedPolicy['deductFrom'], 'BILL');

      final policies = repo.listInsurancePolicies('cust_kasee');
      expect(policies.length, 1); // Still 1 policy
    });

    test('deactivateInsurancePolicy marks policy inactive', () {
      final policies = repo.listInsurancePolicies('cust_kasee');
      final policyId = policies[0]['id'] as String;

      repo.deactivateInsurancePolicy(policyId);

      final updatedPolicies = repo.listInsurancePolicies('cust_kasee');
      expect(updatedPolicies[0]['active'], false);
    });

    test('previewInsurancePremiums returns matching line items', () {
      // Pre-seeded: health_hosp FIXED MONTHLY 250000 BOTH, lastMonthlyCollectedYm = "2026-08"
      // Current month should be 2026-09 or later, so premium should be charged

      final lineItems = repo.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
      );

      expect(lineItems.length, 1);
      expect(lineItems[0]['productNameFr'], 'Santé hospitalisation');
      expect(lineItems[0]['premiumMinor'], 250000);
    });

    test('previewInsurancePremiums filters by rail', () {
      // Activate death_funeral (PERCENT 30 bps, SEND only)
      repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'death_funeral',
        premiumMode: 'PERCENT',
        percentBps: 30,
        deductFrom: 'SEND',
      );

      // BILL rail should only match health_hosp (BOTH)
      final billItems = repo.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
      );

      expect(billItems.length, 1);
      expect(billItems[0]['productNameFr'], 'Santé hospitalisation');

      // SEND rail should match both
      final sendItems = repo.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'SEND',
        principalMinor: 5000000,
      );

      expect(sendItems.length, 2);
    });

    test('collectInsurancePremiums creates journal entries and updates MONTHLY policy', () {
      // Pre-seeded: health_hosp FIXED MONTHLY 250000 BOTH

      final journals = repo.collectInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
        parentTransactionId: 'txn_test_001',
      );

      expect(journals.length, 1);
      expect(journals[0]['type'], 'INSURANCE_PREMIUM');
      expect(journals[0]['amountMinor'], 250000);
      expect(journals[0]['parentTransactionId'], 'txn_test_001');

      // Check that lastMonthlyCollectedYm is updated
      final policies = repo.listInsurancePolicies('cust_kasee');
      final healthPolicy = policies.firstWhere((p) => p['productId'] == 'health_hosp');
      expect(healthPolicy['lastMonthlyCollectedYm'], isNotNull);
      
      // Second collect in same month should create no journals
      final journals2 = repo.collectInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 3000000,
        parentTransactionId: 'txn_test_002',
      );

      expect(journals2.length, 0);
    });

    test('collectInsurancePremiums stacks multiple policies', () {
      // Activate accident (PER_TXN)
      repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'accident',
        premiumMode: 'FIXED',
        fixedSchedule: 'PER_TXN',
        fixedMinor: 100000,
        deductFrom: 'BOTH',
      );

      final journals = repo.collectInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
        parentTransactionId: 'txn_test_003',
      );

      expect(journals.length, 2); // health_hosp + accident
      final totalPremium = journals.fold<int>(
        0,
        (sum, j) => sum + (j['amountMinor'] as int),
      );
      expect(totalPremium, 350000); // 250000 + 100000
    });
  });
}
