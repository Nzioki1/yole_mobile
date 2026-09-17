# Products Fee/Limit Rules (Maker-Checker) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let staff create/edit fee and limit rules on `/dashboard/products` as `PENDING_APPROVAL` proposals that activate only via Pending approvals (maker-checker).

**Architecture:** Add `proposeFeeRule` / `proposeLimitRule` on `OfflineDemoStore` (insert pending `feeLimits` + `pendingApprovals`). Extend `approvePending` with `LIMIT_CHANGE` (mirror FEE_CHANGE supersede). Wire offline `api` methods. Upgrade Products page with create forms + Edit on ACTIVE rows. Approvals page already calls `approvePending` — no UI change if new PENDING rows appear in `listPendingApprovals()`.

**Tech Stack:** Next.js 15 admin_web, TypeScript, Vitest, Color Admin Panel, offline demo store.

**Spec:** `docs/superpowers/specs/2026-09-17-admin-products-fee-limit-rules-design.md`

## Global Constraints

- Offline-first (`NEXT_PUBLIC_OFFLINE_DEMO=true`); no `:3000` dependency for this feature.
- Propose must **not** mutate ACTIVE rows; Approve activates and SUPERSEDEs peers.
- Fee approval type: `FEE_CHANGE`. Limit approval type: `LIMIT_CHANGE`.
- Pending fee/limit status: `PENDING_APPROVAL` until Approve → `ACTIVE` or Reject → `REJECTED`.
- Session only until **Reset demo**; no `universe.json` write-back.
- Do **not** add product catalog create/edit.
- Leave legacy `createFeeConfig` (ACTIVE insert) intact for Config/legacy.
- Roles: no RBAC change required (Products/Approvals already ADMIN/OPS/FINANCE).
- User-visible brand: Poste Finance.

## File map

| File | Responsibility |
| --- | --- |
| `apps/admin_web/lib/offline/store.ts` | `proposeFeeRule`, `proposeLimitRule`, LIMIT_CHANGE in `approvePending` |
| `apps/admin_web/lib/offline/store.fee-limit-propose.test.ts` | Vitest for propose + approve/reject |
| `apps/admin_web/lib/api.ts` | Offline `proposeFeeRule` / `proposeLimitRule` |
| `apps/admin_web/app/dashboard/products/page.tsx` | Create + Edit UI |
| `docs/demo/DEM-SCRIPT.md` | Optional DEM-02 one-liner (fold into Task 3) |

---

### Task 1: Store propose + LIMIT_CHANGE approve (TDD)

**Files:**
- Create: `apps/admin_web/lib/offline/store.fee-limit-propose.test.ts`
- Modify: `apps/admin_web/lib/offline/store.ts` (after `createFeeConfig` ~359–375; `approvePending` ~588–620)
- Test: `apps/admin_web/lib/offline/store.fee-limit-propose.test.ts`

**Interfaces:**
- Consumes: `OfflineDemoStore.createFresh()`, `approvePending`, `listFeeConfigs`, `listLimitConfigs`, `listPendingApprovals`
- Produces:
  - `proposeFeeRule(data): { fee: ReturnType<feeForAdmin>; approval: PendingApproval }`
  - `proposeLimitRule(data): { limit: ReturnType<limitForAdmin>; approval: PendingApproval }`
  - `approvePending` handles `LIMIT_CHANGE`

- [ ] **Step 1: Write failing tests**

```ts
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
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.fee-limit-propose.test.ts
```

Expected: FAIL (methods missing / LIMIT_CHANGE unimplemented).

- [ ] **Step 3: Implement store methods**

Add after `createFeeConfig`:

