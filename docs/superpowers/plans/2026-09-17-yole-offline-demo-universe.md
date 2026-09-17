# YOLE Offline Demo Universe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a shared offline demo universe so admin, customer, and agent apps walk Poste Finance DEM-01…DEM-12 with zero calls to `core-api`.

**Architecture:** Single `packages/demo_universe` JSON graph + language loaders. Each app uses an offline store/repository behind existing service shapes when `OFFLINE_DEMO` is on. Session-local mutations; reset reloads seed. Thin new admin shells for DEM gaps; MOCK/Offline honesty banners.

**Tech Stack:** Next.js 14 admin (`apps/admin_web`), Flutter customer (repo root), Flutter agent (`apps/agent_mobile`), shared JSON in `packages/demo_universe`, TypeScript + Dart loaders. No Postgres; `services/core-api` left unused while offline.

**Spec:** `docs/superpowers/specs/2026-09-17-yole-offline-demo-universe-design.md`  
**Audit:** `docs/audits/2026-09-17-poste-finance-rfp-coverage-audit.md`  
**Repo / branch:** `Nzioki1/yole_mobile` on `cursor/task1-monorepo-scaffold-1d8a` (PR #1) unless user opens a new branch.

## Global Constraints

- With offline flags on, clients **never** `fetch`/`dio`/`http` to `localhost:3000` or any API base URL.
- Shared entity IDs are mandatory (`cust_kasee`, `cust_amina`, `agent-001`, `emp_poste`, journal/loan/payment IDs stable across apps).
- Cards / DEM-07 must show **MOCK — not Visa/Mastercard certified**; DEM-10 must show **DEMO STORYBOARD — not a live HA failover**; global **Offline demo — no live API** badge.
- Prior `apps/admin_web/lib/demo-seed.ts` must be **migrated into** the shared universe (not a second source of truth).
- Staff passwords remain `Password1!` for seeded staff; do not invent production secrets.
- Ask before destructive scope expansion; prefer drafts on PR #1.
- Acceptance = API process **stopped** + all three apps still walk DEM-01…DEM-12.
- **Cross-app live sync is YAGNI:** pre-seed all cross-channel events in `universe.json`. In-app mutations are per-app session only.

## File map

| Area | Paths |
| --- | --- |
| Shared universe | `packages/demo_universe/data/universe.json`, `packages/demo_universe/ts/*`, `packages/demo_universe/dart/*`, `packages/demo_universe/README.md` |
| Workspace | `pnpm-workspace.yaml` (already includes `packages/*`) |
| Admin offline | `apps/admin_web/lib/offline/store.ts`, `apps/admin_web/lib/offline/flags.ts`, `apps/admin_web/lib/api.ts`, `apps/admin_web/.env.local` |
| Admin shells | `apps/admin_web/app/dashboard/products/page.tsx`, `approvals/page.tsx`, `credit-exceptions/page.tsx`, `idempotency/page.tsx`, `remittance/page.tsx`, `resilience/page.tsx`, `export/page.tsx`; enrich `recon`, `cases`, `customer360`, `cards` |
| Admin chrome | `apps/admin_web/components/sidebar/Sidebar.tsx`, `components/header/Header.tsx` |
| Customer offline | `lib/services/offline_demo_repository.dart`, wire `core_api_service.dart` / `core_auth_service.dart` |
| Agent offline | `apps/agent_mobile/lib/services/offline_agent_repository.dart`, wire `agent_api_service.dart` |
| Docs | `docs/demo/DEM-SCRIPT.md`, `README_APPS.md`, pointer in `user_journey.md` |

## End-state definition of done

1. `NEXT_PUBLIC_OFFLINE_DEMO=true` + Flutter `--dart-define=OFFLINE_DEMO=true`; core-api stopped; no network errors in demos.
2. Shared IDs: admin Customer 360 for `cust_kasee` matches customer Flutter home balances (from same seed).
3. DEM-01…DEM-12 each have a documented click-path; thin shells exist for DEM-02/04/05/08/09/10/11/12.
4. Reset demo restores seed state in that app session.
5. Export pack downloads non-empty JSON from the universe.
6. Honesty banners visible on cards, resilience, and header.

---

### Task 1: Shared `demo_universe` package + seed graph

**Files:**
- Create: `packages/demo_universe/package.json`
- Create: `packages/demo_universe/data/universe.json`
- Create: `packages/demo_universe/ts/types.ts`
- Create: `packages/demo_universe/ts/load.ts`
- Create: `packages/demo_universe/ts/index.ts`
- Create: `packages/demo_universe/ts/load.test.ts`
- Create: `packages/demo_universe/dart/pubspec.yaml`
- Create: `packages/demo_universe/dart/lib/demo_universe.dart`
- Create: `packages/demo_universe/README.md`

**Interfaces:**
- Consumes: none
- Produces: `Universe` type; `loadUniverse(): Universe` (deep clone); Dart `DemoUniverse.load()` reading the same JSON asset

- [ ] **Step 1: Write failing loader test**

```ts
import { loadUniverse } from './load';

test('loadUniverse returns cust_kasee with CDF+USD wallets and linked journals', () => {
  const u = loadUniverse();
  expect(u.customers.find((c) => c.id === 'cust_kasee')).toBeTruthy();
  const wallets = u.wallets.filter((w) => w.customerId === 'cust_kasee');
  expect(wallets.map((w) => w.currency).sort()).toEqual(['CDF', 'USD']);
  expect(u.journals.some((j) => j.customerId === 'cust_kasee')).toBe(true);
  expect(u.agents.some((a) => a.id === 'agent-001')).toBe(true);
  expect(u.employers.some((e) => e.id === 'emp_poste')).toBe(true);
  expect(u.loans.some((l) => l.status === 'ACTIVE' && l.scheduleId)).toBe(true);
  expect(u.loans.some((l) => l.status === 'PENDING_EXCEPTION')).toBe(true);
  expect(u.pendingApprovals.length).toBeGreaterThan(0);
  expect(u.cases.some((c) => c.type === 'AML' && c.confidential === true)).toBe(true);
});
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `cd packages/demo_universe && pnpm exec vitest run ts/load.test.ts`  
(Add vitest as package devDependency if the monorepo has no runner.)

Expected: FAIL (module / file missing)

- [ ] **Step 3: Author `universe.json` with must-link seed**

Required IDs: staff (`admin@yole.com` etc., password `Password1!`), `cust_kasee`, `cust_amina` (`amina.payroll@yole.com`), wallets CDF/USD, `agent-001`, `emp_poste`, journals, payments (W2W/MNO/BANK/BILL with `journalId`), employees + salary history for Amina, loans (ACTIVE+schedule, PENDING_EXCEPTION), cards VIRTUAL_DEBIT, cardAuths mock 3DS, remittances CLEAR + SCREENING_HIT, fxRates/conversions, products, feeLimits, pendingApprovals, AML confidential case + card dispute, reconDays with exceptions + eodSnapshot, kyc, notifications, `meta.demBookmarks`.

Migrate rows from `apps/admin_web/lib/demo-seed.ts` into this JSON where IDs already align.

Minimal wallet/customer shape:

```json
{
  "meta": { "version": 1, "name": "yole-poste-offline-demo" },
  "customers": [
    { "id": "cust_kasee", "email": "kasee.demo@yole.com", "password": "Password1!", "firstName": "Kasee", "lastName": "Demo", "segment": "OPEN", "kycStatus": "APPROVED" },
    { "id": "cust_amina", "email": "amina.payroll@yole.com", "password": "Password1!", "firstName": "Amina", "lastName": "Payroll", "segment": "CORPORATE", "employerId": "emp_poste", "kycStatus": "APPROVED" }
  ],
  "wallets": [
    { "id": "wal_kasee_cdf", "customerId": "cust_kasee", "currency": "CDF", "availableMinor": 25000000, "ledgerMinor": 25000000, "blockedMinor": 0, "pendingMinor": 0 },
    { "id": "wal_kasee_usd", "customerId": "cust_kasee", "currency": "USD", "availableMinor": 15000, "ledgerMinor": 15000, "blockedMinor": 0, "pendingMinor": 500 }
  ],
  "agents": [{ "id": "agent-001", "name": "Kinshasa Agent 1", "floatCdfMinor": 500000000, "floatUsdMinor": 200000, "status": "ACTIVE" }],
  "employers": [{ "id": "emp_poste", "name": "Poste Demo SARL", "taxId": "CD-POSTE-001" }]
}
```

- [ ] **Step 4: Implement TS loader**

```ts
import raw from '../data/universe.json';
import type { Universe } from './types';

export function loadUniverse(): Universe {
  return structuredClone(raw) as Universe;
}
```

Dart package declares asset `../data/universe.json` (or copies JSON into `dart/assets/universe.json` kept in sync — prefer one file via path asset).

- [ ] **Step 5: Re-run test — expect PASS**

- [ ] **Step 6: Commit**

```bash
git add packages/demo_universe
git commit -m "feat(demo-universe): shared offline seed graph and loaders"
```

---

### Task 2: Admin OfflineDemoStore + hard offline API path

**Files:**
- Create: `apps/admin_web/lib/offline/flags.ts`
- Create: `apps/admin_web/lib/offline/store.ts`
- Create: `apps/admin_web/lib/offline/store.test.ts`
- Modify: `apps/admin_web/lib/api.ts`
- Modify: `apps/admin_web/app/login/page.tsx`
- Modify: `apps/admin_web/.env.local` (`NEXT_PUBLIC_OFFLINE_DEMO=true`)
- Modify: `apps/admin_web/package.json` (workspace dep on `demo_universe`)
- Migrate: `apps/admin_web/lib/demo-seed.ts` → re-export from universe or delete after move

**Interfaces:**
- Consumes: `loadUniverse()`
- Produces: `OfflineDemoStore` + `getOfflineStore()` with methods mirroring `AdminApiClient` plus `reset()`

- [ ] **Step 1: Failing test**

```ts
import { OfflineDemoStore } from './store';

test('offline store customer360 for cust_kasee has dual wallets', () => {
  const store = OfflineDemoStore.createFresh();
  const c360 = store.getCustomer360('cust_kasee');
  expect(c360.customer.id).toBe('cust_kasee');
  expect(c360.wallets).toHaveLength(2);
});
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement flag + store**

```ts
export const OFFLINE_DEMO = process.env.NEXT_PUBLIC_OFFLINE_DEMO === 'true';
```

`OfflineDemoStore.createFresh()` loads universe; `getCustomer360` composes customer + wallets + payments + loans + cards + cases.

- [ ] **Step 4: Gate `AdminApiClient` and login**

Every public API method: if `OFFLINE_DEMO`, delegate to store. Login authenticates against `store` staff only — no `fetch`.

- [ ] **Step 5: Manual check** — stop API; login `admin@yole.com` / `Password1!`; dashboard loads; Network tab has no `:3000` calls.

- [ ] **Step 6: Commit** `feat(admin): OfflineDemoStore hard-offline path`

---

### Task 3: Admin thin shells for DEM-02/04/05/08/09/10/11/12

**Files:**
- Create pages under `apps/admin_web/app/dashboard/`: `products`, `approvals`, `credit-exceptions`, `idempotency`, `remittance`, `resilience`, `export`
- Modify: `recon/page.tsx`, `cases/page.tsx`, `customer360/page.tsx`, `cards/page.tsx`
- Modify: `components/sidebar/Sidebar.tsx`
- Modify: `lib/offline/store.ts` mutations: `approvePending`, `decideCreditException`, `compensatePayment`, `runEod`, `buildExportPack`, `advanceAmlCase`

**Interfaces:**
- Consumes: `getOfflineStore()`
- Produces: routes listed below + working mutations

Sidebar hrefs/labels:

| href | label |
| --- | --- |
| `/dashboard/products` | Products & rules |
| `/dashboard/approvals` | Pending approvals |
| `/dashboard/credit-exceptions` | Credit exceptions |
| `/dashboard/idempotency` | Idempotency lab |
| `/dashboard/remittance` | Remittance |
| `/dashboard/resilience` | Resilience (demo) |
| `/dashboard/export` | Export pack |

- [ ] **Step 1: Sidebar entries** (Color Admin menu pattern)
- [ ] **Step 2: Products + Approvals (DEM-02)** — list products/feeLimits; approve/reject `pendingApprovals` applies fee change
- [ ] **Step 3: Credit exceptions (DEM-04) + 360 schedule (DEM-03)** — approve PENDING_EXCEPTION → ACTIVE + schedule + wallet credit + journal; 360 shows installments
- [ ] **Step 4: Idempotency lab (DEM-05)** — Replay same key returns same payment; Compensate posts reversing journal + notification
- [ ] **Step 5: Remittance admin (DEM-08)** — clear/screening/refund + partner recon stub
- [ ] **Step 6: AML cases (DEM-09)** — confidential badge; Investigate → Recommend → maker-checker with `approverRole`
- [ ] **Step 7: Resilience (DEM-10)** — banner **DEMO STORYBOARD — not a live HA failover**; show balanced journals
- [ ] **Step 8: Recon EOD (DEM-11) + Export (DEM-12)** — Run EOD writes snapshot; Download `yole-demo-export.json`
- [ ] **Step 9: Cards MOCK (DEM-07)** — banner **MOCK — not Visa/Mastercard certified**; show mock 3DS + dispute link
- [ ] **Step 10: Manual walk** with API stopped for DEM-02/04/05/07/08/09/10/11/12
- [ ] **Step 11: Commit** `feat(admin): offline DEM thin shells and mutations`

---

### Task 4: Admin offline badge + reset

**Files:**
- Modify: `apps/admin_web/components/header/Header.tsx`

- [ ] **Step 1:** Badge text exactly `Offline demo — no live API` when offline
- [ ] **Step 2:** **Reset demo** → `getOfflineStore().reset()` + reload
- [ ] **Step 3:** Verify reset restores exception loan after approve
- [ ] **Step 4: Commit** `feat(admin): offline badge and demo reset`

---

### Task 5: Customer Flutter offline repository (DEM-01/03/06/07/08)

**Files:**
- Modify: root `pubspec.yaml` path dep on `packages/demo_universe/dart`
- Create: `lib/services/offline_demo_repository.dart`
- Modify: `lib/services/core_api_service.dart`, `lib/services/core_auth_service.dart`
- Modify: `lib/screens/cards_screen.dart` (MOCK banner)
- Create: `test/offline_demo_repository_test.dart`

**Interfaces:**
- Consumes: `DemoUniverse.load()`
- Produces: DTO shapes matching existing `CoreApiService` callers; gated by `bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false)`

- [ ] **Step 1: Failing test** — `walletsFor('cust_kasee')` length 2
- [ ] **Step 2: Implement repository** — seeded login; OTP `123456`; KYC submit; payment confirm appends journal; Amina eligibility from salary; remittance screening; cards MOCK
- [ ] **Step 3: Gate CoreApiService / CoreAuthService** — offline branch must not call HTTP
- [ ] **Step 4: Manual**

```bash
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
```

API stopped. Login `kasee.demo@yole.com` / `Password1!`. Walk DEM-06/07/08; Amina for DEM-03/04 pending.

- [ ] **Step 5: Commit** `feat(customer): offline demo repository for DEM walks`

---

### Task 6: Agent Flutter offline repository

**Files:**
- Modify: `apps/agent_mobile/pubspec.yaml`
- Create: `apps/agent_mobile/lib/services/offline_agent_repository.dart`
- Modify: `apps/agent_mobile/lib/services/agent_api_service.dart`
- Create: `apps/agent_mobile/test/offline_agent_repository_test.dart`

**Interfaces:**
- Consumes: same universe JSON
- Produces: `agent-001` login, float, enroll, cash-in/out against session memory; cross-channel proof via **pre-seeded** journals in JSON

- [ ] **Step 1: Failing test** — `agent-001` float matches seed
- [ ] **Step 2: Implement + gate OFFLINE_DEMO**
- [ ] **Step 3: Manual** Chrome with `--dart-define=OFFLINE_DEMO=true`; cash-in works in-session; pre-seeded history visible in admin seed
- [ ] **Step 4: Commit** `feat(agent): offline demo repository`

---

### Task 7: DEM script + README pointers + acceptance

**Files:**
- Create: `docs/demo/DEM-SCRIPT.md`
- Modify: `README_APPS.md`
- Modify: `user_journey.md` (top pointer only)
- Modify: `packages/demo_universe/README.md`

- [ ] **Step 1: Write DEM-SCRIPT.md** — flags, personas, click paths DEM-01…12, reset, honesty banners, acceptance checklist
- [ ] **Step 2: Acceptance run** — API stopped; walk all 12; tick checklist
- [ ] **Step 3: Commit** `docs: Poste offline DEM-01–12 script and README pointers`

---

## Spec coverage self-check

| Spec item | Task |
| --- | --- |
| Shared package + universe.json | T1 |
| Offline flags, no API calls | T2, T5, T6 |
| Admin store + migrate demo-seed | T2 |
| DEM shells 02/04/05/08/09/10/11/12 | T3 |
| Enrich 360/cards/recon/cases | T3 |
| Offline badge + reset | T4 |
| Customer DEM-01/03/06/07/08 | T5 |
| Agent float/enroll/cash | T6 |
| DEM script + pointers | T7 |
| MOCK / storyboard honesty | T3, T5 |
| Export pack | T3 |

## Placeholder scan

No TBD/TODO steps. Cross-app live sync explicitly deferred to pre-seeded trails. IDs and flag names consistent across tasks.

---

*End of plan.*
