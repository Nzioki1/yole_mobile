# Poste Finance offline DEM script (DEM-01 … DEM-12)

Walkthrough for the **offline demo universe**. With offline flags on, clients must **never** call `localhost:3000` (or any API base). Acceptance = **core-api process stopped** + all three apps still complete these paths.

Cross-app live sync is **YAGNI**: trails are **pre-seeded** in `packages/demo_universe/data/universe.json`. In-app mutations stay in that app’s session memory until **Reset demo** (admin) or app restart (Flutter).

---

## 1. Flags & start (API stopped)

### Stop core-api

```bash
# Ensure nothing listens on :3000
lsof -iTCP:3000 -sTCP:LISTEN || true
# If core-api is running, stop it (Ctrl+C in its terminal, or kill the process).
```

### Admin Web (Next.js `:3001`)

```bash
cd apps/admin_web
# .env.local must include:
# NEXT_PUBLIC_OFFLINE_DEMO=true
pnpm install
pnpm dev
# → http://localhost:3001
```

### Customer Flutter

```bash
# From repository root
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
```

### Agent Flutter

```bash
cd apps/agent_mobile
flutter run -d chrome --dart-define=OFFLINE_DEMO=true
```

**Do not** pass `API_BASE_URL` for offline walks. Confirm DevTools **Network** has **no** requests to `:3000`.

---

## 2. Personas & shared IDs

| Persona | Login | Password / ID | Role |
| --- | --- | --- | --- |
| Admin | `admin@postefinance.com` | `Password1!` | Staff ADMIN |
| Ops | `ops@postefinance.com` | `Password1!` | Staff OPS |
| Support | `support@postefinance.com` | `Password1!` | Staff SUPPORT |
| Finance | `finance@postefinance.com` | `Password1!` | Staff FINANCE |
| Jean-Paul | `jp.kabila@gmail.com` (`cust_kasee`) | `Password1!` | Open-market customer (mobile demo focus) |
| Amina | `amina.payroll@postefinance.com` (`cust_amina`) | `Password1!` | Corporate employee @ `emp_poste` |
| Agent | **`agent-001`** | (paste Agent ID) | Float / enroll / cash |

Other stable IDs: `emp_poste` (Poste Demo SARL), journals/payments/loans/cards as in `meta.demBookmarks`.

OTP (offline): always **`123456`**. Transaction PIN (customer): set/use demo PIN (e.g. `123456`) when prompted.

---

## 3. Honesty banners (exact strings)

| Surface | Exact text |
| --- | --- |
| Global (admin header badge; customer/agent offline chrome) | `Offline demo — no live API` |
| Cards / DEM-07 | `MOCK — not Visa/Mastercard certified` |
| Resilience / DEM-10 | `DEMO STORYBOARD — not a live HA failover` |

Do **not** paraphrase. Do not claim live MNO/bank/MTO, Visa/MC certification, or production HA failover.

---

## 4. Admin URLs (new DEM pages)

Base: `http://localhost:3001`

| DEM | Path | Sidebar label |
| --- | --- | --- |
| DEM-02 | `/dashboard/products` | Products & rules |
| DEM-02 | `/dashboard/approvals` | Pending approvals |
| DEM-04 | `/dashboard/credit-exceptions` | Credit exceptions |
| DEM-05 | `/dashboard/idempotency` | Idempotency lab |
| DEM-08 | `/dashboard/remittance` | Remittance |
| DEM-10 | `/dashboard/resilience` | Resilience (demo) |
| DEM-12 | `/dashboard/export` | Export pack |
| — | `/dashboard/users` | Users (view all; create/role ADMIN) |
| — | `/dashboard/aml-ban-list` | AML ban list |
| — | `/dashboard/customers` | Customers directory |

Also used: `/dashboard/customer360`, `/dashboard/cards`, `/dashboard/cases`, `/dashboard/recon`, `/dashboard/payroll`, `/login`.

---

## 5. Reset demo

1. Admin header (offline only): badge **Offline demo — no live API** + button **Reset demo**.
2. Click **Reset demo** → `getOfflineStore().reset()` + hard reload.
3. Seeded entities return (e.g. `loan_kasee_exception_001` back to `PENDING_EXCEPTION` after an approve walk).
4. Flutter apps: restart the run (or re-login) to reload embedded universe; session mutations are not shared across apps.

