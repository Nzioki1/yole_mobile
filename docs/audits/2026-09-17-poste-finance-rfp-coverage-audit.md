# YOLE × Poste Finance SA — RFP Coverage Audit

**Date:** 2026-09-17 (EAT)  
**Auditor:** Grok Bot (executor subagent)  
**RFP:** Poste Finance SA Digital Financial Services Platform — Cahier des Charges (`/workspace/poste-finance-rfp.txt`, 906 lines)  
**Code evidence source:** GitHub `Nzioki1/yole_mobile` **PR #1** branch `cursor/task1-monorepo-scaffold-1d8a` @ `e47650f1d39ca178556beeb67836da163fff0063` (pushed 2026-09-17 ~15:40 UTC / 18:40 EAT)  
**Mac checkout:** `/Users/nzioki/Documents/Yole/yole_mobile` on machineId `6a57419c-e76b-4a39-ab6f-cb051ac9860f` — **not readable from this executor** (`Shell.machineId` / `Read.machineId` not exposed). Audit uses the PR HEAD that tracks the demo monorepo work. Re-verify locally if Mac has unpushed deltas.  
**Scope:** Read-only coverage audit. No fixes. No PR.

---

## Access / methodology notes

| Item | Detail |
| --- | --- |
| Local Mac | Blocked — same class of issue as prior UFAMS audit |
| Fallback | Authenticated GitHub MCP + raw file reads on PR #1 HEAD |
| `main` branch | Still mostly legacy Pesapal Flutter remittance app — **not** the demo portal |
| Demo branch | Monorepo: NestJS `services/core-api`, Next.js `apps/admin_web`, Flutter agent `apps/agent_mobile`, customer Flutter at repo root `lib/` |
| Storage | **In-memory mocks only** (no Postgres persistence). Demo depth ≠ production readiness |
| Supporting docs | `README_APPS.md`, `user_journey.md` (stale — still Pesapal journey), `docs/superpowers/specs/*`, box briefs `phases-2-4-mock-brief.md` |

**Path convention:** Unless noted, API evidence lives under `services/core-api/src/…`, admin under `apps/admin_web/…`, agent under `apps/agent_mobile/…`, customer under root `lib/…`.

**Status legend**

| Status | Meaning |
| --- | --- |
| **COVERED** | Demonstrable in UI and/or API mock with coherent data for a demo walkthrough |
| **PARTIAL** | UI shell, stub, incomplete journey, or mock that omits material RFP behaviors |
| **MISSING** | Not present in tree |
| **N/A (OPS/VENDOR)** | Contractual, hosting, SLA, commercial, migration — not product UI |

**Mock vs production:** Every COVERED/PARTIAL item below is **demo-mock depth** unless explicitly noted. Production CBS, scheme certification, real MNO/bank rails, PCI, HA/DR, and DRC residency are **out of scope of current code**.

---

## A. Executive summary

YOLE’s current demo monorepo is a **credible Phase-1 mock narrative** (wallet + dual-currency pockets + quote/confirm payments + agent float cash-in/out + thin admin ops shell) with **stubbed Phase-2–4 modules** bolted onto the same in-memory ledger. It is **not** an RFP-complete response and would **fail** a hard Poste Finance acceptance demo for mandatory branchless credit STP, Visa/Mastercard, multi-MTO remittance, full back-office configuration/maker-checker, and finance/recon depth.

Rough coverage (product MUST IDs only; OPS excluded):

| Band | Approx. share | Notes |
| --- | --- | --- |
| Phase 1 (wallet/payments/agents/basic admin) | **~55–65% PARTIAL+COVERED** | Strongest story; still missing real eKYC screening, maker-checker, full CoA/treasury |
| Phase 2 (payroll + branchless credit) | **~25–35% PARTIAL** | Employer import + salary credit + loan disbursement stubs; eligibility always-true; no repayment/arrears/maker-checker |
| Phase 3 (cards) | **~20–30% PARTIAL** | Virtual debit mock only; no scheme/3DS/PCI/clearing |
| Phase 4 (remittance/FX + heavy BO) | **~15–25% PARTIAL** | FX convert + inbound remittance stub; outbound incomplete; no admin remittance/FX; recon is a date summary |
| Overall product MUST | **~30% PARTIAL-weighted / ~12–18% true COVERED** | Honest demo ≠ bid compliance |
| Production readiness | **~0–5%** | In-memory, mock adapters, no HA/DR/PCI/AML stack |

