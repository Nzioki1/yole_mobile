# Agent Assisted Bill Pay + Airtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement agent-assisted bill pay and airtime purchase in the offline `agent_mobile` mock. Agents can pay bills or buy airtime on behalf of customers using agent float. Customer pays agent in cash off-app; agent fronts payment from CDF float. Extends Home with "Pay for customer" quick action, History with Bill/Airtime filters, and surfaces transactions in receipt and detail sheets.

**Architecture:** Inside `OfflineAgentRepository`, add `payForCustomer()` that debits agent float by amount+fee, writes `AGENT_ASSISTED_BILL` or `AGENT_ASSISTED_AIRTIME` journal entries, and does NOT mutate customer wallets or accrue commissions. UI follows existing patterns from `cash_in_out_screen.dart` (customer lookup → amount/biller → fee preview → PIN → receipt).

**Tech Stack:** Flutter, `apps/agent_mobile`, `packages/demo_universe`, in-memory offline repository (no HTTP).

**Spec:** `docs/superpowers/specs/2026-09-21-poste-finance-agent-assisted-pay-design.md`

## Global Constraints

- Offline mock only (`--dart-define=OFFLINE_DEMO=true` path).
- Branch: `cursor/task1-monorepo-scaffold-1d8a` (current PR branch tip).
- Funding: Debit agent float CDF only; NEVER mutate customer wallet.
- NEVER call `_accrueCommission` for assisted pay (commission out of scope).
- Fee schema: `feePercent` / `minFeeMinor` / `maxFeeMinor` (NOT percentBps); reuse existing `getFee()` logic.
- Journal types: `AGENT_ASSISTED_BILL` / `AGENT_ASSISTED_AIRTIME`.
- Payment type fee keys: `AGENT_ASSISTED_BILL` / `AGENT_ASSISTED_AIRTIME` strings.
- PIN: hardcoded `123456` (consistent with cash-in/out).
- Customer lookup: reuse existing `CustomerLookupField` widget.
- Home: uses vertical ListTiles for quick actions (not 2×2 grid).
- Kinshasa billers: same 8 billers as customer app (SNEL, REGIDESO, Vodacom Congo, Airtel Congo, Orange RDC, Canal+ Congo, DGI, City of Kinshasa).
- History: add Bill and Airtime chip filters; show commission field as null (no commission on assisted pay).
- Commit after each task; run `flutter test` in `apps/agent_mobile`.

## File map

| File | Role |
|------|------|
| `packages/demo_universe/data/universe.json` | Add two `feeLimits` rows for `AGENT_ASSISTED_BILL` and `AGENT_ASSISTED_AIRTIME` |
| `apps/agent_mobile/lib/constants/kinshasa_billers.dart` | New: constant list of 8 Kinshasa billers with demo account numbers |
| `apps/agent_mobile/lib/services/offline_agent_repository.dart` | Add `payForCustomer()` method; extend history queries for bill/airtime |
| `apps/agent_mobile/lib/services/agent_api_service.dart` | Add offline wrapper `payForCustomer()` |
| `apps/agent_mobile/lib/screens/assisted_pay_screen.dart` | New: Pay for customer screen with Bill\|Airtime toggle, biller dropdown, fee preview, PIN, receipt |
| `apps/agent_mobile/lib/screens/agent_home_screen.dart` | Add "Pay for customer" ListTile quick action |
| `apps/agent_mobile/lib/screens/agent_history_screen.dart` | Add Bill/Airtime filter chips; list/detail for new journal types |
| `apps/agent_mobile/lib/main.dart` | Register `/assisted-pay` route |
| `apps/agent_mobile/test/offline_agent_repository_test.dart` | Unit tests for `payForCustomer()`: bill/airtime float debit, fee math, insufficient float, no wallet mutation, no commission |

---

### Task 1: Seed feeLimits + `payForCustomer()` + unit tests

**Files:**
- Modify: `packages/demo_universe/data/universe.json`
- Modify: `apps/agent_mobile/lib/services/offline_agent_repository.dart`
- Modify: `apps/agent_mobile/test/offline_agent_repository_test.dart`

**Interfaces:**
- Produces: `payForCustomer({customerId, kind: 'BILL'|'AIRTIME', amountMinor, billerCode?, accountNumber?, phoneNumber?})` → returns POSTED map with feeMinor, totalMinor, floatCdfMinorAfter, journalId

