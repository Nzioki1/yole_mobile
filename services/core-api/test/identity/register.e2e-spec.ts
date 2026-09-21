import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { InMemoryCustomerStore } from '../../src/common/stores/customer.store';
import { InMemoryWalletStore } from '../../src/common/stores/wallet.store';
import { InMemoryLedgerStore } from '../../src/common/stores/ledger.store';

describe('Auth - Register (e2e)', () => {
  let app: INestApplication;
  let customerStore: InMemoryCustomerStore;
  let walletStore: InMemoryWalletStore;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    // Get store instances for verification
    customerStore = moduleRef.get<InMemoryCustomerStore>(InMemoryCustomerStore);
    walletStore = moduleRef.get<InMemoryWalletStore>(InMemoryWalletStore);
  });

  beforeEach(() => {
    // Clear stores before each test
    customerStore.clear();
    walletStore.clear();
  });

  afterAll(async () => {
    await app.close();
  });

  it('registers customer and creates CDF+USD pockets', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'ada@example.com',
        password: 'Password1!',
        firstName: 'Ada',
        lastName: 'Lovelace',
      })
      .expect(201);

    expect(res.body.customerId).toBeDefined();
    expect(res.body.accessToken).toBeDefined();

    const customerId = res.body.customerId;

    // Verify customer was created
    const customer = await customerStore.findById(customerId);
    expect(customer).toBeDefined();
    expect(customer?.email).toBe('ada@example.com');
    expect(customer?.firstName).toBe('Ada');
    expect(customer?.lastName).toBe('Lovelace');

    // Verify wallet with CDF and USD pockets was created
    const wallets = await walletStore.findWalletsByCustomerId(customerId);
    expect(wallets).toHaveLength(1);

    const pockets = await walletStore.findPocketsByWalletId(wallets[0].id);
    expect(pockets).toHaveLength(2);

    const currencies = pockets.map((p) => p.currency).sort();
    expect(currencies).toEqual(['CDF', 'USD']);

    // Verify pockets start at 0
    pockets.forEach((pocket) => {
      expect(pocket.ledgerMinor).toBe(0n);
      expect(pocket.blockedMinor).toBe(0n);
      expect(pocket.pendingOutMinor).toBe(0n);
      expect(pocket.pendingInMinor).toBe(0n);
    });
  });

  it('prevents duplicate email registration', async () => {
    await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'duplicate@example.com',
        password: 'Password1!',
        firstName: 'First',
        lastName: 'User',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'duplicate@example.com',
        password: 'DifferentPass1!',
        firstName: 'Second',
        lastName: 'User',
      })
      .expect(409); // Conflict
  });

  it('logs in with correct credentials', async () => {
    // Register a user first
    await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'login@example.com',
        password: 'Password1!',
        firstName: 'Login',
        lastName: 'Test',
      })
      .expect(201);

    // Login
    const res = await request(app.getHttpServer())
      .post('/v1/auth/login')
      .send({
        email: 'login@example.com',
        password: 'Password1!',
      })
      .expect(200);

    expect(res.body.accessToken).toBeDefined();
  });

  it('rejects login with wrong password', async () => {
    await request(app.getHttpServer())
      .post('/v1/auth/login')
      .send({
        email: 'login@example.com',
        password: 'WrongPassword1!',
      })
      .expect(401);
  });
});