**Top 10 critical MUST gaps (would fail demo / RFP narrative)**

1. **CRD-03…CRD-08 / DEM-03–04** — Branchless salary-advance STP with real eligibility, terms consent, receivable+schedule, salary repayment, exception maker-checker  
2. **CAR-01…CAR-07 / DEM-07** — Visa/Mastercard issuing, 3DS, clearing/settlement, disputes (only mock virtual debit)  
3. **REM-01…REM-05 / DEM-08** — Multi-MTO corridors, screening docs, partner recon (inbound stub only; no admin remittance)  
4. **CUS-07/08 / SEC-06** — Replaceable eKYC + sanctions/PEP screening with case escalation (hooks/stubs only)  
5. **BO-03…BO-05** — Product/rule configuration with effective dating + maker-checker (fees/limits CRUD is thin; no product factory)  
6. **FIN-03…FIN-05 / DEM-11** — Partner recon exception queues, EOD/BOD, suspense (admin recon page is KPI/JSON only)  
7. **CBS-01…CBS-04** — Full CIF/accounts/GL/cost centres (wallet ledger subset only)  
8. **WAL-08 / DEM-05** — Compensation/reversal/timeout enquiry with customer notify (idempotency exists; full failure playbook thin)  
9. **API-05…API-08** — Real/replaceable MNO, bank, card, MTO, KYC integrations (mock adapters only)  
10. **PRN-04 / SEC-02–03** — Production-grade RBAC MFA, segregation, tamper-evident audit (demo API key / soft RBAC)

---

## B. Coverage matrix

Evidence paths are relative to repo root on PR #1 HEAD.

### 3.2 Design principles (PRN-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| PRN-01 | Modular API-first, documented interfaces, no unjustified lock-in | PARTIAL | `services/core-api/src/app.module.ts`; modules under `services/core-api/src/modules/*`; `README_APPS.md` | Nest modular core + thin channels is the right shape; OpenAPI/sandbox credentials incomplete vs API-01 |
| PRN-02 | Config before customization; upgrade-safe bespoke | PARTIAL | `apps/admin_web/app/dashboard/config/page.tsx`; `AdminService` fee/limit maps | Fees/limits editable in-memory; products/workflows not config-driven |
| PRN-03 | Multi-entity/branch/channel; CDF/USD; books + audit | PARTIAL | Wallet CDF/USD pockets; ledger journals | Dual currency yes; multi-entity/branch books missing |
| PRN-04 | Security, privacy, AML/CFT, least privilege, maker-checker, audit | PARTIAL | `apps/admin_web/lib/rbac.ts`; case stubs | Soft RBAC + case stubs; no MFA, no real AML, weak maker-checker |
| PRN-05 | Low-bandwidth, idempotent retries, duplicate prevention, offline recovery | PARTIAL | Ledger `idempotencyKey`; payment quote→confirm | Idempotency on journals/payments; offline/pending recovery UX incomplete |
| PRN-06 | Phased deploy, pilot, exit criteria, rollback, coexistence | N/A (OPS/VENDOR) | Phase docs only | Process/plan — not in product demo |
| PRN-07 | Poste Finance retains control of products, pricing, rules, data | PARTIAL | Admin config pages | Intent via configurable fees/limits; data export/exit incomplete |

