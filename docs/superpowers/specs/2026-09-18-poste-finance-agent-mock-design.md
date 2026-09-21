# Poste Finance Agent Mobile Offline Mock Design

**Date:** 2026-09-18  
**Status:** Approved  
**Approach:** B — Separate APK `apps/agent_mobile` (not customer APK agent tabs)

## 1. Overview

This design specifies a fully functional offline agent mobile application for Poste Finance, allowing agents to perform cash-in/cash-out operations, enroll new customers, and view transaction history — all powered by a shared demo universe seed that synchronizes with the customer mobile app.

### 1.1 Approved Decisions

- **Separate APK:** `apps/agent_mobile` is a standalone Flutter APK, not tabs in the customer app
- **Offline-only:** No live API integration; all operations via `OfflineAgentRepository` backed by `DemoUniverse`
- **Login routing:**
  - Agent email (`agent001@postefinance-agents.cd`) + `Password1!` → agent APK login successful
  - Customer email (`jp.kabila@gmail.com`) on agent APK → "Please use customer app" message
  - Same password pattern for demo interchangeability
- **Shared demo universe:** Both customer app and agent app read/mutate the same in-memory `DemoUniverse` instance during a session
- **Agent float:** Multi-currency (CDF + USD) with separate available/pending tracking
- **PIN validation:** Hardcoded `123456` for all agent operations (matching customer pattern)

### 1.2 Out of Scope (Phase 1)

- Commission tracking and accrual (P1 future)
- Assisted bill pay on behalf of customer
- Full Bank UI Kit implementation
- Customer-app agent tabs
- Agent performance analytics
- Float top-up requests
- Multi-agent session handoff

## 2. Screens & User Flows

### 2.1 Agent Login Screen

**Path:** `apps/agent_mobile/lib/screens/agent_login_screen.dart` (already exists)

**Current behavior:**
- Single input: Agent ID (e.g., `agent_1`)
- No password field
- On login: verify agent exists via `AgentApiService.getAgentInfo()`, then navigate to home

**Enhanced behavior for offline mock:**

| Field | Type | Behavior |
|-------|------|----------|
| Email | Text input | Required; validated as email format |
| Password | Secure text | Required; minimum 8 chars |
| Login button | Primary CTA | Disabled until both fields valid |

**Flow:**

```
1. User enters email + password
2. If email matches agent pattern (agent001@postefinance-agents.cd):
   a. Validate password against seed agent.password
   b. If valid → OfflineAgentRepository.login(agentId) → navigate to /home
   c. If invalid → "Invalid credentials"
3. If email matches customer pattern (jp.kabila@gmail.com):
   → Show banner: "Customer accounts must use Yole customer app. Download from [link]."
4. If email unknown:
   → "Agent not found. Contact your supervisor."
```

**Seed agents:**
- `agent-001`: email `agent001@postefinance-agents.cd`, password `Password1!`
- `agent-002`: email `agent002@postefinance-agents.cd`, password `Password1!`

**Autofill behavior:**
- On first launch, pre-fill email: `agent001@postefinance-agents.cd`
- Pre-fill password: `Password1!`
- User can clear and change for testing

---

### 2.2 Agent Home Screen