---

## 6. Click paths DEM-01 … DEM-12

### DEM-01 — Self-reg → OTP → eKYC → dual wallet

**Apps:** Customer  
**Seed bookmark:** `cust_kasee` / path `customer/register-kyc-home`

1. Stop API `:3000`. Start customer with `--dart-define=OFFLINE_DEMO=true`.
2. Confirm offline / no live API affordance where shown.
3. **Option A (seeded login):** Log in `jp.kabila@gmail.com` / `Password1!` → Home shows **CDF + USD** wallets.
4. **Option B (register walk):** Create account → enter phone → OTP **`123456`** → eKYC submit (mock docs) → land on home with wallets.
5. **Pass:** Home loads with dual currency wallets; Network has no `:3000`.

---

### DEM-02 — Products / fees / maker-checker

**Apps:** Admin  
**Seed:** `apr_fee_w2w_001` → `admin/products+approvals`

1. Login `admin@postefinance.com` / `Password1!`. Header shows **Offline demo — no live API**.
2. Sidebar → **Products & rules** (`/dashboard/products`) — list products + fee/limit rows.
3. Sidebar → **Pending approvals** (`/dashboard/approvals`) — row `apr_fee_w2w_001` (FEE_CHANGE).
4. Click **Approve** (or **Reject**). Status updates; fee change applies on approve.
5. **Pass:** Queue updates without network errors; optional **Reset demo** restores pending row.

---

### DEM-03 — Payroll → salary advance → schedule

**Apps:** Admin payroll + Customer credit + Admin 360  
**Seed:** `cust_amina`, `loan_amina_active_001`, `emp_poste`

1. **Admin:** Payroll → employer **Poste Demo SARL** (`emp_poste`) — employees + salary history for Amina.
2. **Customer:** Login `amina.payroll@postefinance.com` / `Password1!` → **Credit** → Salary Advance eligible from salary history → apply / view terms → PIN → wallet credit + loan.
3. **Admin:** Customer 360 → paste `cust_amina` → see active loan `loan_amina_active_001` + **installment schedule**.
4. **Pass:** Eligibility is salary-driven (not always-true); 360 shows schedule; IDs match across apps (pre-seeded).

---

### DEM-04 — Credit exception maker-checker

**Apps:** Admin (+ optional Customer credit for Jean-Paul)  
**Seed:** `loan_kasee_exception_001` → `/dashboard/credit-exceptions`

1. Admin → **Credit exceptions**.
2. Row `loan_kasee_exception_001` status `PENDING_EXCEPTION`.
3. **Approve** → becomes `ACTIVE` + schedule + wallet credit + journal.
4. Customer 360 `cust_kasee` → schedule visible.
5. (Optional) **Reset demo** → exception loan restored.
6. **Pass:** Approve path mutates store locally; no `:3000`.

---

### DEM-05 — Idempotency replay + compensate

**Apps:** Admin Idempotency lab  
**Seed:** `pay_kasee_idem_001` / key `idem_replay_demo_001`

1. Admin → **Idempotency lab** (`/dashboard/idempotency`).
2. Idempotency key prefilled `idem_replay_demo_001` → **Replay confirm** twice → **same payment ID**, no duplicate.
3. On `pay_kasee_idem_001` (or listed Jean-Paul payment) → **Compensate** → reversing journal + notification.
4. **Pass:** Replay stable; compensate posts reverse trail offline.

---

### DEM-06 — Rails W2W / MNO / bank / bill → receipt → journal

**Apps:** Customer + Admin payments / 360 / recon  
**Seed payments:** `pay_kasee_w2w_001`, `pay_kasee_mno_001`, `pay_kasee_bank_001`, `pay_kasee_bill_001`

1. Customer login `jp.kabila@gmail.com` / `Password1!`.
2. History / Pay: open each rail receipt (W2W, MNO, bank, bill) — journal IDs present.
3. Admin → Payments search / Customer 360 `cust_kasee` — same payment + journal IDs.
4. Optional: Agent `agent-001` cash-in history appears as **pre-seeded** journals (not live sync).
5. **Pass:** Four payment IDs visible customer + admin; Network clean.