### 4. Customer, identity, channels (CUS-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| CUS-01 | Android/iOS apps + consistent design + responsive web | PARTIAL | Root Flutter `lib/`; `apps/agent_mobile`; `apps/admin_web` | Customer + agent Flutter; admin web. Responsive customer web not a first-class Poste channel |
| CUS-02 | FR at launch, EN + configurable languages; centralized labels/templates | PARTIAL | `lib/l10n/app_en.arb`, `app_fr.arb`; language screen | FR/EN present; fee/receipt/notification template centralization incomplete |
| CUS-03 | Low-cost devices, low bandwidth, pending/success/failure, safe recovery | PARTIAL | Payment quote/result screens; payment status machine | Explicit pending states partially modeled; offline recovery not demonstrated |
| CUS-04 | Self-reg, OTP, device binding, TXN PIN, biometrics, step-up | PARTIAL | Identity module; PIN set/verify; mock biometric in `README_APPS.md` | OTP/PIN mocked; device binding/step-up risk engine missing |
| CUS-05 | One customer identity across wallet/credit/cards/remittance | PARTIAL | `customers` + wallets + cards/credit/remittance keyed by customerId | Single ID in mock stores; segment/relationship model thin |
| CUS-06 | Configurable KYC/KYB tiers, approved IDs, selfie, consent, refresh | PARTIAL | KYC screens `lib/screens/kyc_*.dart`; `modules/kyc`; admin KYC queue | Tier/doc flows exist as mock upload; KYB/periodic refresh missing |
| CUS-07 | Replaceable eKYC + duplicate detection | PARTIAL | `kyc` ports/hooks in design; mock storage | Provider-replaceable ports sketched; duplicate detection not demonstrated |
| CUS-08 | Sanctions/PEP/watchlist screening + escalation | PARTIAL | Remittance `screeningHit` always false; cases module | Stub only — no real lists, no confidential AML case workflow |

### 5.1 Core banking (CBS-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| CBS-01 | CIF/360, CASA, interest/fees, mandates, holds, statements, lifecycle | PARTIAL | Admin customer360; wallets with ledger/blocked/pending | Wallet 360 subset; no full CASA/interest/mandates |
| CBS-02 | Term deposits | MISSING | — | Not in modules |
| CBS-03 | Credit sub-ledger (origination→collections) | PARTIAL | `modules/credit/credit.service.ts` | Disburse + list only; no schedules/arrears/provisioning |
| CBS-04 | CoA, multi-currency GL, cost centres, auto postings, EOD/BOD | PARTIAL | `modules/ledger/ledger.service.ts` balanced journals | In-memory CoA codes; no EOD/BOD, cost centres, drill-down GL UI |
| CBS-05 | Branch/teller/cash (SHOULD) | MISSING | — | Agent float is not branch teller |
| CBS-06 | Treasury, correspondent, liquidity, forecasting | MISSING | — | |
| CBS-07 | Payment orders, bulk, standing instructions, beneficiaries | PARTIAL | Payments + payroll bulk salary credit | No standing instructions / full payment-order product |
| CBS-08 | Versioned effective-dated params; no destructive edits; authorized reversals | PARTIAL | Reversal philosophy in ledger design; fee maps | No effective-dating/versioning UI; reversals not fully exposed |

### 5.2 Wallet, payments, agents (WAL-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| WAL-01 | CDF/USD wallet; available/ledger/blocked/pending; extra pockets by config | COVERED | `modules/wallets`; `modules/ledger`; customer home | Dual pockets + balance components; extra pockets by config limited |
| WAL-02 | Funding from loan/advance/bank/cards/agents/MM; withdrawals | PARTIAL | Payments MNO_IN/BANK_IN; agent cash-in; credit disburse; cards not a funding rail | Card funding / full rail matrix incomplete |
| WAL-03 | W2W, W2MM, MM2W, bank rails | COVERED | `payments.service.ts` W2W, MNO_IN/OUT, BANK_IN (+ BANK_OUT labeled) | Mock adapters; BANK_OUT/AIRTIME may be partial in switch |
| WAL-04 | Airtime, merchant QR/POS, bills, taxes, passport/public pay | PARTIAL | BILL adapter; airtime labeled | Bills mock; QR/POS/tax/passport not first-class |
| WAL-05 | Pre-PIN quote (beneficiary, fees, tax, FX, total) + verifiable receipt | COVERED | Quote/confirm APIs; Flutter payment quote/result screens | FX on payment quote limited; receipt is mock reference |
| WAL-06 | Bulk disbursement/collection, payroll files/APIs, scheduled/recurring | PARTIAL | Payroll import + salary credit | No scheduled/recurring engine; collection limited |
| WAL-07 | Agent/merchant onboarding, hierarchy, float, commissions, cash-in/out (SHOULD) | PARTIAL | Admin agents; `apps/agent_mobile` enroll + cash in/out | Float cash-in/out works in mock; hierarchy/commissions/settlement thin |
| WAL-08 | Pending/timeouts, enquiry, compensation, reversals, no duplicates, notify | PARTIAL | Idempotency keys; status fields; notifications module | Happy-path strong; compensation/timeout enquiry playbook incomplete |
| WAL-09 | History, unique/external refs, audit, statements, channel cases | PARTIAL | Payment history screens; admin payments search; cases | Statements download / channel cases partial |