**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart` (already exists)

**Layout:**

```
┌────────────────────────────────────────┐
│ Poste Finance Agent          [Logout] │
├────────────────────────────────────────┤
│  Float Balance                         │
│  ┌──────────────────────────────────┐ │
│  │ CDF                              │ │
│  │ Available: FC 5,000,000.00       │ │
│  │ Pending:   FC 0.00               │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ USD                              │ │
│  │ Available: $2,000.00             │ │
│  │ Pending:   $0.00                 │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Agent Status                          │
│  ┌──────────────────────────────────┐ │
│  │ ✓ Active                         │ │
│  │   Claude Mokonzi                 │ │
│  │   ID: agent-001                  │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Quick Actions                         │
│  [Cash In]      [Cash Out]            │
│  [Enroll]       [History]             │
└────────────────────────────────────────┘
```

**Data source:**
- Float balances: `OfflineAgentRepository.getFloatBalances()` returns wallet-shaped response with CDF/USD pockets
- Agent info: `OfflineAgentRepository.getAgentInfo(agentId)` for name, status
- Pull-to-refresh reloads float (no-op in offline, but preserves UX pattern)

**Quick actions:**
- **Cash In:** → `CashInOutScreen(mode: cashIn)`
- **Cash Out:** → `CashInOutScreen(mode: cashOut)`
- **Enroll:** → `EnrollCustomerScreen()`
- **History:** → `AgentHistoryScreen()` (new)
- **Logout:** Clear `_currentAgentId`, navigate to `/login`

**Seed float (agent-001):**
- `floatCdfMinor: 500000000` → FC 5,000,000.00 available
- `floatUsdMinor: 200000` → $2,000.00 available

---

### 2.3 Cash-In Flow

**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart` (already exists, enhance for limits/fee/PIN)

**Current behavior:**
- Segmented control: Cash In / Cash Out
- Inputs: Customer ID, Currency (USD/CDF), Amount
- Execute button → API call → success dialog

**Enhanced flow for offline mock:**

```
┌────────────────────────────────────────┐
│ Cash In                      [< Back]  │
├────────────────────────────────────────┤
│ [Cash In] [Cash Out]                   │
│                                        │
│ Customer Phone or ID                   │
│ [+243990123456____________]            │
│ [Lookup] → displays: Jean-Paul Kabila  │
│                                        │
│ Amount (CDF)                           │
│ [500000___] → FC 5,000.00              │
│                                        │
│ ─────────────────────────────────────  │
│ Transaction Fee:    FC 250.00          │
│ Agent receives:     FC 4,750.00        │
│ Customer credited:  FC 5,000.00        │
│ ─────────────────────────────────────  │
│                                        │
│ Daily Limit: FC 9,500,000 / 10,000,000 │
│ Per-txn max: FC 5,000,000              │
│                                        │
│ [Continue]                             │
└────────────────────────────────────────┘
```

**Step 1: Customer lookup**
- Input: Phone number (E.164) or customer ID
- Lookup via `_findCustomer()` in repository
- Display: Full name + KYC status badge
- Error if not found: "Customer not found. Enroll first?"

**Step 2: Amount + Fee preview**
- Currency selector: CDF / USD (default CDF)
- Amount input: validates > 0
- Fee calculation (read from seed `feeLimits` where `kind: FEE, paymentType: AGENT_CASH_IN`)
- Display breakdown:
  - Transaction fee
  - Customer receives (gross amount, no deduction for cash-in)
  - Agent float debit (amount)

**Limits validation (before PIN):**
- Fetch agent's `dailyLimitMinor` and `perTxnLimitMinor` from seed
- Calculate today's total from `journals` where `agentId = currentAgent AND type IN (AGENT_CASH_IN, AGENT_CASH_OUT) AND postedAt = today`
- Block if: `todayTotal + currentAmount > dailyLimit`
- Block if: `currentAmount > perTxnLimit`
- Show: "Daily limit: {used} / {total}"

**Step 3: PIN confirmation**
- Modal: "Enter your PIN"
- 6-digit input (masked)
- Hardcoded validation: PIN must equal `123456`
- On success → execute cash-in
- On failure → "Invalid PIN" (3 attempts, then block for 60s)

**Step 4: Execute**
```dart
OfflineAgentRepository.cashIn(
  customerId: lookupResult.id,
  amountMinor: (amount * 100).toInt().toString(),
  currency: selectedCurrency,
)
```

**Logic (in OfflineAgentRepository):**
1. Validate agent float >= amount (CDF or USD)
2. Debit agent float
3. Credit customer wallet (CDF or USD)
4. Create journal entries:
   - Agent float debit
   - Customer wallet credit
5. Return `{ journalId, status: POSTED, ... }`

