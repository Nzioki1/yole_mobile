# Jean-Paul Demo Enrichment — Design Spec

**Date:** 2026-09-18  
**Status:** Approved for implementation (Approach A — seed-first)  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a` (PR #1)  
**Related:** Offline demo universe, DEM-02 / DEM-03 / DEM-04, admin Color Admin shell

## Goal

Make **Jean-Paul Kabila** (`jp.kabila@gmail.com`) the clear demo focus in admin back office, matching the mobile-app login, and enrich **Payroll**, **Credit Exceptions**, and **Fees & Limits** so a live walk looks fully populated offline.

## Locked decisions

1. **Canonical customer:** `cust_kasee` — email `jp.kabila@gmail.com`, display name Jean-Paul Kabila. Password `Password1!`.
2. **Approach A (seed-first):** Enrich `packages/demo_universe/data/universe.json` (+ regenerate Dart embed), fix admin list/detail UIs that mis-map seed shapes, wire Fees & Limits propose → approvals.
3. **Jean-Paul stays OPEN/retail** — not attached to an employer. Payroll hero remains Amina (`cust_amina` @ `emp_poste`).
4. **Offline only** — no live API; mutations session-scoped until Reset demo.
5. **Duplicate removal:** Retire `cust_jp_kabila` and its thin wallets from the seed (or merge references into `cust_kasee`) so Customers / 360 never show two Jean-Pauls.

## Non-goals

- Attaching Jean-Paul to corporate payroll (Approach C)
- Live payroll file ingest / MNO connectors
- Flutter UI redesign beyond any seed email already in use
- Production sanctions or live fee engines

---

## 1. Jean-Paul identity & admin visibility

### Current state

- `cust_kasee` already renamed to Jean-Paul / `jp.kabila@gmail.com` with CDF+USD wallets, payments, and `loan_kasee_exception_001`.
- Duplicate `cust_jp_kabila` / `jkabila@example.cd` with separate wallets confuses directory and 360.

### Spec

| Item | Requirement |
| --- | --- |
| Single identity | Only `cust_kasee` represents Jean-Paul |
| Display | Customers table + Customer 360 title/header show **Jean-Paul Kabila** and `jp.kabila@gmail.com` |
| Deep link | `/dashboard/customers` → Open 360 `?customerId=cust_kasee`; bookmarks/DEM script use Jean-Paul naming |
| 360 content | Wallets, recent payments, loans (incl. exception), cards/cases if already seeded — no empty “Unknown Customer” |
| Cleanup | Remove `cust_jp_kabila` customer + `wal_jp_*` wallets; fix any payment/loan/case refs if they pointed at the duplicate (prefer none) |
| Docs | Update DEM-SCRIPT / talking script persona row: Jean-Paul / `jp.kabila@gmail.com` (keep `cust_kasee` id in technical notes) |

### Acceptance

- Admin Customers lists one Jean-Paul.
- Open 360 for `cust_kasee` shows his wallets and payment trail.
- Mobile login email unchanged.

---

## 2. Payroll — employees + salaries

### Current state

- Seed: one employee (`emp_row_amina`) + 3 salary history rows.
- UI: `/dashboard/payroll` employer cards; `/dashboard/payroll/[id]` table expects import-shaped `{ customerId, salaryMinor, currency }` while `listEmployers()` embeds universe `Employee` (`grossSalaryCdfMinor`, `employeeNumber`, …) — mismatch yields thin/wrong columns.

### Spec

#### Seed

For **`emp_poste` (Poste Demo SARL)** add **6–8** `employees` rows including Amina, with:

- `id`, `employerId`, `customerId` (nullable for demo-only staff without customer app login), `employeeNumber`, `jobTitle`
- `grossSalaryCdfMinor`, `netSalaryCdfMinor`, `eligibleAdvanceMaxCdfMinor`, `status`, `hiredAt`

Add matching **`salaryHistory`** (≥3 periods each for Amina; ≥1–2 periods for others).

For **`emp_congo_mining`**: at least **3** employees + light salary history (so second employer is not empty).

**Do not** add Jean-Paul as an employee.

Optionally add thin `customers` only if an employee needs an Open 360 link; otherwise show name from employee fields without customerId.

#### Store / API

- `listEmployers()` must return employees in a **UI-stable shape**, e.g.:

```ts
{
  customerId?: string;
  employeeId: string;
  employeeNumber: string;
  displayName: string; // from customer or "First Last" / job fallback
  jobTitle: string;
  grossSalaryCdfMinor: number;
  netSalaryCdfMinor: number;
  eligibleAdvanceMaxCdfMinor: number;
  status: string;
  // keep salaryMinor/currency aliases if import path needs them
}
```

- Add `listSalaryHistory(employerId: string)` (or embed `salaryHistory` on employer detail payload) filtered by that employer’s employees.

#### UI (`payroll/[id]/page.tsx`)

1. **Employees** panel table: Name | Emp # | Job | Gross (CDF) | Net (CDF) | Advance max | Status | Action (Open 360 if `customerId`)
2. **Salary history** panel: Period | Employee | Gross | Net | Paid at
3. Keep Import Employees + Credit Salaries
4. Format minors as currency (CDF), not raw import-only `/100` USD assumption

#### Acceptance

- Open Poste Demo SARL → see multi-row employee table and salary history.
- Amina row links to 360.
- Congo Mining shows ≥3 employees.

---

## 3. Credit exceptions — richer queue

### Current state

- One loan: `loan_kasee_exception_001` for Jean-Paul, `PENDING_EXCEPTION`.
- Page lists loans with exception fields; approvals has `apr_loan_exception_001`.

### Spec

#### Seed

Keep Jean-Paul’s exception loan.

Add **3–4** additional `PENDING_EXCEPTION` loans, e.g.:

| Loan id (example) | Customer | Notes |
| --- | --- | --- |
| `loan_kasee_exception_001` | Jean-Paul (`cust_kasee`) | Keep — above auto threshold |
| `loan_marie_exception_001` | Marie (`cust_marie_tshala`) | New or reuse; KYC may be PENDING_REVIEW — still show exception |
| `loan_*_exception_*` | 2–3 more (new thin customers or existing) | Distinct `exceptionReason`, principal amounts |

Each needs:

- `status: PENDING_EXCEPTION`
- `exceptionReason` (human-readable)
- Linked `pendingApprovals` row type `CREDIT_EXCEPTION` where the approve path expects it
- Optional schedule stub created only on approve (existing `decideCreditException` behavior)

#### UI

- Columns: Customer name | Loan id | Amount | Reason | Status | Actions
- Resolve display name from `customers` by `customerId`
- Empty state only when queue truly empty

#### Acceptance

- Credit Exceptions shows **≥4** pending rows including Jean-Paul.
- Approve Jean-Paul’s row still activates loan + schedule (existing behavior).
- Reset demo restores pending set.

---

## 4. Fees & Limits — create and submit for approval

### Current state

- `feeLimits` seed has ACTIVE fees/limits + one PENDING fee.
- **Products & rules** already has propose fee/limit → `PENDING_APPROVAL` + Approvals queue.
- **Fees & Limits** (`/dashboard/config`) is read-only and field mapping (`feeType` / `dailyLimit`) may not match store projection.

### Spec

#### Behavior

1. `/dashboard/config` lists ACTIVE (+ optional PENDING badge) fees and limits using store `listFeeConfigs` / `listLimitConfigs` fields correctly.
2. Forms on the same page:
   - **Propose fee:** paymentType, feePercent, min/max minor, currency, effectiveFrom → `api.proposeFeeRule`
   - **Propose limit:** limitType, currency, daily/monthly minor, effectiveFrom → `api.proposeLimitRule`
3. On success: toast/message with approval id + link to `/dashboard/approvals`.
4. Approvals Approve activates rule and SUPERSEDEs peers (existing store logic).
5. Products page propose UI remains; both surfaces share the same store methods (no duplicate engines).

#### Honesty

Optional small note on config page: `Offline demo — fee/limit changes are session-only until Reset demo`.

#### Acceptance

- From Fees & Limits, propose a fee → appears in Approvals → Approve → ACTIVE in list.
- Same for a limit change.
- Reset demo restores seed feeLimits + pendingApprovals.

---

## 5. Implementation notes

| Area | Files (expected) |
| --- | --- |
| Seed | `packages/demo_universe/data/universe.json`, `ts/types.ts` if needed, Dart embed regen |
| Store | `apps/admin_web/lib/offline/store.ts` (+ focused vitest) |
| API | `apps/admin_web/lib/api.ts` if new listSalaryHistory wrapper |
| UI | `payroll/[id]/page.tsx`, `credit-exceptions/page.tsx`, `config/page.tsx` |
| Docs | `docs/demo/DEM-SCRIPT.md` persona row; optional talking-script note |

Prefer TDD for store mapping / propose paths that change behavior.

## 6. Spec coverage checklist

| Requirement | Section |
| --- | --- |
| Single Jean-Paul / mobile email | §1 |
| Rich payroll employees + salaries | §2 |
| More credit exception users | §3 |
| Fees & Limits create → approval | §4 |
| Offline / reset | Locked + §4 |
| No JP corporate attach | Non-goals |

