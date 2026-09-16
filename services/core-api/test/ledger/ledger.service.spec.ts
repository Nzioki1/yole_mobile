import { Test, TestingModule } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { LedgerService } from '../../src/modules/ledger/ledger.service';
import { LedgerModule } from '../../src/modules/ledger/ledger.module';

describe('LedgerService', () => {
  let service: LedgerService;
  let prisma: PrismaClient;
  let senderPocketId: string;
  let receiverPocketId: string;

  beforeAll(async () => {
    prisma = new PrismaClient();
    await prisma.$connect();

    // Clean up any existing test data
    await prisma.posting.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.idempotencyRecord.deleteMany();
    await prisma.walletPocket.deleteMany();
    await prisma.wallet.deleteMany();
    await prisma.customer.deleteMany();

    // Set up test data: two customers with USD wallets
    const sender = await prisma.customer.create({
      data: {
        firstName: 'Alice',
        lastName: 'Sender',
        email: 'alice@test.com',
      },
    });

    const receiver = await prisma.customer.create({
      data: {
        firstName: 'Bob',
        lastName: 'Receiver',
        email: 'bob@test.com',
      },
    });

    const senderWallet = await prisma.wallet.create({
      data: {
        customerId: sender.id,
      },
    });

    const receiverWallet = await prisma.wallet.create({
      data: {
        customerId: receiver.id,
      },
    });

    const senderPocket = await prisma.walletPocket.create({
      data: {
        walletId: senderWallet.id,
        currency: 'USD',
        ledgerMinor: 5000n,
      },
    });

    const receiverPocket = await prisma.walletPocket.create({
      data: {
        walletId: receiverWallet.id,
        currency: 'USD',
        ledgerMinor: 0n,
      },
    });

    senderPocketId = senderPocket.id;
    receiverPocketId = receiverPocket.id;
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LedgerModule],
    }).compile();

    service = module.get<LedgerService>(LedgerService);
  });

  afterAll(async () => {
    // Clean up test data
    await prisma.posting.deleteMany();
    await prisma.journalEntry.deleteMany();
    await prisma.idempotencyRecord.deleteMany();
    await prisma.walletPocket.deleteMany();
    await prisma.wallet.deleteMany();
    await prisma.customer.deleteMany();
    await prisma.$disconnect();
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
    const senderPocket = await prisma.walletPocket.findUnique({
      where: { id: senderPocketId },
    });
    const receiverPocket = await prisma.walletPocket.findUnique({
      where: { id: receiverPocketId },
    });

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

    // Verify only one journal entry was created
    const journalCount = await prisma.journalEntry.count({
      where: { idempotencyKey },
    });
    expect(journalCount).toBe(1);
  });

  it('rejects transfer if sender has insufficient available funds', async () => {
    // Sender currently has 4000 - 500 = 3500 ledgerMinor after previous tests
    const senderPocket = await prisma.walletPocket.findUnique({
      where: { id: senderPocketId },
    });
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
