import { describe, expect, it } from 'vitest';
import { OfflineDemoStore } from './store';

describe('reset restores credit exception (Task 4 Step 3 evidence)', () => {
  it('approve then reset restores PENDING_EXCEPTION loan', () => {
    const store = OfflineDemoStore.createFresh();
    const before = store.listCreditExceptions().filter((l: any) => l.status === 'PENDING_EXCEPTION');
    expect(before.length).toBeGreaterThan(0);
    const loanId = before[0].id;
    store.decideCreditException(loanId, 'APPROVE');
    const mid = store.listLoans().find((l: any) => l.id === loanId);
    expect(mid?.status).toBe('ACTIVE');
    store.reset();
    const after = store.listCreditExceptions().find((l: any) => l.id === loanId);
    expect(after?.status).toBe('PENDING_EXCEPTION');
  });
});
