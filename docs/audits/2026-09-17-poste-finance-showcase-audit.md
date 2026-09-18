# Poste Finance — Offline Showcase Readiness Audit (DEM-01…DEM-12)

**Date:** 2026-09-17 ~21:22 EAT  
**Auditor:** Grok Bot (executor subagent)  
**RFP:** Poste Finance SA Cahier des Charges — Appendix A Mandatory Demonstration Scenarios (`/workspace/poste-finance-rfp.txt` §Appendix A / lines 848–901)  
**Code evidence:** GitHub `Nzioki1/yole_mobile` branch `cursor/task1-monorepo-scaffold-1d8a` @ `1283032` (2026-09-17 21:16 EAT)  
**Mac checkout:** `/Users/nzioki/Documents/Yole/yole_mobile` (machineId `6a57419c-e76b-4a39-ab6f-cb051ac9860f`) — **Shell.machineId not exposed to this executor**; audit re-verified against synced clone of the same branch HEAD (includes Mac-authored offline DEM commits).  
**Baseline (do not copy blindly):** `/workspace/docs/audits/2026-09-17-poste-finance-rfp-coverage-audit.md` — that audit measured **RFP/product completeness** (~30% PARTIAL-weighted). **This audit measures offline SHOWCASE readiness** with honesty banners.  
**Scope:** Can we *show* DEM-01…DEM-12 end-to-end with API stopped (`OFFLINE_DEMO` / `NEXT_PUBLIC_OFFLINE_DEMO=true`)?

---

## Status legend

| Status | Meaning |
| --- | --- |
| **SHOWCASE READY** | UI + offline seed/mutations; walk completes with API stopped; honest if mock |
| **THIN SHELL** | Page/screen exists; limited interaction (mostly list/read) |
| **PARTIAL** | Some path works offline; another required path still network-bound or incomplete |
| **GAP** | Cannot demo offline without API or missing surface |

**Honesty required (exact strings in `packages/demo_universe/data/universe.json` → `meta.honesty`):**

- Global: `Offline demo — no live API`
- Cards / DEM-07: `MOCK — not Visa/Mastercard certified`
- Resilience / DEM-10: `DEMO STORYBOARD — not a live HA failover`

---

## 1. Executive summary

**Yes — we can showcase a credible offline DEM walk across admin + customer Flutter + agent Flutter**, provided presenters use **seeded logins**, keep **core-api stopped**, and **never overclaim** Visa/MC, live HA, or live MNO/bank/MTO rails.

| Band | Estimate | Notes |
| --- | --- | --- |
| DEM-01…DEM-12 showcase-ready (honest mock allowed) | **~10.5 / 12 ≈ 85–90%** | 10 SHOWCASE READY; DEM-01 PARTIAL; DEM-02 products *create* is thin but maker-checker walk is ready |
| Cross-channel continuity | **Pre-seeded IDs, not live sync** | Documented YAGNI in `docs/demo/DEM-SCRIPT.md` — mutations stay in-app session |
| Brand / login readiness | **Code ready; docs drifted** | Staff/customer emails in seed + admin login are `@postefinance.com`; DEM-SCRIPT / README_APPS still `@yole.com` |
| Production / RFP MUST compliance | **Out of scope here** | Still ~low (see prior coverage audit) — offline depth ≠ bid acceptance |

**Bottom line for a 30–45 min live demo:** run the recommended walk below; lead with DEM-06 → DEM-03 → DEM-02/04 → DEM-07 (MOCK) → DEM-08/09 → DEM-11/12; close with DEM-10 storyboard. Call out honesty banners every time cards or HA appear.

---

## 2. Recommended live demo walk order (30–45 min)

**Prep (2 min):** Stop anything on `:3000`. Admin `NEXT_PUBLIC_OFFLINE_DEMO=true` (`apps/admin_web/.env.local`). Customer/agent `--dart-define=OFFLINE_DEMO=true`. Confirm Network has **no** `:3000` calls.

