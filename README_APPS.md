# YOLE Mirror Mockup - Complete Demo Guide

This document provides a comprehensive guide for demoing all features of the YOLE neo-bank platform across all four phases (Phase 1-4).

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Offline Poste DEM (API stopped)](#offline-poste-dem-api-stopped)
- [Quick Start](#quick-start)
- [Demo Credentials](#demo-credentials)
- [Complete Demo Runbook](#complete-demo-runbook)
- [Feature Gap Checklist](#feature-gap-checklist)
- [Known Limitations](#known-limitations)

---

## Architecture Overview

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  Customer Flutter   │────▶│   NestJS Core API    │◀────│   Admin Web     │
│  (lib/)             │     │   (:3000)            │     │   (:3001)       │
│  Chrome/Mobile      │     │   In-memory mocks    │     │   Next.js       │
└─────────────────────┘     └──────────────────────┘     └─────────────────┘
                                     ▲
                                     │
                            ┌────────┴────────┐
                            │  Agent Flutter  │
                            │  (agent_mobile/)│
                            │  Chrome/Mobile  │
                            └─────────────────┘
```

**Tech Stack:**
- **Backend:** NestJS (TypeScript) with in-memory stores
- **Customer App:** Flutter (web + mobile)
- **Agent App:** Flutter (web + mobile)
- **Admin Web:** Next.js + React + TypeScript
- **Database:** In-memory (no persistence across restarts)


---

## Offline Poste DEM (API stopped)

For Poste Finance scenarios **DEM-01…DEM-12**, run all clients against the shared `packages/demo_universe` seed with **core-api stopped**. Full click paths and acceptance checklist: **[`docs/demo/DEM-SCRIPT.md`](docs/demo/DEM-SCRIPT.md)**.

### Offline flags

| App | Flag |
| --- | --- |
| Admin Web | `NEXT_PUBLIC_OFFLINE_DEMO=true` (in `apps/admin_web/.env.local`) |
| Customer Flutter | `--dart-define=OFFLINE_DEMO=true` |
| Agent Flutter | `--dart-define=OFFLINE_DEMO=true` |

With flags on, clients must **never** `fetch` / `dio` / `http` to `localhost:3000` or any API base URL.

### Start clients (do not start API)

```bash
# 1) Confirm API :3000 is STOPPED
lsof -iTCP:3000 -sTCP:LISTEN || echo "OK: nothing on :3000"

# 2) Admin
cd apps/admin_web && pnpm install && pnpm dev
# http://localhost:3001 — login admin@yole.com / Password1!

# 3) Customer (repo root)
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
# kasee.demo@yole.com or amina.payroll@yole.com / Password1!

# 4) Agent
cd apps/agent_mobile
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
# Agent ID: agent-001
```

### Acceptance (minimum)

- [ ] core-api / `:3000` process **stopped**
- [ ] All three apps walk DEM-01…DEM-12 per `docs/demo/DEM-SCRIPT.md`
- [ ] Browser Network tab shows **no** `:3000` traffic
- [ ] Honesty banners exact: `Offline demo — no live API`; cards `MOCK — not Visa/Mastercard certified`; resilience `DEMO STORYBOARD — not a live HA failover`
- [ ] Admin header **Reset demo** restores seed after mutations

Shared IDs: `cust_kasee`, `cust_amina`, `agent-001`, `emp_poste`. Staff passwords: `Password1!`.

---

## Quick Start

> **Offline DEM?** Skip starting Core API. Use [Offline Poste DEM (API stopped)](#offline-poste-dem-api-stopped) and `docs/demo/DEM-SCRIPT.md` instead.

### 1. Start Core API (Backend)
```bash
cd services/core-api
pnpm install
pnpm dev
# API runs on http://localhost:3000
# All endpoints accessible at /v1/*
```

### 2. Start Admin Web
```bash
cd apps/admin_web
pnpm install
pnpm dev
# Admin UI runs on http://localhost:3001
```

### 3. Run Customer App (Chrome)
```bash
# From repository root — live API mode
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Offline DEM (API stopped)
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
```

### 4. Run Agent App (Chrome)
```bash
cd apps/agent_mobile
# Live API mode
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Offline DEM (API stopped) — login agent-001
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
```

**Note:** For Android emulator, omit `--dart-define` (defaults to `10.0.2.2:3000`).

---

## Demo Credentials

### Offline DEM personas (preferred for DEM-01…12)

| App | Credential |
| --- | --- |
| Admin | `admin@yole.com` / `Password1!` (also ops/support/finance @yole.com) |
| Customer | `kasee.demo@yole.com` / `Password1!` (`cust_kasee`); `amina.payroll@yole.com` / `Password1!` (`cust_amina`) |
| Agent | Agent ID **`agent-001`** (not `agent_1`) |
| OTP | Always `123456` when offline |

See `docs/demo/DEM-SCRIPT.md` for full DEM click paths.

### Admin Web
- **API Key:** `dev-admin-key`
- Used in header: `X-Admin-API-Key: dev-admin-key`
- No login screen - key is hardcoded in admin web

### Agent (Created via Admin)
1. Admin → Agents → "+ Enroll Agent"
2. Fill: First/Last name, phone, email
3. **Copy Agent ID** from success (e.g., `agent_1`)
4. In Agent App → Paste Agent ID to login
5. Float auto-seeded: CDF 50,000,000 + USD 100,000

### Customer (Self-Registration)
- Register in customer app with any email/password
- Example: `alice@demo.com` / `Password1!`
- **Transaction PIN:** Set on first payment (6 digits, e.g., `123456`)
- Mock biometric always succeeds with PIN `1234`

---

## Complete Demo Runbook

### Phase 1: Core Platform (Wave A Completion)

#### A. Admin Setup

1. **Open Admin Web** → `http://localhost:3001`
   - Dashboard shows module cards

2. **Create Agent**
   - Click "Agents"
   - Click "+ Enroll Agent"
   - Fill: `Demo` / `Agent` / `+243900000001` / `agent@demo.com`
   - **Copy Agent ID** (e.g., `agent_1`) for agent login

#### B. Agent Operations

1. **Agent Login**
   - Open Agent App (Chrome)
   - Paste Agent ID
   - View float: CDF 50M + USD 100k (auto-seeded)

2. **Enroll Customer**
   - Click "Enroll Customer"
   - Fill: `Alice` / `Demo` / `+243900000100` / `alice@demo.com` / `Password1!`
   - **Copy Customer ID** from success dialog

3. **Cash-In to Customer**
   - Click "Cash In / Out" → "Cash In"
   - Paste Customer ID
   - Amount: `100` USD
   - Click "Cash In"
   - Success: Journal ID displayed

#### C. Customer Experience

1. **Register Another Customer**
   - Customer App → "Create Account"
   - `bob@demo.com` / `Password1!` / Bob Demo
   - Skip email verification

2. **Neo-Bank Home**
   - View wallet cards (empty initially)
   - 6 quick actions: Pay/Send, Bills/Airtime, KYC, Cards, Credit, Remittance, FX
   - Recent activity (empty initially)
   - Bell icon for notifications

3. **Fund Wallet (Add Money)**
   - Home → "Add Money"
   - Select "Mobile Money" or "Bank"
   - Amount: `50` USD
   - Mock fields (any values)
   - **Set PIN** if first time: `123456`
   - Confirm → Success

4. **Send Payment (W2W)**
   - Home → "Pay / Send"
   - Select "Wallet to Wallet"
   - Destination: Paste Alice's Customer ID
   - Amount: `20` USD
   - Note: "Alice Demo"
   - Preview quote (shows fee + tax)
   - Confirm with PIN → Success

5. **Withdraw (Cash-Out)**
   - Home → "Withdraw"
   - Select "MNO_OUT" or "BANK_OUT"
   - Amount: `10` USD
   - Destination: mock phone/account
   - Preview → Confirm with PIN

6. **View History**
   - Bottom nav → "History"
   - See all payments
   - Tap any → Detail view (amounts, fees, tax, IDs)

7. **Notifications**
   - Home → Bell icon (top right)
   - See payment completion notifications
   - "Mark all read" action

8. **Profile & Settings**
   - Bottom nav → "Profile"
   - View personal info
   - **Limits:** Daily/monthly by currency (USD $1k/$10k, CDF 1M/10M)
   - **Language:** Switch FR ↔ EN (persisted)
   - **Dark Mode:** Toggle theme

9. **KYC Submission**
   - Home → "KYC" quick action
   - Fill ID document step (mock upload)
   - Fill selfie step (mock capture)
   - Submit → Status: PENDING

#### D. Admin Monitoring

1. **Customer 360**
   - Admin → "Customer 360"
   - Paste Alice's Customer ID
   - View: profile, wallets (available/blocked/pending), recent payments

2. **Payments Search**
   - Admin → "Payments Search"
   - Filter by customer/status/type
   - See all transactions

3. **KYC Queue**
   - Admin → "KYC Queue"
   - View pending submissions
   - Approve/Reject with reason

4. **Agents List**
   - Admin → "Agents"
   - See all agents, float status

5. **Fees & Limits Config**
   - Admin → "Fees & Limits"
   - View current mock configs (hardcoded)
   - UI ready for future API integration

---

### Phase 2: Credit & Payroll (Wave B Completion)

#### A. Customer Credit

1. **Check Eligibility**
   - Home → "Credit" quick action
   - View "Salary Advance" and "Micro Loan" cards
   - Eligibility shown with max amounts

2. **Apply for Loan**
   - Click "Apply Now" on eligible product
   - Enter amount (e.g., `200` USD)
   - Select currency and term (1-12 months)
   - Review mock terms (interest, fees)
   - Check "agree to terms"
   - Confirm with PIN
   - Success: Loan ID displayed

3. **View Loan Details**
   - Credit screen → "My Loans" section
   - Tap loan → See full details:
     - Status, amounts, term, rate
     - Timeline (requested, disbursed, due, repaid dates)
     - Repayment schedule (if available)

#### B. Admin Payroll

1. **Create Employer**
   - Admin → "Payroll"
   - Click "+ Create Employer"
   - Name: `ACME Corp` / Tax ID: `TAX12345`
   - Create

2. **Import Employees**
   - Click employer from list
   - Click "📋 Import Employees"
   - Paste format: `customerId,salaryMinor,currency`
   - Example:
     ```
     cust_abc123,50000,USD
     cust_def456,75000,USD
     ```
   - Import

3. **Credit Salaries**
   - Click "💰 Credit Salaries to All Employees"
   - Confirm
   - View success count

4. **Verify Credits**
   - Admin → Customer 360
   - Enter employee customer ID
   - Check wallet increased
   - Recent payments shows `SALARY_CREDIT`

---

### Phase 3: Virtual Cards (Wave C Completion)

#### A. Customer Cards

1. **Issue Card**
   - Home → "Cards" quick action
   - Click "+ Issue Card" (floating button)
   - Select wallet pocket (USD or CDF)
   - Set daily limit: `500`
   - Set monthly limit: `5000`
   - Click "Issue Card"
   - Success: Card ID displayed

2. **View Card Details**
   - Cards list → Tap card
   - See full virtual card display:
     - Card number (tap to unmask)
     - CVV (tap to copy)
     - Expiry date
     - Status badge

3. **Card Controls**
   - In card detail:
   - **Freeze:** Temporarily suspend
   - **Activate:** Unfreeze
   - **Block:** Permanent (requires confirmation)

4. **Update Limits**
   - Card detail → Edit icon on limits card
   - Change daily/monthly limits
   - Save

5. **View Transactions**
   - Card detail → Scroll to "Transactions"
   - See mock card transactions (if API generates them)

#### B. Admin Card Oversight

1. **View All Cards**
   - Admin → "Virtual Cards"
   - See all cards across customers
   - Filter by customer ID
   - View: last 4, currency, status, limits, dates

2. **Summary Stats**
   - Active, Frozen, Blocked counts
   - At bottom of cards list

---

### Phase 4: Remittance & FX (Wave D Completion)

#### A. Customer Remittance

1. **Send Money Abroad (Outbound)**
   - Home → "Remittance" quick action
   - Tab: "Send Money"
   - Amount: `100` USD
   - Select currency
   - Click "Get Quote"
   - Review: exchange rate, fee, recipient amount
   - Confirm with PIN
   - Success: Remittance initiated

2. **Receive Money (Inbound)**
   - Remittance → Tab: "Receive Money"
   - Expected amount: `50` USD
   - Click "Get Quote"
   - Review: fee deducted, net credit, quote ID
   - Click "Claim Money"
   - Success: Funds credited instantly

#### B. Customer FX (Currency Exchange)

1. **View Rates**
   - Home → "FX" quick action
   - See USD ↔ CDF exchange rates

2. **Convert Currency**
   - Select From: `USD` / To: `CDF`
   - Amount: `100`
   - Click "Preview Conversion"
   - Review: rate, amount received
   - Confirm with PIN
   - Success: Receipt with transaction ID
   - Copy ID or start new conversion

#### C. Admin Recon & Cases

1. **Daily Reconciliation**
   - Admin → "Reconciliation"
   - Select date (today or past)
   - Click "Load Summary"
   - View: total transactions, volume, status
   - Details section shows JSON data

2. **Case Management**
   - Admin → "Cases & Support"
   - Click "+ Create Case"
   - Type: DISPUTE/INQUIRY/FRAUD/OTHER
   - Description: issue details
   - Customer ID: optional link
   - Create

3. **Case Actions**
   - In cases list:
   - Pending cases show action buttons:
     - "In Progress" → Update status
     - "Resolve" → Mark resolved
     - "Close" → Close case
   - Filter by status: All/Pending/In Progress/Resolved/Closed

---

## Feature Gap Checklist

### Phase 1: Payments, Wallets, KYC, Agents ✅

| Feature | Status | Notes |
|---------|--------|-------|
| Customer registration/login | ✅ DONE | JWT-based |
| Wallet management (CDF/USD) | ✅ DONE | Available, blocked, pending tracked |
| Wallet-to-wallet (W2W) | ✅ DONE | With fee/tax |
| MNO in/out | ✅ DONE | Mock settlement accounts |
| Bank in/out | ✅ DONE | Mock settlement accounts |
| Bills payment | ✅ DONE | Mock billers |
| Airtime | ✅ DONE | Mock providers |
| Transaction PIN | ✅ DONE | Set on first use, bcrypt hashed |
| Transaction history | ✅ DONE | List + detail view |
| KYC submission | ✅ DONE | Mock document upload |
| Agent enrollment | ✅ DONE | Via admin |
| Agent cash-in/out | ✅ DONE | Debits agent float |
| Admin customer 360 | ✅ DONE | Full profile + wallets + payments |
| Admin payments search | ✅ DONE | Filter by customer/status/type |
| Admin KYC queue | ✅ DONE | Approve/reject |
| Admin agents list | ✅ DONE | View all agents |
| Admin fees/limits config | ⚠️ PARTIAL | UI exists, mock data hardcoded |
| Notifications center | ✅ DONE | Payment/KYC events |
| Language switch (FR/EN) | ✅ DONE | Persisted with SharedPreferences |
| Dark mode | ✅ DONE | Toggle in profile |
| Favorites → multi-rail | ✅ DONE | Retargeted from legacy |

### Phase 2: Credit & Payroll ✅

| Feature | Status | Notes |
|---------|--------|-------|
| Credit eligibility check | ✅ DONE | SALARY_ADVANCE, MICRO_LOAN |
| Loan application | ✅ DONE | With terms/consent |
| Loan disbursement | ✅ DONE | Instant to wallet |
| Loan list + detail | ✅ DONE | Timeline, schedule |
| Payroll employers | ✅ DONE | CRUD via admin |
| Employee import | ✅ DONE | CSV format via admin |
| Salary credit | ✅ DONE | Bulk posting to wallets |

### Phase 3: Virtual Cards ✅

| Feature | Status | Notes |
|---------|--------|-------|
| Card issuance | ✅ DONE | Linked to wallet pocket |
| Card freeze/activate | ✅ DONE | Temporary suspension |
| Card block | ✅ DONE | Permanent, with confirmation |
| Card limits (update) | ✅ DONE | Daily/monthly |
| Card transactions | ✅ DONE | Mock auth endpoint exists |
| Admin cards oversight | ✅ DONE | List all cards, filter by customer |

### Phase 4: Remittance, FX, Recon ✅

| Feature | Status | Notes |
|---------|--------|-------|
| Remittance inbound quote | ✅ DONE | Fee deducted from incoming |
| Remittance inbound confirm | ✅ DONE | Claim money |
| Remittance outbound quote | ✅ DONE | Exchange rate, fees |
| Remittance outbound confirm | ⚠️ PARTIAL | Quote created, confirm pending backend |
| FX rates display | ✅ DONE | USD ↔ CDF |
| FX conversion | ✅ DONE | Preview-then-confirm with PIN |
| Daily reconciliation | ✅ DONE | Date-based lookup |
| Case management | ✅ DONE | CRUD + status workflow |
| **Admin remittance list** | ❌ MISSING | No `/v1/admin/remittance` endpoint |
| **Admin FX conversions list** | ❌ MISSING | No `/v1/admin/fx/conversions` endpoint |

---

## Known Limitations

### 1. **In-Memory Storage (No Persistence)**
- **Impact:** All data resets when API restarts
- **Workaround:** Keep API running during demos
- **Production Fix:** Add Postgres/Prisma persistence layer

### 2. **No Admin Remittance/FX Lists**
- **Impact:** Admin cannot view all remittances or FX conversions globally
- **Workaround:** Use Customer 360 for customer-specific history
- **Recommendation:** Add these endpoints:
  - `GET /v1/admin/remittance?customerId=&status=`
  - `GET /v1/admin/fx/conversions?customerId=&fromCurrency=`

### 3. **Mock OTP (No Real SMS)**
- **Impact:** OTP verification auto-succeeds
- **Production Fix:** Integrate with SMS provider (Twilio, Africa's Talking)

### 4. **Mock Document Upload (KYC)**
- **Impact:** No actual file storage
- **Production Fix:** Integrate with S3/cloud storage

### 5. **Mock Biometric Auth**
- **Impact:** Biometric always succeeds with PIN `1234`
- **Production Fix:** Use platform biometric APIs (local_auth package)

### 6. **Hardcoded Fees & Limits**
- **Impact:** Cannot change fees/limits via admin UI
- **Production Fix:** Implement backend CRUD for fee/limit configs

### 7. **Mock MNO/Bank Settlement**
- **Impact:** No real money movement
- **Production Fix:** Integrate with MNO APIs (MTN, Airtel, Orange) and bank APIs

### 8. **No Refresh Tokens**
- **Impact:** JWT expires, requires re-login
- **Production Fix:** Implement refresh token rotation

### 9. **No Email Verification**
- **Impact:** Email verification skipped
- **Production Fix:** Integrate with email provider (SendGrid, Mailgun)

### 10. **Remittance Outbound Confirm**
- **Impact:** Quote created but no backend confirm endpoint for outbound
- **Backend Status:** Controller has `POST /v1/remittance/outbound/quote` but no `/confirm` endpoint
- **Production Fix:** Add confirm endpoint and payment posting logic

---

## API Endpoints Reference

### Customer APIs (JWT Bearer)
```
POST   /v1/auth/register
POST   /v1/auth/login
GET    /v1/wallets/me
GET    /v1/me/limits
POST   /v1/payments/quote
POST   /v1/payments/confirm
GET    /v1/payments
GET    /v1/payments/:id
POST   /v1/kyc/submissions
GET    /v1/notifications
POST   /v1/notifications/:id/read
POST   /v1/auth/pin/set
POST   /v1/auth/pin/verify
GET    /v1/credit/eligibility/:type
POST   /v1/credit/loans
GET    /v1/credit/loans
GET    /v1/credit/loans/:id
POST   /v1/cards
GET    /v1/cards
GET    /v1/cards/:id
POST   /v1/cards/:id/freeze
POST   /v1/cards/:id/activate
POST   /v1/cards/:id/block
PATCH  /v1/cards/:id/limits
GET    /v1/cards/:id/transactions
POST   /v1/remittance/inbound/quote
POST   /v1/remittance/inbound/:id/confirm
POST   /v1/remittance/outbound/quote
GET    /v1/remittance
GET    /v1/fx/rates
POST   /v1/fx/convert
```

### Agent APIs (X-Agent-Id header)
```
POST   /v1/agent/customers
POST   /v1/agent/cash-in
POST   /v1/agent/cash-out
```

### Admin APIs (X-Admin-API-Key header)
```
GET    /v1/admin/customers/:id/360
GET    /v1/admin/payments/search
GET    /v1/admin/agents
POST   /v1/admin/agents
GET    /v1/admin/kyc/submissions
POST   /v1/admin/kyc/submissions/:id/decision
GET    /v1/admin/config/fees
GET    /v1/admin/config/limits
GET    /v1/admin/wallets/:id
GET    /v1/admin/payroll/employers
POST   /v1/admin/payroll/employers
POST   /v1/admin/payroll/employers/:id/employees/import
POST   /v1/admin/payroll/employers/:id/salary/credit
GET    /v1/admin/cards
GET    /v1/admin/recon/daily?date=
GET    /v1/admin/cases
POST   /v1/admin/cases
POST   /v1/admin/cases/:id/decision
```

---

## Technical Notes

### Authentication
- **Customer:** JWT (stored in `flutter_secure_storage`)
- **Agent:** Agent ID in `X-Agent-Id` header (simpler auth for demo)
- **Admin:** API key `dev-admin-key` in `X-Admin-API-Key` header

### Currency Representation
- All amounts stored as **minor units** (cents)
- USD: 100 minor = $1.00
- CDF: 100 minor = FC 100.00

### Double-Entry Ledger
- All financial transactions post via `LedgerService`
- Every journal has balanced debits/credits
- Assertion: `SUM(debits) === SUM(credits)`

### Idempotency
- Payment confirmations use `Idempotency-Key` header (UUID)
- Prevents duplicate postings
- Journal deduplication by key

### Auto-Seeding
- **Agent Float:** CDF 50,000,000 + USD 100,000 on enrollment
- **Welcome Notification:** Sent to new customers on registration

### Mock Calculations
- **Fee:** 1% of amount OR 100 minor, whichever is greater
- **Tax:** 5% of fee (outbound only; inbound 0%)
- **Limits (TIER_1):** USD $1k daily / $10k monthly, CDF 1M / 10M

---

## Troubleshooting

### API Not Starting
```bash
cd services/core-api
rm -rf node_modules pnpm-lock.yaml
pnpm install
pnpm dev
```

### Flutter Not Connecting
- Chrome: Ensure `--dart-define=API_BASE_URL=http://localhost:3000`
- Android Emulator: Default is `10.0.2.2:3000`
- Check browser console for CORS errors (should be enabled)

### Admin Web Not Loading
- Ensure running on port 3001
- Check `NEXT_PUBLIC_API_BASE_URL` in `.env` (should be `http://localhost:3000`)

### Payment Fails "Insufficient funds"
- Fund wallet via "Add Money" first
- Check available balance (not just ledger)
- For agent cash-in, ensure agent has float

### PIN Not Working
- First transaction requires setting PIN (6 digits)
- PIN is in-memory (resets on API restart)
- Mock biometric uses PIN `1234`

---

## Repository Structure

```
/
├── services/
│   └── core-api/          # NestJS backend (in-memory)
├── apps/
│   ├── admin_web/         # Next.js admin dashboard
│   └── agent_mobile/      # Flutter agent app
├── lib/                   # Flutter customer app (root)
│   ├── screens/           # All customer screens
│   ├── services/          # API clients
│   └── widgets/           # Reusable components
├── README_APPS.md         # This file
└── README_FLUTTER.md      # Flutter-specific setup
```

---

## Next Steps for Production

1. **Persistence:** Migrate from in-memory to Postgres with Prisma
2. **Real Integrations:**
   - SMS OTP (Twilio)
   - MNO APIs (MTN, Airtel, Orange)
   - Bank APIs
   - KYC provider (Smile Identity, Youverify)
   - Document storage (S3)
3. **Security:**
   - Refresh tokens
   - Rate limiting
   - Input validation/sanitization
   - HTTPS/TLS
4. **Admin Endpoints:**
   - Add remittance list
   - Add FX conversions list
   - Enable fee/limit CRUD
5. **Monitoring:**
   - Logging (Winston, Pino)
   - Error tracking (Sentry)
   - APM (New Relic, Datadog)
6. **Testing:**
   - E2E tests (Jest, Flutter integration tests)
   - Load testing
   - Security audit
7. **DevOps:**
   - CI/CD pipeline
   - Docker containerization
   - Kubernetes orchestration
   - Environment configs (dev/staging/prod)

---

**Demo Complete!** All Phase 1-4 features are functional in this mock environment.
