# Poste Finance Agent Mock Implementation Plan

> **For agentic workers:** This plan REQUIRES the `subagent-driven-development` or `executing-plans` sub-skill.

**Date:** 2026-09-18  
**Spec:** [Agent Mock Design](../specs/2026-09-18-poste-finance-agent-mock-design.md)  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a`  
**Approach:** Extend existing `apps/agent_mobile/` — separate APK, offline-only

---

## Goal

Implement a fully functional offline agent mobile app for Poste Finance that allows agents to:
- Login with email/password (agent credentials only)
- View multi-currency float balances (CDF + USD)
- Perform cash-in/cash-out operations with customer lookup, fee preview, limits enforcement, and PIN validation
- Enroll new customers with basic offline KYC
- View transaction history (today's cash operations and enrollments)
- Sync with customer app via shared `DemoUniverse` instance

**Success:** Agent can login as `agent001@postefinance-agents.cd` / `Password1!`, cash-in FC 5,000 to `cust_kasee` (Jean-Paul), and customer app immediately shows updated balance (FC 25K → FC 30K).

---

## Architecture

### App Boundaries
- **Agent APK:** `apps/agent_mobile/` — standalone Flutter app (not tabs in customer app)
- **Customer APK:** `apps/yole_mobile/` — existing customer app (no changes required except shared universe)

### Shared Universe Pattern
```
packages/demo_universe/
├── data/universe.json (seed: agents, customers, wallets, journals)
└── dart/lib/demo_universe.dart (DemoUniverse.load())

apps/agent_mobile/lib/services/
├── offline_agent_repository.dart (agent operations)
└── agent_api_service.dart (offline gate: if OFFLINE_DEMO=true → repo)

