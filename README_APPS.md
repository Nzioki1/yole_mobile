# YOLE Apps - Agent Mobile & Admin Web

Complete guide for running all YOLE applications against the mock core-api.

## Quick Start - Full Stack

### Terminal 1: Backend API
```bash
cd services/core-api
pnpm install
pnpm dev
# Runs on http://localhost:3000
```

### Terminal 2: Customer Flutter App
```bash
# From repo root
flutter pub get
flutter run
# Android emulator uses http://10.0.2.2:3000 automatically
```

### Terminal 3: Agent Flutter App
```bash
cd apps/agent_mobile
flutter pub get
flutter run
# Use different device or emulator instance
```

### Terminal 4: Admin Web UI
```bash
cd apps/admin_web
pnpm install
pnpm dev
# Runs on http://localhost:3001
```

## Agent Mobile App

**Location:** `apps/agent_mobile/`

### Features
- ✅ Agent login (uses X-Agent-Id header auth)
- ✅ Float balance display (CDF & USD)
- ✅ Enroll customer
- ✅ Cash-in (customer gives cash, agent credits wallet)
- ✅ Cash-out (customer withdraws, agent gives cash)

### Agent Authentication
Agents are created by admin via:
```bash
POST /v1/admin/agents
X-Admin-API-Key: dev-admin-key

{
  "firstName": "John",
  "lastName": "Agent",
  "phoneE164": "+243999999999",
  "email": "agent@yole.com"
}
```

Returns `agentId` (e.g. `agent_1`) which is used for login.

### Running Agent App

**Android Emulator:**
```bash
cd apps/agent_mobile
flutter run
```

**iOS Simulator:**
```bash
cd apps/agent_mobile
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

**Demo Flow:**
1. Login with `agent_1` (create agent via admin web first)
2. View float balances
3. Enroll a new customer
4. Perform cash-in to credit customer wallet
5. Perform cash-out to debit customer wallet

### Endpoints Used
- `POST /v1/agent/customers` - Enroll customer
- `POST /v1/agent/cash-in` - Cash in to customer wallet
- `POST /v1/agent/cash-out` - Cash out from customer wallet
- `GET /v1/admin/agents/:id` - Get agent info (via admin key)

## Admin Web UI

**Location:** `apps/admin_web/`

### Features

#### Dashboard
- Customer count
- Payment count
- Pending KYC count
- Agent count

#### Customer 360
- Full customer profile
- Wallet balances (CDF & USD)
- Recent payments
- Endpoint: `GET /v1/admin/customers/:id/360`

#### KYC Queue
- List pending submissions
- Approve/Reject with reason
- Endpoints:
  - `GET /v1/admin/kyc/submissions?status=PENDING_REVIEW`
  - `POST /v1/admin/kyc/submissions/:id/decision`

#### Agent Management
- List all agents
- Enroll new agent with float wallet
- Endpoints:
  - `GET /v1/admin/agents`
  - `POST /v1/admin/agents`

#### Payments Search
- Filter by customer, status, type
- Endpoint: `GET /v1/admin/payments/search`

#### Fees & Limits Config
- List/create fee configurations
- List/create limit configurations
- Endpoints:
  - `GET/POST /v1/admin/config/fees`
  - `GET/POST /v1/admin/config/limits`

#### Payroll (Phase 2)
- List employers
- Create employer
- Endpoints: `GET/POST /v1/admin/payroll/employers`

#### Recon & Cases (Phase 4)
- Daily reconciliation summary
- Case management (AML alerts)
- Endpoints:
  - `GET /v1/admin/recon/daily?date=YYYY-MM-DD`
  - `GET/POST /v1/admin/cases`

### Running Admin Web

```bash
cd apps/admin_web
pnpm install
pnpm dev
```

Access at `http://localhost:3001`

### Configuration

Create `.env.local`:
```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
```

### Login

- **Default API Key:** `dev-admin-key`
- This is the Phase 1 simple admin guard (`X-Admin-API-Key` header)
- Store in localStorage for session persistence

### Tech Stack
- **Next.js 14** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **Client-side rendering** (all pages use 'use client')

## Testing the Full Flow

### 1. Setup (Admin Web)
```
1. Open admin web (localhost:3001)
2. Login with dev-admin-key
3. Go to Agents → Enroll new agent
   - First Name: John
   - Last Name: Agent
   - Phone: +243111111111
4. Note the agentId (e.g. agent_1)
```

### 2. Agent Operations (Agent Mobile)
```
1. Open agent app on emulator
2. Login with agent_1
3. Enroll Customer:
   - First Name: Jane
   - Last Name: Doe
   - Password: Password1!
   - Note customerId
4. Cash-in $100 to customer
   - Customer ID: (from step 3)
   - Amount: 100
   - Currency: USD
```

### 3. Customer App (Customer Mobile)
```
1. Open customer app
2. Login with jane.doe credentials (if email set)
   OR register new customer
3. View wallet balances (should show $100 from cash-in)
4. Make payments, check credit, issue cards, etc.
```

### 4. Admin Monitoring (Admin Web)
```
1. Go to Customer 360
2. Enter customerId from step 2.3
3. View customer details, wallets, recent transactions
4. Go to Payments Search to see all transactions
5. Check KYC Queue if customer submitted KYC
```

## Architecture

```
┌─────────────────┐
│  Customer App   │ ─┐
│   (Flutter)     │  │
└─────────────────┘  │
                     │
┌─────────────────┐  │    ┌──────────────────┐
│   Agent App     │ ─┼───→│   Core API       │
│   (Flutter)     │  │    │   (NestJS)       │
└─────────────────┘  │    │  Port: 3000      │
                     │    │                  │
┌─────────────────┐  │    │  In-Memory       │
│   Admin Web     │ ─┘    │  Stores Only     │
│   (Next.js)     │       │  No Database     │
│  Port: 3001     │       └──────────────────┘
└─────────────────┘
```

## API Authentication Summary

| App | Method | Header/Storage |
|-----|--------|----------------|
| Customer | JWT | `Authorization: Bearer <token>` |
| Agent | Header | `X-Agent-Id: agent_1` |
| Admin | API Key | `X-Admin-API-Key: dev-admin-key` |

All stored in secure/local storage for session persistence.

## Troubleshooting

**Android emulator connection refused:**
- Ensure API is running on localhost:3000
- Use `10.0.2.2:3000` for Android (automatic)

**Admin web can't reach API:**
- Check NEXT_PUBLIC_API_BASE_URL in .env.local
- Ensure core-api is running
- Check browser console for CORS errors (should be none for localhost)

**Agent login fails:**
- Ensure agent was created via admin web first
- Verify agentId matches (case-sensitive)
- Check core-api logs for errors

## Production Considerations

When deploying:
1. Replace in-memory stores with Prisma + PostgreSQL
2. Implement proper admin authentication (not just API key)
3. Add agent JWT authentication (not just header ID)
4. Configure CORS for production domains
5. Add rate limiting and security middleware
6. Implement refresh tokens for all apps
7. Add comprehensive error handling and retry logic