---

### DEM-07 — Virtual card + mock 3DS + dispute

**Apps:** Customer Cards + Admin Cards  
**Seed:** `card_kasee_virtual_001`, `cauth_kasee_3ds_001`, `case_card_dispute_001`

1. Customer → **Cards** — banner exactly **`MOCK — not Visa/Mastercard certified`**.
2. Open virtual debit `card_kasee_virtual_001` — controls / limits; mock auth trail.
3. Admin → **Virtual Cards** / cards page — same MOCK banner; **Mock 3DS** table; dispute link to `case_card_dispute_001`.
4. **Pass:** Exact MOCK string; card + 3DS + dispute IDs aligned.

---

### DEM-08 — Remittance clear / screening / refund / partner recon

**Apps:** Customer remittance + Admin Remittance  
**Seed:** `rmt_clear_001`, `rmt_screen_hit_001`

1. Customer → Remittance — see clear inbound + screening-hit exception path.
2. Admin → **Remittance** (`/dashboard/remittance`).
3. On `SCREENING_HIT` (`rmt_screen_hit_001`): **Clear** and/or **Refund**; **Partner recon** stub.
4. **Pass:** Both remittance IDs; admin actions update without API.

---

### DEM-09 — AML confidential case maker-checker

**Apps:** Admin Cases  
**Seed:** `case_aml_conf_001`

1. Admin → **Cases & Support** (`/dashboard/cases`).
2. Open AML case — **CONFIDENTIAL** badge visible.
3. Workflow: **Investigate** → **Recommend** → maker-checker with `approverRole`.
4. **Pass:** Confidential + SoD steps complete offline.

---

### DEM-10 — Resilience storyboard

**Apps:** Admin  
**Path:** `/dashboard/resilience`

1. Sidebar → **Resilience (demo)**.
2. Banner exactly **`DEMO STORYBOARD — not a live HA failover`**.
3. Review failure → failover story → balanced journals / ledger integrity panel.
4. **Pass:** Exact storyboard string; no claim of live HA.

---

### DEM-11 — EOD / recon / GL snapshot

**Apps:** Admin Recon  
**Seed:** `recon_2026-09-16`

1. Admin → **Reconciliation** (`/dashboard/recon`).
2. Load day / see matched rails + open exceptions.
3. **Run EOD** → writes/updates EOD snapshot.
4. Drill into suspense / GL balance as shown.
5. **Pass:** EOD runs offline; snapshot present after run.

---

### DEM-12 — Export pack

**Apps:** Admin  
**Path:** `/dashboard/export`

1. Sidebar → **Export pack**.
2. Click **Download poste-finance-demo-export.json**.
3. File non-empty; contains customers / wallets / loans / txns / cases (universe-derived).
4. **Pass:** Download succeeds with API stopped.

---

### Agent companion (supports DEM-01/06 trails)

1. Agent app `--dart-define=OFFLINE_DEMO=true`.
2. Login Agent ID **`agent-001`** (not `agent_1`).
3. Float matches seed (CDF + USD).
4. Enroll / cash-in / cash-out mutate **session only**; admin continues to show **pre-seeded** cross-channel journals from universe.

---

## 7. Acceptance checklist

Run with **core-api stopped** and offline flags on. Tick when observed.

### Preconditions

- [ ] Nothing listening on `:3000` (or core-api confirmed stopped)
- [ ] Admin: `NEXT_PUBLIC_OFFLINE_DEMO=true`
- [ ] Customer: `--dart-define=OFFLINE_DEMO=true`
- [ ] Agent: `--dart-define=OFFLINE_DEMO=true`
- [ ] DevTools Network: **no** calls to `:3000` during walks

### Honesty

- [ ] Global badge: `Offline demo — no live API`
- [ ] Cards: `MOCK — not Visa/Mastercard certified`
- [ ] Resilience: `DEMO STORYBOARD — not a live HA failover`

### Personas / IDs

- [ ] `admin@postefinance.com` / `Password1!` logs into admin
- [ ] `jp.kabila@gmail.com` / `Password1!` customer
- [ ] `amina.payroll@postefinance.com` / `Password1!` customer
- [ ] Agent login **`agent-001`**