apps/yole_mobile/lib/services/
└── offline_demo_repository.dart (customer operations)
```

**Shared state:** Both repos reference the same `DemoUniverse._instance`. Mutations (cash-in, enroll) modify the shared `Map<String, dynamic> _data`. Session-local only — restart reloads seed.

### Offline Mock Architecture
- **Build flag:** `--dart-define=OFFLINE_DEMO=true` (default for agent app)
- **No network:** All operations succeed instantly via in-memory mutations
- **Hardcoded PIN:** `123456` for all agent operations (same as customer demo PIN)
- **Autofill credentials:** `agent001@postefinance-agents.cd` / `Password1!` pre-filled on first launch

---

## Tech Stack

- **Flutter:** 3.x (existing monorepo setup)
- **State management:** StatefulWidget + `setState` (matches existing agent screens)
- **Navigation:** Named routes (existing: `/`, `/home`)
- **Data:** In-memory `DemoUniverse` (no SQLite, no network)
- **Shared package:** `package:demo_universe/demo_universe.dart`

---

## Global Constraints

1. **Separate APK only:** `apps/agent_mobile/` is standalone (not customer app agent tabs)
2. **Offline mock:** `OFFLINE_DEMO=true` — no live API integration
3. **Hardcoded credentials:** `agent001@postefinance-agents.cd` / `Password1!` / PIN `123456`
4. **Email routing:** Customer email on agent login → banner "Please use customer app"
5. **Cash operations:** Agent cash-in/out moves Jean-Paul's wallet via shared universe
6. **P0 features:** Login, home, cash-in, cash-out, receipt, history, limits, enroll polish
7. **Out of scope (P1+):** Commissions, assisted bill pay, full Bank UI Kit, customer APK agent tabs, biometrics
8. **TDD:** Unit tests for repository methods (limits, history), widget tests for login routing and PIN modal
9. **Commits:** One commit per logical task (e.g., "feat: add email/password to agent login", "feat: add daily limits enforcement")
10. **No placeholders:** All methods must be fully implemented — no TBD or TODO comments

---

## Implementation Tasks

### Phase 1: Seed & Universe Setup

#### Task 1.1: Update universe.json with agent limits and fee configs
**Path:** `packages/demo_universe/data/universe.json`

- [ ] Add `dailyLimitCdfMinor`, `perTxnLimitCdfMinor`, `dailyLimitUsdMinor`, `perTxnLimitUsdMinor` to `agents[agent-001]` and `agents[agent-002]`
- [ ] Verify `agent-001` has:
  - `email: "agent001@postefinance-agents.cd"`
  - `password: "Password1!"`
  - `floatCdfMinor: 500000000` (FC 5M)
  - `floatUsdMinor: 200000` ($2K)
  - `dailyLimitCdfMinor: 1000000000` (FC 10M)
  - `perTxnLimitCdfMinor: 500000000` (FC 5M)
  - `dailyLimitUsdMinor: 400000` ($4K)
  - `perTxnLimitUsdMinor: 200000` ($2K)
- [ ] Add `agent-002` if not present (similar structure, Gombe agent)
- [ ] Verify `cust_kasee` has `enrolledByAgentId: "agent-001"`
- [ ] Verify `cust_kasee` has CDF wallet `wal_kasee_cdf` with `availableMinor: 25000000` (FC 25K)
- [ ] Add `feeLimits` array if not present (cash-in/out fee structures)

**Commit:** `feat: add agent limits and fee configs to universe seed`

---

### Phase 2: Authentication & Login

#### Task 2.1: Add email/password fields to AgentLoginScreen
**Path:** `apps/agent_mobile/lib/screens/agent_login_screen.dart`

- [ ] Replace single `_agentIdController` with `_emailController` and `_passwordController`
- [ ] Update UI: email input (with email validation), password input (obscured)
- [ ] Autofill on `initState`: email `agent001@postefinance-agents.cd`, password `Password1!`
- [ ] Update login button: disabled until both fields valid (email format + password min 8 chars)
- [ ] Remove agent ID hint text
- [ ] Call `_api.login(email: email, password: password)` instead of `getAgentInfo(agentId)`

**Commit:** `feat: add email/password to agent login screen`

#### Task 2.2: Implement email-based login routing in AgentApiService
**Path:** `apps/agent_mobile/lib/services/agent_api_service.dart`

- [ ] Add `login({required String email, required String password})` method
- [ ] Offline gate: if `_offlineDemo`, find agent by email in `OfflineAgentRepository`
- [ ] Route logic:
  - If email matches agent pattern (`@postefinance-agents.cd`):
    - Validate password against seed agent.password
    - If valid → return `OfflineAgentRepository.instance.login(agentId: agent['id'])`
    - If invalid → throw `Exception('Invalid password')`
  - If email matches customer pattern (e.g., `@gmail.com`, not agent domain):
    - Throw `Exception('CUSTOMER_EMAIL')` (caught by UI to show banner)
  - If email unknown:
    - Throw `Exception('Agent not found')`
- [ ] Add `_findAgentByEmail(String email)` helper (iterates `_list('agents')`)

**Commit:** `feat: add email-based login routing with customer detection`

#### Task 2.3: Show "Use customer app" banner for customer emails
**Path:** `apps/agent_mobile/lib/screens/agent_login_screen.dart`

- [ ] Update `_login()` error handling: catch `Exception('CUSTOMER_EMAIL')`
- [ ] Show dismissible banner (not SnackBar): "Customer accounts must use Yole customer app. Download from [link]."
- [ ] Use `MaterialBanner` or Card with warning icon
- [ ] Banner dismissible with "X" button or auto-dismiss after 10s

**Commit:** `feat: show customer app banner on customer email login attempt`

#### Task 2.4: Add login repository tests
**Path:** `apps/agent_mobile/test/services/offline_agent_repository_test.dart`

- [ ] Test: `login()` with valid agent email/password → returns agent info, sets `_currentAgentId`
- [ ] Test: `login()` with invalid password → throws "Invalid password"
- [ ] Test: `login()` with customer email → (handled by service layer, repo test not needed)
- [ ] Test: `login()` with unknown email → throws "Agent not found"

**Commit:** `test: add offline agent repository login tests`

---

### Phase 3: Agent Home & Float Display

#### Task 3.1: Add agent status card to AgentHomeScreen
**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart`

