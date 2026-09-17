# YOLE Offline Demo Universe — Design Spec

**Date:** 2026-09-17 (EAT)  
**Status:** Approved 2026-09-17 — implementation plan written  
**Related:** Poste Finance SA Cahier des Charges; `docs/audits/2026-09-17-poste-finance-rfp-coverage-audit.md`; prior `2026-09-17-yole-admin-demo-seed-design.md` (admin-only seed — superseded for offline DEM scope)

---

## 1. Goal

Enable a full **offline** walkthrough of Poste Finance demo scenarios **DEM-01 through DEM-12** across:

- Admin Next.js (`apps/admin_web`)
- Customer Flutter (repo root `lib/`)
- Agent Flutter (`apps/agent_mobile`)

**Hard constraint:** with the offline flag on, clients **never** call `core-api` (no network to `:3000`). All reads and mutations use a shared in-memory demo universe.

**Non-goal:** production CBS, real MNO/bank/card/MTO adapters, PCI/HSM, HA/DR, DRC hosting. Those stay proposal/ops annexes. Offline demo depth ≠ production readiness.

---

## 2. Approach (approved)

**Approach A — Shared offline demo universe**

One coherent seed world (shared entity IDs) consumed by all three apps. Session-local mutations so DEM walks feel interactive. Thin new UI shells where DEM steps have no surface today. Persistent MOCK / DEMO-ONLY honesty banners where the RFP would otherwise be overclaimed.

Rejected alternatives:

- **B** Per-app independent seeds — breaks cross-channel DEM continuity  
- **C** Seed clients while leaving API “available” — violates zero-API-call requirement and dual sources of truth

---

## 3. Architecture

### 3.1 Feature flag

| Surface | Flag | Default for this work |
| --- | --- | --- |
| Admin | `NEXT_PUBLIC_OFFLINE_DEMO=true` | On for local demo |
| Customer Flutter | `--dart-define=OFFLINE_DEMO=true` | On for local demo |
| Agent Flutter | `--dart-define=OFFLINE_DEMO=true` | On for local demo |

When the flag is **on**:

- No `http`/`dio`/`fetch` to `NEXT_PUBLIC_API_BASE_URL` / core-api  
- Login uses seeded staff / customers / agents only  
- All repositories resolve through an offline store  

When **off**: existing API (or prior prefer-seed fallback) behavior may remain for future hybrid demos — but this project’s acceptance is **flag on + API stopped**.

### 3.2 Shared package layout

```
packages/demo_universe/
  README.md
  data/
    universe.json          # or split JSON files loaded as one graph
  schema/                  # optional JSON schema / TS types
  # Language-specific thin loaders (generated or hand-written):
  # - TypeScript: used by admin_web
  # - Dart: used by customer + agent apps
```

Monorepo wiring:

- Admin: import TS loader from `packages/demo_universe` (or copy-synced `lib/offline/` if package wiring is blocked short-term — prefer real package).
- Flutter apps: path dependency on a Dart package wrapping the same JSON (single source: `data/universe.json`).

**Invariant:** customer `cust_kasee`, agent `agent-001`, loan `loan_…`, journal `jnl_…` IDs match across admin 360, customer home, and agent cash-in.

### 3.3 Offline stores

| App | Entry | Behavior |
| --- | --- | --- |
| Admin | `OfflineDemoStore` (singleton, session) | Replaces `AdminApiClient` when offline; mutable Map/arrays |
| Customer | `OfflineDemoRepository` behind existing service interfaces | Same shapes as current API DTOs where possible |
| Agent | `OfflineAgentRepository` | Enroll, float, cash-in/out against shared wallets |

**Mutations:** in-process only (approve KYC, cash-in, disburse, remittance payout, maker-checker approve/deny, EOD run, export generate).  
**Reset:** reload `universe.json` into memory (button in admin header + documented Flutter hot-restart / in-app “Reset demo”).

### 3.4 Honesty layer

Always-visible banners:

- Cards / DEM-07: **MOCK — not Visa/Mastercard certified**
- DEM-10 page: **DEMO STORYBOARD — not a live HA failover**
- Global offline badge: **Offline demo — no live API**

Do not claim real MNO/bank/MTO connectivity, BCC-ready AML, or production RBAC MFA while offline.

---

## 4. Personas (shared)

| ID | Role | Purpose |
| --- | --- | --- |
| `admin@yole.com` / Ops / Support / Finance | Staff (Password1!) | RBAC demos |
| `kasee.demo@yole.com` (`cust_kasee`) | Open-market customer | DEM-01/06/07/08 |
| `amina.payroll@yole.com` (`cust_amina`) | Corporate-linked employee | DEM-03/04 |
| `agent-001` | Agent with float | Cash-in/out, enroll |
| Employer `Poste Demo SARL` (`emp_poste`) | Corporate | Payroll import |

---

## 5. DEM-01 … DEM-12 map