### 6.1 Corporate / payroll (COR-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| COR-01 | Employer profiles with contracts, products, pricing, limits, rules | PARTIAL | `payroll.service.ts` createEmployer; admin payroll pages | Name/taxId only — no contract/product matrix |
| COR-02 | Employee onboard individual/bulk; employer + payroll ID + status | PARTIAL | `importEmployees` JSON | Bulk JSON; employment status model thin |
| COR-03 | HR/payroll API + file upload; validate duplicates/totals/rejects | PARTIAL | Admin import UI + API | Mock JSON import; validation/rejects basic |
| COR-04 | Salary amount/history/status/tenure for eligibility | PARTIAL | Employee salaryMinor stored | History/tenure not rich enough for real eligibility |
| COR-05 | Exit/suspension/salary interrupt → recalc credit access | MISSING | — | |
| COR-06 | Employer dashboards within permissions (SHOULD) | MISSING | Admin-only payroll | No employer portal |

### 6.2 Credit (CRD-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| CRD-01 | Configurable salary advances, consumer loans, SME; future products | PARTIAL | `SALARY_ADVANCE` / `CONSUMER_LOAN` types | Hardcoded types; SME missing; not product-configurable |
| CRD-02 | Configure currency/amount/%/tenure/rates/fees/taxes/grace/schedule | PARTIAL | Fixed interest 5%/10% in service | Not admin-configurable |
| CRD-03 | Eligibility/affordability rules from salary/exposure/risk | PARTIAL | `checkEligibility` **always eligible** | Stub — demo-breaking for RFP MUST |
| CRD-04 | Display cost/schedule/late consequences before e-accept; preserve version | PARTIAL | Customer credit apply screens | Terms UI partial; versioned acceptance not evidenced |
| CRD-05 | STP immediate wallet credit; no branch/staff | PARTIAL | `requestLoan` → ledger credit | Instant disburse yes; eligibility/consent/exception modes inadequate |
| CRD-06 | Atomic receivable + wallet credit; idempotent; no imbalance | PARTIAL | Ledger balanced postings on disburse | Receivable/sub-ledger/schedule atomicity incomplete |
| CRD-07 | Modes: auto / threshold / manual queue / suspend + maker-checker | MISSING | — | No exception queue |
| CRD-08 | Auto repay from salary/wallet; allocation, partial/early, refinance | MISSING | — | No repayment engine |
| CRD-09 | Arrears, penalties, collections, restructuring, provisioning, write-off | MISSING | — | |
| CRD-10 | Supplier payments / SME committee/guarantees (SHOULD) | MISSING | — | |
| CRD-11 | Record rule version, inputs, decision, overrides, notices | MISSING | — | |

### 7.1 Cards (CAR-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| CAR-01 | Visa/Mastercard physical+virtual; debit/prepaid; credit-ready | PARTIAL | `cards.service.ts` VIRTUAL_DEBIT only | **Not** Visa/MC — mock PAN |
| CAR-02 | Order, personalize, activate, PIN, token, renew, replace, freeze, hotlist, close | PARTIAL | issue/freeze/activate/block/limits | No PIN/token/renew/replace/hotlist depth |
| CAR-03 | Wallet-linked, card-to-wallet, ecom, contact/contactless, ATM/POS | PARTIAL | Linked to wallet pocket; mock auth | No ATM/POS/ecom/3DS rails |
| CAR-04 | Real-time auth, limits, stand-in, FX, fees, clearing, settlement, recon | PARTIAL | mockAuthorization; limits | No clearing/settlement/recon |
| CAR-05 | EMV, 3DS, tokenization, scheme cert; BIN sponsor responsibilities | MISSING | — | Explicitly mock / out of scope |
| CAR-06 | PCI DSS / PCI PIN; HSM; dual-control keys | N/A (OPS/VENDOR) / MISSING product | — | Must be third-party in production; not in demo |
| CAR-07 | Disputes, chargebacks, fraud rules, evidence, notifications | MISSING | — | |
| CAR-08 | National/regional switches; ISO 8583/20022 | MISSING | — | |

