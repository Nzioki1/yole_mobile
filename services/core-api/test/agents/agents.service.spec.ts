import { Test, TestingModule } from '@nestjs/testing';
import { AgentsService } from '../../src/modules/agents/agents.service';
import { AppModule } from '../../src/app.module';
import { InMemoryAgentStore } from '../../src/common/stores/agent.store';
import { InMemoryWalletStore } from '../../src/common/stores/wallet.store';

describe('AgentsService', () => {
  let service: AgentsService;
  let agentStore: InMemoryAgentStore;
  let walletStore: InMemoryWalletStore;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    service = module.get<AgentsService>(AgentsService);
    agentStore = module.get<InMemoryAgentStore>(InMemoryAgentStore);
    walletStore = module.get<InMemoryWalletStore>(InMemoryWalletStore);
  });

  beforeEach(async () => {
    agentStore.clear();
    walletStore.clear();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('enrolls a new agent', async () => {
    const result = await service.enrollAgent({
      firstName: 'Agent',
      lastName: 'One',
      phoneE164: '+243111111111',
      email: 'agent@yole.com',
    });

    expect(result.agentId).toBeDefined();
    expect(result.phoneE164).toBe('+243111111111');
    expect(result.floatWalletId).toBeDefined();

    // Verify float wallet has pockets
    const pockets = await walletStore.findPocketsByWalletId(result.floatWalletId);
    expect(pockets).toHaveLength(2);
    expect(pockets.some((p) => p.currency === 'CDF')).toBe(true);
    expect(pockets.some((p) => p.currency === 'USD')).toBe(true);
  });

  it('agent enrolls a customer', async () => {
    const agent = await service.enrollAgent({
      firstName: 'Agent',
      lastName: 'One',
      phoneE164: '+243111111111',
    });

    const customer = await service.enrollCustomer(agent.agentId, {
      firstName: 'Customer',
      lastName: 'One',
      phoneE164: '+243222222222',
      email: 'customer@example.com',
      password: 'Password1!',
    });

    expect(customer.customerId).toBeDefined();
    expect(customer.walletId).toBeDefined();
  });

  it('cash-in from float to customer', async () => {
    const agent = await service.enrollAgent({
      firstName: 'Agent',
      lastName: 'One',
      phoneE164: '+243111111111',
    });

    const customer = await service.enrollCustomer(agent.agentId, {
      firstName: 'Customer',
      lastName: 'One',
      password: 'Password1!',
    });

    // Add funds to agent float
    const floatPockets = await walletStore.findPocketsByWalletId(agent.floatWalletId);
    const usdPocket = floatPockets.find((p) => p.currency === 'USD');
    await walletStore.updatePocket(usdPocket!.id, {
      ledgerMinor: 100000n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    const result = await service.cashIn(agent.agentId, {
      customerId: customer.customerId,
      amountMinor: 5000n,
      currency: 'USD',
    });

    expect(result.status).toBe('POSTED');
    expect(result.journalId).toBeDefined();
  });
});