| # | Min | DEM | What to click | Talk track |
| --- | ---: | --- | --- | --- |
| 1 | 3 | — | Admin login **`admin@postefinance.com` / `Password1!`** (not `@yole.com`) | Offline badge in header + **Reset demo** |
| 2 | 5 | DEM-06 | Customer `kasee.demo@postefinance.com` → history/receipts W2W/MNO/bank/bill; Admin Payments + Customer 360 `cust_kasee` | Dual wallets + journal IDs; best Phase-1 story |
| 3 | 4 | Agent | Agent ID **`agent-001`** → float CDF/USD → enroll / cash-in (session) | Companion channel; admin shows *pre-seeded* agent journals |
| 4 | 5 | DEM-03 | Admin Payroll `emp_poste`; Customer `amina.payroll@postefinance.com` → Credit; Admin 360 schedule `loan_amina_active_001` | Salary-driven eligibility (not always-true) |
| 5 | 4 | DEM-02 | `/dashboard/products` → `/dashboard/approvals` approve `apr_fee_w2w_001` | Maker-checker + effective fee change |
| 6 | 3 | DEM-04 | `/dashboard/credit-exceptions` approve `loan_kasee_exception_001` | Threshold exception → ACTIVE + schedule |
| 7 | 3 | DEM-05 | `/dashboard/idempotency` Replay `idem_replay_demo_001` twice → Compensate | No duplicate; reverse journal + notify |
| 8 | 4 | DEM-07 | Customer Cards + Admin Cards | Exact **MOCK** banner; 3DS `cauth_kasee_3ds_001`; dispute case |
| 9 | 3 | DEM-08 | Customer Remittance + Admin `/dashboard/remittance` Clear/Refund + Partner recon | Screening-hit exception path |
| 10 | 3 | DEM-09 | Admin Cases `case_aml_conf_001` Investigate → Recommend → Approve | CONFIDENTIAL + SoD |
| 11 | 3 | DEM-11+12 | `/dashboard/recon` Run EOD; `/dashboard/export` download | Finance close + open-format exit |
| 12 | 2 | DEM-10 | `/dashboard/resilience` | Exact **DEMO STORYBOARD** banner — not live HA |
| 13 | 2 | DEM-01 | Customer seeded login dual wallets; *optional* register/OTP `123456` | Full legacy KYC submit may still hit Yole API — prefer seeded path |

---

## 3. DEM-01…DEM-12 matrix

