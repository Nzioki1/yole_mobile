# YOLE Apps - Demo Guide

This guide provides end-to-end demo walkthroughs for the YOLE neo-bank platform.

## Architecture

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

## Quick Start

### 1. Start Core API
```bash
cd services/core-api
pnpm install
pnpm dev
# API runs on http://localhost:3000
```

### 2. Start Admin Web
```bash
cd apps/admin_web
pnpm install
pnpm dev
# Admin UI runs on http://localhost:3001
```

### 3. Run Customer App
```bash
# Chrome (recommended for demo)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Android Emulator (uses 10.0.2.2:3000 by default)
flutter run -d <device-id>
```

### 4. Run Agent App
```bash
cd apps/agent_mobile
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

---

## Phase 1 Demo Script

### Part A: Admin Setup (Admin Web)

**URL:** http://localhost:3001

1. **Login**
   - API Key: `dev-admin-key` (hardcoded for demo)

2. **Dashboard Overview**
   - View customer count, payment count, pending KYC, agents count
   - Navigate through module cards

3. **Create Agent**
   - Click "Agents" module
   - Click "+ Enroll Agent"
   - Fill form:
     - First Name: `Demo`
     - Last Name: `Agent`
     - Phone: `+243900000001`
     - Email: `agent@demo.com`
   - Copy **Agent ID** for agent login

---

### Part B: Agent Operations (Agent Flutter App)

**Agent Login:**
- Paste the Agent ID from admin
- View float balances (CDF & USD, seeded automatically)

**1. Enroll Customer**
- Click "Enroll Customer"
- Fill form:
  - First Name: `Alice`
  - Last Name: `Demo`
  - Phone: `+243900000100`
  - Email: `alice@demo.com`
  - Password: `Password1!`
- Click "Enroll Customer"
- **Copy Customer ID** from success dialog (needed for W2W and cash-in)

**2. Cash-In (Fund Customer Wallet)**
- Click "Cash In / Out"
- Select "Cash In"
- Paste Customer ID
- Currency: USD
- Amount: 100
- Click "Cash In"
- Note Journal ID in success dialog

**3. Return to Home**
- Pull to refresh to see updated float balance

---

### Part C: Customer Experience (Customer Flutter App)

**1. Register New Customer**
- Open customer app
- Click "Create Account"
- Fill form:
  - Email: `bob@demo.com`
  - First Name: `Bob`
  - Last Name: `Demo`
  - Password: `Password1!`
- Click "Create account"
- Skip email verification (mock)

**2. Explore Neo-Bank Home**
- View wallet cards (CDF & USD, initially empty or with small amount)
- Pull to refresh to load balances

**3. Fund Wallet (Add Money)**
- Click "Add Money"
- Select rail: Mobile Money or Bank
- Amount: 50
- Currency: USD
- Fill mock MNO/Bank fields
- Review quote (shows fee + tax)
- **Set PIN** if first time (e.g., `123456`)
- Confirm with PIN
- View success screen

**4. Send Payment (W2W to Alice)**
- Click "Pay / Send" quick action
- Select "Wallet to Wallet"
- Enter destination: Paste Alice's **Customer ID** (from agent enroll)
- Amount: 20
- Currency: USD
- Note: Alice Demo
- View quote (amount + fee + tax breakdown)
- Confirm with PIN
- View success + receipt

**5. Withdraw (Cash-Out)**
- Click "Withdraw"
- Select MNO_OUT or BANK_OUT
- Amount: 10
- Currency: USD
- Fill destination (mock phone/account)
- View quote
- Confirm with PIN
- View success

**6. View History**
- Click "History" tab (bottom nav)
- See list of all payments
- Tap any payment for detailed view:
  - Amount breakdown
  - Fee & tax
  - Payment ID, type, status
  - Timestamps

**7. Notifications**
- Click bell icon (top right on Home)
- See payment completion notifications
- See welcome notification

**8. Profile**
- Click "Profile" tab
- View personal information
- **Limits:** View daily/monthly transaction limits by currency
- **Language:** Switch between English and Français
- **Dark Mode:** Toggle theme

**9. KYC Submission** (Optional)
- Home → KYC quick action
- Fill ID document step (mock upload)
- Fill selfie step (mock capture)
- Submit
- Status: PENDING (visible in profile after submission)

---

### Part D: Admin Monitoring & Operations

**1. Customer 360**
- Admin Web → "Customer 360" module
- Paste Alice's Customer ID
- Click "Search"
- View:
  - Customer details (name, email, phone, KYC status)
  - Wallet balances per currency (available, ledger, blocked, pending)
  - Recent payments list

**2. Payments Search**
- Admin Web → "Payments Search" module
- Filter by:
  - Customer ID (optional)
  - Status: Posted, Pending, Failed
  - Type: W2W, MNO_IN/OUT, BANK_IN/OUT, etc.
- Click "Search"
- View all matching payments with:
  - Payment ID, Customer ID, Type, Amount, Status, Timestamp
- Results update in real-time as customers transact

**3. KYC Queue**
- Admin Web → "KYC Queue" module
- View pending submissions
- Click a submission:
  - Review customer info
  - View document images (if available)
  - Approve or Reject with reason
- After approval:
  - Customer KYC status becomes APPROVED
  - Transaction limits increase (in real impl)

**4. Agents List**
- Admin Web → "Agents" module
- View all enrolled agents
- See Agent ID, name, phone, email, created date

**5. Fees & Limits Config**
- Admin Web → "Fees & Limits" module
- **Fees:** Currently shows mock message (calculated in PaymentsService: 1% or 100 minor)
- **Limits:** Currently shows mock message (hardcoded TIER_1: USD $1k daily / $10k monthly)
- UI ready for future config API integration

---

## Payment Flow Summary

### Inbound (Add Money)
```
Customer App → Quote (MNO_IN/BANK_IN) → PIN → Confirm
  → Backend credits CUST_WALLET from MNO_SETTLEMENT/BANK_SETTLEMENT
  → Deducts fee from customer wallet to FEE_REVENUE
  → Notification sent
