### Task 1: Seed — Jean-Paul cleanup + payroll roster + exceptions

**Files:**
- Modify: `packages/demo_universe/data/universe.json`
- Modify: Dart embed + assets (regen)
- Create: `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts`

**Interfaces:**
- Produces: single JP customer; at least 6 `emp_poste` employees; salaryHistory; at least 4 PENDING_EXCEPTION loans + matching CREDIT_EXCEPTION pendingApprovals

- [ ] **Step 1: Write failing seed/store tests**

```ts
import { OfflineDemoStore } from './store';

describe('Jean-Paul demo enrichment seed', () => {
  test('single Jean-Paul customer is cust_kasee with jp.kabila@gmail.com', () => {
    const store = OfflineDemoStore.createFresh();
    const jps = store.listCustomers().filter(
      (c) => c.firstName === 'Jean-Paul' && c.lastName === 'Kabila',
    );
    expect(jps).toHaveLength(1);
    expect(jps[0].id).toBe('cust_kasee');
    expect(jps[0].email).toBe('jp.kabila@gmail.com');
    expect(store.listCustomers().some((c) => c.id === 'cust_jp_kabila')).toBe(false);
  });

  test('emp_poste has at least 6 employees', () => {
    const store = OfflineDemoStore.createFresh();
    const poste = store.listEmployers().find((e) => e.id === 'emp_poste');
    expect(poste).toBeTruthy();
    expect((poste!.employees || []).length).toBeGreaterThanOrEqual(6);
  });

  test('at least 4 pending credit exceptions including Jean-Paul', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listCreditExceptions();
    expect(list.length).toBeGreaterThanOrEqual(4);
    expect(list.some((l) => l.customerId === 'cust_kasee' && l.status === 'PENDING_EXCEPTION')).toBe(true);
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.jean-paul-enrichment.test.ts
```

- [ ] **Step 3: Edit universe.json**

1. Delete customer `cust_jp_kabila` and wallets `wal_jp_usd` / `wal_jp_cdf` (and any refs).
2. Confirm `cust_kasee`: Jean-Paul Kabila / `jp.kabila@gmail.com`.
3. Expand `employees` for `emp_poste` to 6-8 rows (keep `emp_row_amina`). Add thin `cust_payroll_*` customers if `customerId` is required for Open 360.
4. Add at least 3 employees for `emp_congo_mining`.
5. Expand `salaryHistory` (at least 3 periods for Amina; 1-2 for others).
6. Add loans `PENDING_EXCEPTION` for Marie + 2 others with `exceptionReason` and principal.
7. Add `pendingApprovals` CREDIT_EXCEPTION rows targeting each new loan id.

- [ ] **Step 4: Regenerate Dart embed** (same pattern as AML Task 1: write `dart/lib/universe_json.dart` from `data/universe.json`; copy to `dart/assets/universe.json`).

- [ ] **Step 5: Run tests — expect PASS** for identity, employee count, exceptions.

- [ ] **Step 6: Commit**

```bash
git add packages/demo_universe apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts
git commit -m "feat(demo): Jean-Paul single identity + rich payroll/exception seed"
```

---
