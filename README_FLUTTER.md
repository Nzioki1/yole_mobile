# Yole Flutter + NestJS Core API Integration

## Prerequisites

- Node.js 18+ and pnpm
- Flutter 3.3+
- Android Studio / Xcode for emulators

## Running the Stack

### 1. Start NestJS Core API (Backend)

```bash
# From repository root
cd services/core-api
pnpm install
pnpm dev
```

API will run on `http://localhost:3000`

### 2. Start Flutter App

```bash
# From repository root
flutter pub get
flutter run
```

#### API Base URL Configuration

**Android Emulator (default):**
```bash
flutter run
# Uses http://10.0.2.2:3000 automatically
```

**iOS Simulator:**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

**Physical Device:**
```bash
# Find your computer's IP address first
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:3000
```

## Features Wired to Core API

### Authentication
- **Register:** `POST /v1/auth/register` with email, password, firstName, lastName
- **Login:** `POST /v1/auth/login` with email, password
- **JWT Storage:** Secure storage with automatic Bearer token inclusion
- **OTP:** `POST /v1/auth/otp/request` and `/verify` (if screens exist)

### Wallets
- **My Wallets:** `GET /v1/wallets/me` shows CDF and USD pocket balances
- Home screen displays available balance from core-api

### Payments
- **Quote:** `POST /v1/payments/quote` with type (W2W, MNO_OUT, BILL, etc.)
- **Confirm:** `POST /v1/payments/confirm` with `Idempotency-Key` UUID header
- **List:** `GET /v1/payments` shows payment history
- W2W (wallet-to-wallet) payment flow functional

### KYC
- **Submit:** `POST /v1/kyc/submissions` multipart (if UI supports)

### New Features (Demo Screens)

#### Credit & Loans
- **Check Eligibility:** `GET /v1/credit/eligibility/:type`
- **Request Loan:** `POST /v1/credit/loans` - instant wallet credit
- Screen: `CreditScreen`

#### Virtual Cards
- **Issue Card:** `POST /v1/cards` linked to wallet pocket
- **List Cards:** `GET /v1/cards` with status and limits
- Screen: `CardsScreen`

#### Currency Exchange (FX)
- **Get Rates:** `GET /v1/fx/rates` - CDF/USD exchange rates
- **Convert:** `POST /v1/fx/convert` - execute FX via ledger
- Screen: `FxScreen`

## Testing

### Backend Tests (No Database Required)
```bash
cd services/core-api
pnpm test        # Unit tests (14 pass)
pnpm test:e2e    # E2E tests (9 pass)
```

All tests use in-memory stores - no Docker/Postgres needed.

### Flutter Tests
```bash
flutter test
# Unit tests for DTOs and API client mocks
```

## API Architecture

- **In-Memory Stores:** Customer, Wallet, Ledger, Payment, KYC, Agent
- **No Database:** All data stored in memory for Phase 1 mock
- **Double-Entry Ledger:** All money movements via LedgerService
- **Idempotency:** Payment confirmations use UUID-based idempotency keys

## Troubleshooting

**"Connection refused" on Android:**
- Ensure API is running on `localhost:3000`
- Android emulator uses `10.0.2.2` to reach host machine

**"Connection refused" on iOS:**
- Use `--dart-define=API_BASE_URL=http://localhost:3000`

**Token expired:**
- Re-login to get fresh JWT token
- Tokens stored securely in flutter_secure_storage

## Next Steps

When ready for production:
1. Swap in-memory stores for Prisma + PostgreSQL
2. Add Redis for caching
3. Configure proper CORS for Flutter web
4. Add refresh token flow
5. Implement proper error handling and retry logic
