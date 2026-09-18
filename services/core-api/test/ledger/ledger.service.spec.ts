import { Test, TestingModule } from '@nestjs/testing';
import { LedgerService } from '../../src/modules/ledger/ledger.service';
import { LedgerModule } from '../../src/modules/ledger/ledger.module';
import { AppModule } from '../../src/app.module';
import { InMemoryWalletStore } from '../../src/common/stores/wallet.store';
import { InMemoryLedgerStore } from '../../src/common/stores/ledger.store';
import { InMemoryCustomerStore } from '../../src/common/stores/customer.store';

describe('LedgerService', () => {
  let service: LedgerService;
  let walletStore: InMemoryWalletStore;
  let ledgerStore: InMemoryLedgerStore;
  let customerStore: InMemoryCustomerStore;
  let senderPocketId: string;
  let receiverPocketId: string;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    service = module.get<LedgerService>(LedgerService);
    walletStore = module.get<InMemoryWalletStore>(InMemoryWalletStore);
    ledgerStore = module.get<InMemoryLedgerStore>(InMemoryLedgerStore);
    customerStore = module.get<InMemoryCustomerStore>(InMemoryCustomerStore);
  });

  beforeEach(async () => {
    // Clear stores
    walletStore.clear();
    ledgerStore.clear();
    customerStore.clear();

    // Set up test data: two customers with USD wallets
    const sender = await customerStore.create({
      firstName: 'Alice',
      lastName: 'Sender',
      email: 'alice@test.com',
      phoneE164: null,
      passwordHash: 'hash',
      segment: 'retail',
      status: 'active',
      enrolledByAgentId: null,
    });

    const receiver = await customerStore.create({
      firstName: 'Bob',
      lastName: 'Receiver',
      email: 'bob@test.com',
      phoneE164: null,
      passwordHash: 'hash',
      segment: 'retail',
      status: 'active',
      enrolledByAgentId: null,
    });

    const senderWallet = await walletStore.createWallet(sender.id);
    const receiverWallet = await walletStore.createWallet(receiver.id);

    const senderPocket = await walletStore.createPocket({
      walletId: senderWallet.id,
      currency: 'USD',
      ledgerMinor: 5000n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    const receiverPocket = await walletStore.createPocket({
      walletId: receiverWallet.id,
      currency: 'USD',
      ledgerMinor: 0n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    senderPocketId = senderPocket.id;
    receiverPocketId = receiverPocket.id;
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('posts a balanced transfer and updates pocket ledger balances', async () => {
    const result = await service.postJournal({
      idempotencyKey: 'ik-test-1',
      yoleReference: 'YOLE-TEST-1',
      correlationId: 'corr-1',
      actorType: 'customer',
      actorId: 'cust-1',
      currency: 'USD',
      postings: [
        {
          accountCode: 'CUST_WALLET_USD',
          direction: 'debit',
          amountMinor: 1000n,
          currency: 'USD',
          walletPocketId: senderPocketId,
        },
        {
          accountCode: 'CUST_WALLET_USD',
          direction: 'credit',
          amountMinor: 1000n,
          currency: 'USD',
          walletPocketId: receiverPocketId,
        },
      ],
    });

    expect(result.status).toBe('POSTED');
    expect(result.journalId).toBeDefined();

    // Verify pocket balances
    const senderPocket = await walletStore.findPocketById(senderPocketId);
    const receiverPocket = await walletStore.findPocketById(receiverPocketId);

    expect(senderPocket?.ledgerMinor).toBe(4000n); // 5000 - 1000
    expect(receiverPocket?.ledgerMinor).toBe(1000n); // 0 + 1000
  });

  it('returns the same journal for duplicate idempotency key', async () => {
    const idempotencyKey = 'ik-test-2';

    const result1 = await service.postJournal({
      idempotencyKey,
      yoleReference: 'YOLE-TEST-2',
      correlationId: 'corr-2',
      actorType: 'customer',
      actorId: 'cust-2',
      currency: 'USD',
      postings: [
        {
          accountCode: 'CUST_WALLET_USD',
          direction: 'debit',
          amountMinor: 500n,
          currency: 'USD',
          walletPocketId: senderPocketId,
        },
        {
          accountCode: 'CUST_WALLET_USD',
          direction: 'credit',
          amountMinor: 500n,
          currency: 'USD',
          walletPocketId: receiverPocketId,
        },
      ],
    });

    const result2 = await service.postJournal({
      idempotencyKey,
      yoleReference: 'YOLE-TEST-2-DUPLICATE',
      correlationId: 'corr-2-dup',
      actorType: 'customer',
      actorId: 'cust-2',
      currency: 'USD',
      postings: [
        {
          accountCode: 'CUST_WALLET_USD',
          direction: 'debit',
          amountMinor: 9999n, // Different amount, should be ignored
          currency: 'USD',
          walletPocketId: senderPocketId,
        },
        {
          accountCode: 'CUST_WALLET_USD',
          direction: 'credit',
          amountMinor: 9999n,
          currency: 'USD',
          walletPocketId: receiverPocketId,
        },
      ],
    });

    // Should return the same journal ID
    expect(result1.journalId).toBe(result2.journalId);
    expect(result2.status).toBe('POSTED');

    // Verify the same journal was returned
    const journal = await ledgerStore.findJournalByIdempotencyKey(idempotencyKey);
    expect(journal?.id).toBe(result1.journalId);
  });

  it('rejects transfer if sender has insufficient available funds', async () => {
    // Sender currently has 4000 - 500 = 3500 ledgerMinor after previous tests
    const senderPocket = await walletStore.findPocketById(senderPocketId);
    const currentBalance = senderPocket?.ledgerMinor || 0n;

    await expect(
      service.postJournal({
        idempotencyKey: 'ik-test-insufficient',
        yoleReference: 'YOLE-TEST-INSUFFICIENT',
        correlationId: 'corr-insufficient',
        actorType: 'customer',
        actorId: 'cust-1',
        currency: 'USD',
        postings: [
          {
            accountCode: 'CUST_WALLET_USD',
            direction: 'debit',
            amountMinor: currentBalance + 1n, // Try to spend more than available
            currency: 'USD',
            walletPocketId: senderPocketId,
          },
          {
            accountCode: 'CUST_WALLET_USD',
            direction: 'credit',
            amountMinor: currentBalance + 1n,
            currency: 'USD',
            walletPocketId: receiverPocketId,
          },
        ],
      }),
    ).rejects.toThrow(/insufficient.*fund/i);
  });
});
