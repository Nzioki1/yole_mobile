import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/models/insurance_product.dart';

void main() {
  group('InsurancePremiumCalculator', () {
    test('PERCENT mode calculates premium correctly', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'death_funeral',
        active: true,
        premiumMode: PremiumMode.PERCENT,
        percentBps: 30, // 0.3%
        deductFrom: DeductFrom.SEND,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      // 50,000 CDF = 5,000,000 minor
      // 0.3% = floor(5,000,000 * 30 / 10,000) = floor(15,000) = 15,000 minor = 150 CDF
      final premium = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 5000000,
        currentYearMonth: '2026-09',
      );

      expect(premium, 15000);
    });

    test('PERCENT mode floors fractional premiums', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'death_funeral',
        active: true,
        premiumMode: PremiumMode.PERCENT,
        percentBps: 30, // 0.3%
        deductFrom: DeductFrom.SEND,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      // 100 CDF = 10,000 minor
      // 0.3% = floor(10,000 * 30 / 10,000) = floor(30) = 30 minor = 0.3 CDF
      final premium = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 10000,
        currentYearMonth: '2026-09',
      );

      expect(premium, 30);
    });

    test('FIXED PER_TXN mode charges on every transaction', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'accident',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.PER_TXN,
        fixedMinor: 100000, // 1,000 CDF
        deductFrom: DeductFrom.BOTH,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final premium1 = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 5000000,
        currentYearMonth: '2026-09',
      );

      final premium2 = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 10000000,
        currentYearMonth: '2026-09',
      );

      expect(premium1, 100000);
      expect(premium2, 100000);
    });

    test('FIXED MONTHLY mode charges once per month', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'health_hosp',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.MONTHLY,
        fixedMinor: 250000, // 2,500 CDF
        deductFrom: DeductFrom.BOTH,
        lastMonthlyCollectedYm: null, // Not collected yet
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      // First transaction in September: charged
      final premium1 = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 5000000,
        currentYearMonth: '2026-09',
      );

      expect(premium1, 250000);

      // Simulate policy updated with lastMonthlyCollectedYm = "2026-09"
      final updatedPolicy = policy.copyWith(
        lastMonthlyCollectedYm: '2026-09',
      );

      // Second transaction in September: not charged
      final premium2 = InsurancePremiumCalculator.calculatePremium(
        policy: updatedPolicy,
        principalMinor: 10000000,
        currentYearMonth: '2026-09',
      );

      expect(premium2, 0);

      // First transaction in October: charged
      final premium3 = InsurancePremiumCalculator.calculatePremium(
        policy: updatedPolicy,
        principalMinor: 8000000,
        currentYearMonth: '2026-10',
      );

      expect(premium3, 250000);
    });

    test('Stacking multiple policies sums premiums', () {
      final policy1 = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'health_hosp',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.MONTHLY,
        fixedMinor: 250000, // 2,500 CDF
        deductFrom: DeductFrom.BOTH,
        lastMonthlyCollectedYm: null,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final policy2 = InsurancePolicy(
        id: 'pol_2',
        customerId: 'cust_1',
        productId: 'accident',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.PER_TXN,
        fixedMinor: 100000, // 1,000 CDF
        deductFrom: DeductFrom.BOTH,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final policy3 = InsurancePolicy(
        id: 'pol_3',
        customerId: 'cust_1',
        productId: 'death_funeral',
        active: true,
        premiumMode: PremiumMode.PERCENT,
        percentBps: 30, // 0.3%
        deductFrom: DeductFrom.SEND,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final principalMinor = 5000000; // 50,000 CDF
      final currentYm = '2026-09';

      final premium1 = InsurancePremiumCalculator.calculatePremium(
        policy: policy1,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      final premium2 = InsurancePremiumCalculator.calculatePremium(
        policy: policy2,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      final premium3 = InsurancePremiumCalculator.calculatePremium(
        policy: policy3,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      final totalPremium = premium1 + premium2 + premium3;

      expect(premium1, 250000); // 2,500 CDF
      expect(premium2, 100000); // 1,000 CDF
      expect(premium3, 15000); // 150 CDF
      expect(totalPremium, 365000); // 3,650 CDF
    });
  });
}