**Receipt screen:**
```
┌────────────────────────────────────────┐
│        ✓ Cash-In Successful            │
├────────────────────────────────────────┤
│  Jean-Paul Kabila                      │
│  +243990123456                         │
│                                        │
│  Amount:        FC 5,000.00            │
│  Fee:           FC 250.00              │
│  Customer gets: FC 5,000.00            │
│                                        │
│  Agent float:   FC 4,995,000.00        │
│  Journal:       jnl_cashin_sess_42     │
│  Time:          2026-09-18 10:23 UTC   │
│                                        │
│  [Share Receipt]  [Done]               │
└────────────────────────────────────────┘
```

---

### 2.4 Cash-Out Flow

**Path:** Same screen, `CashInOutScreen` with mode toggle

**Enhanced flow:**

**Step 1: Customer identification**
- **Option A: Phone lookup** (same as cash-in)
- **Option B: OTP/Code entry**
  - Customer pre-generates a 6-digit OTP code in customer app (future)
  - For offline mock: accept hardcoded OTP `123456` → maps to `cust_kasee`

**Step 2: Amount + Fee preview**
- Customer balance check (read `availableMinor` from wallet)
- Block if insufficient balance
- Fee calculation (read from seed `feeLimits` where `paymentType: AGENT_CASH_OUT`)
- Display:
  - Customer pays (amount + fee)
  - Agent receives (amount)
  - Customer new balance

**Step 3: Limits + PIN** (same as cash-in)

**Step 4: Execute**
```dart
OfflineAgentRepository.cashOut(
  customerId: lookupResult.id,
  amountMinor: (amount * 100).toInt().toString(),
  currency: selectedCurrency,
)
```

**Logic:**
1. Validate customer balance >= (amount + fee)
2. Debit customer wallet
3. Credit agent float
4. Create journal entries
5. Return success

**Insufficient balance handling:**
- Show before PIN step: "Customer balance: FC 3,000. Cannot withdraw FC 5,000."
- Suggest lower amount or cancel

---

### 2.5 Enroll Customer Screen

**Path:** `apps/agent_mobile/lib/screens/enroll_customer_screen.dart` (already exists, enhance for offline KYC)

**Current behavior:**
- Inputs: First name, Last name, Phone, Email, Password
- API call → success dialog shows customer ID

**Enhanced for offline:**

**Fields:**
| Field | Required | Notes |
|-------|----------|-------|
| First Name | Yes | Min 2 chars |
| Last Name | Yes | Min 2 chars |
| Phone (E.164) | Optional | Used for cash-out OTP (future) |
| Email | Optional | Pre-filled `""` |
| Password | Yes | Pre-filled `Password1!` for demo |
| ID Number | Optional | Basic offline KYC |
| ID Type | Optional | Dropdown: National ID / Passport / Driver's License |

**Flow:**
1. Agent fills form
2. Tap **Enroll Customer**
3. Offline validation:
   - Check email uniqueness (if provided)
   - Create customer record with `enrolledByAgentId: currentAgentId`
   - Create CDF + USD wallets (both `availableMinor: 0`)
   - If ID provided: create `kyc` record with `status: PENDING_REVIEW`
4. Success screen:
   ```
   ✓ Customer Enrolled
   
   Jean-Paul Kabila
   ID: cust_sess_7
   Phone: +243990123456
   
   CDF Wallet: wal_cust_sess_7_cdf (FC 0.00)
   USD Wallet: wal_cust_sess_7_usd ($0.00)
   
   Customer can now receive cash-in.
   KYC status: PENDING_REVIEW
   
   [Done]
   ```

**Edge cases:**
- Email already exists → "Email already registered. Use phone lookup for cash operations."
- No phone + no email → Allow enrollment, but warn: "Customer will need email or phone for self-service login."

---

### 2.6 Agent History Screen (New)

**Path:** `apps/agent_mobile/lib/screens/agent_history_screen.dart`

