import 'package:flutter_test/flutter_test.dart';
import 'package:agent_mobile/services/offline_agent_repository.dart';

void main() {
  test('agent-001 float matches seed', () {
    final repo = OfflineAgentRepository.createFresh();
    final float = repo.floatFor('agent-001');
    expect(float['floatCdfMinor'], 500000000);
    expect(float['floatUsdMinor'], 200000);
  });
}