```

### Wallet-to-Wallet
```
Customer App → Pick W2W → Enter destination (Customer ID) → Quote → PIN → Confirm
  → Backend debits sender CUST_WALLET → credits receiver CUST_WALLET
  → Deducts fee from sender to FEE_REVENUE
  → Notifications sent to both parties
```

### Outbound (Withdraw)
```
Customer App → Quote (MNO_OUT/BANK_OUT) → PIN → Confirm
  → Backend debits CUST_WALLET → credits MNO_SETTLEMENT/BANK_SETTLEMENT
  → Deducts fee from customer wallet to FEE_REVENUE
  → Notification sent
```

### Agent Cash-In
```
Agent App → Enter Customer ID + Amount → Cash In
  → Backend debits AGENT_FLOAT → credits CUST_WALLET
  → Ledger-balanced journal created
  → Agent float updates in real-time
```

---

## Key Features Demonstrated

### Customer App
- ✅ Neo-bank Home hub with wallet cards
- ✅ Multi-rail payments (W2W, MNO, Bank, Bills, Airtime)
- ✅ Quote/Confirm pattern with fee & tax breakdown
- ✅ Transaction PIN security (with mock biometric stub)
- ✅ Wallet balances (available, pending, blocked)
- ✅ Transaction history with detail view
- ✅ Notifications center
- ✅ FR/EN language switch with persistence
- ✅ Profile with KYC status & limits display
- ✅ Dark mode toggle
- ✅ KYC submission flow

### Agent App
- ✅ Float balance display (CDF & USD)
- ✅ Enroll customer (returns Customer ID)
- ✅ Cash-in / Cash-out operations
- ✅ Real-time float updates

### Admin Web
- ✅ Dashboard with counts
- ✅ Customer 360 (full profile, wallets, payments)
- ✅ Payments search (filter by customer, status, type)
- ✅ KYC queue (approve/reject)
- ✅ Agents list + enroll
- ✅ Fees & Limits config (UI ready)

### Backend (NestJS Core API)
- ✅ In-memory stores (customers, wallets, payments, ledger, KYC, agents, notifications)
- ✅ Double-entry ledger with assertions
- ✅ Idempotent payment confirmations
- ✅ JWT authentication for customers
- ✅ X-Agent-Id authentication for agents
- ✅ X-Admin-API-Key authentication for admin
- ✅ Auto-seeded float for agents
- ✅ Notification emission on events
- ✅ CORS enabled for browser clients

---

## API Endpoints Reference

### Customer APIs (JWT Bearer)
- `POST /v1/auth/register` - Register new customer
- `POST /v1/auth/login` - Login customer
- `GET /v1/wallets/me` - Get customer wallets
- `GET /v1/me/limits` - Get transaction limits
- `POST /v1/payments/quote` - Quote payment
- `POST /v1/payments/confirm` - Confirm payment
- `GET /v1/payments` - List customer payments
- `GET /v1/payments/:id` - Get payment detail
- `POST /v1/kyc/submissions` - Submit KYC
- `GET /v1/notifications` - List notifications
- `POST /v1/notifications/:id/read` - Mark notification read
- `POST /v1/auth/pin/set` - Set transaction PIN
- `POST /v1/auth/pin/verify` - Verify transaction PIN

### Agent APIs (X-Agent-Id header)
- `POST /v1/agent/customers` - Enroll customer
- `POST /v1/agent/cash-in` - Cash in to customer wallet
- `POST /v1/agent/cash-out` - Cash out from customer wallet

### Admin APIs (X-Admin-API-Key header)
- `GET /v1/admin/customers/:id/360` - Customer 360 view
- `GET /v1/admin/payments/search` - Search payments
- `GET /v1/admin/agents` - List agents
- `POST /v1/admin/agents` - Enroll agent
- `GET /v1/admin/kyc/submissions` - List KYC submissions
- `POST /v1/admin/kyc/submissions/:id/decision` - Approve/reject KYC
- `GET /v1/admin/config/fees` - List fee configs
- `GET /v1/admin/config/limits` - List limit configs
- `GET /v1/admin/wallets/:id` - Get wallet (for agent float)

---

## Troubleshooting

### Customer App Can't Connect
- Ensure Core API is running on :3000
- For Chrome: Use `--dart-define=API_BASE_URL=http://localhost:3000`
- For Android Emulator: Default `10.0.2.2:3000` should work
- Check browser console for CORS errors (should be enabled in backend)