- [ ] After float balance cards, add "Agent Status" section
- [ ] Fetch agent info: `await _api.getAgentInfo(_currentAgentId)`
- [ ] Display:
  - Status badge: "✓ Active" (green) or "⊗ Inactive" (red) based on `agent.status`
  - Agent full name: `agent.firstName + agent.lastName`
  - Agent ID: `agent.id`
- [ ] Styled as Card with ListTile or custom layout

**Commit:** `feat: add agent status card to home screen`

#### Task 3.2: Add History button to home quick actions
**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart`

- [ ] Update "Actions" section: add "History" tile after "Cash In / Out"
- [ ] OnTap: navigate to `AgentHistoryScreen()` (created in Phase 6)
- [ ] Icon: `Icons.history`
- [ ] Temporarily navigate to placeholder screen (remove after Phase 6)

**Commit:** `feat: add history button to agent home quick actions`

---

### Phase 4: Cash Operations (Cash-In & Cash-Out)

#### Task 4.1: Create reusable customer lookup widget
**Path:** `apps/agent_mobile/lib/widgets/customer_lookup_field.dart`

- [ ] Create `CustomerLookupField` stateful widget
- [ ] Input: phone (E.164 format) or customer ID
- [ ] "Lookup" button triggers `OfflineAgentRepository._findCustomer(phoneOrId)`
- [ ] On success: display customer full name + KYC status badge below input
- [ ] On failure: show "Customer not found. Enroll first?" with link to EnrollCustomerScreen
- [ ] Return `Map<String, dynamic>? customer` to parent via callback

**Commit:** `feat: create customer lookup widget for cash operations`

#### Task 4.2: Add customer lookup to CashInOutScreen
**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

- [ ] Replace `_customerIdController` TextFormField with `CustomerLookupField`
- [ ] Store looked-up customer in `_selectedCustomer` state
- [ ] Disable amount input until customer looked up
- [ ] Update existing flow: use `_selectedCustomer['id']` for cash-in/out API calls

**Commit:** `feat: integrate customer lookup in cash-in/out screen`

#### Task 4.3: Add fee preview calculation (read from seed feeLimits)
**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

- [ ] After amount input, fetch fee from `OfflineAgentRepository.getFee(paymentType, currency, amountMinor)`
- [ ] Display breakdown card:
  - Transaction fee: calculated from seed `feeLimits` where `kind: FEE, paymentType: AGENT_CASH_IN/OUT`
  - Customer credited (cash-in): gross amount (no deduction)
  - Customer debited (cash-out): amount + fee
  - Agent float change: -amount (cash-in) or +amount (cash-out)
- [ ] Use currency symbol: CDF → `FC`, USD → `$`
- [ ] Real-time recalc on amount change

**Commit:** `feat: add fee preview to cash-in/out screen`

#### Task 4.4: Add daily limits display and enforcement
**Path:** `apps/agent_mobile/lib/services/offline_agent_repository.dart`

- [ ] Add `getTodayUsage({String? agentId})` method:
  - Query `journals` where `agentId = currentAgent AND type IN (AGENT_CASH_IN, AGENT_CASH_OUT) AND postedAt = today`
  - Sum `totalCdfMinor`, `totalUsdMinor`, `cashInCount`, `cashOutCount`
  - Return map with usage + limits from agent seed
- [ ] Add `_isWithinLimits({required amount, required currency})` validator:
  - Check: `todayTotal + currentAmount <= dailyLimit`
  - Check: `currentAmount <= perTxnLimit`
  - Return `{withinLimits: bool, reason: String?}`

**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

- [ ] After fee preview, display limits card:
  - "Daily Limit: FC X / Y" (used / total)
  - "Per-txn max: FC Z"
- [ ] Before PIN modal, validate limits: if exceeded → show error banner, block proceed
- [ ] Red warning banner: "Daily limit exceeded. Remaining: FC X."

**Commit:** `feat: add daily limits display and enforcement`

#### Task 4.5: Create reusable PIN input modal
**Path:** `apps/agent_mobile/lib/widgets/pin_input_modal.dart`

- [ ] Create `showPinModal(BuildContext context)` function → returns `Future<bool>`
- [ ] Modal: 6-digit PIN input (masked dots or obscured text)
- [ ] Hardcoded validation: PIN must equal `123456`
- [ ] On success → return `true`, dismiss modal
- [ ] On failure → show "Invalid PIN" inline, allow retry (max 3 attempts)
- [ ] After 3 failed attempts → return `false`, show "Too many attempts. Try again in 60s." (UI only, no actual block in offline)

**Commit:** `feat: create PIN input modal widget`

#### Task 4.6: Integrate PIN validation in cash-in/out flow
**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

- [ ] Update `_execute()` method: before API call, show PIN modal
- [ ] Call `await showPinModal(context)`
- [ ] If PIN valid → proceed with cash-in/out
- [ ] If PIN invalid → return early, show error

**Commit:** `feat: integrate PIN validation in cash-in/out flow`

#### Task 4.7: Enhance receipt screen with balance after and journal ID
**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

- [ ] Update success dialog to include:
  - Customer name + phone (from `_selectedCustomer`)
  - Amount + fee breakdown
  - Customer balance after (fetch updated wallet via `OfflineAgentRepository.getWallet()`)
  - Agent float after (fetch updated float via `OfflineAgentRepository.getFloatBalances()`)
  - Journal ID (from API response)
  - Timestamp (ISO 8601 formatted)
- [ ] Add "Share Receipt" button (future: SMS/email, for now just toast "Feature coming soon")
- [ ] "Done" button → pop twice (back to home)

**Commit:** `feat: enhance receipt screen with full transaction details`

#### Task 4.8: Add repository methods for cash operations helpers
**Path:** `apps/agent_mobile/lib/services/offline_agent_repository.dart`

- [ ] Add `_findCustomerByPhone(String phoneE164)` helper:
  - Iterate `_list('customers')` where `phoneE164` matches
  - Return customer or null
- [ ] Add `_findCustomerById(String customerId)` (already exists as `_findCustomer`, verify)
- [ ] Add `getFee({required String paymentType, required String currency, required int amountMinor})`:
  - Read `feeLimits` from seed where `kind: FEE, paymentType: paymentType, currency: currency`
  - Calculate fee: flat + bps (basis points)
  - Return `{feeMinor: int}`
- [ ] Add `getWallet({required String customerId, required String currency})`:
  - Find wallet, return DTO with `availableMinor`, `ledgerMinor`, etc.

**Commit:** `feat: add cash operations helper methods to repository`

#### Task 4.9: Update cashIn/cashOut to handle fee deduction (cash-out only)
**Path:** `apps/agent_mobile/lib/services/offline_agent_repository.dart`

- [ ] Cash-in: Customer receives full amount (no fee deduction)
- [ ] Cash-out: Customer debited amount + fee, agent receives amount (fee stays with bank)
- [ ] Update `_moveCash()` method:
  - Fetch fee via `getFee()`
  - For cash-out: debit customer wallet `amount + fee`, credit agent float `amount`
  - For cash-in: debit agent float `amount`, credit customer wallet `amount`
- [ ] Create separate journal entries for fee (if tracked in P1, otherwise skip)

**Commit:** `feat: add fee handling to cash-out operations`

#### Task 4.10: Add cash operations tests
**Path:** `apps/agent_mobile/test/services/offline_agent_repository_test.dart`

- [ ] Test: `getTodayUsage()` with no transactions → returns 0 usage
- [ ] Test: `getTodayUsage()` after one cash-in → returns correct CDF usage
- [ ] Test: `_isWithinLimits()` with amount under daily limit → true
- [ ] Test: `_isWithinLimits()` with amount exceeding per-txn limit → false
- [ ] Test: `cashIn()` updates agent float and customer wallet correctly
- [ ] Test: `cashOut()` with fee → debits customer amount+fee, credits agent amount

**Commit:** `test: add cash operations tests for limits and fees`

---

### Phase 5: Customer Enrollment

#### Task 5.1: Add ID fields to EnrollCustomerScreen
**Path:** `apps/agent_mobile/lib/screens/enroll_customer_screen.dart`

- [ ] Add optional `_idNumberController` TextFormField (label: "ID Number (Optional)")
- [ ] Add optional `_idTypeController` dropdown: National ID / Passport / Driver's License
- [ ] Update success dialog to show:
  - Customer ID
  - CDF wallet ID (FC 0.00)
  - USD wallet ID ($0.00)
  - KYC status: "PENDING_REVIEW" (if ID provided) or "PENDING" (no ID)

**Commit:** `feat: add ID fields for offline KYC to enroll screen`

#### Task 5.2: Create KYC record on enrollment (if ID provided)
**Path:** `apps/agent_mobile/lib/services/offline_agent_repository.dart`

- [ ] Update `enrollCustomer()` method:
  - If `idNumber` and `idType` provided → create KYC record:
    - `id: _nextId('kyc')`
    - `customerId: newCustomerId`
    - `idNumber: idNumber`
    - `idType: idType`
    - `status: 'PENDING_REVIEW'`
    - `submittedAt: now`
  - Add to `_list('kycs')` (create key if not exists)
  - Return KYC status in response

**Commit:** `feat: create offline KYC record on enrollment with ID`

#### Task 5.3: Add enrollment tests
**Path:** `apps/agent_mobile/test/services/offline_agent_repository_test.dart`

- [ ] Test: `enrollCustomer()` with email → creates customer + 2 wallets (CDF + USD)
- [ ] Test: `enrollCustomer()` with duplicate email → throws "Email already registered"
- [ ] Test: `enrollCustomer()` with ID → creates KYC record with status PENDING_REVIEW
- [ ] Test: `enrollCustomer()` sets `enrolledByAgentId` to current agent

**Commit:** `test: add enrollment and KYC tests`

---

### Phase 6: Agent History

#### Task 6.1: Create AgentHistoryScreen with today's transactions
**Path:** `apps/agent_mobile/lib/screens/agent_history_screen.dart`

- [ ] Create new screen: AppBar "Agent History" with back button
- [ ] Segment filter: [All] [Cash In] [Cash Out] [Enroll]
- [ ] Fetch data:
  - Cash operations: `OfflineAgentRepository.getTodayHistory()` (returns journals)
  - Enrollments: `OfflineAgentRepository.getTodayEnrollments()` (returns customers)
- [ ] Display grouped list: time descending, each item shows:
  - Time (HH:MM AM/PM)
  - Type icon (cash-in: down arrow green, cash-out: up arrow orange, enroll: person add)
  - Customer name (from journal `customerId` lookup)
  - Amount + currency (for cash operations)
  - Reference ID (journal ID or customer ID)
- [ ] Tap item → show detail sheet (see Task 6.3)

**Commit:** `feat: create agent history screen with today's transactions`