**Layout:**
```
┌────────────────────────────────────────┐
│ Agent History                [< Back]  │
├────────────────────────────────────────┤
│ Today                                  │
│ [All] [Cash In] [Cash Out] [Enroll]   │
│                                        │
│ Search by phone or ref:                │
│ [+243990...____________] [Search]      │
│                                        │
│ ┌──────────────────────────────────┐  │
│ │ 10:23 AM  Cash In                │  │
│ │ Jean-Paul Kabila  FC 5,000.00    │  │
│ │ Ref: jnl_cashin_sess_42          │  │
│ └──────────────────────────────────┘  │
│ ┌──────────────────────────────────┐  │
│ │ 09:45 AM  Enroll                 │  │
│ │ Marie Tshala                     │  │
│ │ Ref: cust_sess_5                 │  │
│ └──────────────────────────────────┘  │
│ ┌──────────────────────────────────┐  │
│ │ 09:12 AM  Cash Out               │  │
│ │ Pierre Lumbu  FC 2,500.00        │  │
│ │ Ref: jnl_cashout_sess_41         │  │
│ └──────────────────────────────────┘  │
│                                        │
│ Total Today:                           │
│ Cash In:  FC 15,000 (3 txns)          │
│ Cash Out: FC 8,500 (2 txns)           │
│ Enrolled: 1 customer                   │
└────────────────────────────────────────┘
```

**Data source:**
- Query `journals` list where:
  - `agentId = currentAgentId`
  - `type IN (AGENT_CASH_IN, AGENT_CASH_OUT)`
  - `postedAt = today` (ISO date match on `YYYY-MM-DD`)
- Query `customers` where `enrolledByAgentId = currentAgentId AND createdAt = today`

**Filters:**
- **All:** Cash-in + Cash-out + Enrollments
- **Cash In:** Only `type: AGENT_CASH_IN`
- **Cash Out:** Only `type: AGENT_CASH_OUT`
- **Enroll:** Only customer records

**Search:**
- Input: Phone (partial match) or Reference ID (exact match)
- Filter displayed list client-side

**Tap item → Detail sheet:**
```
Cash-In Detail

Customer: Jean-Paul Kabila
Phone: +243990123456
ID: cust_kasee

Amount: FC 5,000.00
Fee: FC 250.00
Currency: CDF

Customer wallet after: FC 30,000.00
Agent float after: FC 4,995,000.00

Journal ID: jnl_cashin_sess_42
Posted: 2026-09-18T10:23:14Z

[Close]
```

---

## 3. Data Model & Seed

### 3.1 Agent Schema (universe.json)

```json
{
  "agents": [
    {
      "id": "agent-001",
      "name": "Kinshasa Agent 1",
      "firstName": "Claude",
      "lastName": "Mokonzi",
      "phoneE164": "+243810111111",
      "email": "agent001@postefinance-agents.cd",
      "password": "Password1!",
      "floatCdfMinor": 500000000,
      "floatUsdMinor": 200000,
      "floatWalletId": "wallet_float_agent001",
      "status": "ACTIVE",
      "dailyLimitCdfMinor": 1000000000,
      "perTxnLimitCdfMinor": 500000000,
      "dailyLimitUsdMinor": 400000,
      "perTxnLimitUsdMinor": 200000,
      "commissionBps": 50,
      "createdAt": "2026-07-01T08:00:00Z"
    },
    {
      "id": "agent-002",
      "name": "Gombe Agent 2",
      "firstName": "Beatrice",
      "lastName": "Nzuzi",
      "phoneE164": "+243810222222",
      "email": "agent002@postefinance-agents.cd",
      "password": "Password1!",
      "floatCdfMinor": 300000000,
      "floatUsdMinor": 100000,
      "floatWalletId": "wallet_float_agent002",
      "status": "ACTIVE",
      "dailyLimitCdfMinor": 800000000,
      "perTxnLimitCdfMinor": 400000000,
      "dailyLimitUsdMinor": 300000,
      "perTxnLimitUsdMinor": 150000,
      "commissionBps": 50,
      "createdAt": "2026-07-05T09:00:00Z"
    }
  ]
}
```

