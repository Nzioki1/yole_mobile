import { OfflineDemoStore } from './store';

describe('OfflineDemoStore propose fee/limit rules', () => {
  test('proposeFeeRule inserts PENDING_APPROVAL fee + FEE_CHANGE approval', () => {
    const store = OfflineDemoStore.createFresh();
    const { fee, approval } = store.proposeFeeRule({
      paymentType: 'W2W',
      feePercent: 0.5,
      minFeeMinor: 50,
      maxFeeMinor: 5000,
      currency: 'USD',
      effectiveFrom: '2026-11-01',
      makerStaffId: 'staff_ops',
      summary: 'Demo lower W2W fee',
    });
    expect(fee.status).toBe('PENDING_APPROVAL');
    expect(fee.paymentType).toBe('W2W');
    expect(approval.type).toBe('FEE_CHANGE');
    expect(approval.targetId).toBe(fee.id);
    expect(approval.status).toBe('PENDING');
    expect(store.listPendingApprovals('PENDING').some((a) => a.id === approval.id)).toBe(true);
  });

  test('approve FEE_CHANGE activates pending and SUPERSEDEs other ACTIVE same paymentType', () => {
    const store = OfflineDemoStore.createFresh();
    const beforeActive = store.listFeeConfigs().filter((f) => f.status === 'ACTIVE' && f.paymentType === 'W2W');
    expect(beforeActive.length).toBeGreaterThanOrEqual(1);
    const { fee, approval } = store.proposeFeeRule({
      paymentType: 'W2W',
      feePercent: 0.5,
      minFeeMinor: 50,
      maxFeeMinor: 5000,
      makerStaffId: 'staff_ops',
    });
    store.approvePending(approval.id, 'APPROVE');
    const fees = store.listFeeConfigs();
    expect(fees.find((f) => f.id === fee.id)?.status).toBe('ACTIVE');
    for (const old of beforeActive) {
      expect(fees.find((f) => f.id === old.id)?.status).toBe('SUPERSEDED');
    }
  });

  test('reject FEE_CHANGE marks pending REJECTED and leaves ACTIVE intact', () => {
    const store = OfflineDemoStore.createFresh();
    const activeId = store.listFeeConfigs().find((f) => f.status === 'ACTIVE' && f.paymentType === 'W2W')!.id;
    const { fee, approval } = store.proposeFeeRule({
      paymentType: 'W2W',
      feePercent: 2,
      minFeeMinor: 100,
      maxFeeMinor: 9000,
    });
    store.approvePending(approval.id, 'REJECT');
    expect(store.listFeeConfigs().find((f) => f.id === fee.id)?.status).toBe('REJECTED');
    expect(store.listFeeConfigs().find((f) => f.id === activeId)?.status).toBe('ACTIVE');
  });

  test('proposeLimitRule + approve LIMIT_CHANGE SUPERSEDEs peer ACTIVE limit', () => {
    const store = OfflineDemoStore.createFresh();
    const peers = store
      .listLimitConfigs()
      .filter((l) => l.status === 'ACTIVE' && l.limitType === 'CUSTOMER_DAILY' && l.currency === 'USD');
    expect(peers.length).toBeGreaterThanOrEqual(1);
    const { limit, approval } = store.proposeLimitRule({
      limitType: 'CUSTOMER_DAILY',
      currency: 'USD',
      dailyLimitMinor: 200000,
      monthlyLimitMinor: 2000000,
      makerStaffId: 'staff_ops',
    });
    expect(limit.status).toBe('PENDING_APPROVAL');
    expect(approval.type).toBe('LIMIT_CHANGE');
    store.approvePending(approval.id, 'APPROVE');
    const limits = store.listLimitConfigs();
    expect(limits.find((l) => l.id === limit.id)?.status).toBe('ACTIVE');
    for (const p of peers) {
      expect(limits.find((l) => l.id === p.id)?.status).toBe('SUPERSEDED');
    }
  });

  test('edit via supersedesId does not mutate ACTIVE until approve', () => {
    const store = OfflineDemoStore.createFresh();
    const active = store.listFeeConfigs().find((f) => f.status === 'ACTIVE' && f.paymentType === 'W2W')!;
    const { fee, approval } = store.proposeFeeRule({
      paymentType: 'W2W',
      feePercent: 0.9,
      minFeeMinor: 100,
      maxFeeMinor: 10000,
      supersedesId: active.id,
      summary: `Supersede ${active.id}`,
    });
    expect(store.listFeeConfigs().find((f) => f.id === active.id)?.status).toBe('ACTIVE');
    expect(fee.id).not.toBe(active.id);
    expect(approval.targetId).toBe(fee.id);
  });

  test('reset clears proposed rules', () => {
    const store = OfflineDemoStore.createFresh();
    const { fee } = store.proposeFeeRule({
      paymentType: 'MNO',
      feePercent: 1.5,
      minFeeMinor: 10,
      maxFeeMinor: 1000,
    });
    store.reset();
    expect(store.listFeeConfigs().some((f) => f.id === fee.id)).toBe(false);
  });
});