#### Task 6.2: Add repository methods for history
**Path:** `apps/agent_mobile/lib/services/offline_agent_repository.dart`

- [ ] Add `getTodayHistory({String? agentId})` method:
  - Query `journals` where `agentId = currentAgent AND postedAt = today (YYYY-MM-DD)`
  - Return list sorted by `postedAt` descending
- [ ] Add `getTodayEnrollments({String? agentId})` method:
  - Query `customers` where `enrolledByAgentId = currentAgent AND createdAt = today`
  - Return list sorted by `createdAt` descending

**Commit:** `feat: add history query methods to repository`

#### Task 6.3: Add transaction detail sheet
**Path:** `apps/agent_mobile/lib/screens/agent_history_screen.dart`

- [ ] On item tap: show bottom sheet with full transaction details
- [ ] Cash-in/out detail:
  - Customer name + phone + ID
  - Amount + fee + currency
  - Customer balance after (from journal `balanceAfterMinor`)
  - Agent float after (calculate from current float - sum of later txns)
  - Journal ID
  - Posted timestamp
- [ ] Enroll detail:
  - Customer name + phone + email
  - Customer ID
  - Wallet IDs (CDF + USD)
  - KYC status
  - Enrolled timestamp
- [ ] "Close" button to dismiss sheet