### DEM walks

- [ ] **DEM-01** dual wallets / OTP-KYC path
- [ ] **DEM-02** products + approve/reject `apr_fee_w2w_001`
- [ ] **DEM-03** Amina payroll eligibility + schedule on 360
- [ ] **DEM-04** approve `loan_kasee_exception_001` → ACTIVE + schedule
- [ ] **DEM-05** replay same key; compensate `pay_kasee_idem_001`
- [ ] **DEM-06** W2W/MNO/bank/bill receipts + journal IDs
- [ ] **DEM-07** MOCK card + 3DS + dispute case
- [ ] **DEM-08** clear/screening remittance + partner recon
- [ ] **DEM-09** AML confidential Investigate → Recommend → checker
- [ ] **DEM-10** resilience storyboard banner + balanced journals
- [ ] **DEM-11** Run EOD on `recon_2026-09-16`
- [ ] **DEM-12** Download `poste-finance-demo-export.json` non-empty

### Reset

- [ ] **Reset demo** restores seed (e.g. exception loan after DEM-04 approve)

---

## 8. Related docs

- App runbook: `README_APPS.md` (offline + stop-API section)
- Legacy Pesapal UX: `user_journey.md` (pointer only — not rewritten)
- Seed package: `packages/demo_universe/README.md`

---

## NEW: Priority 1-8 Enhanced Journeys

### DEM-13: Employer Portal (Priority 2)

**Login**: `employer@postefinance.com` / `Password1!`

**Steps**:
1. Navigate to /dashboard/employer-portal
2. View employee list (Jean-Paul, Amina, others)
3. **Add Employee**:
   - Click "+ Add Employee"
   - Employee #: TEST-001
   - Customer ID: (optional)
   - Job Title: Test Analyst
   - Gross Salary (CDF minor): 60000000
   - Net Salary (CDF minor): 51000000
   - Click "Save"
4. **Edit Employee** (Jean-Paul):
   - Click "Edit" on Jean-Paul's row
   - Change Job Title to: "Senior Business Analyst"
   - Change Net Salary to: 70000000
   - Change Status to: ACTIVE
   - Click "Save"
5. **View Salary History**:
   - Scroll to "Salary Payment History"
   - See Jul & Aug 2026 payments
   - Verify Jean-Paul and Amina salaries

**Acceptance**:
- [x] Employer sees only their employees (emp_poste)
- [x] Can add new employees
- [x] Can edit employee details
- [x] Salary history displays correctly

---

### DEM-14: Savings Withdrawal (Priority 5)

**Login**: `jp.kabila@gmail.com` / `Password1!` (Jean-Paul)

**Pre-req**: Jean-Paul has a savings goal with deposited amount

**Steps**:
1. Navigate to Home → Savings
2. Tap existing savings goal
3. **Withdraw Money**:
   - Click "Withdraw" button
   - Enter amount (e.g., 50.00 CDF)
   - Click "Continue"
   - Enter PIN: 123456
   - Confirm
4. **Verify**:
   - Goal balance decreased
   - Wallet balance increased
   - Notification received: "Withdrew FC 50 from [Goal Name]"

**Acceptance**:
- [x] Withdraw button enabled when goal has balance
- [x] Withdrawal credits wallet
- [x] Goal balance updated
- [x] Notification sent

---

### DEM-15: Credit Configuration (Priority 6)

**Login**: `finance@postefinance.com` / `Password1!` (Finance role)

**Steps**:
1. Navigate to /dashboard/credit-config
2. **View Products**:
   - See SALARY_ADVANCE, NANO_LOAN, etc.
   - Note current rates and tenors
3. **Edit Product**:
   - Click "Edit" on NANO_LOAN
   - Change Annual Rate: 0.15 (15%)
   - Change Max Tenor: 18 months
   - Change Auto-Approve Max: 5000000 (FC 50K)
   - Click "Save"
4. **View Scoring Model**:
   - See "Retail Credit Scoring Model"
   - Weights: KYC 30%, Salary 35%, Loan 25%, Savings 10%
   - Thresholds: Min Score 600, Max Loan FC 1M