### 7.2 Remittance & FX (REM-*, FX-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| REM-01 | Multi-MTO/aggregators; corridor routing without single-partner lock-in | MISSING | Single stub module | No partner abstraction |
| REM-02 | Inbound (+ outbound when authorized) to wallet/account/card/MM/cash | PARTIAL | Inbound quote/confirm → wallet; outbound quote only | Outbound confirm missing (README admits) |
| REM-03 | Pre-confirm disclose amounts, rate, spread, fees, taxes, ETA | PARTIAL | Customer remittance/FX screens + quotes | Incomplete vs full disclosure matrix |
| REM-04 | Screen parties/countries; purpose/source of funds; docs by risk | PARTIAL | `screeningHit: false` stub | No real screening/docs |
| REM-05 | E2E status, amendments, exceptions, cancel/refund, liquidity, partner recon | MISSING | — | Admin remittance list missing |
| FX-01 | Effective-dated CDF/USD rates, spreads, bands, maker-checker, history | PARTIAL | `fx.service.ts` seeded CDF↔USD | No maker-checker / history / bands |
| FX-02 | Persist exact rate/fee used; controlled conversion for wallet/transfer/card | PARTIAL | `convert` posts two ledger legs | Rate persisted only in txn response; not full audit product |

### 8. Back office (BO-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| BO-01 | Role portals: Ops, Care, Credit, Risk, Finance, Treasury, IT, SysAdmin | PARTIAL | `rbac.ts` ADMIN/OPS/SUPPORT/FINANCE | Collapsed roles; no Credit/Risk/Treasury portals |
| BO-02 | Configure customer types/segments/KYC tiers/limits/access | PARTIAL | Config + KYC admin | Segment/product factory incomplete |
| BO-03 | Create/configure products without vendor code | MISSING | — | Critical gap |
| BO-04 | Configure salary-advance/loan rules, thresholds, employer policies | MISSING | — | Credit config not in admin |
| BO-05 | Version/effective-date configs; maker-checker; SoD; before/after audit | PARTIAL | Soft RBAC | Maker-checker not implemented for config |
| BO-06 | Customer 360: KYC, relationships, wallets, cards, loans, txns, cases, limits, docs, audit | PARTIAL | `customer360` page + `getCustomer360` | Cards/loans/cases/docs/audit not fully composed |
| BO-07 | Search, suspend/unblock, credential reset, holds, lists, adjustments | PARTIAL | Payments/KYC/agents search | Holds/blacklist/adjustment workflows thin |
| BO-08 | Case mgmt for disputes/refunds/AML/credit exceptions + SLA | PARTIAL | Cases pages + `createCase`/`updateCase` | Stub statuses; no SLA/evidence vault |
| BO-09 | Dashboards, CSV/XLSX/PDF exports, API feeds | PARTIAL | Dashboard KPIs | Exports/API feeds incomplete |

### 9. Finance, data, reporting (FIN-*, DAT-*, RPT-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| FIN-01 | Auditable double-entry for every financial event with refs | COVERED | `ledger.service.ts` balanced postings + idempotency | In-memory; good demo story |
| FIN-02 | Separate principal/interest/fees/taxes/insurance/penalties/commissions/FX | PARTIAL | Fee/tax on payments; FX separate legs | Credit components not separated in schedules |
| FIN-03 | Auto daily/intraday recon vs MNO/banks/cards/MTOs/billers/agents | PARTIAL | Admin recon daily summary | No partner file matching |
| FIN-04 | Matching rules + exception queues + resolution audit | MISSING | — | |
| FIN-05 | EOD/BOD + 24/7 with suspense, restart, no destructive edits | MISSING | — | |
| DAT-01 | PF owns data; open-format export on demand/exit | PARTIAL | — | No documented export pack (DEM-12 missing) |
| DAT-02 | Dictionary, lineage, quality, retention, legal hold, non-prod protection | MISSING | — | |
| RPT-01 | Executive/finance/ops/credit/risk/partner/regulatory dashboards | PARTIAL | Admin dashboard KPIs | Not role-complete or reproducible regulatory |
| RPT-02 | Credit reporting: decisions, PAR/NPL, vintage, provisions | MISSING | — | |