**Commit:** `feat: add transaction detail sheet to history screen`

#### Task 6.4: Add search by phone/ref in history
**Path:** `apps/agent_mobile/lib/screens/agent_history_screen.dart`

- [ ] Add search bar above list: "Search by phone or ref"
- [ ] On input change: filter displayed list client-side
- [ ] Phone search: partial match on customer phone (fetch customer from journal `customerId`)
- [ ] Ref search: exact match on journal ID or customer ID

**Commit:** `feat: add search to agent history screen`

#### Task 6.5: Add today's totals summary footer
**Path:** `apps/agent_mobile/lib/screens/agent_history_screen.dart`

- [ ] At bottom of list, show summary card:
  - "Total Today:"
  - "Cash In: FC X (N txns)"
  - "Cash Out: FC Y (M txns)"
  - "Enrolled: Z customers"
- [ ] Calculate from filtered list (respects segment filter and search)

**Commit:** `feat: add totals summary to history screen`

#### Task 6.6: Add history tests
**Path:** `apps/agent_mobile/test/services/offline_agent_repository_test.dart`

- [ ] Test: `getTodayHistory()` with no transactions → returns empty list
- [ ] Test: `getTodayHistory()` after cash-in → returns 1 journal
- [ ] Test: `getTodayEnrollments()` after enrollment → returns 1 customer