**Field notes:**
- `floatCdfMinor` / `floatUsdMinor`: Available balance in minor units (cents)
- `dailyLimitCdfMinor`: Maximum CDF agent can process per day (all txns combined)
- `perTxnLimitCdfMinor`: Maximum CDF per single transaction
- `commissionBps`: Basis points (50bps = 0.5%) — not deducted in P1, tracked for future

### 3.2 Customer Link (cust_kasee)

**Existing customer in seed:**
```json
{
  "id": "cust_kasee",
  "email": "jp.kabila@gmail.com",
  "password": "Password1!",
  "phoneE164": "+243990123456",
  "firstName": "Jean-Paul",
  "lastName": "Kabila",
  "segment": "OPEN",
  "status": "ACTIVE",
  "kycStatus": "APPROVED",
  "enrolledByAgentId": "agent-001",
  "createdAt": "2026-08-15T10:30:00Z"
}
```

**Wallets:**
```json
{
  "id": "wal_kasee_cdf",
  "customerId": "cust_kasee",
  "currency": "CDF",
  "availableMinor": 25000000,
  "ledgerMinor": 25000000,
  "blockedMinor": 0,
  "pendingMinor": 0
}
```

**Why this matters:**
- When agent-001 performs cash-in to `cust_kasee`, the `wal_kasee_cdf.availableMinor` increases
- Customer opens customer app → sees updated balance (via same `DemoUniverse` instance)
- **Shared universe sync:** Both APKs mutate the same in-memory seed during session

---

## 4. Shared Universe Integration

### 4.1 Current Architecture

```
packages/demo_universe/
├── data/universe.json (seed)
└── dart/
    └── lib/
        └── demo_universe.dart (DemoUniverse.load())

apps/yole_mobile/                         apps/agent_mobile/
lib/services/                             lib/services/
├── offline_demo_repository.dart          ├── offline_agent_repository.dart
│   (customer operations)                 │   (agent operations)
└── core_api_service.dart                 └── agent_api_service.dart
    (if OFFLINE_DEMO=true, uses repo)         (if OFFLINE_DEMO=true, uses repo)
```

**Shared state mechanism:**
- `DemoUniverse.load()` deep-clones `universe.json` into memory
- `OfflineDemoRepository._instance` (customer) and `OfflineAgentRepository._instance` (agent) both reference the **same** `DemoUniverse` object
- Mutations (cash-in, cash-out, enroll) modify the shared `Map<String, dynamic> _data`
- **Session-local:** Mutations do not persist to disk; restart = reload seed

### 4.2 Cross-App Demo Flow

**Scenario:** Agent cash-in visible in customer app

1. **Agent app:**
   - Agent logs in as `agent-001`
   - Cash-in FC 5,000 to `cust_kasee` (Jean-Paul)
   - `OfflineAgentRepository.cashIn()` mutates `DemoUniverse.data['wallets'][wal_kasee_cdf].availableMinor += 500000`

2. **Customer app (same device or emulator session):**
   - Customer logs in as `jp.kabila@gmail.com`
   - `OfflineDemoRepository.getMyWallets()` reads from same `DemoUniverse` instance
   - Home screen shows: "CDF Balance: FC 30,000.00" (was FC 25,000, now +5,000)

**Implementation notes:**
- Both repos MUST import `package:demo_universe/demo_universe.dart` and call `DemoUniverse.load()` once per session
- Use singleton pattern: `_instance ??= createFresh()`
- Do NOT reload universe between operations within same session

---

## 5. Offline Mock Architecture

### 5.1 AgentApiService (Existing)

**Path:** `apps/agent_mobile/lib/services/agent_api_service.dart`

**Current methods:**
- `getAgentInfo(String agentId)`
- `setAgentId(String agentId)`
- `clearAgentId()`
- `getFloatBalances()`
- `enrollCustomer(...)`
- `cashIn(...)`
- `cashOut(...)`