### 10. APIs / integrations (API-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| API-01 | Versioned REST/JSON, OpenAPI, examples, sandbox/UAT/prod credentials | PARTIAL | `/v1/*` routes in README_APPS | OpenAPI/Swagger incomplete; env credentials demo-only |
| API-02 | OAuth/OIDC/mTLS/signed requests; rotation, throttle, allowlists, audit | PARTIAL | JWT customer; admin API key; agent header | No mTLS/rotation/throttle productization |
| API-03 | Idempotency keys, correlation IDs, status enquiry, retry rules | PARTIAL | Ledger/payment idempotency | Status enquiry/retry matrix incomplete |
| API-04 | Signed webhooks, retries, DLQ, replay protection, monitoring | MISSING | — | |
| API-05 | Airtel/Orange/Vodacom/Afrimoney/pawaPay without core redesign | PARTIAL | `MockMnoAdapter` port pattern | Adapter shape OK; no real operators |
| API-06 | SCPT/employer HR payroll API + file | PARTIAL | Payroll import API | Not SCPT-specific |
| API-07 | Banks/settlement accounts, statements, positions, recon | PARTIAL | MockBankAdapter | Statements/positions/recon missing |
| API-08 | Visa/MC, MTOs, billers, KYC/AML, SMS/OTP replaceable providers | PARTIAL | Ports/mocks | No production providers |
| API-09 | Controlled APIs to partners (e.g. Post Mobile) + gateway monitoring | MISSING | — | |
| API-10 | State third-party licences/fees/deps; no hidden internal API charges | N/A (OPS/VENDOR) | — | Commercial response |

### 11. Security / compliance (SEC-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| SEC-01 | Encrypt in transit/at rest; keys; tokenization; HSM for cards | PARTIAL | HTTPS assumed; flutter_secure_storage mentioned | No HSM/tokenization; demo secrets |
| SEC-02 | RBAC, MFA privileged, SoD, recertification, JIT vendor access | PARTIAL | `rbac.ts` | MFA/SoD/recert missing |
| SEC-03 | Tamper-evident centralized audit logs | PARTIAL | Actor fields on journals | Not a tamper-evident audit product |
| SEC-04 | Secure SDLC, SBOM, vuln mgmt, pen tests | N/A (OPS/VENDOR) | — | |
| SEC-05 | Segmentation, WAF, anti-DDoS, EDR, SIEM, 24/7 alerting | N/A (OPS/VENDOR) | — | |
| SEC-06 | Sanctions/PEP + TM/fraud rules/velocity/network detection | PARTIAL | screening stub | |
| SEC-07 | Confidential case mgmt; FP/whitelist; regulatory reports | PARTIAL | Cases stub | |
| SEC-08 | Privacy/consent, DSAR, retention, breach, DRC data protection | PARTIAL | KYC consent UX partial | |
| SEC-09 | IR plan; critical notify ≤30 min | N/A (OPS/VENDOR) | — | |
| SEC-10 | Audit rights + remediation SLAs | N/A (OPS/VENDOR) | — | |

### 12. Architecture / NFR (ARC-*)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| ARC-01 | Separate channels / API / business / ledger / DB / reporting / security | PARTIAL | Approach A monorepo | Reporting/security components thin; DB is memory |
| ARC-02 | Cloud/private/hybrid; state infra deps | N/A (OPS/VENDOR) | docker-compose postgres/redis present but demo is memory | |
| ARC-03 | Prod + DRC replica/DR + UAT/dev | N/A (OPS/VENDOR) | — | |
| ARC-04 | No SPOF; data residency; local recovery | N/A (OPS/VENDOR) | — | |
| ARC-05 | ≥99.9% monthly availability | N/A (OPS/VENDOR) | — | |
| ARC-06 | RPO≤15m / RTO≤2h | N/A (OPS/VENDOR) | — | |
| ARC-07 | Monitoring apps/APIs/jobs/queues/integrations/DB/certs/settlement | MISSING | — | |
| ARC-08 | Scale ≥10× launch without redesign | PARTIAL | Modular Nest | Unproven; in-memory won’t scale |
| ARC-09 | Encrypted immutable backups; failover exercises; runbooks | N/A (OPS/VENDOR) | — | |
| ARC-10 | No single-person ops dependency; transfer tools/docs | N/A (OPS/VENDOR) | README_APPS helps demo KT | |