**Commit:** `test: add history query tests`

---

### Phase 7: Cross-App Sync & Integration Tests

#### Task 7.1: Verify shared universe singleton pattern
**Path:** `apps/agent_mobile/lib/main.dart`

- [ ] In `main()`, ensure `OfflineAgentRepository.createFresh()` called once on app start (if `OFFLINE_DEMO=true`)
- [ ] Verify `_instance` is singleton and shared across all service calls

**Path:** `apps/yole_mobile/lib/main.dart` (customer app)

- [ ] Verify `OfflineDemoRepository.createFresh()` called once on customer app start
- [ ] Confirm both repos use same `DemoUniverse.load()` (no separate instances)

**Commit:** `chore: verify shared universe singleton pattern`

#### Task 7.2: Integration test: cash-in on agent → balance visible in customer
**Path:** `apps/agent_mobile/test_integration/cross_app_sync_test.dart`

- [ ] Test scenario:
  1. Agent login as `agent001@postefinance-agents.cd`
  2. Cash-in FC 5,000 to `cust_kasee`
  3. Customer repo reads wallet for `cust_kasee` → verify balance increased by FC 5,000
- [ ] Use `OfflineAgentRepository.instance` and `OfflineDemoRepository.instance` in same test
- [ ] Assert: customer wallet `availableMinor` = `25000000 + 500000 = 25500000`

**Commit:** `test: add cross-app sync integration test`

---

### Phase 8: Polish & Device Checklist

#### Task 8.1: Add offline demo banner to agent home screen
**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart`

- [ ] Import existing `OfflineDemoBanner` widget (if exists)
- [ ] Display at top of home screen: "Offline demo — no live API"
- [ ] Only show if `OFFLINE_DEMO=true`

**Commit:** `feat: add offline demo banner to agent home`

#### Task 8.2: Add logout confirmation dialog
**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart`