```ts
proposeFeeRule(data: {
  paymentType: string;
  feePercent: number;
  minFeeMinor: number;
  maxFeeMinor: number;
  currency?: string;
  effectiveFrom?: string;
  summary?: string;
  makerStaffId?: string;
  supersedesId?: string;
}) {
  const id = `fee_demo_${Date.now()}`;
  const effectiveFrom = data.effectiveFrom || new Date().toISOString().slice(0, 10);
  const paymentType = String(data.paymentType || 'W2W');
  const row: FeeLimit = {
    id,
    kind: 'FEE',
    paymentType,
    feePercent: Number(data.feePercent ?? 0),
    minFeeMinor: Number(data.minFeeMinor ?? 0),
    maxFeeMinor: Number(data.maxFeeMinor ?? 0),
    currency: String(data.currency || 'USD'),
    effectiveFrom,
    status: 'PENDING_APPROVAL',
  };
  this.u.feeLimits.push(row);
  const approval: PendingApproval = {
    id: `apr_fee_${Date.now()}`,
    type: 'FEE_CHANGE',
    targetId: id,
    summary:
      data.summary ||
      `Propose ${paymentType} fee ${row.feePercent}% effective ${effectiveFrom}` +
        (data.supersedesId ? ` (supersedes ${data.supersedesId})` : ''),
    makerStaffId: data.makerStaffId || 'staff_admin',
    status: 'PENDING',
    createdAt: nowIso(),
  };
  this.u.pendingApprovals.push(approval);
  return { fee: feeForAdmin(row), approval };
}

proposeLimitRule(data: {
  limitType: string;
  currency: string;
  dailyLimitMinor: number;
  monthlyLimitMinor: number;
  effectiveFrom?: string;
  summary?: string;
  makerStaffId?: string;
  supersedesId?: string;
}) {
  const id = `lim_demo_${Date.now()}`;
  const effectiveFrom = data.effectiveFrom || new Date().toISOString().slice(0, 10);
  const limitType = String(data.limitType || 'CUSTOMER_DAILY');
  const currency = String(data.currency || 'USD');
  const row: FeeLimit = {
    id,
    kind: 'LIMIT',
    limitType,
    currency,
    dailyLimitMinor: Number(data.dailyLimitMinor ?? 0),
    monthlyLimitMinor: Number(data.monthlyLimitMinor ?? 0),
    effectiveFrom,
    status: 'PENDING_APPROVAL',
  };
  this.u.feeLimits.push(row);
  const approval: PendingApproval = {
    id: `apr_lim_${Date.now()}`,
    type: 'LIMIT_CHANGE',
    targetId: id,
    summary:
      data.summary ||
      `Propose ${limitType} ${currency} limits effective ${effectiveFrom}` +
        (data.supersedesId ? ` (supersedes ${data.supersedesId})` : ''),
    makerStaffId: data.makerStaffId || 'staff_admin',
    status: 'PENDING',
    createdAt: nowIso(),
  };
  this.u.pendingApprovals.push(approval);
  return { limit: limitForAdmin(row), approval };
}
```

Inside `approvePending`, after the FEE_CHANGE block, add:

```ts
if (apr.type === 'LIMIT_CHANGE') {
  const pendingLimit = this.u.feeLimits.find((f) => f.id === apr.targetId);
  if (pendingLimit) {
    if (approved) {
      for (const f of this.u.feeLimits) {
        if (
          f.kind === 'LIMIT' &&
          f.limitType === pendingLimit.limitType &&
          f.currency === pendingLimit.currency &&
          f.id !== pendingLimit.id &&
          f.status === 'ACTIVE'
        ) {
          f.status = 'SUPERSEDED';
        }
      }
      pendingLimit.status = 'ACTIVE';
    } else {
      pendingLimit.status = 'REJECTED';
    }
  }
}
```

- [ ] **Step 4: Run — expect PASS**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.fee-limit-propose.test.ts
```

- [ ] **Step 5: Commit**

```bash
git add apps/admin_web/lib/offline/store.ts apps/admin_web/lib/offline/store.fee-limit-propose.test.ts
git commit -m "feat(admin): propose fee/limit rules with LIMIT_CHANGE approve"
```

---

### Task 2: API offline wrappers

**Files:**
- Modify: `apps/admin_web/lib/api.ts` (near `createFeeConfig` ~201)

**Interfaces:**
- Consumes: store `proposeFeeRule` / `proposeLimitRule`
- Produces: `api.proposeFeeRule`, `api.proposeLimitRule`

- [ ] **Step 1: Add methods**

```ts
async proposeFeeRule(data: {
  paymentType: string;
  feePercent: number;
  minFeeMinor: number;
  maxFeeMinor: number;
  currency?: string;
  effectiveFrom?: string;
  summary?: string;
  makerStaffId?: string;
  supersedesId?: string;
}) {
  if (OFFLINE_DEMO) return this.store().proposeFeeRule(data);
  throw new Error('proposeFeeRule is only available in offline demo');
}