**Offline gate (add):**
```dart
class AgentApiService {
  static const bool _offlineDemo = 
      bool.fromEnvironment('OFFLINE_DEMO', defaultValue: true);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (_offlineDemo) {
      // Find agent by email in universe
      final agent = _findAgentByEmail(email);
      if (agent == null) throw Exception('Agent not found');
      if (agent['password'] != password) {
        throw Exception('Invalid password');
      }
      return OfflineAgentRepository.instance.login(agentId: agent['id']);
    } else {
      // Future: POST /api/agent/auth/login
      throw UnimplementedError('Live API not implemented');
    }
  }

  Map<String, dynamic>? _findAgentByEmail(String email) {
    final agents = OfflineAgentRepository.instance._list('agents');
    for (final a in agents) {
      if (a['email']?.toLowerCase() == email.toLowerCase()) return a;
    }
    return null;
  }
}
```

### 5.2 OfflineAgentRepository Enhancements

**Add methods:**

```dart
// Limits enforcement (called before PIN in UI)
Map<String, dynamic> getTodayUsage({String? agentId}) {
  final aid = agentId ?? _requireAgent();
  final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
  final journals = _list('journals')
      .where((j) =>
          j['agentId'] == aid &&
          (j['type'] == 'AGENT_CASH_IN' || j['type'] == 'AGENT_CASH_OUT') &&
          j['postedAt']?.startsWith(today) == true)
      .toList();

  int totalCdfMinor = 0;
  int totalUsdMinor = 0;
  int cashInCount = 0;
  int cashOutCount = 0;

  for (final j in journals) {
    final amt = _int(j['amountMinor']);
    if (j['currency'] == 'CDF') totalCdfMinor += amt;
    if (j['currency'] == 'USD') totalUsdMinor += amt;
    if (j['type'] == 'AGENT_CASH_IN') cashInCount++;
    if (j['type'] == 'AGENT_CASH_OUT') cashOutCount++;
  }

  return {
    'agentId': aid,
    'date': today,
    'totalCdfMinor': totalCdfMinor,
    'totalUsdMinor': totalUsdMinor,
    'cashInCount': cashInCount,
    'cashOutCount': cashOutCount,
  };
}

// History: journals filtered by agent + today
List<Map<String, dynamic>> getTodayHistory({String? agentId}) {
  final aid = agentId ?? _requireAgent();
  final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
  return _list('journals')
      .where((j) =>
          j['agentId'] == aid &&
          j['postedAt']?.startsWith(today) == true)
      .toList();
}

// Enrollments today
List<Map<String, dynamic>> getTodayEnrollments({String? agentId}) {
  final aid = agentId ?? _requireAgent();
  final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
  return _list('customers')
      .where((c) =>
          c['enrolledByAgentId'] == aid &&
          c['createdAt']?.startsWith(today) == true)
      .toList();
}
```

### 5.3 Build Configuration

**Dart define:** `--dart-define=OFFLINE_DEMO=true` (default for agent app)

**main.dart:**
```dart
void main() {
  const offlineDemo = bool.fromEnvironment('OFFLINE_DEMO', defaultValue: true);
  if (offlineDemo) {
    OfflineAgentRepository.createFresh(); // Load universe once
  }
  runApp(const AgentMobileApp());
}
```

---

## 6. Acceptance Criteria

### 6.1 Agent Login
- [ ] Agent email `agent001@postefinance-agents.cd` + `Password1!` → login success, navigate to home
- [ ] Agent email + wrong password → "Invalid credentials"
- [ ] Customer email `jp.kabila@gmail.com` on agent APK → banner "Use customer app"
- [ ] Unknown email → "Agent not found"
- [ ] Autofill: email pre-filled `agent001@postefinance-agents.cd`, password `Password1!` on first launch

### 6.2 Agent Home
- [ ] Float balances display CDF + USD from seed (agent-001: FC 5M CDF, $2K USD)
- [ ] Pending amounts show as 0 (offline has no async pending)
- [ ] Agent status shows "Active"
- [ ] Agent name displays: "Claude Mokonzi"
- [ ] Quick actions navigate: Cash In, Cash Out, Enroll, History
- [ ] Logout clears session, returns to login