| ID | RFP scenario (Appendix A) | Status | Where to click / evidence | Gaps |
| --- | --- | --- | --- | --- |
| **DEM-01** | Self-reg → OTP/device → eKYC/screening → CDF/USD wallet | **PARTIAL** | **Ready:** Customer login `kasee.demo@postefinance.com` → Home dual wallets (`lib/screens/home_screen.dart` + `OfflineDemoRepository.getMyWallets`). OTP always `123456` (`offline_demo_repository.dart` `demoOtp`). Register via `CoreAuthService` offline. Admin KYC queue `/dashboard/kyc`. Seed bookmark `cust_kasee`. | **Full eKYC UI** still uses `lib/services/kyc_service.dart` → `YoleApiService` (**HTTP**, not offline). Device binding/step-up thin. Customer chrome often lacks global offline badge. Screening not a first-class customer step. |
| **DEM-02** | Create segment/product; limits/fees; maker-checker; effective date | **SHOWCASE READY** | `/dashboard/products` lists products + fee/limit rows (`apps/admin_web/app/dashboard/products/page.tsx`). `/dashboard/approvals` Approve/Reject `apr_fee_w2w_001` (`approvePending` in `lib/offline/store.ts`; tested in `store.mutations.test.ts`). Sidebar: Products & rules / Pending approvals. | **Create** new segment/product UI is **THIN** (list-only). Walk uses seeded pending fee change — honest for demo; full BO product factory still not built. |
| **DEM-03** | Payroll → eligibility → salary advance → terms/PIN → wallet + schedule | **SHOWCASE READY** | Admin `/dashboard/payroll` employer `emp_poste`. Customer Credit (`credit_screen.dart` / `credit_apply_screen.dart`) — eligibility from `salaryHistory` for `cust_amina` (`checkCreditEligibility`). Admin Customer 360 shows `loan_amina_active_001` + `loanSchedules`. | Live apply mutates **customer session only**; admin schedule is **pre-seeded**. PIN UX present but soft. |
| **DEM-04** | Auto loan + threshold exception → maker-checker | **SHOWCASE READY** | `/dashboard/credit-exceptions` Approve `loan_kasee_exception_001` → ACTIVE + schedule + wallet credit + journal (`decideCreditException`; reset evidence test). Optional micro-loan path for KYC-approved customers. | Auto consumer loan STP narrative thinner than exception queue; no separate Credit portal role. |
| **DEM-05** | Interrupted/replayed payment; no dup; compensate; notify | **SHOWCASE READY** | `/dashboard/idempotency` Replay confirm key `idem_replay_demo_001`; Compensate `pay_kasee_idem_001` (`replayIdempotentConfirm`, `compensatePayment`). | Packaged as **admin lab**, not live interrupt of Flutter mid-flight. |
| **DEM-06** | MM/bank/W2W/bill + receipt/ledger/recon trace | **SHOWCASE READY** | Seeded `pay_kasee_w2w_001`, `_mno_001`, `_bank_001`, `_bill_001`. Customer history via `CoreApiService.listPayments` offline. Admin Payments + Customer 360 + journals. Agent cash-in/out offline (`offline_agent_repository.dart`). | Public-service/QR/tax thin. Cross-app agent cash-in **not** live-synced to admin (pre-seeded journals). |
| **DEM-07** | Virtual Visa/MC + controls + 3DS + clearing + dispute | **SHOWCASE READY** *(honest MOCK)* | Customer `cards_screen.dart` banner exact MOCK string. Admin `/dashboard/cards` banner + Mock 3DS table `cauth_kasee_3ds_001` + dispute `case_card_dispute_001`. | **Not** Visa/MC certified; no real clearing/settlement — must keep MOCK banner visible. |
| **DEM-08** | Inbound remittance quote/screen → payout → exception/refund → partner/FX recon | **SHOWCASE READY** | Customer `remittance_screen.dart` + offline quote/confirm. Admin `/dashboard/remittance` Clear / Refund / Partner recon stub (`remittanceAction`). Seeds `rmt_clear_001`, `rmt_screen_hit_001`. | Partner recon is explicitly a **stub**. Multi-MTO corridor routing narrative thin. |
| **DEM-09** | AML/fraud alert → confidential case → investigation → maker-checker → audit | **SHOWCASE READY** | Admin `/dashboard/cases` — `case_aml_conf_001` `confidential: true`; Investigate / Recommend / Maker-checker approve (`advanceAmlCase`). | Soft RBAC (approverRole badge); not production SoD/MFA. |
| **DEM-10** | Node failure → failover → RTO/RPO → ledger integrity | **SHOWCASE READY** *(storyboard)* | `/dashboard/resilience` with exact **DEMO STORYBOARD** banner + balanced journals panel. | Intentionally **not** live HA — do not claim RTO/RPO evidence beyond storyboard. |
| **DEM-11** | EOD/BOD, GL/sub-ledger, suspense, reporting drill-down | **SHOWCASE READY** | `/dashboard/recon` date `2026-09-16` / `recon_2026-09-16`; **Run EOD** (`runEod`) writes snapshot, suspense/GL flags. | Regulatory report drill-down thin; BOD less emphasized than EOD. |
| **DEM-12** | Open-format export of customer universe | **SHOWCASE READY** | `/dashboard/export` → Download `yole-demo-export.json` (`buildExportPack`). | Filename still **yole-*** (brand drift). Zip/CSV multi-file pack not separate — single JSON universe export. |

### Agent companion (supports DEM-01/06)

| Surface | Status | Evidence |
| --- | --- | --- |
| Agent Flutter offline | **SHOWCASE READY** | `apps/agent_mobile/lib/services/offline_agent_repository.dart` + `agent_api_service.dart` gate; login `agent-001`; float/enroll/cash-in/out; test `offline_agent_repository_test.dart` |
| Global offline badge on agent | **THIN / missing** | AppBar title “Poste Finance Agent”; no exact global honesty string |

---

## 4. RFP chapter coverage matrix (showcase lens)