- [ ] On logout button tap: show confirmation dialog "Are you sure you want to logout?"
- [ ] Confirm → clear session via `_api.clearAgentId()`, navigate to `/`
- [ ] Cancel → dismiss dialog

**Commit:** `feat: add logout confirmation dialog`

#### Task 8.3: Add error handling for insufficient float
**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

- [ ] Before PIN modal, check agent float >= amount (for cash-in)
- [ ] If insufficient: show red banner "Insufficient float. Available: FC X. Requested: FC Y."
- [ ] Block proceed until amount reduced or customer changed

**Commit:** `feat: add insufficient float error handling`

#### Task 8.4: Add pull-to-refresh to agent home
**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart`

- [ ] Already exists (`RefreshIndicator` on ListView)
- [ ] Verify refresh reloads float balances (no-op in offline, but preserves UX pattern)

**Commit:** `chore: verify pull-to-refresh on agent home`

#### Task 8.5: Add loading states to all screens
**Paths:** All screens

- [ ] Verify all API calls show `CircularProgressIndicator` during load
- [ ] Disable buttons while loading (already exists on most screens, audit all)

**Commit:** `chore: audit loading states on all screens`

#### Task 8.6: Add navigation tests for all flows
**Path:** `apps/agent_mobile/test/navigation_test.dart`

- [ ] Test: login → home → cash-in → receipt → home
- [ ] Test: login → home → enroll → success → home
- [ ] Test: login → home → history → detail sheet → home
- [ ] Test: logout → login screen

**Commit:** `test: add navigation flow tests`

---

## Acceptance Criteria Checklist

### Agent Login (Design § 6.1)
- [ ] Agent email `agent001@postefinance-agents.cd` + `Password1!` → login success, navigate to home
- [ ] Agent email + wrong password → "Invalid credentials"
- [ ] Customer email `jp.kabila@gmail.com` on agent APK → banner "Use customer app"
- [ ] Unknown email → "Agent not found"
- [ ] Autofill: email pre-filled `agent001@postefinance-agents.cd`, password `Password1!` on first launch

### Agent Home (Design § 6.2)
- [ ] Float balances display CDF + USD from seed (agent-001: FC 5M CDF, $2K USD)
- [ ] Pending amounts show as 0 (offline has no async pending)
- [ ] Agent status shows "Active"
- [ ] Agent name displays: "Claude Mokonzi"
- [ ] Quick actions navigate: Cash In, Cash Out, Enroll, History
- [ ] Logout clears session, returns to login

### Cash-In (Design § 6.3)
- [ ] Phone lookup `+243990123456` → displays "Jean-Paul Kabila"
- [ ] Invalid phone → "Customer not found. Enroll first?"
- [ ] Amount FC 5,000 → fee preview shows (read from seed feeLimits)
- [ ] Limits shown: "Daily: 0 / 10,000,000" before first txn
- [ ] PIN `123456` → success
- [ ] PIN `000000` → "Invalid PIN"
- [ ] After cash-in: agent float decreases, customer wallet increases
- [ ] Receipt shows journal ID, timestamp, balances

### Cash-Out (Design § 6.4)
- [ ] Phone lookup works same as cash-in
- [ ] Customer balance insufficient → blocked before PIN, suggest lower amount
- [ ] Amount + fee deducted from customer, amount credited to agent
- [ ] Receipt generated

### Enroll Customer (Design § 6.5)
- [ ] Minimal form: First + Last + Phone → creates customer with CDF+USD wallets (0 balance)
- [ ] Email uniqueness: duplicate email → error "Email already registered"
- [ ] Success screen shows customer ID + wallet IDs
- [ ] Customer added to universe with `enrolledByAgentId: agent-001`

### History (Design § 6.6)
- [ ] Today's cash-in/out displayed, grouped by time descending
- [ ] Filter: Cash In only → hides cash-out
- [ ] Search by phone: `+243990` → shows matching txns
- [ ] Totals correct: "Cash In: FC 15,000 (3 txns)"
- [ ] Tap item → detail sheet with full info

### Cross-App Sync (Design § 6.7)
- [ ] Agent cash-in FC 5,000 to `cust_kasee` → customer app shows balance increase from FC 25K → FC 30K
- [ ] Enrollment by agent → customer can login with email/password in customer app

---

## Files to Modify

### New Files
- [ ] `apps/agent_mobile/lib/screens/agent_history_screen.dart`
- [ ] `apps/agent_mobile/lib/widgets/pin_input_modal.dart`
- [ ] `apps/agent_mobile/lib/widgets/customer_lookup_field.dart`
- [ ] `apps/agent_mobile/test_integration/cross_app_sync_test.dart`
- [ ] `apps/agent_mobile/test/navigation_test.dart`

### Enhanced Files
- [ ] `apps/agent_mobile/lib/screens/agent_login_screen.dart` — email/password, customer banner
- [ ] `apps/agent_mobile/lib/screens/agent_home_screen.dart` — agent status card, history button
- [ ] `apps/agent_mobile/lib/screens/cash_in_out_screen.dart` — lookup, fee, limits, PIN
- [ ] `apps/agent_mobile/lib/screens/enroll_customer_screen.dart` — ID fields, offline KYC
- [ ] `apps/agent_mobile/lib/services/offline_agent_repository.dart` — `getTodayUsage()`, `getTodayHistory()`, `getTodayEnrollments()`, `getFee()`, etc.
- [ ] `apps/agent_mobile/lib/services/agent_api_service.dart` — `login(email, password)`, email routing
- [ ] `packages/demo_universe/data/universe.json` — agent limits, fee configs

### Test Files
- [ ] `apps/agent_mobile/test/services/offline_agent_repository_test.dart` — limits, history, enrollments
- [ ] `apps/agent_mobile/test/screens/agent_login_screen_test.dart` — email routing, customer banner
- [ ] `apps/agent_mobile/test/screens/cash_in_out_screen_test.dart` — PIN flow, limits blocking

---

## Risks & Assumptions

### Risks
| Risk | Mitigation |
|------|------------|
| Shared universe mutations not synced | Enforce singleton `DemoUniverse.load()` once per session; verify via integration test (Task 7.2) |
| Hardcoded PIN `123456` leaks to production | Gate behind `--dart-define=OFFLINE_DEMO=true`; add assertion in PIN modal |
| Agent limits not enforced | UI blocks before PIN; unit tests verify (Task 4.10) |
| Fee calculation differs from live API | Document: "Fee preview is illustrative; live API may differ" |
| Customer APK shows agent login | Not applicable (separate APK); if merged future: route by email pattern |

### Assumptions
1. **Session-local only:** Mutations do not persist; app restart reloads seed
2. **No network:** All operations succeed instantly
3. **Single agent per session:** No multi-agent handoff
4. **PIN hardcoded:** All agents use `123456`
5. **Commissions not accrued:** `commissionBps` in seed but not calculated in P1
6. **Float top-up manual:** No auto-reload; future: top-up request UI
7. **No biometrics:** Email+password only; future: fingerprint
8. **Timezone UTC:** All timestamps UTC; no local conversion
9. **Language English:** No i18n in P1; future: French
10. **No camera KYC:** ID typed, not scanned; future: OCR

---

## Future Enhancements (Out of Scope P1)

1. Commission tracking: Display agent earnings per txn (read `commissionBps`)
2. Assisted bill pay: Agent pays SNEL/Vodacom on behalf of customer
3. Float top-up request: Agent submits request to supervisor
4. Multi-day history: Date picker, pagination
5. Biometrics: Fingerprint unlock
6. Customer-app agent tabs: Merge agent APK as tabs in customer app
7. French i18n: Localize all strings
8. ID card OCR: Camera-based ID scanning
9. Receipt sharing: SMS or email receipt to customer
10. Offline persistence: SQLite + sync on reconnect (hybrid mode)

---

**End of Implementation Plan**