### 6.3 Cash-In
- [ ] Phone lookup `+243990123456` → displays "Jean-Paul Kabila"
- [ ] Invalid phone → "Customer not found. Enroll first?"
- [ ] Amount FC 5,000 → fee preview shows (read from seed feeLimits)
- [ ] Limits shown: "Daily: 0 / 10,000,000" before first txn
- [ ] PIN `123456` → success
- [ ] PIN `000000` → "Invalid PIN"
- [ ] After cash-in: agent float decreases, customer wallet increases
- [ ] Receipt shows journal ID, timestamp, balances

### 6.4 Cash-Out
- [ ] Phone lookup works same as cash-in
- [ ] Customer balance insufficient → blocked before PIN, suggest lower amount
- [ ] Amount + fee deducted from customer, amount credited to agent
- [ ] Receipt generated

### 6.5 Enroll Customer
- [ ] Minimal form: First + Last + Phone → creates customer with CDF+USD wallets (0 balance)
- [ ] Email uniqueness: duplicate email → error "Email already registered"
- [ ] Success screen shows customer ID + wallet IDs
- [ ] Customer added to universe with `enrolledByAgentId: agent-001`

### 6.6 History
- [ ] Today's cash-in/out displayed, grouped by time descending
- [ ] Filter: Cash In only → hides cash-out
- [ ] Search by phone: `+243990` → shows matching txns
- [ ] Totals correct: "Cash In: FC 15,000 (3 txns)"
- [ ] Tap item → detail sheet with full info

### 6.7 Cross-App Sync
- [ ] Agent cash-in FC 5,000 to `cust_kasee` → customer app shows balance increase from FC 25K → FC 30K
- [ ] Enrollment by agent → customer can login with email/password in customer app

---

## 7. Risks & Assumptions

### 7.1 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Shared universe mutations not synced | High — cross-app demo fails | Enforce singleton `DemoUniverse.load()` once per session, shared via package import |
| Hardcoded PIN `123456` leaks to production | High — security vuln | Add build-time assertion: `assert(_offlineDemo, 'Hardcoded PIN only for demo')`; gate behind `OFFLINE_DEMO` flag |
| Agent limits not enforced | Medium — demo exceeds real-world caps | UI blocks before PIN; add red banner if limit exceeded |
| Fee calculation differs from live API | Low — demo inaccuracy | Document: "Fee preview is illustrative; live API may differ" |
| Customer APK shows agent login option | Medium — UX confusion | Not applicable (separate APK); but if merged: route by email pattern |

### 7.2 Assumptions

1. **Session-local only:** Mutations do not persist; app restart reloads seed. Accepted for offline demo.
2. **No network:** All operations succeed instantly. No retry, no timeout, no partial failure.
3. **Single agent per session:** No multi-agent handoff or session transfer.
4. **PIN hardcoded:** All agents use `123456`. Future: per-agent PIN in seed.
5. **Commissions not accrued:** `commissionBps` exists in seed but not calculated/displayed in P1.
6. **Float top-up manual:** Agent float never auto-reloads. Future: agent requests top-up via supervisor UI.
7. **No biometrics:** Agent login is email+password only. Future: fingerprint on supported devices.
8. **Timezone UTC:** All timestamps in UTC. No local timezone conversion.
9. **Language English:** No i18n in P1. Future: French localization.
10. **No camera KYC:** ID number is typed, not scanned. Future: ID card OCR.

---

## 8. Files to Modify

### 8.1 New Files
- `apps/agent_mobile/lib/screens/agent_history_screen.dart` — History view
- `apps/agent_mobile/lib/widgets/pin_input_modal.dart` — Reusable PIN dialog
- `apps/agent_mobile/lib/widgets/customer_lookup_field.dart` — Phone/ID lookup component