### 13–14 Implementation / SLA / commercial (IMP-* + deliverables)

| Req ID | Requirement (short) | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| IMP-01…IMP-07 | Delivery, migration, testing, training, support | N/A (OPS/VENDOR) | — | Proposal artifacts, not UI |
| SLA P1–P4 | Response/restore/RCA matrix | N/A (OPS/VENDOR) | — | |
| 14.1–14.4 | Fit-gap, plans, specs, API catalogue, acceptance | N/A (OPS/VENDOR) | This audit supports fit-gap | Commercial/TCO separate |

---

## C. Channel heatmap

| Channel | Strong | Weak |
| --- | --- | --- |
| **Customer Flutter** (`lib/screens/*`) | Register/login/KYC shell; home wallets; fund/send/withdraw quote flows; history; FR/EN; credit/cards/remittance/FX **screens exist** | Still mixed with legacy Pesapal send journey (`user_journey.md` stale); credit/remittance/FX are mock-thin; offline/pending recovery; biometric/device binding; public-service/QR payments |
| **Agent Flutter** (`apps/agent_mobile`) | Login by agent id; float display; enroll customer; cash-in/out | No commissions, hierarchy, device security UX, receipts history depth, merchant QR/POS |
| **Admin Next.js** (`apps/admin_web`) | Ops shell + sidebar groups; customer360, KYC, agents, payments, cards, payroll, recon, cases, fees/limits; soft RBAC | No remittance/FX/credit-config/product-factory/maker-checker; recon is summary JSON; some pages use `mockApi` fallback; Color Admin polish ≠ functional depth |
| **Core API** (`services/core-api`) | Modular Nest modules; in-memory double-entry ledger with idempotency; payments adapters; wallets; agents; admin APIs; stub credit/cards/fx/remittance/payroll | Always-eligible credit; remittance outbound incomplete; no webhooks; no OpenAPI completeness; no partner recon; memory-only; account-code naming inconsistent across modules |

**Phase heatmap (demo mock depth)**

```
Phase 1 ████████████░░░░  ~60%
Phase 2 ██████░░░░░░░░░░  ~30%
Phase 3 █████░░░░░░░░░░░  ~25%
Phase 4 ████░░░░░░░░░░░░  ~20%
Prod    ░░░░░░░░░░░░░░░░  ~0–5%
```

---

## D. Demo script gaps (DEM-*)

| ID | Scenario | Walk today? | Blockers |
| --- | --- | --- | --- |
| DEM-01 | Self-reg → OTP/device → eKYC/screening → CDF/USD wallet | **PARTIAL** | OTP/KYC mocked; screening stub; device security thin — still a walkable happy path |
| DEM-02 | Create segment/product in BO, limits/fees/workflow, maker-checker, effective date | **BLOCKED** | No product factory; no maker-checker; no effective dating — only fee/limit CRUD |
| DEM-03 | Payroll import → eligibility → salary advance → terms/PIN → auto approve → wallet + receivable/schedule | **BLOCKED / thin** | Payroll import+salary credit OK; advance eligibility always-true; schedule/receivable incomplete |
| DEM-04 | Auto consumer loan + separate threshold exception → maker-checker | **BLOCKED** | No threshold modes / exception queue / maker-checker |
| DEM-05 | Interrupted/replayed disbursement & external payment; no dup; compensate; notify | **PARTIAL** | Idempotency helps; full interrupt/compensation/notify demo not packaged |
| DEM-06 | MM fund/withdraw, bank-to-wallet, W2W, bill/public pay, receipt/ledger/recon trace | **WALKABLE (mock)** | Best Phase-1 story; public-service/QR thin; recon trace weak beyond ledger refs |
| DEM-07 | Virtual Visa/MC, controls, 3DS ecom auth, clearing/settlement, dispute | **BLOCKED** | Mock virtual debit only — label clearly as MOCK; do not claim scheme |
| DEM-08 | Inbound remittance quote/screen → wallet → exception/refund → partner+FX recon | **PARTIAL inbound only** | Screening always clear; no exception/refund/partner recon; admin remittance missing |
| DEM-09 | AML/fraud alert → confidential case → investigation → maker-checker → audit | **PARTIAL / weak** | Cases stub exists; not confidential AML workflow with maker-checker |
| DEM-10 | Node failure → failover/queue recovery → RTO/RPO → ledger integrity | **BLOCKED** | Single in-memory process; no HA demo |
| DEM-11 | EOD/BOD, GL/sub-ledger balance, suspense, mgmt/regulatory drill-down | **BLOCKED** | Recon page ≠ EOD/BOD |
| DEM-12 | Full open-format export of customer universe | **BLOCKED** | No export pack |

