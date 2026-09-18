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
  });
}
