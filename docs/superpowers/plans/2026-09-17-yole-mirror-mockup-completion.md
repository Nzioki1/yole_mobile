# Yole Mirror Mockup Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete a mirror mockup of Poste Finance / Yole customer requirements across three channels — customer Flutter app, agent Flutter app, and backend admin web — using the existing Phase 1–4 in-memory mock core-api (no new product phases).

**Architecture:** Keep Approach A (modular NestJS core-api + thin channels). Extend mock APIs only where UI needs a missing endpoint. Customer app stays the root Flutter package; agent stays `apps/agent_mobile`; admin stays `apps/admin_web`. Work in waves: Wave A finishes Phase 1 customer gaps; Waves B–D polish Phases 2–4 UI/admin on APIs already present.

**Tech Stack:** Flutter (customer + agent), Next.js admin web, NestJS core-api with in-memory stores, JWT customer auth, `X-Agent-Id` / `X-Admin-API-Key` for agent/admin.

**Repo / branch:** `Nzioki1/yole_mobile` — continue on `cursor/task1-monorepo-scaffold-1d8a` (PR #1) unless user opens a new branch.

## Global Constraints

- Stay on **in-memory mocks** (no Postgres / real MNO / Pesapal / card scheme) until user says otherwise.
- Customer happy-path auth is **CoreAuthService → mock JWT** (`POST /v1/auth/register|login`), not Pesapal/yolepesa.
- Chrome demo uses `--dart-define=API_BASE_URL=http://localhost:3000`; keep CORS enabled on core-api for web.
- Preserve web-safe HTTP (no `dart:io` in web path).
- Ask before destructive/big scope changes; prefer drafts on PR #1.
- French-first / FR+EN toggle is a Phase 1 acceptance item for customer UI.
- End state: customer app + agent app + admin web demonstrably cover Phase 1–4 **customer-facing and ops mockups** from the design spec + `user_journey.md` + RFP skim (not production go-live gates).

## End-state definition of done

1. **Customer app:** Fund/withdraw, PIN-on-confirm, pending/blocked balances, limits, receipts, FR/EN, notifications, multi-rail pay (existing), KYC, favorites→rails, transaction detail; Phase 2–4 screens no longer stubs (credit, cards, remittance/FX usable demos).
2. **Agent app:** Enroll, cash-in/out, float balances, basic customer lookup — reliable against mock API.
3. **Admin web:** Customer 360, KYC queue, agents, payments search, fees/limits, payroll employers, cases/recon, cards/credit/remittance ops views wired to existing admin APIs.
4. **Docs:** Single runbook to demo full stack locally (API :3000, admin :3001, both Flutter apps).

## File map (major touch points)

| Area | Paths |
| --- | --- |
| Customer shell | `lib/screens/home_screen.dart`, `lib/screens/main_tabs.dart`, `lib/widgets/yole_bottom_nav.dart`, `lib/app_router.dart`, `lib/router_types.dart` |
| Customer payments | `lib/screens/payment_*.dart`, `lib/services/core_api_service.dart`, `lib/services/core_auth_service.dart` |
| Customer KYC / profile | `lib/screens/kyc_*.dart`, `lib/screens/profile_screen.dart`, `lib/screens/favorites_screen.dart`, `lib/screens/transactions_history_screen.dart` |
| Customer P2–P4 | `lib/screens/credit_screen.dart`, `lib/screens/cards_screen.dart`, `lib/screens/fx_screen.dart`, new `lib/screens/remittance_*.dart`, `lib/screens/fund_*.dart`, `lib/screens/withdraw_*.dart` |
| Agent | `apps/agent_mobile/lib/**` |
| Admin | `apps/admin_web/app/**`, `apps/admin_web/lib/api.ts` |
| Core API | `services/core-api/src/modules/{payments,wallets,identity,agents,admin,credit,cards,fx,remittance,payroll,kyc}/**` |
| Docs | `README_FLUTTER.md`, `README_APPS.md`, this plan |

---

## Wave A — Phase 1 customer-completion pass

### Task A1: Fund wallet (Add money) — MNO-in / bank-in mocks

**Files:**
- Create: `lib/screens/fund_wallet_screen.dart`
- Modify: `lib/screens/home_screen.dart` (Add money CTA)
- Modify: `lib/app_router.dart`, `lib/router_types.dart`
- Modify: `lib/services/core_api_service.dart` (if inbound rails missing, add quote/confirm helpers)
- Modify / Create: `services/core-api/src/modules/payments/*` only if `MNO_IN` / `BANK_IN` (or equivalent) not already supported

**Interfaces:**
- Consumes: JWT via `CoreApiService`; payment quote/confirm pattern already used by outbound rails
- Produces: Customer can credit CDF/USD wallet via mock inbound rail; home refresh shows new available balance

- [ ] **Step 1:** Confirm whether payments service already accepts inbound types; if not, add mock inbound quote/confirm that credits `CUST_WALLET` from a mock rail liability account (ledger-balanced).
- [ ] **Step 2:** Add `FundWalletScreen` — pick rail (MNO / Bank), amount, currency, mock source fields → quote → confirm → result.
- [ ] **Step 3:** Wire Home “Add money” / fund CTA to `/fund`.
- [ ] **Step 4:** Manual test: register → fund $50 USD → wallets/me shows availableMinor increased.
- [ ] **Step 5:** Commit `feat(customer): fund wallet MNO/bank mock inbound`

### Task A2: Withdraw / cash-out (MNO / bank out from wallet)

**Files:**
- Create: `lib/screens/withdraw_screen.dart`
- Modify: `lib/screens/home_screen.dart`, router, `core_api_service.dart`
- Reuse: existing `MNO_OUT` / `BANK_OUT` payment quote/confirm where possible

**Interfaces:**
- Consumes: Outbound payment rails
- Produces: Withdraw flow from Home that debits wallet after PIN (PIN wired in A3)

- [ ] **Step 1:** Implement withdraw UI reusing payment form patterns for MNO_OUT/BANK_OUT.
- [ ] **Step 2:** Wire Home “Withdraw” action.
- [ ] **Step 3:** Test insufficient funds + happy path after fund.
- [ ] **Step 4:** Commit `feat(customer): withdraw to MNO/bank mocks`

### Task A3: Transaction PIN on confirm (+ optional biometric stub)

**Files:**
- Create: `lib/widgets/pin_confirm_sheet.dart` (or `lib/screens/pin_confirm_screen.dart`)
- Modify: `lib/screens/payment_quote_screen.dart` (and fund/withdraw confirm)
- Modify: `lib/services/core_api_service.dart` / identity mocks if PIN set/verify endpoints needed
- Optional API: `POST /v1/auth/pin/set`, `POST /v1/auth/pin/verify` in-memory

**Interfaces:**
- Consumes: Confirm payment/fund/withdraw actions
- Produces: No debit without successful PIN (mock: 4–6 digit PIN stored hashed or plain in memory for demo)

- [ ] **Step 1:** Add mock PIN set on first use (profile or post-register prompt).
- [ ] **Step 2:** Gate Confirm behind PIN sheet; wrong PIN blocks API call.
- [ ] **Step 3:** Optional “Use device biometrics” button that succeeds in mock/Chrome stub.
- [ ] **Step 4:** Commit `feat(customer): PIN gate before payment confirm`

### Task A4: Pending / blocked balances on Home

**Files:**
- Modify: `lib/screens/home_screen.dart` (`_WalletCard` / pocket flattening)
- Optional: `services/core-api/.../wallets.service.ts` already exposes `blockedMinor`, `pendingOutMinor`, `pendingInMinor`

**Interfaces:**
- Consumes: `GET /v1/wallets/me` pocket fields
- Produces: Home shows Available + Pending (and Blocked if > 0)

- [ ] **Step 1:** Extend pocket display maps to include pending/blocked.
- [ ] **Step 2:** Update wallet card UI (secondary lines under available).
- [ ] **Step 3:** Commit `feat(customer): show pending/blocked wallet balances`

### Task A5: Limits on Profile (daily/monthly / KYC tier)

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Modify: `lib/services/core_api_service.dart`
- Use or add: `GET /v1/me/limits` or admin config limits filtered for customer; if missing, add thin mock endpoint returning KYC-tier defaults

**Interfaces:**
- Produces: Profile section “Limits” with daily/monthly remaining vs cap

- [ ] **Step 1:** Ensure mock limits endpoint exists (customer-readable).
- [ ] **Step 2:** Profile Limits card wired to API.
- [ ] **Step 3:** Commit `feat(customer): show KYC-tier limits on profile`

### Task A6: Quote taxes + full debit breakdown; shareable receipt

**Files:**
- Modify: `lib/screens/payment_quote_screen.dart`, `lib/screens/payment_result_screen.dart`
- Modify: payments quote response to include `taxMinor` / `totalDebitMinor` if not present (`services/core-api/.../payments.service.ts`)
- Optional: `share_plus` or web share for receipt text

**Interfaces:**
- Quote shows amount, fee, tax, total debit
- Result offers Share / Copy receipt (payment id, rail, amounts, timestamp)

- [ ] **Step 1:** Extend mock quote payload with tax (can be 0 or fixed %).
- [ ] **Step 2:** Update quote UI breakdown.
- [ ] **Step 3:** Result screen share/copy receipt.
- [ ] **Step 4:** Commit `feat(customer): tax breakdown and shareable receipt`

### Task A7: Working FR/EN language switch

**Files:**
- Modify: language route stub in `lib/app_router.dart` / dedicated language screen
- Modify: `lib/screens/profile_screen.dart` (entry)
- Use existing `l10n` / locale provider

**Interfaces:**
- Produces: Profile → Language toggles `fr` / `en` and persists

- [ ] **Step 1:** Replace “coming soon” language route with real switcher.
- [ ] **Step 2:** Persist locale; verify Home strings flip for keyed l10n.
- [ ] **Step 3:** Commit `feat(customer): FR/EN language switch`

### Task A8: Notifications center (mock)

**Files:**
- Create: `lib/screens/notifications_screen.dart`
- Modify: Home header bell → notifications
- API: in-memory `GET /v1/notifications` (+ seed on payment/KYC events) or client-local list fed after actions

**Interfaces:**
- Produces: Bell opens list of mock notifications (payment posted, KYC status)

- [ ] **Step 1:** Minimal notifications store + list UI.
- [ ] **Step 2:** Emit notification on payment success / KYC submit.
- [ ] **Step 3:** Commit `feat(customer): notifications center mock`

### Task A9: Favorites → multi-rail; retire legacy send-money primary paths

**Files:**
- Modify: `lib/screens/favorites_screen.dart`
- Modify: router — stop using `RouteNames.sendMoneyEnterDetails` as default from favorites/home
- Optional: hide or gate legacy `send_money_*` screens behind debug flag

**Interfaces:**
- Favorites “Send” opens `/payment/w2w` (or picker) with prefilled destination

- [ ] **Step 1:** Retarget favorite send to `/payment/*`.
- [ ] **Step 2:** Remove legacy CTAs from Home/Favorites; keep files but unused or debug-only.
- [ ] **Step 3:** Commit `refactor(customer): favorites use multi-rail payments`

### Task A10: Transaction detail + History vs new ledger

**Files:**
- Create: `lib/screens/transaction_detail_screen.dart`
- Modify: `lib/screens/transactions_history_screen.dart`, Home recent activity tap
- Use: `GET /v1/payments` and `GET /v1/payments/:id`

**Interfaces:**
- History lists mock payments; tap → detail (status, ids, amounts, rail)

- [ ] **Step 1:** Wire history to `CoreApiService.listPayments`.
- [ ] **Step 2:** Detail screen from payment id.
- [ ] **Step 3:** Commit `feat(customer): payment history and detail`

### Task A11: Wave A agent polish (Phase 1 parity)

**Files:** `apps/agent_mobile/lib/**`

- [ ] **Step 1:** Reliable float display from admin/agent wallet endpoints.
- [ ] **Step 2:** Enroll + cash-in/out error handling; show customerId for handoff to customer W2W demos.
- [ ] **Step 3:** Commit `feat(agent): Phase 1 polish float and cash ops`

### Task A12: Wave A admin polish (Phase 1 ops)

**Files:** `apps/admin_web/app/dashboard/**`, `apps/admin_web/lib/api.ts`

- [ ] **Step 1:** Ensure Customer 360, Payments search, Fees/Limits, KYC, Agents are real pages (not stubs) against admin APIs.
- [ ] **Step 2:** Demo script section in `README_APPS.md`.
- [ ] **Step 3:** Commit `feat(admin): Phase 1 ops pages complete`

### Wave A exit criteria

Customer can: register/login → see balances (available/pending) → fund → pay (PIN) → withdraw → see receipt/history → view limits → switch FR/EN → see notifications. Agent can enroll + cash-in. Admin can review customer 360 / KYC / payments / agents / fees.

---

## Wave B — Phase 2 UI (payroll + credit)

### Task B1: Customer credit journey (not stub)

**Files:** `lib/screens/credit_screen.dart` (+ possibly `credit_apply_screen.dart`, `credit_loan_detail_screen.dart`)
**API:** existing `GET /v1/credit/eligibility/:type`, `POST /v1/credit/loans`, `GET /v1/credit/loans`

- [ ] **Step 1:** Eligibility check UI from API.
- [ ] **Step 2:** Apply with amount/type; show mock terms + consent checkbox.
- [ ] **Step 3:** Loan list + detail (schedule mock).
- [ ] **Step 4:** Commit `feat(customer): Phase 2 credit journey`

### Task B2: Admin payroll employers + salary credit demo

**Files:** admin payroll pages; APIs `GET/POST /v1/admin/payroll/employers`, salary credit

- [ ] **Step 1:** Employers list/create UI.
- [ ] **Step 2:** Import employees + trigger salary credit mock; verify customer wallet credited.
- [ ] **Step 3:** Commit `feat(admin): Phase 2 payroll ops`

### Wave B exit criteria

Customer can request and view a mock loan; admin can run a mock payroll credit that lands in a customer wallet.

---

## Wave C — Phase 3 UI (cards)

### Task C1: Customer card lifecycle

**Files:** `lib/screens/cards_screen.dart` (+ issue/controls screens)
**API:** `POST/GET /v1/cards`, freeze/activate/block/limits, transactions, mock-auth

- [ ] **Step 1:** Issue virtual card from wallet currency.
- [ ] **Step 2:** Freeze / activate / block controls.
- [ ] **Step 3:** Set limits; list mock card transactions.
- [ ] **Step 4:** Commit `feat(customer): Phase 3 card lifecycle`

### Task C2: Admin card oversight (thin)

**Files:** admin cards page listing customer cards / status via admin search or new thin admin list endpoint if needed

- [ ] **Step 1:** Admin view of cards + status.
- [ ] **Step 2:** Commit `feat(admin): Phase 3 cards overview`

### Wave C exit criteria

Customer can issue and control a mock card; admin can see card status.

---

## Wave D — Phase 4 UI (remittance + FX + admin depth)

### Task D1: Customer remittance (inbound/outbound quote flows)

**Files:** Create `lib/screens/remittance_screen.dart` (+ quote/confirm)
**API:** existing remittance controllers

- [ ] **Step 1:** Outbound quote/confirm UI.
- [ ] **Step 2:** Inbound quote/confirm UI (or claim).
- [ ] **Step 3:** Home quick action Remittance.
- [ ] **Step 4:** Commit `feat(customer): Phase 4 remittance`

### Task D2: Customer FX beyond stub

**Files:** `lib/screens/fx_screen.dart`
**API:** rates + convert

- [ ] **Step 1:** Show rates; convert between CDF/USD pockets with confirmation + receipt line.
- [ ] **Step 2:** Commit `feat(customer): Phase 4 FX convert UX`

### Task D3: Admin recon + cases + remittance/FX ops

**Files:** admin dashboard modules for recon daily, cases, remittance search if endpoints exist

- [ ] **Step 1:** Wire recon + cases pages fully.
- [ ] **Step 2:** Smoke-test fees/limits/payroll/cards/credit from admin nav.
- [ ] **Step 3:** Commit `feat(admin): Phase 4 recon cases depth`

### Task D4: Final demo runbook + gap checklist

**Files:** `README_APPS.md`, `README_FLUTTER.md`, optional `docs/superpowers/plans/2026-09-17-yole-mirror-mockup-completion.md` (this file)

- [ ] **Step 1:** Document full demo: API, admin, customer, agent; seeded users; PIN; fund→pay→withdraw; credit; cards; FX; remittance.
- [ ] **Step 2:** Checklist mapping RFP/mockup items → screen.
- [ ] **Step 3:** Commit `docs: mirror mockup completion runbook`

### Wave D / program exit criteria

All three channels demo Phase 1–4 customer + ops journeys on mocks. No reliance on Pesapal for primary flows. PR #1 (or follow-on PR) green enough for stakeholder walkthrough.

---

## Suggested execution order

A1 → A2 → A3 → A4 → A6 → A5 → A7 → A8 → A9 → A10 → A11 → A12 → B1 → B2 → C1 → C2 → D1 → D2 → D3 → D4

(PIN before shareable receipts on confirm paths; fund before withdraw tests.)

## Out of scope (explicit)

- Real MNO/bank/card-scheme integrations, Postgres migration, USSD, production DR/certification
- Full visual rebrand
- Replacing Nest mock stores with real ledger DB

## Spec coverage self-check

| Requirement source | Covered by |
| --- | --- |
| Phase 1 P0 audit gaps (fund, withdraw, PIN, pending, limits, tax/receipt, FR/EN, notifications, favorites→rails, history detail) | A1–A10 |
| Agent Phase 1 | A11 |
| Admin Phase 1 | A12 |
| Phase 2 credit + payroll | B1–B2 |
| Phase 3 cards | C1–C2 |
| Phase 4 remittance/FX/admin depth | D1–D4 |
| End: customer + agent + admin mirror | Wave exit criteria + D4 |

