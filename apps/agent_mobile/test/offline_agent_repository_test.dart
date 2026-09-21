import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/services/offline_agent_repository.dart';

void main() {
  group('OfflineAgentRepository', () {
    late OfflineAgentRepository repo;

    setUp(() {
      repo = OfflineAgentRepository.createFresh();
    });

    test('agent-001 float matches seed', () {
      final float = repo.floatFor('agent-001');
      expect(float['floatCdfMinor'], 500000000);
      expect(float['floatUsdMinor'], 200000);
    });

    group('email-based login', () {
      test('login with valid agent email and password returns agent info', () {
        final result = repo.loginByEmail(
          email: 'agent001@postefinance-agents.cd',
          password: 'Password1!',
        );

        expect(result['id'], 'agent-001');
        expect(result['email'], 'agent001@postefinance-agents.cd');
        expect(repo.currentAgentId, 'agent-001');
      });

      test('login with valid agent email (case-insensitive) succeeds', () {
        final result = repo.loginByEmail(
          email: 'AGENT001@postefinance-agents.cd',
          password: 'Password1!',
        );

        expect(result['id'], 'agent-001');
        expect(repo.currentAgentId, 'agent-001');
      });

      test('login with invalid password throws exception', () {
        expect(
          () => repo.loginByEmail(
            email: 'agent001@postefinance-agents.cd',
            password: 'WrongPassword',
          ),
          throwsA(
            predicate((e) => e.toString().contains('Invalid password')),
          ),
        );
      });

      test('login with customer email throws CUSTOMER_EMAIL exception', () {
        expect(
          () => repo.loginByEmail(
            email: 'jp.kabila@gmail.com',
            password: 'Password1!',
          ),
          throwsA(
            predicate((e) => e.toString().contains('CUSTOMER_EMAIL')),
          ),
        );
      });

      test('login with unknown agent email throws exception', () {
        expect(
          () => repo.loginByEmail(
            email: 'unknown@postefinance-agents.cd',
            password: 'Password1!',
          ),
          throwsA(
            predicate((e) => e.toString().contains('Agent not found')),
          ),
        );
      });

      test('login with non-agent domain throws CUSTOMER_EMAIL exception', () {
        expect(
          () => repo.loginByEmail(
            email: 'someone@example.com',
            password: 'Password1!',
          ),
          throwsA(
            predicate((e) => e.toString().contains('CUSTOMER_EMAIL')),
          ),
        );
      });
    });

    group('cash operations', () {
      setUp(() {
        repo = OfflineAgentRepository.createFresh();
        repo.setAgentId('agent-001');
      });

      test('getTodayUsage() with no transactions returns 0 usage', () {
        final usage = repo.getTodayUsage();

        expect(usage['totalCdfMinor'], 0);
        expect(usage['totalUsdMinor'], 0);
        expect(usage['cashInCount'], 0);
        expect(usage['cashOutCount'], 0);
      });

      test('getTodayUsage() after one cash-in returns correct CDF usage', () {
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '100000',
          currency: 'CDF',
        );

        final usage = repo.getTodayUsage();

        expect(usage['totalCdfMinor'], 100000);
        expect(usage['totalUsdMinor'], 0);
        expect(usage['cashInCount'], 1);
        expect(usage['cashOutCount'], 0);
      });

      test('isWithinLimits() with amount under daily limit returns true', () {
        final result = repo.isWithinLimits(
          amountMinor: 100000,
          currency: 'CDF',
        );

        expect(result['withinLimits'], true);
      });

      test('isWithinLimits() with amount exceeding per-txn limit returns false', () {
        final result = repo.isWithinLimits(
          amountMinor: 600000000,
          currency: 'CDF',
        );

        expect(result['withinLimits'], false);
        expect(result['reason'], contains('Per-transaction limit exceeded'));
      });

      test('cashIn() updates agent float and customer wallet correctly', () {
        final floatBefore = repo.floatFor('agent-001');
        final initialCdf = floatBefore['floatCdfMinor'] as int;

        final walletBefore = repo.getWallet(
          customerId: 'cust_kasee',
          currency: 'CDF',
        );
        final initialBalance = int.parse(walletBefore['availableMinor']?.toString() ?? '0');

        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '100000',
          currency: 'CDF',
        );

        final floatAfter = repo.floatFor('agent-001');
        final walletAfter = repo.getWallet(
          customerId: 'cust_kasee',
          currency: 'CDF',
        );

        expect(floatAfter['floatCdfMinor'], initialCdf - 100000);
        expect(
          int.parse(walletAfter['availableMinor']?.toString() ?? '0'),
          initialBalance + 100000,
        );
      });

      test('cashOut() with fee debits customer amount+fee, credits agent amount', () {
        // First cash-in to give customer balance
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '200000',
          currency: 'CDF',
        );

        final floatBefore = repo.floatFor('agent-001');
        final initialFloat = floatBefore['floatCdfMinor'] as int;

        final walletBefore = repo.getWallet(
          customerId: 'cust_kasee',
          currency: 'CDF',
        );
        final initialBalance = int.parse(walletBefore['availableMinor']?.toString() ?? '0');

        final result = repo.cashOut(
          customerId: 'cust_kasee',
          amountMinor: '100000',
          currency: 'CDF',
        );

        final feeMinor = int.parse(result['feeMinor']?.toString() ?? '0');
        expect(feeMinor, greaterThan(0));

        final floatAfter = repo.floatFor('agent-001');
        final walletAfter = repo.getWallet(
          customerId: 'cust_kasee',
          currency: 'CDF',
        );

        // Agent float increases by amount only (not fee)
        expect(floatAfter['floatCdfMinor'], initialFloat + 100000);

        // Customer debited amount + fee
        expect(
          int.parse(walletAfter['availableMinor']?.toString() ?? '0'),
          initialBalance - 100000 - feeMinor,
        );
      });

      test('getFee() returns correct fee for AGENT_CASH_IN CDF', () {
        final feeResult = repo.getFee(
          paymentType: 'AGENT_CASH_IN',
          currency: 'CDF',
          amountMinor: 100000,
        );

        final feeMinor = feeResult['feeMinor'] as int;
        // 0.5% of 100000 = 500, which is the min fee
        expect(feeMinor, 500);
      });

      test('getFee() returns correct fee for AGENT_CASH_OUT USD', () {
        final feeResult = repo.getFee(
          paymentType: 'AGENT_CASH_OUT',
          currency: 'USD',
          amountMinor: 10000,
        );

        final feeMinor = feeResult['feeMinor'] as int;
        // 1.0% of 10000 = 100, but min is 50
        expect(feeMinor, 100);
      });

      test('getWallet() returns wallet for customer and currency', () {
        final wallet = repo.getWallet(
          customerId: 'cust_kasee',
          currency: 'CDF',
        );

        expect(wallet['customerId'], 'cust_kasee');
        expect(wallet['currency'], 'CDF');
        expect(wallet.containsKey('availableMinor'), true);
      });

      test('findCustomerByPhoneOrId() finds customer by phone', () {
        final customer = repo.findCustomerByPhoneOrId('+243990123456');

        expect(customer['id'], 'cust_kasee');
        expect(customer['firstName'], 'Jean-Paul');
      });

      test('findCustomerByPhoneOrId() finds customer by ID', () {
        final customer = repo.findCustomerByPhoneOrId('cust_kasee');

        expect(customer['id'], 'cust_kasee');
        expect(customer['phoneE164'], '+243990123456');
      });

      test('findCustomerByPhoneOrId() throws if customer not found', () {
        expect(
          () => repo.findCustomerByPhoneOrId('+999999999999'),
          throwsA(
            predicate((e) => e.toString().contains('Customer not found')),
          ),
        );
      });
    });

    group('customer enrollment', () {
      setUp(() {
        repo = OfflineAgentRepository.createFresh();
        repo.setAgentId('agent-001');
      });

      test('enrollCustomer() with email creates customer and 2 wallets (CDF + USD)', () {
        final result = repo.enrollCustomer(
          firstName: 'Test',
          lastName: 'Customer',
          password: 'Password1!',
          email: 'test@example.com',
        );

        expect(result['customerId'], isNotNull);
        expect(result['wallets'], hasLength(2));
        expect(result['wallets'][0], contains('_cdf'));
        expect(result['wallets'][1], contains('_usd'));
        expect(result['status'], 'ACTIVE');
      });

      test('enrollCustomer() with duplicate email throws exception', () {
        repo.enrollCustomer(
          firstName: 'First',
          lastName: 'Customer',
          password: 'Password1!',
          email: 'duplicate@example.com',
        );

        expect(
          () => repo.enrollCustomer(
            firstName: 'Second',
            lastName: 'Customer',
            password: 'Password1!',
            email: 'duplicate@example.com',
          ),
          throwsA(
            predicate((e) => e.toString().contains('email already registered')),
          ),
        );
      });

      test('enrollCustomer() with ID creates KYC record with status PENDING_REVIEW', () {
        final result = repo.enrollCustomer(
          firstName: 'Test',
          lastName: 'Customer',
          password: 'Password1!',
          idNumber: '123456789',
          idType: 'NATIONAL_ID',
        );

        expect(result['kycStatus'], 'PENDING_REVIEW');
      });

      test('enrollCustomer() without ID has status PENDING (no KYC record)', () {
        final result = repo.enrollCustomer(
          firstName: 'Test',
          lastName: 'Customer',
          password: 'Password1!',
        );

        expect(result['kycStatus'], 'PENDING');
      });

      test('enrollCustomer() sets enrolledByAgentId to current agent', () {
        final result = repo.enrollCustomer(
          firstName: 'Test',
          lastName: 'Customer',
          password: 'Password1!',
        );

        final customer = repo.findCustomerById(result['customerId']);
        expect(customer, isNotNull);
        expect(customer!['enrolledByAgentId'], 'agent-001');
      });
    });

    group('commission tracking', () {
      setUp(() {
        repo = OfflineAgentRepository.createFresh();
        repo.setAgentId('agent-001');
      });

      test('floor math: 10000 minor × 50 bps → 50 minor', () {
        final commission = (10000 * 50 / 10000).floor();
        expect(commission, 50);
      });

      test('floor math: small amount floors to 0 → no commission row', () {
        final commission = (10 * 50 / 10000).floor();
        expect(commission, 0);
      });

      test('cash-in creates commission row with correct fields', () {
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '1000000',
          currency: 'CDF',
        );

        final commissions = repo.listCommissionsToday();
        expect(commissions, hasLength(1));

        final comm = commissions[0];
        expect(comm['agentId'], 'agent-001');
        expect(comm['customerId'], 'cust_kasee');
        expect(comm['type'], 'AGENT_CASH_IN');
        expect(comm['currency'], 'CDF');
        expect(comm['principalMinor'], 1000000);
        expect(comm['bps'], 50);
        // 1000000 * 50 / 10000 = 5000
        expect(comm['commissionMinor'], 5000);
        expect(comm['txnId'], isNotNull);
        expect(comm['createdAt'], isNotNull);
      });

      test('cash-out creates commission row with correct type', () {
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '2000000',
          currency: 'CDF',
        );

        repo.cashOut(
          customerId: 'cust_kasee',
          amountMinor: '500000',
          currency: 'CDF',
        );

        final commissions = repo.listCommissionsToday();
        expect(commissions, hasLength(2));
        expect(commissions.any((c) => c['type'] == 'AGENT_CASH_IN'), true);
        expect(commissions.any((c) => c['type'] == 'AGENT_CASH_OUT'), true);
      });

      test('commissionSummaryToday aggregates CDF and USD separately', () {
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '1000000',
          currency: 'CDF',
        );

        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '100000',
          currency: 'USD',
        );

        final summary = repo.commissionSummaryToday();
        // CDF: 1000000 * 50 / 10000 = 5000
        expect(summary['cdfMinor'], 5000);
        // USD: 100000 * 50 / 10000 = 500
        expect(summary['usdMinor'], 500);
        expect(summary['count'], 2);
      });

      test('commissionSummaryToday with empty day returns zeros', () {
        final summary = repo.commissionSummaryToday();
        expect(summary['cdfMinor'], 0);
        expect(summary['usdMinor'], 0);
        expect(summary['count'], 0);
      });

      test('cash-in return includes commission fields', () {
        final result = repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '1000000',
          currency: 'CDF',
        );

        // 1000000 * 50 / 10000 = 5000
        expect(result['commissionMinor'], 5000);
        expect(result['commissionBps'], 50);
      });

      test('small amount that floors to 0 skips commission row', () {
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '10',
          currency: 'CDF',
        );

        final commissions = repo.listCommissionsToday();
        expect(commissions, isEmpty);
      });
    });

    group('history queries', () {
      setUp(() {
        repo = OfflineAgentRepository.createFresh();
        repo.setAgentId('agent-001');
      });

      test('getTodayHistory() with no transactions returns empty list', () {
        final history = repo.getTodayHistory();
        expect(history, isEmpty);
      });

      test('getTodayHistory() after cash-in returns 1 journal', () {
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '100000',
          currency: 'CDF',
        );

        final history = repo.getTodayHistory();
        expect(history, hasLength(1));
        expect(history[0]['type'], 'AGENT_CASH_IN');
        expect(history[0]['customerId'], 'cust_kasee');
      });

      test('getTodayHistory() returns journals sorted by postedAt descending', () {
        // Create multiple transactions
        repo.cashIn(
          customerId: 'cust_kasee',
          amountMinor: '100000',
          currency: 'CDF',
        );
        
        // Wait a moment to ensure different timestamps
        Future.delayed(const Duration(milliseconds: 10));
        
        repo.cashOut(
          customerId: 'cust_kasee',
          amountMinor: '50000',
          currency: 'CDF',
        );

        final history = repo.getTodayHistory();
        expect(history, hasLength(2));
        
        // Most recent first (cash-out)
        expect(history[0]['type'], 'AGENT_CASH_OUT');
        expect(history[1]['type'], 'AGENT_CASH_IN');
      });

      test('getTodayEnrollments() with no enrollments returns empty list', () {
        final enrollments = repo.getTodayEnrollments();
        expect(enrollments, isEmpty);
      });

      test('getTodayEnrollments() after enrollment returns 1 customer', () {
        repo.enrollCustomer(
          firstName: 'Test',
          lastName: 'Customer',
          password: 'Password1!',
        );

        final enrollments = repo.getTodayEnrollments();
        expect(enrollments, hasLength(1));
        expect(enrollments[0]['firstName'], 'Test');
        expect(enrollments[0]['enrolledByAgentId'], 'agent-001');
      });

      test('getTodayEnrollments() returns customers sorted by createdAt descending', () {
        repo.enrollCustomer(
          firstName: 'First',
          lastName: 'Customer',
          password: 'Password1!',
        );
        
        repo.enrollCustomer(
          firstName: 'Second',
          lastName: 'Customer',
          password: 'Password1!',
        );

        final enrollments = repo.getTodayEnrollments();
        expect(enrollments, hasLength(2));
        
        // Most recent first
        expect(enrollments[0]['firstName'], 'Second');
        expect(enrollments[1]['firstName'], 'First');
      });
    });

    group('payForCustomer - assisted bill pay and airtime', () {
      setUp(() {
        repo = OfflineAgentRepository.createFresh();
        repo.setAgentId('agent-001');
      });

      group('bill payment', () {
        test('debits agent float by amount + fee', () {
          final floatBefore = repo.floatFor('agent-001');
          final initialFloat = floatBefore['floatCdfMinor'] as int;

          final result = repo.payForCustomer(
            customerId: 'cust_kasee',
            kind: 'BILL',
            amountMinor: 5000, // FC 50.00
            billerCode: 'SNEL_KINSHASA',
            accountNumber: '12345678',
          );

          expect(result['status'], 'POSTED');

          final floatAfter = repo.floatFor('agent-001');
          final finalFloat = floatAfter['floatCdfMinor'] as int;

          final feeMinor = result['feeMinor'] as int;
          expect(finalFloat, lessThan(initialFloat));
          expect(initialFloat - finalFloat, equals(5000 + feeMinor));
        });

        test('throws on insufficient float', () {
          // Drain float to near-zero
          final agent = repo.getAgentInfo('agent-001');
          agent['floatCdfMinor'] = 100; // FC 1.00

          expect(
            () => repo.payForCustomer(
              customerId: 'cust_kasee',
              kind: 'BILL',
              amountMinor: 5000,
              billerCode: 'SNEL_KINSHASA',
              accountNumber: '12345678',
            ),
            throwsA(
              predicate((e) => 
                e.toString().contains('Insufficient float') &&
                e.toString().contains('Need') &&
                e.toString().contains('have')
              ),
            ),
          );
        });

        test('writes AGENT_ASSISTED_BILL journal with metadata', () {
          final result = repo.payForCustomer(
            customerId: 'cust_kasee',
            kind: 'BILL',
            amountMinor: 5000,
            billerCode: 'SNEL_KINSHASA',
            accountNumber: '12345678',
          );

          final history = repo.getTodayHistory();
          final journal = history.firstWhere(
            (j) => j['id'] == result['journalId'],
          );

          expect(journal['type'], 'AGENT_ASSISTED_BILL');
          expect(journal['agentId'], 'agent-001');
          expect(journal['customerId'], 'cust_kasee');
          expect(journal['currency'], 'CDF');
          expect(journal['amountMinor'], 5000);
          
          final metadata = journal['metadata'] as Map<String, dynamic>;
          expect(metadata['billerCode'], 'SNEL_KINSHASA');
          expect(metadata['accountNumber'], '12345678');
        });

        test('does not mutate customer wallet', () {
          final walletBefore = repo.getWallet(
            customerId: 'cust_kasee',
            currency: 'CDF',
          );
          final initialBalance = int.parse(walletBefore['availableMinor']?.toString() ?? '0');

          repo.payForCustomer(
            customerId: 'cust_kasee',
            kind: 'BILL',
            amountMinor: 5000,
            billerCode: 'SNEL_KINSHASA',
            accountNumber: '12345678',
          );

          final walletAfter = repo.getWallet(
            customerId: 'cust_kasee',
            currency: 'CDF',
          );
          final finalBalance = int.parse(walletAfter['availableMinor']?.toString() ?? '0');

          expect(finalBalance, equals(initialBalance)); // Wallet unchanged
        });

        test('does not accrue commission', () {
          final commissionsBefore = repo.listCommissionsToday();
          final initialCount = commissionsBefore.length;

          repo.payForCustomer(
            customerId: 'cust_kasee',
            kind: 'BILL',
            amountMinor: 5000,
            billerCode: 'SNEL_KINSHASA',
            accountNumber: '12345678',
          );

          final commissionsAfter = repo.listCommissionsToday();
          final finalCount = commissionsAfter.length;

          expect(finalCount, equals(initialCount)); // No commission row
        });

        test('throws on customer not found', () {
          expect(
            () => repo.payForCustomer(
              customerId: 'cust_nonexistent',
              kind: 'BILL',
              amountMinor: 5000,
              billerCode: 'SNEL_KINSHASA',
              accountNumber: '12345678',
            ),
            throwsA(
              predicate((e) => e.toString().contains('Customer not found')),
            ),
          );
        });
      });

      group('airtime purchase', () {
        test('debits agent float and writes AGENT_ASSISTED_AIRTIME journal', () {
          final floatBefore = repo.floatFor('agent-001');
          final initialFloat = floatBefore['floatCdfMinor'] as int;

          final result = repo.payForCustomer(
            customerId: 'cust_kasee',
            kind: 'AIRTIME',
            amountMinor: 10000, // FC 100.00
            phoneNumber: '+243812345678',
          );

          expect(result['status'], 'POSTED');
          expect(result['kind'], 'AIRTIME');

          final history = repo.getTodayHistory();
          final journal = history.firstWhere(
            (j) => j['id'] == result['journalId'],
          );

          expect(journal['type'], 'AGENT_ASSISTED_AIRTIME');
          
          final metadata = journal['metadata'] as Map<String, dynamic>;
          expect(metadata['phoneNumber'], '+243812345678');

          final floatAfter = repo.floatFor('agent-001');
          final finalFloat = floatAfter['floatCdfMinor'] as int;
          expect(finalFloat, lessThan(initialFloat));
        });

        test('throws on customer not found', () {
          expect(
            () => repo.payForCustomer(
              customerId: 'cust_nonexistent',
              kind: 'AIRTIME',
              amountMinor: 10000,
              phoneNumber: '+243812345678',
            ),
            throwsA(
              predicate((e) => e.toString().contains('Customer not found')),
            ),
          );
        });
      });

      group('fee math', () {
        test('calculates 0.5% fee with min/max bounds for AGENT_ASSISTED_BILL', () {
          // Small amount → min fee (25 minor = FC 0.25)
          final feeSmall = repo.getFee(
            paymentType: 'AGENT_ASSISTED_BILL',
            currency: 'CDF',
            amountMinor: 100, // FC 1.00
          );
          expect(feeSmall['feeMinor'], 25); // Min FC 0.25

          // Medium amount → percentage
          final feeMedium = repo.getFee(
            paymentType: 'AGENT_ASSISTED_BILL',
            currency: 'CDF',
            amountMinor: 10000, // FC 100.00
          );
          expect(feeMedium['feeMinor'], 50); // 0.5% = FC 0.50

          // Large amount → max fee (500000 minor = FC 5000)
          final feeLarge = repo.getFee(
            paymentType: 'AGENT_ASSISTED_BILL',
            currency: 'CDF',
            amountMinor: 500000000, // FC 5,000,000
          );
          expect(feeLarge['feeMinor'], 500000); // Max FC 5,000
        });

        test('calculates 0.5% fee for AGENT_ASSISTED_AIRTIME', () {
          final feeResult = repo.getFee(
            paymentType: 'AGENT_ASSISTED_AIRTIME',
            currency: 'CDF',
            amountMinor: 10000, // FC 100.00
          );
          expect(feeResult['feeMinor'], 50); // 0.5% = FC 0.50
        });
      });
    });
  });
}