### Agent Float Not Loading
- Ensure agent was created via Admin Web (auto-seeds float)
- Check agent ID is correct
- Pull to refresh on agent home screen
- Check Core API logs for errors

### Admin Web Pages Not Loading
- Ensure Core API is running on :3000
- Check Admin Web is running on :3001
- Verify API key is `dev-admin-key`
- Check browser console for fetch errors

### Payment Fails with "Insufficient funds"
- Ensure wallet has enough balance
- Try funding wallet via "Add Money" first
- For agent cash-in, ensure agent has float
- Check available balance (not just ledger)

### PIN Not Working
- First transaction requires setting PIN (6 digits)
- PIN is stored in backend in-memory (resets on API restart)
- Mock biometric always succeeds with PIN `1234`

---

## Next Steps (Phase 2+)

- **Payroll:** Bulk salary credits to employee wallets
- **Credit:** Salary advance and consumer loans
- **Cards:** Virtual card issuance and auth
- **Remittance:** International transfers with compliance screening
- **FX:** Currency exchange CDF ↔ USD
- **Advanced Admin:** Recon dashboard and case management

---

## Technical Notes

- All data is **in-memory** and resets on API restart
- Amounts are stored as **minor units** (cents) in backend
- Ledger follows **double-entry** accounting
- All operations are **idempotent** with journal deduplication
- Agent float is **auto-seeded** with CDF 50M + USD 100k on enroll
- Welcome notification is **auto-sent** on customer registration
- Payment notifications are **auto-sent** on successful confirm

**Mock API Keys:**
- Admin: `dev-admin-key`
- Customer: JWT from register/login
- Agent: Agent ID from admin enroll

**Mock PIN:**
- Any 6 digits set by customer
- Biometric mock auto-fills `1234`

**Mock Fee Calculation:**
- 1% of amount OR 100 minor units, whichever is greater
- Tax: 5% of fee (outbound only, inbound has 0% tax)

**Mock Limits (TIER_1):**
- USD: $1,000 daily / $10,000 monthly
- CDF: FC 1,000,000 daily / FC 10,000,000 monthly