### 8.2 Enhanced Files
- `apps/agent_mobile/lib/screens/agent_login_screen.dart` — Add email+password auth, customer email banner
- `apps/agent_mobile/lib/screens/agent_home_screen.dart` — Add History button, agent status card
- `apps/agent_mobile/lib/screens/cash_in_out_screen.dart` — Add customer lookup, fee preview, limits, PIN modal
- `apps/agent_mobile/lib/screens/enroll_customer_screen.dart` — Add ID fields, offline KYC
- `apps/agent_mobile/lib/services/offline_agent_repository.dart` — Add `getTodayUsage()`, `getTodayHistory()`, `getTodayEnrollments()`
- `apps/agent_mobile/lib/services/agent_api_service.dart` — Add `login(email, password)`, email-based routing
- `packages/demo_universe/data/universe.json` — Add agent limits (`dailyLimitCdfMinor`, `perTxnLimitCdfMinor`, etc.)

### 8.3 Test Files
- `apps/agent_mobile/test/offline_agent_repository_test.dart` — Add tests for limits, history, enrollments
- `apps/agent_mobile/test/screens/agent_login_screen_test.dart` — Test email routing, customer banner
- `apps/agent_mobile/test/screens/cash_in_out_screen_test.dart` — Test PIN flow, limits blocking

---

## 9. Implementation Checklist

**Phase 1A: Authentication & Home (Days 1-2)**
- [ ] Add email+password fields to `AgentLoginScreen`
- [ ] Implement email-based routing (agent vs customer)
- [ ] Show "Use customer app" banner for customer emails
- [ ] Add agent status card to `AgentHomeScreen`
- [ ] Add History button to home quick actions

**Phase 1B: Cash Operations (Days 3-5)**
- [ ] Customer lookup component (phone/ID → name)
- [ ] Fee preview calculation (read `feeLimits` from seed)
- [ ] Daily limits display ("Daily: X / Y")
- [ ] Limits enforcement (block if exceeded)
- [ ] PIN input modal (6 digits, masked)
- [ ] PIN validation (`123456` hardcoded)
- [ ] Receipt screen with journal ID, balances

**Phase 1C: Enroll & History (Days 6-7)**
- [ ] Add ID fields to `EnrollCustomerScreen`
- [ ] Offline KYC record creation
- [ ] Implement `AgentHistoryScreen` with filters
- [ ] Search by phone/ref in history
- [ ] Detail sheet for transaction tap
- [ ] Today's totals summary footer

**Phase 1D: Seed & Universe (Day 8)**
- [ ] Add agent-002 to `universe.json` (second demo agent)
- [ ] Add `dailyLimitCdfMinor`, `perTxnLimitCdfMinor` to both agents
- [ ] Link `cust_kasee` to `agent-001` via `enrolledByAgentId`
- [ ] Verify CDF+USD wallets for `cust_kasee` have non-zero balances

**Phase 1E: Testing & Validation (Days 9-10)**
- [ ] Unit tests: `offline_agent_repository_test.dart` (limits, history)
- [ ] Widget tests: Login routing, PIN modal, customer lookup
- [ ] Integration test: Cash-in on agent app → balance visible in customer app
- [ ] Manual QA: All acceptance criteria green

---

## 10. Future Enhancements (Out of Scope P1)

1. **Commission tracking:** Display agent earnings per transaction (read `commissionBps`)
2. **Assisted bill pay:** Agent pays SNEL/Vodacom bill on behalf of customer
3. **Float top-up request:** Agent submits request to supervisor via app
4. **Multi-day history:** Date picker, pagination for older transactions
5. **Biometrics:** Fingerprint unlock for agent login
6. **Customer-app agent tabs:** Merge agent APK as tabs in customer app (decision pending)
7. **French i18n:** Localize all strings to French
8. **ID card OCR:** Camera-based ID scanning for enrollment
9. **Receipt sharing:** SMS or email receipt to customer
10. **Offline persistence:** Save mutations to SQLite, sync on reconnect (hybrid mode)

---

**End of Design Document**