| Chapter area | Showcase status | Primary evidence | Notes |
| --- | --- | --- | --- |
| KYC / channels | **PARTIAL** | Customer register/login/OTP offline; KYC screens exist; Admin KYC queue | Full KYC submit still legacy `YoleApiService`; FR/EN l10n present |
| Wallet / payments / agents | **SHOWCASE READY** | Dual CDF/USD wallets; quote/confirm payments; agent float cash-in/out; Admin payments | Mock adapters; offline store + Flutter repos |
| Payroll / credit | **SHOWCASE READY** | Payroll admin; salary-driven eligibility; advances; exception queue; 360 schedules | Session vs pre-seed continuity limits |
| Cards | **SHOWCASE READY** *(MOCK)* | Virtual debit + controls + mock 3DS + dispute + banners | Honesty mandatory |
| Remittance / FX | **SHOWCASE READY** / **PARTIAL** FX | Admin remittance actions; customer remittance/FX screens; `fxRates` in universe | FX maker-checker/history thin |
| Back-office config | **PARTIAL** → **SHOWCASE READY** for fees maker-checker | Products list + Pending approvals + Fees & Limits config | No full product factory create UI |
| Customer 360 | **SHOWCASE READY** | `/dashboard/customer360` wallets/loans/schedules/payments/cards/cases | Docs/audit vault still light |
| Recon / reporting | **SHOWCASE READY** | Recon EOD + dashboard KPIs + export pack | Partner file matching stub-level |
| APIs / integrations | **THIN SHELL** *(offline)* | Offline path **disables** live API on purpose | Ports/mocks exist in core-api for when online; not the offline demo story |
| Security / fraud | **PARTIAL** → **SHOWCASE READY** for AML case | Confidential AML workflow + soft RBAC (`rbac.ts`) | No MFA; screening seeded not live lists |
| NFR / resilience | **SHOWCASE READY** *(storyboard)* | Resilience page + honesty banner | Not measurable HA/DR |

---

## 5. Blocking gaps for showcase (prioritized)

| Prio | Gap | Impact | Fix hint |
| --- | --- | --- | --- |
| **P0** | DEM-SCRIPT / README_APPS still document `@yole.com` while seed + admin login use `@postefinance.com` | Live demo login **fails** if presenter follows the script | Update `docs/demo/DEM-SCRIPT.md`, `README_APPS.md` checklist to `@postefinance.com` |
| **P1** | DEM-01 full eKYC path (`KycService` → `YoleApiService`) not offline-gated | Option B register→KYC **breaks** with API stopped | Route `kyc_provider` / OTP screens through `OfflineDemoRepository.submitKyc` / `requestOtp` when `OFFLINE_DEMO` |
| **P2** | Customer + Agent missing global `Offline demo — no live API` chrome (admin Header has it) | Honesty inconsistency vs DEM-SCRIPT §3 | Banner/snackbar on Flutter scaffolds when offline |
| **P3** | DEM-02 “create product/segment” is list-only | RFP wording expects create-in-BO; walk relies on seeded approval | Thin “propose fee/limit change” form or accept scripted seed as showcase |
| **P4** | Export download still named `yole-demo-export.json`; guest fallback `guest@yole.com` | Brand slip in front of Poste Finance | Rename export; scrub leftover `@yole.com` UI strings |
| **P5** | No cross-app live mutation sync | Presenter may expect agent cash-in to appear instantly in admin | Stick to DEM-SCRIPT: pre-seeded trails; Reset demo per app |

Non-blocking but call out: Color Admin sidebar scroll fix is on branch (DEM nav below fold reachable); Next 15.5 + Poste logo on login (`/assets/img/brand/poste-finance-logo-header.png`).

---

## 6. Doc / script drift to fix (emails, logos)

