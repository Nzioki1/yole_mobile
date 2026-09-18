import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { InMemoryPaymentStore } from '../../src/common/stores/payment.store';
import { InMemoryCustomerStore } from '../../src/common/stores/customer.store';
import { InMemoryWalletStore } from '../../src/common/stores/wallet.store';

describe('Payments (e2e)', () => {
  let app: INestApplication;
  let paymentStore: InMemoryPaymentStore;
  let customerStore: InMemoryCustomerStore;
  let walletStore: InMemoryWalletStore;
  let accessToken: string;
  let customerId: string;
  let receiverCustomerId: string;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    paymentStore = moduleRef.get<InMemoryPaymentStore>(InMemoryPaymentStore);
    customerStore = moduleRef.get<InMemoryCustomerStore>(InMemoryCustomerStore);
    walletStore = moduleRef.get<InMemoryWalletStore>(InMemoryWalletStore);
  });

  beforeEach(async () => {
    // Clear stores
    paymentStore.clear();
    customerStore.clear();
    walletStore.clear();

    // Register sender
    const senderRes = await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'sender@example.com',
        password: 'Password1!',
        firstName: 'Sender',
        lastName: 'User',
      })
      .expect(201);

    accessToken = senderRes.body.accessToken;
    customerId = senderRes.body.customerId;

    // Register receiver
    const receiverRes = await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'receiver@example.com',
        password: 'Password1!',
        firstName: 'Receiver',
        lastName: 'User',
      })
      .expect(201);

    receiverCustomerId = receiverRes.body.customerId;

    // Add funds to sender's USD pocket
    const senderWallets = await walletStore.findWalletsByCustomerId(customerId);
    const senderPockets = await walletStore.findPocketsByWalletId(senderWallets[0].id);
    const usdPocket = senderPockets.find((p) => p.currency === 'USD');
    if (!usdPocket) {
      throw new Error('USD pocket not found for sender');
    }
    await walletStore.updatePocket(usdPocket.id, { 
      ledgerMinor: 100000n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('quotes and confirms W2W payment', async () => {
    // Step 1: Quote
    const quoteRes = await request(app.getHttpServer())
      .post('/v1/payments/quote')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'W2W',
        currency: 'USD',
        amountMinor: '5000',
        metadata: { toCustomerId: receiverCustomerId },
      })
      .expect(200);

    expect(quoteRes.body.paymentId).toBeDefined();
    expect(quoteRes.body.amountMinor).toBe('5000');
    expect(quoteRes.body.feeMinor).toBeDefined();
    expect(quoteRes.body.status).toBe('QUOTED');

    const paymentId = quoteRes.body.paymentId;

    // Step 2: Confirm
    const confirmRes = await request(app.getHttpServer())
      .post('/v1/payments/confirm')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ paymentId })
      .expect(200);

    expect(confirmRes.body.status).toBe('POSTED');

    // Step 3: Verify balances
    const senderWallets = await walletStore.findWalletsByCustomerId(customerId);
    const senderPockets = await walletStore.findPocketsByWalletId(senderWallets[0].id);
    const senderUsd = senderPockets.find((p) => p.currency === 'USD');

    const receiverWallets = await walletStore.findWalletsByCustomerId(receiverCustomerId);
    const receiverPockets = await walletStore.findPocketsByWalletId(receiverWallets[0].id);
    const receiverUsd = receiverPockets.find((p) => p.currency === 'USD');

    // Sender should be debited total (amount + fee)
    expect(senderUsd!.ledgerMinor).toBeLessThan(100000n);
    // Receiver should be credited amount only
    expect(receiverUsd!.ledgerMinor).toBe(5000n);
  });

  it('quotes and confirms MNO_OUT payment', async () => {
    const quoteRes = await request(app.getHttpServer())
      .post('/v1/payments/quote')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'MNO_OUT',
        currency: 'USD',
        amountMinor: '3000',
        metadata: { phoneE164: '+243123456789' },
      })
      .expect(200);

    const paymentId = quoteRes.body.paymentId;

    const confirmRes = await request(app.getHttpServer())
      .post('/v1/payments/confirm')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ paymentId })
      .expect(200);

    expect(confirmRes.body.status).toBe('POSTED');
    expect(confirmRes.body.externalRef).toContain('MNO-OUT-');
  });

  it('quotes and confirms BILL payment', async () => {
    const quoteRes = await request(app.getHttpServer())
      .post('/v1/payments/quote')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'BILL',
        currency: 'USD',
        amountMinor: '2000',
        metadata: {
          billerId: 'JIRAMA',
          accountNumber: '123456',
        },
      })
      .expect(200);

    const paymentId = quoteRes.body.paymentId;

    const confirmRes = await request(app.getHttpServer())
      .post('/v1/payments/confirm')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ paymentId })
      .expect(200);

    expect(confirmRes.body.status).toBe('POSTED');
    expect(confirmRes.body.externalRef).toContain('BILL-');
  });

  it('lists customer payments', async () => {
    // Create a payment first
    const quoteRes = await request(app.getHttpServer())
      .post('/v1/payments/quote')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'W2W',
        currency: 'USD',
        amountMinor: '1000',
        metadata: { toCustomerId: receiverCustomerId },
      })
      .expect(200);

    // List payments
    const listRes = await request(app.getHttpServer())
      .get('/v1/payments')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(Array.isArray(listRes.body)).toBe(true);
    expect(listRes.body.length).toBeGreaterThan(0);
  });
});