| DEM | Offline walk | Primary surfaces | Thin new shell |
| --- | --- | --- | --- |
| DEM-01 | Self-reg → OTP → eKYC → CDF/USD wallet | Customer register/OTP/KYC/home | Seed OTP always-accept; staged screening result |
| DEM-02 | Segment/product + fees/limits + maker-checker + effective date | Admin config | **Products & rules** + **Pending approvals** queue |
| DEM-03 | Payroll → eligibility → salary advance → terms/PIN → wallet + schedule | Admin payroll + Customer credit | **Loan receivable/schedule** on admin 360 & credit |
| DEM-04 | Auto loan + threshold exception → maker-checker | Customer credit + Admin | **Credit exceptions** queue |
| DEM-05 | Replay/interrupt payment; no dup; compensate; notify | Customer + Admin payments/cases | **Idempotency lab** + compensation action |
| DEM-06 | MM/bank/W2W/bill → receipt → ledger/recon trace | Customer rails + Admin payments/360/recon | Enrich; receipt → journal deep-link |
| DEM-07 | Virtual card + controls + mock 3DS + dispute | Customer + Admin cards | **Mock 3DS** + dispute case + MOCK banner |
| DEM-08 | Inbound remittance → screen → wallet → exception/refund → partner recon | Customer remittance + Admin | **Admin remittance** + partner recon stub |
| DEM-09 | AML alert → confidential case → investigation → maker-checker | Admin cases | **AML case workflow** (confidential, SoD) |
| DEM-10 | Failure → failover story → ledger integrity | Admin | **Resilience storyboard** (DEMO ONLY) |
| DEM-11 | EOD/BOD, GL balance, suspense, drill-down | Admin recon | **EOD/BOD run** + suspense + GL snapshot |
| DEM-12 | Open-format export of customer universe | Admin | **Export pack** (JSON/CSV zip from seed) |

### Admin nav additions

Under existing Color Admin sidebar groups:

- Products & rules (BO / config)
- Credit exceptions (Credit / Ops)
- Remittance (Ops / Finance)
- Resilience demo (IT / SysAdmin — clearly labeled)
- Export pack (Finance / SysAdmin)

Keep existing: Dashboard, Customer 360, KYC, Agents, Payments, Cards, Payroll, Recon, Cases, Config.

---

## 6. Seed contents (must-link)

The universe MUST include coherent links for:

1. Dual wallets with available / ledger / blocked / pending for demo customers  
2. Quote→confirm payment history (W2W, MNO, bank, bills) with journal refs  
3. Agent float + enroll + cash-in/out history tied to customer wallets  
4. Employer + employees + salary history that drives **real** eligibility (not always-true)  
5. One auto-approved advance with schedule + receivable; one exception-queue loan  
6. Pending maker-checker fee/limit change with effective date  
7. MOCK virtual debit + one mock 3DS auth + one dispute case  
8. Inbound remittance (clear + one screening-hit exception) + FX convert legs  
9. AML case with confidential flag and two-step approval  
10. Recon day: matched rails + open exceptions + EOD snapshot  
11. Export pack manifest covering customers / wallets / loans / txns / cases  

---

## 7. Out of scope

- Real Postgres persistence, production adapters, PCI/HSM, MFA, HA/DR, DRC residency  
- Replacing or deleting `services/core-api` (clients ignore it when offline)  
- Full rewrite of legacy Pesapal `user_journey.md` (add pointer to new DEM script instead)  
- Claiming Visa/Mastercard, real MNO certification, or BCC-ready AML based on this demo  

---

## 8. Success criteria

1. Stop core-api (`:3000`). With offline flags on, admin (`:3001`), customer Flutter, and agent Flutter still run.  
2. Walk DEM-01 … DEM-12 using the shared personas; IDs match across channels.  
3. Mutations update UI without network errors; Reset restores seed.  
4. MOCK / Offline badges visible on overclaim-risk surfaces.  
5. Export pack downloads a non-empty open-format archive derived from the universe.  

---

## 9. Implementation notes (for plan — not yet approved to build)

Suggested build waves after plan approval:

1. `packages/demo_universe` + `universe.json` + TS/Dart loaders  
2. Admin: force offline path; enrich existing pages; add thin shells (DEM-02/04/05/08/09/10/11/12)  
3. Customer: offline repository; DEM-01/03/06/07/08 walks  
4. Agent: offline repository; float/enroll/cash aligned to universe  
5. DEM script doc + reset affordances + acceptance checklist  

Prior admin-only `demo-seed.ts` should be **migrated into** the shared universe (not maintained as a second source of truth).

---

## 10. Spec self-review

| Check | Result |
| --- | --- |
| Placeholders | None intentional; package path may fall back to `lib/offline/` if monorepo package wiring blocked |
| Contradictions | Offline = no API calls; core-api may still exist unused — explicit |
| Ambiguity | Flutter path package vs embedded assets — prefer path dep on shared JSON |
| Scope | DEM shells are thin; production ARC/SEC deferred |
| Honesty | MOCK banners required for DEM-07/10 |

---

*End of design spec — approved; see docs/superpowers/plans/2026-09-17-yole-offline-demo-universe.md.*
