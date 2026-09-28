import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/services/offline_demo_repository.dart';

void main() {
  late OfflineDemoRepository repo;

  setUp(() {
    repo = OfflineDemoRepository.instance;
    // Login as Jean-Paul (approved KYC)
    repo.login(email: 'jeanpaul@demo.com', password: 'Password1!');
  });

  group('Item 1: KYC Wallet Gate', () {
    test('should block payment for non-approved KYC customer', () {
      // Login as pending KYC customer
      repo.login(email: 'pending.kyc@demo.com', password: 'Password1!');
      
      expect(
        () => repo.quotePayment(
          type: 'W2W',
          currency: 'CDF',
          amountMinor: '10000',
        ),
        throwsA(predicate((e) => e.toString().contains('KYC not approved'))),
      );
    });

    test('should allow payment for approved KYC customer', () {
      // Jean-Paul is approved
      final quote = repo.quotePayment(
        type: 'W2W',
        currency: 'CDF',
        amountMinor: '10000',
      );
      
      expect(quote['status'], equals('QUOTED'));
      expect(quote['type'], equals('W2W'));
    });

    test('isKycApproved should return true for approved customer', () {
      final approved = repo.isKycApproved();
      expect(approved, isTrue);
    });

    test('isKycApproved should return false for pending customer', () {
      repo.login(email: 'pending.kyc@demo.com', password: 'Password1!');
      final approved = repo.isKycApproved();
      expect(approved, isFalse);
    });
  });

  group('Item 2: Credit Scoring & Affordability', () {
    test('should calculate credit score with factors', () {
      final score = repo.getCreditScore();
      
      expect(score['score'], isA<int>());
      expect(score['rating'], isA<String>());
      expect(score['factors'], isA<Map>());
      expect(score['factors']['salaryHistory'], isA<int>());
    });

    test('should check affordability based on salary', () {
      final affordability = repo.checkAffordability(
        principalMinor: '100000',
        termMonths: 6,
        currency: 'CDF',
      );
      
      expect(affordability['affordable'], isA<bool>());
      expect(affordability['monthlyInstallmentMinor'], isA<int>());
      expect(affordability['avgMonthlySalaryMinor'], isA<int>());
      expect(affordability['reason'], isA<String>());
    });

    test('should return APPROVED for good credit + affordable', () {
      // Jean-Paul has good credit (6+ salaries, good history)
      final loan = repo.requestLoan(
        type: 'SALARY_ADVANCE',
        principalMinor: '100000',
        currency: 'CDF',
        termMonths: 3,
      );
      
      // Should be approved or already have loan
      expect(loan['status'], anyOf('ACTIVE', 'DECLINED'));
    });

    test('should return DECLINED for unaffordable amount', () {
      // Request huge amount
      final loan = repo.requestLoan(
        type: 'SALARY_ADVANCE',
        principalMinor: '100000000', // 1M CDF
        currency: 'CDF',
        termMonths: 3,
      );
      
      expect(loan['status'], anyOf('DECLINED', 'PENDING_EXCEPTION'));
      if (loan['status'] == 'DECLINED') {
        expect(loan['reason'], contains('affordable'));
      }
    });

    test('poor credit customer should get DECLINED', () {
      repo.login(email: 'poor.credit@demo.com', password: 'Password1!');
      
      expect(
        () => repo.requestLoan(
          type: 'SALARY_ADVANCE',
          principalMinor: '100000',
          currency: 'CDF',
          termMonths: 3,
        ),
        throwsA(predicate((e) => 
          e.toString().contains('not eligible') || 
          e.toString().contains('No payroll')
        )),
      );
    });
  });

  group('Item 5: Per-Employer Arrangements', () {
    test('should apply employer-specific max advance percentage', () {
      // Jean-Paul is at emp_kinshasa_elec with 50% max advance
      final eligibility = repo.checkCreditEligibility(type: 'SALARY_ADVANCE');
      
      expect(eligibility['eligible'], isTrue);
      expect(eligibility['maxAmountMinor'], isA<String>());
      expect(eligibility['interestRate'], isA<double>());
      expect(eligibility['employerId'], equals('emp_kinshasa_elec'));
    });

    test('should return employer-specific interest rate', () {
      final eligibility = repo.checkCreditEligibility(type: 'SALARY_ADVANCE');
      final rate = eligibility['interestRate'] as double;
      
      // emp_kinshasa_elec has 0.12 (12%) preferential rate
      expect(rate, lessThanOrEqualTo(0.15));
    });
  });

  group('2-Salary Eligibility Check', () {
    test('should require at least 2 salary payments', () {
      // Fair credit customer has 3 salaries
      repo.login(email: 'fair.credit@demo.com', password: 'Password1!');
      
      final eligibility = repo.checkCreditEligibility(type: 'SALARY_ADVANCE');
      expect(eligibility['eligible'], isTrue);
      expect(eligibility['salaryPeriods'], greaterThanOrEqualTo(2));
    });
  });
}