- [ ] **Step 1:** Add failing tests for bill path (debit float by amount+fee, write `AGENT_ASSISTED_BILL` journal with billerCode/accountNumber metadata, customer wallet unchanged, no commission row) and airtime path (write `AGENT_ASSISTED_AIRTIME` journal with phoneNumber, float debit, no commission). Test insufficient float exception with clear message showing Need/Have amounts. Test fee math min/percent/max clamps.
- [ ] **Step 2:** Run tests — expect fail
- [ ] **Step 3:** Add two `feeLimits` entries to `universe.json`: `feelim_agent_assist_bill_cdf` and `feelim_agent_assist_airtime_cdf` with `paymentType: AGENT_ASSISTED_BILL` / `AGENT_ASSISTED_AIRTIME`, `currency: CDF`, `feePercent: 0.5`, `minFeeMinor: 25`, `maxFeeMinor: 500000`
- [ ] **Step 4:** Implement `payForCustomer()` in `OfflineAgentRepository`: validate agent session, validate customer exists, calculate fee via `getFee(paymentType: AGENT_ASSISTED_BILL or AGENT_ASSISTED_AIRTIME)`, check sufficient `floatCdfMinor`, debit float by `amountMinor + feeMinor`, write journal with type `AGENT_ASSISTED_BILL` or `AGENT_ASSISTED_AIRTIME` and metadata `{customerId, customerName, billerCode?, accountNumber?, phoneNumber?}`, do NOT call `_accrueCommission`, do NOT touch customer wallets, return `{status: POSTED, journalId, amountMinor, feeMinor, totalMinor, floatCdfMinorAfter, kind, billerCode?, accountNumber?, phoneNumber?, postedAt}`
- [ ] **Step 5:** Run tests — expect pass
- [ ] **Step 6:** Commit `feat(agent): payForCustomer bill/airtime offline repository + tests`

---

### Task 2: `AgentApiService.payForCustomer()` offline branch

**Files:**
- Modify: `apps/agent_mobile/lib/services/agent_api_service.dart`

**Interfaces:**
- Consumes: `OfflineAgentRepository.payForCustomer()`
- Produces: `Future<Map<String, dynamic>> payForCustomer({customerId, kind, amountMinor, billerCode?, accountNumber?, phoneNumber?})`

- [ ] **Step 1:** Add offline `payForCustomer()` method routing to `OfflineAgentRepository.instance.payForCustomer()` when `_offlineDemo == true`; throw `UnimplementedError('Live API for assisted pay not implemented')` otherwise
- [ ] **Step 2:** Commit `feat(agent): AgentApiService.payForCustomer offline branch`

---

### Task 3: Kinshasa billers constant + assisted_pay_screen.dart

**Files:**
- Create: `apps/agent_mobile/lib/constants/kinshasa_billers.dart`
- Create: `apps/agent_mobile/lib/screens/assisted_pay_screen.dart`
- Modify: `apps/agent_mobile/lib/main.dart`

**Interfaces:**
- Produces: `/assisted-pay` route; single screen with Bill|Airtime segmented control; customer lookup → biller dropdown (bill) or phone input (airtime) → amount → fee preview (totalDebit, floatAfter) → PIN `123456` → receipt (customer name, biller/phone, amount, fee, float left, journal ref, timestamp)

- [ ] **Step 1:** Create `kinshasa_billers.dart` with constant list `kKinshasaBillers = [...]` (8 billers: SNEL_KINSHASA, REGIDESO_KINSHASA, VODACOM_CONGO, AIRTEL_CONGO, ORANGE_RDC, CANALPLUS_CONGO, DGI, CITY_KINSHASA), each with `{code, name, category, demoAccountNumber}`
- [ ] **Step 2:** Create `assisted_pay_screen.dart`: Scaffold with "Pay for Customer" AppBar, segmented button Bill|Airtime (default Bill), `CustomerLookupField` for customer lookup, bill mode shows dropdown of `kKinshasaBillers` + account number TextFormField (pre-fill from `demoAccountNumber`), airtime mode shows phone TextFormField (E.164 hint), amount TextFormField (CDF only), fee preview card showing "Transaction Fee: FC X.XX", "Total Debit: FC Y.YY", "Float After: FC Z.ZZ" (calculate via `_repo.getFee(paymentType: AGENT_ASSISTED_BILL or AGENT_ASSISTED_AIRTIME)` and `currentFloatCdfMinor - totalDebit`), block Continue button if insufficient float with red alert card "Insufficient float. Need FC X, have FC Y", on Continue tap show PIN modal via `showPinModal()` (from `pin_input_modal.dart`), on PIN success execute `_api.payForCustomer()`, show receipt dialog with customer name, biller code+account (bill) or phone topped up (airtime), amount, fee, float left, journal ref, timestamp, [Share Receipt] [Done] buttons (Done pops twice to return to Home)
- [ ] **Step 3:** Register route in `main.dart`: `'/assisted-pay': (context) => const AssistedPayScreen()`
- [ ] **Step 4:** Smoke test: verify no compile errors; defer device test until UI wired
- [ ] **Step 5:** Commit `feat(agent): assisted pay screen with bill/airtime toggle + fee preview`

---

