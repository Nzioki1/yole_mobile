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
        expect(wallet, containsKey('availableMinor'));
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
  });
}
