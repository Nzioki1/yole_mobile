import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from '../../src/modules/payments/payments.service';
import { AppModule } from '../../src/app.module';
import { InMemoryPaymentStore } from '../../src/common/stores/payment.store';
import { InMemoryCustomerStore } from '../../src/common/stores/customer.store';
import { InMemoryWalletStore } from '../../src/common/stores/wallet.store';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let paymentStore: InMemoryPaymentStore;
  let customerStore: InMemoryCustomerStore;
  let walletStore: InMemoryWalletStore;
  let senderCustomerId: string;
  let receiverCustomerId: string;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
    paymentStore = module.get<InMemoryPaymentStore>(InMemoryPaymentStore);
    customerStore = module.get<InMemoryCustomerStore>(InMemoryCustomerStore);
    walletStore = module.get<InMemoryWalletStore>(InMemoryWalletStore);
  });

  beforeEach(async () => {
    paymentStore.clear();
    customerStore.clear();
    walletStore.clear();

    // Create sender
    const sender = await customerStore.create({
      email: 'sender@test.com',
      phoneE164: null,
      firstName: 'Sender',
      lastName: 'Test',
      passwordHash: 'hash',
      segment: 'retail',
      status: 'active',
      enrolledByAgentId: null,
    });
    senderCustomerId = sender.id;

    const senderWallet = await walletStore.createWallet(sender.id);
    await walletStore.createPocket({
      walletId: senderWallet.id,
      currency: 'USD',
      ledgerMinor: 100000n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    // Create receiver
    const receiver = await customerStore.create({
      email: 'receiver@test.com',
      phoneE164: null,
      firstName: 'Receiver',
      lastName: 'Test',
      passwordHash: 'hash',
      segment: 'retail',
      status: 'active',
      enrolledByAgentId: null,
    });
    receiverCustomerId = receiver.id;

    const receiverWallet = await walletStore.createWallet(receiver.id);
    await walletStore.createPocket({
      walletId: receiverWallet.id,
      currency: 'USD',
      ledgerMinor: 0n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('quotes a W2W payment', async () => {
    const result = await service.quote({
      customerId: senderCustomerId,
      type: 'W2W',
      currency: 'USD',
      amountMinor: 5000n,
      metadata: { toCustomerId: receiverCustomerId },
    });

    expect(result.paymentId).toBeDefined();
    expect(result.amountMinor).toBe('5000');
    expect(result.status).toBe('QUOTED');
  });

  it('confirms a W2W payment', async () => {
    const quote = await service.quote({
      customerId: senderCustomerId,
      type: 'W2W',
      currency: 'USD',
      amountMinor: 5000n,
      metadata: { toCustomerId: receiverCustomerId },
    });

    const result = await service.confirm({
      paymentId: quote.paymentId,
      customerId: senderCustomerId,
    });

    expect(result.status).toBe('POSTED');
  });
});
