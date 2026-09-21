import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { InMemoryKycStore } from '../../src/common/stores/kyc.store';
import { InMemoryCustomerStore } from '../../src/common/stores/customer.store';
import { InMemoryWalletStore } from '../../src/common/stores/wallet.store';

describe('KYC (e2e)', () => {
  let app: INestApplication;
  let kycStore: InMemoryKycStore;
  let customerStore: InMemoryCustomerStore;
  let walletStore: InMemoryWalletStore;
  let accessToken: string;
  let customerId: string;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    kycStore = moduleRef.get<InMemoryKycStore>(InMemoryKycStore);
    customerStore = moduleRef.get<InMemoryCustomerStore>(InMemoryCustomerStore);
    walletStore = moduleRef.get<InMemoryWalletStore>(InMemoryWalletStore);
  });

  beforeEach(async () => {
    // Clear stores
    kycStore.clear();
    customerStore.clear();
    walletStore.clear();

    // Register a test customer
    const registerRes = await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email: 'kyc-test@example.com',
        password: 'Password1!',
        firstName: 'KYC',
        lastName: 'Tester',
      })
      .expect(201);

    accessToken = registerRes.body.accessToken;
    customerId = registerRes.body.customerId;
  });

  afterAll(async () => {
    await app.close();
  });

  it('submits KYC and admin approves', async () => {
    // Step 1: Submit KYC
    const submitRes = await request(app.getHttpServer())
      .post('/v1/kyc/submissions')
      .set('Authorization', `Bearer ${accessToken}`)
      .field('idNumber', 'ID123456')
      .field('phoneE164', '+243123456789')
      .attach('idDocument', Buffer.from('fake-id-doc'), 'id.jpg')
      .attach('selfie', Buffer.from('fake-selfie'), 'selfie.jpg')
      .expect(201);

    expect(submitRes.body.submissionId).toBeDefined();
    expect(submitRes.body.status).toBe('PENDING_REVIEW');

    const submissionId = submitRes.body.submissionId;

    // Step 2: Verify submission exists in store
    const submission = await kycStore.findById(submissionId);
    expect(submission).toBeDefined();
    expect(submission?.customerId).toBe(customerId);
    expect(submission?.idNumber).toBe('ID123456');
    expect(submission?.status).toBe('PENDING_REVIEW');
    expect(submission?.screeningHit).toBe(false);

    // Step 3: Admin lists pending submissions
    const listRes = await request(app.getHttpServer())
      .get('/v1/admin/kyc/submissions?status=PENDING_REVIEW')
      .set('X-Admin-API-Key', 'dev-admin-key')
      .expect(200);

    expect(listRes.body).toHaveLength(1);
    expect(listRes.body[0].id).toBe(submissionId);

    // Step 4: Admin approves submission
    const approveRes = await request(app.getHttpServer())
      .post(`/v1/admin/kyc/submissions/${submissionId}/decision`)
      .set('X-Admin-API-Key', 'dev-admin-key')
      .send({
        decision: 'APPROVE',
        reason: 'Documents verified',
      })
      .expect(201);

    expect(approveRes.body.submissionId).toBe(submissionId);
    expect(approveRes.body.status).toBe('APPROVED');

    // Step 5: Verify submission was updated
    const updatedSubmission = await kycStore.findById(submissionId);
    expect(updatedSubmission?.status).toBe('APPROVED');
    expect(updatedSubmission?.decision).toBe('APPROVE');
    expect(updatedSubmission?.decisionReason).toBe('Documents verified');
    expect(updatedSubmission?.decidedAt).toBeDefined();
  });

  it('requires authentication for KYC submission', async () => {
    await request(app.getHttpServer())
      .post('/v1/kyc/submissions')
      .field('idNumber', 'ID123456')
      .field('phoneE164', '+243123456789')
      .attach('idDocument', Buffer.from('fake-id-doc'), 'id.jpg')
      .attach('selfie', Buffer.from('fake-selfie'), 'selfie.jpg')
      .expect(401);
  });

  it('requires admin API key for admin endpoints', async () => {
    await request(app.getHttpServer())
      .get('/v1/admin/kyc/submissions?status=PENDING_REVIEW')
      .expect(403);
  });

  it('admin can reject submission', async () => {
    // Submit KYC
    const submitRes = await request(app.getHttpServer())
      .post('/v1/kyc/submissions')
      .set('Authorization', `Bearer ${accessToken}`)
      .field('idNumber', 'ID789012')
      .field('phoneE164', '+243987654321')
      .attach('idDocument', Buffer.from('fake-id-doc'), 'id.jpg')
      .attach('selfie', Buffer.from('fake-selfie'), 'selfie.jpg')
      .expect(201);

    const submissionId = submitRes.body.submissionId;

    // Admin rejects
    const rejectRes = await request(app.getHttpServer())
      .post(`/v1/admin/kyc/submissions/${submissionId}/decision`)
      .set('X-Admin-API-Key', 'dev-admin-key')
      .send({
        decision: 'REJECT',
        reason: 'Unclear documents',
      })
      .expect(201);

    expect(rejectRes.body.status).toBe('REJECTED');

    // Verify rejection
    const submission = await kycStore.findById(submissionId);
    expect(submission?.status).toBe('REJECTED');
    expect(submission?.decision).toBe('REJECT');
    expect(submission?.decisionReason).toBe('Unclear documents');
  });
});