async proposeLimitRule(data: {
  limitType: string;
  currency: string;
  dailyLimitMinor: number;
  monthlyLimitMinor: number;
  effectiveFrom?: string;
  summary?: string;
  makerStaffId?: string;
  supersedesId?: string;
}) {
  if (OFFLINE_DEMO) return this.store().proposeLimitRule(data);
  throw new Error('proposeLimitRule is only available in offline demo');
}
```

- [ ] **Step 2: Sanity vitest**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.fee-limit-propose.test.ts lib/offline/store.mutations.test.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add apps/admin_web/lib/api.ts
git commit -m "feat(admin): offline API for proposeFeeRule and proposeLimitRule"
```

---

### Task 3: Products page create + edit UI

**Files:**
- Modify: `apps/admin_web/app/dashboard/products/page.tsx`
- Optional: `docs/demo/DEM-SCRIPT.md` DEM-02 note

**Interfaces:**
- Consumes: `api.proposeFeeRule`, `api.proposeLimitRule`, `api.listProducts/listFeeConfigs/listLimitConfigs`, `authService.getCurrentUser` for `makerStaffId`

- [ ] **Step 1: Extend Products page**

Keep existing product table. Add:

1. Helper paragraph about Pending approvals + Reset.
2. State: `showFeeForm`, `showLimitForm`, `editingFee`, `editingLimit`, form fields, `message`/`error`.
3. **+ Fee rule** / **+ Limit rule** buttons; Edit on ACTIVE fee/limit rows only.
4. On submit fee:

```ts
await api.proposeFeeRule({
  ...feeForm,
  feePercent: Number(feeForm.feePercent),
  minFeeMinor: Number(feeForm.minFeeMinor),
  maxFeeMinor: Number(feeForm.maxFeeMinor),
  makerStaffId: authService.getCurrentUser()?.id,
  supersedesId: editingFee?.id,
});
```

Then reload lists.

5. Fee form fields: paymentType select (W2W/MNO/BANK/BILL), feePercent, minFeeMinor, maxFeeMinor, currency (USD/CDF), effectiveFrom (date input).
6. Limit form: limitType (default CUSTOMER_DAILY), currency, dailyLimitMinor, monthlyLimitMinor, effectiveFrom.
7. Fee/limit tables: show status badge (reuse existing fee badge pattern on limits too); Add **Edit** button when `status === 'ACTIVE'`.

Mirror Agents/Users Panel form styling (`btn btn-theme`, `form-control`, `form-select`).

Full page may be rewritten in place; preserve the products list Panel unchanged.

- [ ] **Step 2: Optional DEM-SCRIPT**

Under DEM-02, add: “Optional: Products → + Fee rule → Pending approvals Approve.”

- [ ] **Step 3: Manual acceptance** (Mac `:3001`)

1. Login admin → Products → + Fee rule → see PENDING_APPROVAL in fee table.
2. Approvals → Approve → fee ACTIVE; prior W2W ACTIVE SUPERSEDED.
3. Edit ACTIVE → new pending; Reject → ACTIVE unchanged.
4. Same for a limit.
5. Reset demo → proposals gone.

- [ ] **Step 4: Commit + push when asked**

```bash
git add apps/admin_web/app/dashboard/products/page.tsx docs/demo/DEM-SCRIPT.md
git commit -m "feat(admin): create and edit fee/limit rules on Products page"
```

---

## Spec coverage checklist

| Spec requirement | Task |
| --- | --- |
| proposeFeeRule + approval | Task 1 |
| proposeLimitRule + LIMIT_CHANGE | Task 1 |
| Approve supersede / Reject | Task 1 |
| Edit = supersedesId clone | Task 1 + 3 |
| api offline | Task 2 |
| Products UI forms + Edit | Task 3 |
| No product catalog CRUD | Global |
| Reset clears | Task 1 test |

## Placeholder / consistency scan

- Method names: `proposeFeeRule`, `proposeLimitRule`, `LIMIT_CHANGE` — consistent across tasks.
- No TBD left in steps.