5. **Check Approval**:
   - Navigate to /dashboard/approvals
   - See pending approval for credit product update

**Acceptance**:
- [x] Credit products editable
- [x] Changes create pending approvals
- [x] Scoring model visible with weights/thresholds

---

### DEM-16: Audit Log (Priority 8)

**Login**: `admin@postefinance.com` / `Password1!`

**Steps**:
1. Navigate to /dashboard/audit-log
2. **View Audit Entries**:
   - See EMPLOYER_APPROVED action
   - See SALARY_CREDITED action
   - User emails visible (admin@, finance@)
   - Timestamps in chronological order
3. **Inspect Changes**:
   - Click expand on SALARY_CREDITED
   - See JSON: {"employeeCount": 12, "totalMinor": 800000000}

**Acceptance**:
- [x] All system actions logged
- [x] Maker/approver emails recorded
- [x] Changes JSON visible
- [x] Timestamps accurate

---

### DEM-17: Dashboard KPIs (Priority 8)

**Login**: `admin@postefinance.com` / `Password1!`

**Steps**:
1. Navigate to /dashboard/kpis
2. **View Credit KPIs**:
   - Active Loans count
   - Total Portfolio amount (CDF)
   - Arrears count and amount
3. **View Savings KPIs**:
   - Total Savings Goals
   - Total Deposited amount
   - Active Term Deposits
   - Term Deposit total value
4. **View Employer KPIs**:
   - Total Employers
   - Total Employees
   - Active Employees
5. **View Salary Reconciliation**:
   - This Month payments and total
   - Last Month payments and total

**Acceptance**:
- [x] All KPI cards display real data
- [x] Credit portfolio accurate
- [x] Savings totals correct
- [x] Salary reconciliation shows monthly breakdown

---

### DEM-18: Loan Repayment (Priority 4)

**Login**: `jp.kabila@gmail.com` / `Password1!` (Jean-Paul)

**Steps**:
1. Navigate to Home → Credit
2. Tap active loan (FC 300K principal)
3. **View Schedule**:
   - See 3 installments
   - 2 marked PAID (Aug 28, Sep 28)
   - 1 marked DUE (Oct 28)
4. **Make Repayment**:
   - Click "Make Repayment" button
   - Enter amount: 10750 (FC 107.50)
   - Click "Pay"
   - Enter PIN: 123456
   - Confirm
5. **Verify**:
   - Wallet debited
   - Outstanding balance reduced
   - Installment marked PAID
   - Notification received

**Acceptance**:
- [x] Schedule displays correctly
- [x] Overdue installments marked red (if past due date)
- [x] Repay button available for ACTIVE loans
- [x] Repayment updates balance and schedule
- [x] Loan marked REPAID when balance = 0

---

## Offline Demo Acceptance (All Priorities)

### Priority 1: Add Money Fix ✓
- [x] MNO_IN and BANK_IN credit wallet (not debit)
- [x] Journal direction = CREDIT for inbound
- [x] Fee deducted correctly

### Priority 2: Employer Portal ✓
- [x] Employer login works
- [x] Employee list filtered by employer
- [x] Add employee creates record
- [x] Edit employee updates details
- [x] Salary history visible

### Priority 3: Salary System ✓
- [x] Jean-Paul is employee with 2 salaries
- [x] Admin salary credit reaches wallet
- [x] Notification sent
- [x] Eligibility requires 2 salaries (not 1)

### Priority 4: Credit Servicing ✓
- [x] Loan schedule displays
- [x] Repay button works
- [x] Arrears marked red
- [x] Credit/Cards visible on home

### Priority 5: Savings & Term Deposits ✓
- [x] Withdraw from savings goal works
- [x] Term deposits tracked (amount, tenor, rate, maturity)
- [x] Early exit with penalty

### Priority 6: Credit Config ✓
- [x] Credit products editable
- [x] Scoring model visible
- [x] Changes create approvals

### Priority 7: KYC Gate & Consent ✓
- [x] Consent records stored
- [x] Jean-Paul already approved (demo works)

### Priority 8: Audit & KPIs ✓
- [x] Audit log tracks all actions
- [x] Dashboard KPIs accurate
- [x] Salary reconciliation visible