| Item | Current code (truth) | Stale docs |
| --- | --- | --- |
| Staff emails | `admin@postefinance.com`, `ops@`, `support@`, `finance@` in `universe.json` + `apps/admin_web/app/login/page.tsx` | `docs/demo/DEM-SCRIPT.md` §2 / checklist; `README_APPS.md` still `@yole.com` |
| Customer emails | `kasee.demo@postefinance.com`, `amina.payroll@postefinance.com` | Same docs |
| Agent ID | `agent-001` | Script correct |
| OTP | `123456` | Script correct |
| Logo | Poste Finance header logo on admin login | OK on code path; ensure Flutter `yole_logo` widget not shown as brand in offline demo if still Yole-named asset |
| Export filename | `yole-demo-export.json` | Script §DEM-12 matches code but **brand-wrong** |
| Design persona table | Older offline design on box used `@yole.com` | Repo design `docs/superpowers/specs/2026-09-17-poste-finance-offline-mock-design.md` — align emails if still Yole |

---

## 7. What’s intentionally MOCK / DEMO STORYBOARD

| Topic | Label | Surfaces |
| --- | --- | --- |
| Offline mode | `Offline demo — no live API` | Admin `Header.tsx` badge; universe `meta.honesty.globalBadge`; **should** appear on Flutter |
| Cards / DEM-07 | `MOCK — not Visa/Mastercard certified` | Customer cards screen; Admin cards page; universe seed `MOCK Virtual Debit`, `2.2-MOCK` 3DS |
| Resilience / DEM-10 | `DEMO STORYBOARD — not a live HA failover` | `/dashboard/resilience` |
| Remittance partners | MOCK-MTO-WEST / EAST | Universe remittances; partner recon stub message in store |
| Screening | Seeded hit/clear rows | Not live sanctions lists |
| Cross-app sync | Pre-seeded continuity | DEM-SCRIPT §intro — session mutations local |
| core-api | **Stopped** for acceptance | Online Nest mocks exist but are out of offline showcase scope |

---

## Evidence index (paths)

| Layer | Paths |
| --- | --- |
| Seed | `packages/demo_universe/data/universe.json` (`meta.demBookmarks`, `meta.honesty`, staff `@postefinance.com`) |
| Admin offline | `apps/admin_web/lib/offline/store.ts`, `flags.ts`, `apps/admin_web/lib/api.ts` |
| Admin DEM pages | `apps/admin_web/app/dashboard/{products,approvals,credit-exceptions,idempotency,remittance,resilience,export,recon,cards,cases,customer360,payroll,payments,kyc}/page.tsx` |
| Customer offline | `lib/services/offline_demo_repository.dart`, `core_api_service.dart`, `core_auth_service.dart` |
| Agent offline | `apps/agent_mobile/lib/services/offline_agent_repository.dart`, `agent_api_service.dart` |
| Script | `docs/demo/DEM-SCRIPT.md` |
| Tests | `apps/admin_web/lib/offline/store.mutations.test.ts`, `reset.evidence.test.ts`; `test/offline_demo_repository_test.dart`; `apps/agent_mobile/test/offline_agent_repository_test.dart` |

---

## Delta vs prior RFP coverage audit (same day)

| DEM | Prior (coverage audit @ e47650f era) | This showcase audit @ 1283032 |
| --- | --- | --- |
| DEM-01 | PARTIAL | **PARTIAL** (seeded ready; KYC HTTP gap remains) |
| DEM-02 | BLOCKED | **SHOWCASE READY** (approvals + products list) |
| DEM-03 | BLOCKED / thin | **SHOWCASE READY** (salary eligibility + schedule) |
| DEM-04 | BLOCKED | **SHOWCASE READY** |
| DEM-05 | PARTIAL | **SHOWCASE READY** (idempotency lab) |
| DEM-06 | WALKABLE | **SHOWCASE READY** offline |
| DEM-07 | BLOCKED | **SHOWCASE READY** with MOCK honesty |
| DEM-08 | PARTIAL inbound | **SHOWCASE READY** admin remittance |
| DEM-09 | PARTIAL / weak | **SHOWCASE READY** AML workflow |
| DEM-10 | BLOCKED | **SHOWCASE READY** storyboard |
| DEM-11 | BLOCKED | **SHOWCASE READY** EOD |
| DEM-12 | BLOCKED | **SHOWCASE READY** export |

---

*End of showcase audit. Showcase ≠ production acceptance. Keep honesty banners on.*