---

## E. Recommended next build waves (priority only)

1. **Demo script hardening for DEM-01 + DEM-06** — Seeded personas, coherent CDF/USD balances, quote→PIN→receipt→ledger drill from customer + admin 360 (highest demo ROI).  
2. **Maker-checker + effective-dated fees/limits** — Unblocks DEM-02 narrative without full product factory.  
3. **Payroll → salary advance happy path** — Real eligibility using imported salary; terms screen; atomic loan+schedule+wallet; admin view of receivable (DEM-03 minimum).  
4. **Exception queue for credit** — One threshold rule + maker-checker approve/deny (DEM-04).  
5. **Payment failure/idempotency showcase** — Replay same idempotency key; timeout→enquiry; reverse+notify (DEM-05).  
6. **Inbound remittance + FX convert admin visibility** — Screening hit toggle, payout, simple partner recon stub (DEM-08 lite).  
7. **Cards honesty layer** — Keep virtual debit demo but add “MOCK — not scheme certified” banners; optional mock 3DS challenge screen (avoid overclaiming CAR-*).  
8. **Customer 360 completeness** — Compose loans, cards, remittances, cases, audit timeline on one admin page (BO-06).  
9. **OpenAPI publish + adapter matrix slide** — Documents API-01/05–08 for RFP response even while mocks remain.  
10. **Defer production ARC/SEC/IMP** to proposal annexes — do not burn sprint capacity pretending in-memory is HA/PCI.

---

## Inventory snapshot (evidence anchors)

### Admin routes (`apps/admin_web/app/dashboard/**`)
`/dashboard`, `customer360`, `kyc`, `agents`, `payments`, `cards`, `payroll`, `recon`, `cases`, `config` (+ `/login`). Sidebar: `apps/admin_web/components/sidebar/Sidebar.tsx` + RBAC `apps/admin_web/lib/rbac.ts`. **No** remittance, FX, credit-product, treasury, or regulatory-reporting suites.

### Agent screens (`apps/agent_mobile/lib/screens/**`)
`agent_login_screen.dart`, `agent_home_screen.dart` (float), `enroll_customer_screen.dart`, `cash_in_out_screen.dart`; API client `apps/agent_mobile/lib/services/agent_api_service.dart`.

### Customer screens (root Flutter `lib/screens/**`)
Auth/KYC/home/fund/send/withdraw/history/profile/notifications plus `credit_*`, `cards_*`, `remittance_*`, `fx_*` mock-era screens. Legacy Pesapal-oriented send/favorites remain. Router: `lib/app_router.dart`. **Note:** `user_journey.md` still describes the old money-transfer UX — not the Poste demo script.

### Core API modules (`services/core-api/src/modules/**`)
Wired in `services/core-api/src/app.module.ts`: `identity`, `customers`, `ledger`, `kyc`, `payments`, `agents`, `admin`, `payroll`, `credit`, `cards`, `remittance`, `fx`, `wallets`, `notifications` (+ in-memory stores under `services/core-api/src/common/stores/`).

### Demo seed
`README_APPS.md` documents credentials (`dev-admin-key`, agent enroll → float seed, customer self-reg). Boot seed controlled by env patterns in briefs (`SEED_DEMO`); treat as **mock seed**, not live CBS.

---

## Explicit honesty statements

1. **Demo mock depth ≠ production readiness.** Double-entry in RAM is a great story; it is not a CBS.  
2. **Do not claim Visa/Mastercard, real MNO certification, or BCC-ready AML** based on current code.  
3. **`user_journey.md` on the branch describes the old Pesapal remittance app** — do not use it as Poste Finance demo script. Prefer `README_APPS.md`.  
4. **Mac path was not inspected.** If local tree diverges from PR #1 HEAD, re-run this matrix with `Shell.machineId` enabled.

---

*End of audit — 2026-09-17 EAT*
