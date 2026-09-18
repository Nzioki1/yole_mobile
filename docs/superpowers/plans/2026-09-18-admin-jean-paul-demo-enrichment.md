# Jean-Paul Demo Enrichment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Jean-Paul (`cust_kasee` / `jp.kabila@gmail.com`) the single rich demo customer in admin, and enrich Payroll, Credit Exceptions, and Fees & Limits for an offline showcase.

**Architecture:** Seed-first changes in `universe.json` (regenerate Dart embed), fix `OfflineDemoStore.listEmployers` / salary-history projection for payroll UI, expand exception loans + approvals, add propose forms on `/dashboard/config` reusing existing `proposeFeeRule` / `proposeLimitRule`.

**Tech Stack:** Next.js admin_web, TypeScript, Vitest, demo_universe JSON + Dart embed, Color Admin Panels.

**Spec:** `docs/superpowers/specs/2026-09-18-admin-jean-paul-demo-enrichment-design.md`

## Global Constraints

- Canonical customer: `cust_kasee`, email `jp.kabila@gmail.com`, name Jean-Paul Kabila; password `Password1!`
- Remove duplicate `cust_jp_kabila` (+ its wallets); do not leave two Jean-Pauls in Customers
- Jean-Paul stays OPEN/retail — **not** an `employees` row
- Offline-first; session mutations until Reset demo
- Regenerate `packages/demo_universe/dart/lib/universe_json.dart` (+ sync `dart/assets/universe.json` if present) after JSON edits
- Fees & Limits propose must call the **same** store methods as Products (no second engine)
- User-visible brand: Poste Finance
- Do not claim live payroll ingest or live sanctions

## File map

| File | Responsibility |
| --- | --- |
| `packages/demo_universe/data/universe.json` | JP cleanup; employees; salaryHistory; exception loans; approvals |
| `packages/demo_universe/dart/lib/universe_json.dart` | Regenerated embed |
| `packages/demo_universe/dart/assets/universe.json` | Sync copy if present |
| `apps/admin_web/lib/offline/store.ts` | Employer employee projection; `listSalaryHistory` |
| `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts` | Vitest |
| `apps/admin_web/lib/api.ts` | Optional `listSalaryHistory` wrapper |
| `apps/admin_web/app/dashboard/payroll/[id]/page.tsx` | Rich employees + salary history tables |
| `apps/admin_web/app/dashboard/credit-exceptions/page.tsx` | Name column; multi-row queue |
| `apps/admin_web/app/dashboard/config/page.tsx` | Propose fee/limit forms + correct list fields |
| `docs/demo/DEM-SCRIPT.md` | Persona row: Jean-Paul / `jp.kabila@gmail.com` |

---

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

### Task 2: Store — employer employee projection + salary history (TDD)

**Files:**
- Modify: `apps/admin_web/lib/offline/store.ts`
- Modify: `apps/admin_web/lib/api.ts`
- Modify: `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts`

**Interfaces:**
- Produces:
  - `listEmployers()` employees with `employeeId`, `customerId?`, `employeeNumber`, `displayName`, `jobTitle`, `grossSalaryCdfMinor`, `netSalaryCdfMinor`, `eligibleAdvanceMaxCdfMinor`, `status`, plus `salaryMinor`/`currency` aliases for import/credit compatibility
  - `listSalaryHistory(employerId: string)` rows with `displayName`

- [ ] **Step 1: Extend failing tests** for `displayName` on Amina row and `listSalaryHistory('emp_poste')` length >= 3

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement projection in `listEmployers`** and `listSalaryHistory`

- [ ] **Step 4: API wrapper `listSalaryHistory`**

- [ ] **Step 5: Tests PASS → Commit**

```bash
git commit -m "feat(admin): project payroll employees and salary history for offline store"
```

---

### Task 3: Payroll employer detail UI

**Files:**
- Modify: `apps/admin_web/app/dashboard/payroll/[id]/page.tsx`

- [ ] **Step 1: Employees table** — Name | Emp # | Job | Gross CDF | Net CDF | Advance max | Status | Open 360

- [ ] **Step 2: Salary history Panel** via `api.listSalaryHistory(employerId)`

- [ ] **Step 3: Manual check** `:3001/dashboard/payroll/emp_poste`

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(admin): rich payroll employee and salary history tables"
```

---

### Task 4: Credit exceptions UI enrichment

**Files:**
- Modify: `apps/admin_web/lib/offline/store.ts` (`listCreditExceptions` add `customerName`)
- Modify: `apps/admin_web/app/dashboard/credit-exceptions/page.tsx`

- [ ] **Step 1: Enrich `listCreditExceptions`** with `customerName` from customers

- [ ] **Step 2: UI Customer column** (name + id); amount formatted

- [ ] **Step 3: Manual check** — at least 4 rows including Jean-Paul

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(admin): credit exceptions show customer names and richer queue"
```

---

### Task 5: Fees & Limits propose UI on config page

**Files:**
- Modify: `apps/admin_web/app/dashboard/config/page.tsx`

- [ ] **Step 1: Fix list rendering** to store projection fields (`paymentType`, `feePercent`/`value`, `status`, limit minors)

- [ ] **Step 2: Propose fee form** → `api.proposeFeeRule` → message + link `/dashboard/approvals`

- [ ] **Step 3: Propose limit form** → `api.proposeLimitRule`

- [ ] **Step 4: Honesty** — `Offline demo — fee/limit changes are session-only until Reset demo`

- [ ] **Step 5: Manual path** propose → Approvals → Approve → ACTIVE

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(admin): Fees & Limits propose fee/limit for approval"
```

---

### Task 6: DEM script + smoke verify

**Files:**
- Modify: `docs/demo/DEM-SCRIPT.md`

- [ ] **Step 1: Persona row** — Jean-Paul / `jp.kabila@gmail.com` (note `cust_kasee` id)

- [ ] **Step 2: Smoke** customers, 360, payroll, credit-exceptions, config on `:3001`

- [ ] **Step 3: Commit**

```bash
git commit -m "docs(demo): Jean-Paul persona in DEM script"
```

---

## Spec coverage checklist

| Spec requirement | Task |
| --- | --- |
| Single JP / remove duplicate | Task 1 |
| Payroll seed roster + history | Task 1 |
| Employer projection + listSalaryHistory | Task 2 |
| Payroll UI tables | Task 3 |
| At least 4 credit exceptions + names | Task 1 + 4 |
| Fees & Limits propose to approvals | Task 5 |
| DEM script persona | Task 6 |