### Task 4: Home "Pay for customer" quick action

**Files:**
- Modify: `apps/agent_mobile/lib/screens/agent_home_screen.dart`

- [ ] **Step 1:** Add new `Card(child: ListTile(...))` quick action after "History" tile: leading `Icon(Icons.receipt_long)`, title `'Pay for customer'`, trailing `Icon(Icons.arrow_forward_ios, size: 16)`, onTap `Navigator.pushNamed(context, '/assisted-pay')`
- [ ] **Step 2:** Commit `feat(agent): add Pay for customer quick action to Home`

---

### Task 5: History Bill/Airtime filters + list/detail

**Files:**
- Modify: `apps/agent_mobile/lib/screens/agent_history_screen.dart`
- Modify: `apps/agent_mobile/lib/services/offline_agent_repository.dart`

**Interfaces:**
- Enhances: `getTodayHistory()` to include `AGENT_ASSISTED_BILL` and `AGENT_ASSISTED_AIRTIME` journals; history screen adds Bill/Airtime chip filters, list rows, detail sheets

- [ ] **Step 1:** Extend `getTodayHistory()` in `OfflineAgentRepository` (already returns all agent journals; no code change required — journals with type `AGENT_ASSISTED_BILL` / `AGENT_ASSISTED_AIRTIME` will auto-appear). Update history screen `_filterItems()` to handle `BILL` / `AIRTIME` segment filters: map to journal types `AGENT_ASSISTED_BILL` / `AGENT_ASSISTED_AIRTIME`.
- [ ] **Step 2:** Add Bill and Airtime buttons to `SegmentedButton<String>` segments in `agent_history_screen.dart`: `ButtonSegment(value: 'BILL', label: Text('Bill'))`, `ButtonSegment(value: 'AIRTIME', label: Text('Airtime'))`
- [ ] **Step 3:** Update `_getTypeLabel()` switch to handle `AGENT_ASSISTED_BILL` → 'Bill Payment', `AGENT_ASSISTED_AIRTIME` → 'Airtime Purchase'
- [ ] **Step 4:** Update `_getTypeIcon()` switch: `AGENT_ASSISTED_BILL` → `Icons.receipt_long`, `AGENT_ASSISTED_AIRTIME` → `Icons.phone_android`
- [ ] **Step 5:** Update `_getTypeColor()` switch: both → `Colors.purple` (or `Colors.teal` for differentiation)
- [ ] **Step 6:** Extend `_buildCashOperationDetails()` to conditionally show biller/account (when `item['data']['metadata']['billerCode']` exists) or phone topped up (when `item['data']['metadata']['phoneNumber']` exists). Show commission as null (commission field won't exist for assisted pay journals).
- [ ] **Step 7:** Update list subtitle builder: for bill show `$symbol$amount • Biller`, for airtime show `$symbol$amount • Airtime`
- [ ] **Step 8:** Commit `feat(agent): History Bill/Airtime filters + list/detail`

---

### Task 6: Widget tests (assisted_pay_screen)

**Files:**
- Create: `apps/agent_mobile/test/screens/assisted_pay_screen_test.dart`

- [ ] **Step 1:** Write widget tests: toggle Bill ↔ Airtime resets form fields, customer lookup displays name, bill mode shows biller dropdown + account field, airtime mode shows phone field, fee preview updates on amount change, insufficient float shows alert, Continue button opens PIN modal, PIN `123456` → success receipt, PIN `000000` → error. Use `OfflineAgentRepository.createFresh()` and seed test data; pump `AssistedPayScreen` with `MaterialApp` wrapper.
- [ ] **Step 2:** Run `flutter test` in `apps/agent_mobile` — expect pass
- [ ] **Step 3:** Commit `test(agent): assisted pay screen widget tests`

---

## Done when

- Spec §5 acceptance criteria all met:
  - Home: "Pay for customer" tile navigates to AssistedPayScreen
  - Bill path: lookup Jean-Paul → select SNEL → enter account/amount → fee FC 0.25 (0.5% of FC 50) → PIN `123456` → receipt shows float debited FC 50.25, customer wallet unchanged, journal ref, no commission
  - Airtime path: lookup customer → enter phone/amount → fee FC 0.50 (0.5% of FC 100) → PIN → receipt shows float debited, journal type `AGENT_ASSISTED_AIRTIME`
  - History: Bill/Airtime chips filter journals; list rows show biller/phone; detail sheets show metadata + fee (commission null)
  - Errors: customer not found, insufficient float alert, invalid PIN, form validation
- Unit tests pass: `payForCustomer()` debits float, writes correct journal type/metadata, no wallet mutation, no commission, insufficient float throws, fee math min/max/percent
- `flutter test` in `apps/agent_mobile` passes
- All commits pushed to `cursor/task1-monorepo-scaffold-1d8a`
