import { OfflineDemoStore } from './store';

describe('OfflineDemoStore DEM mutations', () => {
  test('approvePending FEE_CHANGE activates pending fee and supersedes current', () => {
    const store = OfflineDemoStore.createFresh();
    const result = store.approvePending('apr_fee_w2w_001', 'APPROVE');
    expect(result.status).toBe('APPROVED');

    const approvals = store.listPendingApprovals();
    const apr = approvals.find((a) => a.id === 'apr_fee_w2w_001');
    expect(apr?.status).toBe('APPROVED');

    const fees = store.listFeeConfigs();
    const pending = fees.find((f) => f.id === 'fee_w2w_pending');
    const current = fees.find((f) => f.id === 'fee_w2w_current');
    expect(pending?.status).toBe('ACTIVE');
    expect(current?.status).toBe('SUPERSEDED');
  });

  test('decideCreditException APPROVE activates loan, schedule, wallet credit, journal', () => {
    const store = OfflineDemoStore.createFresh();
    const before = store.getCustomer360('cust_kasee');
    const cdfBefore = Number(
      before.wallets.find((w) => w.id === 'wal_kasee_cdf')?.availableMinor || 0,
    );

    const result = store.decideCreditException('loan_kasee_exception_001', 'APPROVE');
    expect(result.status).toBe('ACTIVE');
    expect(result.scheduleId).toBeTruthy();

    const loan = store.listCreditExceptions().find((l) => l.id === 'loan_kasee_exception_001')
      || store.getCustomer360('cust_kasee').loans.find((l) => l.id === 'loan_kasee_exception_001');
    expect(loan?.status).toBe('ACTIVE');
    expect(loan?.scheduleId).toBeTruthy();

    const schedule = store.getLoanSchedule(loan!.scheduleId!);
    expect(schedule?.installments?.length).toBeGreaterThan(0);

    const after = store.getCustomer360('cust_kasee');
    const cdfAfter = Number(
      after.wallets.find((w) => w.id === 'wal_kasee_cdf')?.availableMinor || 0,
    );
    expect(cdfAfter).toBe(cdfBefore + 5000000);

    const journals = store.listJournals({ refId: 'loan_kasee_exception_001' });
    expect(journals.length).toBeGreaterThan(0);
    expect(journals[0].direction).toBe('CREDIT');
  });

  test('compensatePayment posts reversing journal and notification', () => {
    const store = OfflineDemoStore.createFresh();
    const paymentId = 'pay_kasee_w2w_001';
    const result = store.compensatePayment(paymentId);
    expect(result.status).toBe('COMPENSATED');

    const payments = store.searchPayments({ customerId: 'cust_kasee' });
    const pay = payments.find((p) => p.id === paymentId);
    expect(pay?.status).toBe('COMPENSATED');

    const journals = store.listJournals({ refId: paymentId });
    const reversing = journals.filter((j) => j.type === 'COMPENSATION' || j.direction === 'CREDIT');
    expect(reversing.length).toBeGreaterThan(0);

    const notes = store.listNotifications({ customerId: 'cust_kasee' });
    expect(notes.some((n) => n.title.toLowerCase().includes('compensat'))).toBe(true);
  });
});
