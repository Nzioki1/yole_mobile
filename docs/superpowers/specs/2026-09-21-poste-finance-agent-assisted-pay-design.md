# Poste Finance Agent Assisted Pay Design

**Date:** 2026-09-21  
**Status:** Approved (Approach A)  
**App:** `apps/agent_mobile` offline mock only  
**Depends on:** Agent mock P0 (login, home/float, cash-in/out, history, enroll)

## 1. Overview

Agents can now pay bills and purchase airtime on behalf of customers using agent float. The customer pays the agent in cash off-app; the agent fronts the payment from their CDF float. This extends Agent Home with a new "Pay for customer" flow that debits agent float, writes specialized journal entries, and displays assisted-pay transactions in History.

### 1.1 Approved Decisions

- **Approach A:** Single "Pay for customer" screen with Bill | Airtime toggle (not separate menu tiles)
- **Funding source:** Agent float (CDF only). Customer wallet is NOT debited. Narrative: customer hands agent cash → agent pays biller from float
- **Currencies:** CDF only for Phase 1 (USD assisted pay deferred)
- **Billers:** Kinshasa billers only (same 8 as customer bill pay: SNEL, REGIDESO, Vodacom Congo, Airtel Congo, Orange RDC, Canal+ Congo, DGI, City of Kinshasa)
- **Fees:** Accrued on agent (read from `feeLimits` with `paymentType: AGENT_ASSISTED_BILL` and `AGENT_ASSISTED_AIRTIME`); fee structure mirrors customer bill pay (e.g. 0.5% with min/max bounds)
- **Commission:** Out of scope for this pass; no commission accrual on assisted pays (future feature)
- **Customer lookup:** Reuse existing phone/ID lookup component from cash-in/out
- **PIN validation:** Hardcoded `123456` for all agent operations (consistent with cash flow)

### 1.2 Out of Scope

- Commission accrual on assisted bill pay / airtime
- Customer wallet debit (cash-backed only)
- USD assisted pay (CDF only)
- Insurance premium stacking or multi-biller bundles
- Receipt sharing polish (SMS/email to customer)
- Float top-up / EOD declaration / agent locator
- Live API integration (offline mock only)

## 2. Screens & User Flows

### 2.1 Agent Home

**Enhancement:** Add new quick action tile "Pay for customer" (sibling of Enroll / Cash In-Out / History).

**Note:** Agent Home uses vertical `ListTile` widgets for quick actions (not a 2×2 grid). The new "Pay for customer" tile follows the same pattern.

**Layout:**

```
┌────────────────────────────────────────┐
│  Quick Actions                         │
│  [Cash In]           [Cash Out]        │
│  [Enroll]            [History]         │
│  [Pay for customer]                    │
└────────────────────────────────────────┘
```

**Behavior:**
- Tap "Pay for customer" → navigate to `AssistedPayScreen()`
- Tile icon: bill/phone hybrid (suggest `Icons.receipt_long` or `Icons.payment`)

---

### 2.2 Assisted Pay Screen (New)

**Path:** `apps/agent_mobile/lib/screens/assisted_pay_screen.dart`

**Layout:**

```
┌────────────────────────────────────────┐
│ Pay for Customer             [< Back]  │
├────────────────────────────────────────┤
│ [Bill] [Airtime]                       │
│                                        │
│ Customer Phone or ID                   │
│ [+243990123456____________]            │
│ [Lookup] → displays: Jean-Paul Kabila  │
│                                        │
│ ─── Bill Mode ───────────────────────  │
│ Biller                                 │
│ [SNEL Kinshasa          ▼]            │
│                                        │
│ Account Number                         │
│ [12345678______________]               │
│ (Demo default for selected biller)     │
│                                        │
│ ─── Airtime Mode ────────────────────  │
│ Phone to Top Up                        │
│ [+243812345678_________]               │
│                                        │
│ ─── Common ──────────────────────────  │
│ Amount (CDF)                           │
│ [5000___] → FC 50.00                   │
│                                        │
│ Transaction Fee:    FC 0.25            │
│ Total Debit:        FC 50.25           │
│ Float After:        FC 4,999,949.75    │
│                                        │
│ [Continue]                             │
└────────────────────────────────────────┘
```

**Flow:**

**Step 1: Select Bill or Airtime**
- Segmented control at top (default: Bill)
- Switching resets form fields

**Step 2: Customer lookup**
- Reuse `CustomerLookupField` widget from cash-in/out
- Input: Phone number (E.164) or customer ID
- Lookup via `OfflineAgentRepository._findCustomer()`
- Display: Full name + status badge
- Error if not found: "Customer not found. Enroll first?"

**Step 3A: Bill mode inputs**
- **Biller dropdown:** Kinshasa billers (constant list in agent app, same 8 as customer app):
  - SNEL Kinshasa (electric)
  - REGIDESO Kinshasa (water)
  - Vodacom Congo (postpaid mobile)
  - Airtel Congo (postpaid)
  - Orange RDC (postpaid)
  - Canal+ Congo (TV)
  - DGI (taxes)
  - City of Kinshasa (municipal services)
- **Account number:** Text input; for demo, suggest defaults per biller (e.g. SNEL → `12345678`)
- **Amount (CDF):** Numeric input; validates > 0

**Step 3B: Airtime mode inputs**
- **Phone to top up:** E.164 format (can match or differ from customer's phone)
- **Amount (CDF):** Numeric input; validates > 0

**Step 4: Fee preview**
- Fetch fee via `OfflineAgentRepository.getFee(paymentType: AGENT_ASSISTED_BILL or AGENT_ASSISTED_AIRTIME, amountMinor: ...)`
- Display:
  - Transaction Fee: FC X.XX (suggest 0.5% with sensible min/max)
  - Total Debit: amount + fee
  - Float After: `currentFloatCdfMinor - (amount + fee)`
- Block if insufficient float: "Insufficient float. Need FC X, have FC Y"

**Step 5: PIN confirmation**
- Modal: "Confirm payment for [Customer Name]"
- 6-digit input (masked)
- Hardcoded validation: PIN must equal `123456`
- On success → execute payment
- On failure → "Invalid PIN" (3 attempts, then 60s cooldown)

**Step 6: Execute payment**

**Bill path:**
```dart
OfflineAgentRepository.payForCustomer(
  customerId: lookupResult.id,
  kind: 'BILL',
  amountMinor: (amount * 100).toInt(),
  billerCode: selectedBiller.code,
  accountNumber: accountNumberInput.text,
)
```

**Airtime path:**
```dart
OfflineAgentRepository.payForCustomer(
  customerId: lookupResult.id,
  kind: 'AIRTIME',
  amountMinor: (amount * 100).toInt(),
  phoneNumber: phoneToTopUpInput.text,
)
```

**Receipt screen:**

```
┌────────────────────────────────────────┐
│     ✓ Bill Payment Successful          │
│        (or Airtime Purchase)           │
├────────────────────────────────────────┤
│  For: Jean-Paul Kabila                 │
│  +243990123456                         │
│                                        │
│  ─── Bill ─────────────────────        │
│  Biller:        SNEL Kinshasa          │
│  Account:       12345678               │
│                                        │
│  ─── Airtime ──────────────────        │
│  Phone topped up: +243812345678        │
│                                        │
│  ─── Common ───────────────────        │
│  Amount:        FC 50.00               │
│  Fee:           FC 0.25                │
│  Total:         FC 50.25               │
│                                        │
│  Float left:    FC 4,999,949.75        │
│  Journal:       jnl_assistbill_s_17    │
│  Time:          2026-09-21 14:32 UTC   │
│                                        │
│  [Share Receipt]  [Done]               │
└────────────────────────────────────────┘
```

**Errors:**
- **Customer not found:** "Customer not found. Enroll first?" (before preview)
- **Amount ≤ 0:** Form validation; disable Continue button
- **Insufficient float:** "Insufficient float. Need FC {amount+fee}, have FC {currentFloat}" (before PIN modal)
- **Invalid PIN:** "Invalid PIN" (retry up to 3 times)
- **Empty biller/account (bill mode):** Form validation
- **Empty phone (airtime mode):** Form validation

---

### 2.3 Agent History Enhancements

**Existing:** `agent_history_screen.dart` shows AGENT_CASH_IN / AGENT_CASH_OUT / enrollments.

**Enhancements:**

**Filters:** Add **Bill** and **Airtime** chips alongside [All] [Cash In] [Cash Out] [Enroll]

```
┌────────────────────────────────────────┐
│ Today                                  │
│ [All] [Cash In] [Cash Out]             │
│ [Enroll] [Bill] [Airtime]              │
└────────────────────────────────────────┘
```

**List items:**

**Bill payment row:**
```
┌──────────────────────────────────┐
│ 14:32  Bill Payment              │
│ Jean-Paul Kabila  FC 50.00       │
│ SNEL • 12345678                  │
│ Ref: jnl_assistbill_s_17         │
└──────────────────────────────────┘
```

**Airtime purchase row:**
```
┌──────────────────────────────────┐
│ 15:12  Airtime Purchase          │
│ Jean-Paul Kabila  FC 100.00      │
│ Phone: +243812345678             │
│ Ref: jnl_assistair_s_23          │
└──────────────────────────────────┘
```

**Detail sheet (tap item):**

**Bill detail:**
```
Bill Payment Detail

Customer: Jean-Paul Kabila
Phone: +243990123456
ID: cust_kasee

Biller: SNEL Kinshasa
Account: 12345678

Amount: FC 50.00
Fee: FC 0.25
Total: FC 50.25
Currency: CDF

Agent float after: FC 4,999,949.75

Journal ID: jnl_assistbill_s_17
Posted: 2026-09-21T14:32:08Z

[Close]
```

**Airtime detail:**
```
Airtime Purchase Detail

Customer: Jean-Paul Kabila
Phone: +243990123456
ID: cust_kasee

Phone topped up: +243812345678

Amount: FC 100.00
Fee: FC 0.50
Total: FC 100.50
Currency: CDF

Agent float after: FC 4,999,849.25

Journal ID: jnl_assistair_s_23
Posted: 2026-09-21T15:12:41Z

[Close]
```

**Icons:**
- Bill: `Icons.receipt_long` or `Icons.description`
- Airtime: `Icons.phone_android` or `Icons.smartphone`

---

### 2.4 Agent Home Float Refresh

**After successful payment:** Pull-to-refresh or auto-refresh agent float balances to reflect debit.

**Implementation note:** `AssistedPayScreen.onSuccess()` should call `setState()` on parent Home or use state management (Provider / Riverpod) to refresh float card.

---

## 3. Data Model & Architecture

### 3.1 Billers (Constant in Agent App)

**Path:** `apps/agent_mobile/lib/constants/kinshasa_billers.dart`

```dart
const kKinshasaBillers = [
  {
    'code': 'SNEL_KINSHASA',
    'name': 'SNEL Kinshasa',
    'category': 'ELECTRIC',
    'demoAccountNumber': '12345678',
  },
  {
    'code': 'REGIDESO_KINSHASA',
    'name': 'REGIDESO Kinshasa',
    'category': 'WATER',
    'demoAccountNumber': '87654321',
  },
  {
    'code': 'VODACOM_CONGO',
    'name': 'Vodacom Congo',
    'category': 'MOBILE_POSTPAID',
    'demoAccountNumber': '243990111222',
  },
  {
    'code': 'AIRTEL_CONGO',
    'name': 'Airtel Congo',
    'category': 'MOBILE_POSTPAID',
    'demoAccountNumber': '243810333444',
  },
  {
    'code': 'ORANGE_RDC',
    'name': 'Orange RDC',
    'category': 'MOBILE_POSTPAID',
    'demoAccountNumber': '243820555666',
  },
  {
    'code': 'CANALPLUS_CONGO',
    'name': 'Canal+ Congo',
    'category': 'TV',
    'demoAccountNumber': 'CAN123456',
  },
  {
    'code': 'DGI',
    'name': 'DGI',
    'category': 'TAX',
    'demoAccountNumber': 'TAX987654',
  },
  {
    'code': 'CITY_KINSHASA',
    'name': 'City of Kinshasa',
    'category': 'MUNICIPAL',
    'demoAccountNumber': 'MUN456789',
  },
];
```

**Note:** Billers are NOT required as universe.json records for agent-assisted pay (constant list is sufficient for offline mock). Customer bill pay may still reference universe billers if already implemented; agent app reuses the same list for consistency.

---

### 3.2 Fee Limits (Seed Enhancement)

**Path:** `packages/demo_universe/data/universe.json`

Add to `feeLimits` array:

```json
{
  "id": "feelim_agent_assist_bill_cdf",
  "kind": "FEE",
  "paymentType": "AGENT_ASSISTED_BILL",
  "currency": "CDF",
  "status": "ACTIVE",
  "feePercent": 0.5,
  "minFeeMinor": 25,
  "maxFeeMinor": 500000,
  "createdAt": "2026-09-21T00:00:00Z"
},
{
  "id": "feelim_agent_assist_airtime_cdf",
  "kind": "FEE",
  "paymentType": "AGENT_ASSISTED_AIRTIME",
  "currency": "CDF",
  "status": "ACTIVE",
  "feePercent": 0.5,
  "minFeeMinor": 25,
  "maxFeeMinor": 500000,
  "createdAt": "2026-09-21T00:00:00Z"
}
```

**Fee math:** `rawFee = (amountMinor * feePercent / 100).toInt()`, then `feeMinor = max(minFeeMinor, min(maxFeeMinor, rawFee))`

**Example:**
- Amount: FC 50.00 (5000 minor)
- 0.5%: `(5000 * 0.5 / 100).toInt() = 25 minor = FC 0.25`
- Clamped: `max(25, min(500000, 25)) = 25`
- Result: FC 0.25 fee

**Dart universe regeneration:** If `packages/demo_universe` requires typed Dart generation, run `dart run build_runner build` after adding to `universe.json`. If repo uses dynamic access (`_list('feeLimits')`), regeneration not required (preferred for parity with other seed additions).

---

### 3.3 OfflineAgentRepository.payForCustomer()

**Method signature:**

```dart
Future<Map<String, dynamic>> payForCustomer({
  required String customerId,
  required String kind, // 'BILL' or 'AIRTIME'
  required int amountMinor,
  String? billerCode,
  String? accountNumber,
  String? phoneNumber,
}) async {
  // Implementation below
}
```

**Logic:**

1. **Validate agent session**
   ```dart
   final agentId = _currentAgentId;
   if (agentId == null) throw Exception('Agent not logged in');
   ```

2. **Validate customer exists**
   ```dart
   final customer = _findById('customers', customerId);
   if (customer == null) throw Exception('Customer not found');
   ```

3. **Calculate fee**
   ```dart
   final paymentType = kind == 'BILL' 
       ? 'AGENT_ASSISTED_BILL' 
       : 'AGENT_ASSISTED_AIRTIME';
   final fee = getFee(
     paymentType: paymentType,
     currency: 'CDF',
     amountMinor: amountMinor,
   );
   final totalDebit = amountMinor + fee['feeMinor'];
   ```

4. **Validate sufficient float**
   ```dart
   final agent = _findById('agents', agentId);
   final floatCdfMinor = _int(agent['floatCdfMinor']);
   if (floatCdfMinor < totalDebit) {
     throw Exception(
       'Insufficient float. Need FC ${_formatMinor(totalDebit)}, '
       'have FC ${_formatMinor(floatCdfMinor)}'
     );
   }
   ```

5. **Debit agent float**
   ```dart
   agent['floatCdfMinor'] = floatCdfMinor - totalDebit;
   ```

6. **Write journal entry**
   ```dart
   final journalType = kind == 'BILL' 
       ? 'AGENT_ASSISTED_BILL' 
       : 'AGENT_ASSISTED_AIRTIME';
   
   final metadata = <String, dynamic>{
     'customerId': customerId,
     'customerName': '${customer['firstName']} ${customer['lastName']}',
   };
   
   if (kind == 'BILL') {
     metadata['billerCode'] = billerCode;
     metadata['accountNumber'] = accountNumber;
   } else {
     metadata['phoneNumber'] = phoneNumber;
   }
   
   final journal = {
     'id': _nextId('jnl_assist${kind.toLowerCase()}_sess'),
     'type': journalType,
     'agentId': agentId,
     'customerId': customerId,
     'currency': 'CDF',
     'amountMinor': amountMinor,
     'feeMinor': fee['feeMinor'],
     'metadata': metadata,
     'postedAt': DateTime.now().toUtc().toIso8601String(),
     'refId': _nextId('ref_assist${kind.toLowerCase()}'),
   };
   
   _list('journals').add(journal);
   ```

7. **Do NOT mutate customer wallets** (customer paid agent in cash off-app; wallet not involved)

8. **Do NOT call _accrueCommission** (commission on assisted pay out of scope)

9. **Return success response**
   ```dart
   return {
     'status': 'POSTED',
     'journalId': journal['id'],
     'refId': journal['refId'],
     'amountMinor': amountMinor,
     'feeMinor': fee['feeMinor'],
     'totalMinor': totalDebit,
     'floatCdfMinorAfter': agent['floatCdfMinor'],
     'postedAt': journal['postedAt'],
     'kind': kind,
     'billerCode': billerCode,
     'accountNumber': accountNumber,
     'phoneNumber': phoneNumber,
   };
   ```

**Errors:**
- `Exception('Agent not logged in')` → UI should never hit (require session)
- `Exception('Customer not found')` → show "Customer not found. Enroll first?"
- `Exception('Insufficient float. Need FC X, have FC Y')` → show alert before PIN modal
- `Exception('Invalid PIN')` → handled by PIN modal widget (separate validation)

---

### 3.4 AgentApiService Offline Branch

**Path:** `apps/agent_mobile/lib/services/agent_api_service.dart`

**Add method:**

```dart
Future<Map<String, dynamic>> payForCustomer({
  required String customerId,
  required String kind,
  required int amountMinor,
  String? billerCode,
  String? accountNumber,
  String? phoneNumber,
}) async {
  if (_offlineDemo) {
    return OfflineAgentRepository.instance.payForCustomer(
      customerId: customerId,
      kind: kind,
      amountMinor: amountMinor,
      billerCode: billerCode,
      accountNumber: accountNumber,
      phoneNumber: phoneNumber,
    );
  } else {
    // Future: POST /api/agent/assisted-pay
    throw UnimplementedError('Live API for assisted pay not implemented');
  }
}
```

---

### 3.5 History Query Enhancements

**OfflineAgentRepository method:**

```dart
List<Map<String, dynamic>> getTodayHistory({
  String? agentId,
  String? typeFilter, // 'BILL' | 'AIRTIME' | 'CASH_IN' | 'CASH_OUT' | null (all)
}) {
  final aid = agentId ?? _requireAgent();
  final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
  
  final journals = _list('journals')
      .where((j) =>
          j['agentId'] == aid &&
          j['postedAt']?.startsWith(today) == true)
      .toList();
  
  if (typeFilter != null) {
    final journalType = typeFilter == 'BILL' 
        ? 'AGENT_ASSISTED_BILL'
        : typeFilter == 'AIRTIME'
            ? 'AGENT_ASSISTED_AIRTIME'
            : 'AGENT_$typeFilter'; // CASH_IN → AGENT_CASH_IN
    
    return journals.where((j) => j['type'] == journalType).toList();
  }
  
  return journals;
}
```

**UI History screen:**
- Filter chips: All | Cash In | Cash Out | Enroll | **Bill** | **Airtime**
- Tap Bill → `getTodayHistory(typeFilter: 'BILL')`
- Tap Airtime → `getTodayHistory(typeFilter: 'AIRTIME')`

---

## 4. Tests

### 4.1 Unit Tests

**Path:** `apps/agent_mobile/test/offline_agent_repository_test.dart`

**Test suite: Assisted Bill Pay**

```dart
group('payForCustomer - Bill', () {
  test('debits agent float by amount + fee', () async {
    // Setup: agent-001 has FC 5M float
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    final initialFloat = repo._findById('agents', 'agent-001')['floatCdfMinor'];
    
    // Execute: pay FC 50 bill
    final result = await repo.payForCustomer(
      customerId: 'cust_kasee',
      kind: 'BILL',
      amountMinor: 5000, // FC 50.00
      billerCode: 'SNEL_KINSHASA',
      accountNumber: '12345678',
    );
    
    final finalFloat = repo._findById('agents', 'agent-001')['floatCdfMinor'];
    
    expect(result['status'], 'POSTED');
    expect(finalFloat, lessThan(initialFloat));
    expect(initialFloat - finalFloat, equals(5000 + result['feeMinor']));
  });
  
  test('throws on insufficient float', () async {
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    // Drain float to near-zero
    final agent = repo._findById('agents', 'agent-001');
    agent['floatCdfMinor'] = 100; // FC 1.00
    
    expect(
      () => repo.payForCustomer(
        customerId: 'cust_kasee',
        kind: 'BILL',
        amountMinor: 5000,
        billerCode: 'SNEL_KINSHASA',
        accountNumber: '12345678',
      ),
      throwsA(isA<Exception>()),
    );
  });
  
  test('writes AGENT_ASSISTED_BILL journal with metadata', () async {
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    final result = await repo.payForCustomer(
      customerId: 'cust_kasee',
      kind: 'BILL',
      amountMinor: 5000,
      billerCode: 'SNEL_KINSHASA',
      accountNumber: '12345678',
    );
    
    final journal = repo._findById('journals', result['journalId']);
    
    expect(journal['type'], 'AGENT_ASSISTED_BILL');
    expect(journal['agentId'], 'agent-001');
    expect(journal['customerId'], 'cust_kasee');
    expect(journal['currency'], 'CDF');
    expect(journal['amountMinor'], 5000);
    expect(journal['metadata']['billerCode'], 'SNEL_KINSHASA');
    expect(journal['metadata']['accountNumber'], '12345678');
  });
  
  test('does not mutate customer wallet', () async {
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    final customer = repo._findById('customers', 'cust_kasee');
    final wallet = repo._list('wallets').firstWhere(
      (w) => w['customerId'] == 'cust_kasee' && w['currency'] == 'CDF',
    );
    final initialBalance = wallet['availableMinor'];
    
    await repo.payForCustomer(
      customerId: 'cust_kasee',
      kind: 'BILL',
      amountMinor: 5000,
      billerCode: 'SNEL_KINSHASA',
      accountNumber: '12345678',
    );
    
    final finalBalance = wallet['availableMinor'];
    
    expect(finalBalance, equals(initialBalance)); // Wallet unchanged
  });
  
  test('does not accrue commission', () async {
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    final initialCommissions = repo._list('agentCommissions').length;
    
    await repo.payForCustomer(
      customerId: 'cust_kasee',
      kind: 'BILL',
      amountMinor: 5000,
      billerCode: 'SNEL_KINSHASA',
      accountNumber: '12345678',
    );
    
    final finalCommissions = repo._list('agentCommissions').length;
    
    expect(finalCommissions, equals(initialCommissions)); // No commission row
  });
});
```

**Test suite: Assisted Airtime**

```dart
group('payForCustomer - Airtime', () {
  test('debits agent float and writes AGENT_ASSISTED_AIRTIME journal', () async {
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    final initialFloat = repo._findById('agents', 'agent-001')['floatCdfMinor'];
    
    final result = await repo.payForCustomer(
      customerId: 'cust_kasee',
      kind: 'AIRTIME',
      amountMinor: 10000, // FC 100.00
      phoneNumber: '+243812345678',
    );
    
    expect(result['status'], 'POSTED');
    expect(result['kind'], 'AIRTIME');
    
    final journal = repo._findById('journals', result['journalId']);
    expect(journal['type'], 'AGENT_ASSISTED_AIRTIME');
    expect(journal['metadata']['phoneNumber'], '+243812345678');
    
    final finalFloat = repo._findById('agents', 'agent-001')['floatCdfMinor'];
    expect(finalFloat, lessThan(initialFloat));
  });
  
  test('throws on customer not found', () async {
    final repo = OfflineAgentRepository.createFresh();
    await repo.login(agentId: 'agent-001');
    
    expect(
      () => repo.payForCustomer(
        customerId: 'cust_nonexistent',
        kind: 'AIRTIME',
        amountMinor: 10000,
        phoneNumber: '+243812345678',
      ),
      throwsA(isA<Exception>()),
    );
  });
});
```

**Test suite: Fee Math**

```dart
group('getFee - Assisted Pay', () {
  test('calculates 0.5% fee with min/max bounds for AGENT_ASSISTED_BILL', () async {
    final repo = OfflineAgentRepository.createFresh();
    
    // Small amount → min fee
    final feeSmall = repo.getFee(
      paymentType: 'AGENT_ASSISTED_BILL',
      currency: 'CDF',
      amountMinor: 100, // FC 1.00
    );
    expect(feeSmall['feeMinor'], 25); // Min FC 0.25
    
    // Medium amount → percentage
    final feeMedium = repo.getFee(
      paymentType: 'AGENT_ASSISTED_BILL',
      currency: 'CDF',
      amountMinor: 10000, // FC 100.00
    );
    expect(feeMedium['feeMinor'], 50); // 0.5% = FC 0.50
    
    // Large amount → max fee
    final feeLarge = repo.getFee(
      paymentType: 'AGENT_ASSISTED_BILL',
      currency: 'CDF',
      amountMinor: 500000000, // FC 5,000,000
    );
    expect(feeLarge['feeMinor'], 500000); // Max FC 5,000
  });
});
```

---

### 4.2 Widget Tests

**Path:** `apps/agent_mobile/test/screens/assisted_pay_screen_test.dart`

**Test cases:**
- [ ] Switching Bill ↔ Airtime resets form fields
- [ ] Customer lookup displays name on success
- [ ] Bill mode: biller dropdown + account number visible
- [ ] Airtime mode: phone input visible
- [ ] Fee preview updates when amount changes
- [ ] Insufficient float blocks Continue button
- [ ] PIN modal appears on Continue tap
- [ ] PIN `123456` → success, PIN `000000` → error
- [ ] Receipt screen shows correct journal ID + balances

---

## 5. Acceptance Criteria

### 5.1 Agent Home
- [ ] "Pay for customer" quick action tile navigates to `AssistedPayScreen`

### 5.2 Assisted Pay - Bill Path
- [ ] Toggle Bill | Airtime; Bill mode shows biller dropdown + account number
- [ ] Customer lookup (phone `+243990123456`) → displays "Jean-Paul Kabila"
- [ ] Select SNEL Kinshasa biller, enter account `12345678`, amount FC 50.00
- [ ] Fee preview shows FC 0.25 fee (0.5% of FC 50), total FC 50.25
- [ ] Float after preview: current float - FC 50.25
- [ ] PIN `123456` → success; PIN `000000` → error
- [ ] After success: agent float decreases by FC 50.25; customer wallet unchanged
- [ ] Receipt shows: customer name, SNEL, account, amount, fee, float left, journal ref, timestamp

### 5.3 Assisted Pay - Airtime Path
- [ ] Toggle to Airtime mode; phone input appears
- [ ] Enter customer `cust_kasee`, phone `+243812345678`, amount FC 100.00
- [ ] Fee preview shows FC 0.50 fee, total FC 100.50
- [ ] PIN validation same as bill path
- [ ] After success: agent float decreases; journal type `AGENT_ASSISTED_AIRTIME` written
- [ ] Receipt shows: customer name, phone topped up, amount, fee, float left, journal ref

### 5.4 History
- [ ] Today's list includes bill pay and airtime rows (icons differ from cash-in/out)
- [ ] Filter "Bill" → shows only AGENT_ASSISTED_BILL journals
- [ ] Filter "Airtime" → shows only AGENT_ASSISTED_AIRTIME journals
- [ ] Tap bill row → detail sheet with biller code, account, fee
- [ ] Tap airtime row → detail sheet with phone number, fee

### 5.5 Errors
- [ ] Customer not found → "Customer not found. Enroll first?"
- [ ] Amount ≤ 0 → form validation; Continue button disabled
- [ ] Insufficient float → alert before PIN: "Insufficient float. Need FC X, have FC Y"
- [ ] Empty biller or account in bill mode → form validation
- [ ] Empty phone in airtime mode → form validation

### 5.6 Unit Tests
- [ ] `payForCustomer` bill path debits float by amount + fee
- [ ] `payForCustomer` airtime path writes AGENT_ASSISTED_AIRTIME journal
- [ ] Insufficient float throws clear exception
- [ ] Customer wallet NOT mutated (balance unchanged)
- [ ] No commission row created (`agentCommissions` count unchanged)
- [ ] Fee math tests pass (min/max bounds, 0.5% percentage)

---

## 6. Files to Modify

### 6.1 New Files
- `apps/agent_mobile/lib/screens/assisted_pay_screen.dart` — Pay for customer screen with Bill | Airtime toggle
- `apps/agent_mobile/lib/constants/kinshasa_billers.dart` — Biller constant list (8 Kinshasa billers)
- `apps/agent_mobile/lib/widgets/customer_lookup_field.dart` — Reusable customer lookup widget (if not already extracted from cash-in/out)
- `apps/agent_mobile/test/screens/assisted_pay_screen_test.dart` — Widget tests

### 6.2 Enhanced Files
- `apps/agent_mobile/lib/screens/agent_home_screen.dart` — Add "Pay for customer" quick action tile
- `apps/agent_mobile/lib/screens/agent_history_screen.dart` — Add Bill / Airtime filters; list / detail for new journal types
- `apps/agent_mobile/lib/services/offline_agent_repository.dart` — Add `payForCustomer()` method, history filter enhancements
- `apps/agent_mobile/lib/services/agent_api_service.dart` — Add `payForCustomer()` offline branch (online `UnimplementedError`)
- `packages/demo_universe/data/universe.json` — Add two `feeLimits` records for `AGENT_ASSISTED_BILL` and `AGENT_ASSISTED_AIRTIME`
- `apps/agent_mobile/test/offline_agent_repository_test.dart` — Extend with assisted pay test suites

### 6.3 Optional Dart Universe Regeneration
- `packages/demo_universe/dart/` — If package uses typed generation, run `dart run build_runner build` after `universe.json` changes
- If dynamic access pattern (`_list('feeLimits')`) is used, regeneration not required (preferred)

---

## 7. Implementation Notes

### 7.1 Biller List Reuse
- Customer app may already have a biller list in `OfflineDemoRepository` or `universe.json`
- Agent app duplicates this as a constant for offline simplicity (no cross-app import)
- Future: unify biller list in shared package if customer + agent apps both grow biller features

### 7.2 Commission Deferral
- `commissionBps` already exists on agent seed (from commission tracking design)
- This pass does NOT accrue commission on assisted pay (commission logic already complex; add later)
- If commission on assisted pay is desired, extend `_accrueCommission()` to accept `type` parameter and call from `payForCustomer()`

### 7.3 USD Assisted Pay
- Phase 1: CDF only
- Phase 2: add USD; requires separate fee limits for `AGENT_ASSISTED_BILL_USD` / `AGENT_ASSISTED_AIRTIME_USD`
- Architecture supports it (currency parameter already in `payForCustomer()`)

### 7.4 Branding
- Reuse Poste Finance teal + existing agent app theme
- No new demo banners; "Pay for customer" tile follows existing quick action style

### 7.5 French i18n
- Deferred (consistent with agent mock P0 deferral)

---

## 8. Risks & Assumptions

### 8.1 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Biller list mismatches customer app | Medium — demo inconsistency | Copy exact list from customer app; document single source of truth in implementation |
| Fee preview math differs from customer bill pay | Low — demo accuracy | Reuse `getFee()` pattern; unit test coverage ensures consistency |
| Insufficient float not blocked early | High — poor UX | Validate before PIN modal; show clear alert with current/needed amounts |
| Customer wallet accidentally debited | High — breaks narrative | Explicit test: "customer wallet unchanged"; code review enforcement |
| Commission accidentally accrued | Medium — scope creep | Explicit test: "no commission row"; comment in code why `_accrueCommission` NOT called |

### 8.2 Assumptions

1. **Cash-backed only:** Customer hands agent physical cash → agent fronts from float. Customer wallet NOT involved.
2. **CDF only:** USD assisted pay deferred to future phase.
3. **No receipt polish:** SMS/email sharing to customer out of scope (receipt screen only).
4. **Same PIN:** Agent PIN `123456` applies to all operations (consistent with cash-in/out).
5. **Offline-only:** No live API; all operations via `OfflineAgentRepository`.
6. **Session-local:** Mutations do not persist across app restarts.
7. **Kinshasa billers only:** No rural or provincial biller expansion in Phase 1.
8. **No insurance stacking:** Single bill payment only; no multi-premium bundles.
9. **Fee structure mirrors customer:** 0.5% with min/max bounds (suggest FC 0.25 min, FC 5,000 max); adjust in seed if needed.
10. **Float top-up out of scope:** Agent cannot request float top-up via app (future supervisor UI feature).

---

## 9. Future Enhancements (Out of Scope)

1. **Commission on assisted pay:** Accrue agent earnings for bill/airtime operations
2. **USD assisted pay:** Add USD fee limits + currency selector
3. **Customer wallet debit option:** Toggle between cash-backed (float) and wallet-backed (customer balance)
4. **Receipt sharing:** SMS or email receipt to customer after payment
5. **Multi-biller bundles:** Pay multiple bills in one transaction (e.g. electric + water)
6. **Provincial billers:** Expand beyond Kinshasa to Goma, Lubumbashi, etc.
7. **Insurance premium stacking:** Pay multiple SONAS premiums in one assisted pay
8. **Float top-up request:** Agent submits request to supervisor via app
9. **Assisted pay limits:** Separate daily/per-txn limits for bill/airtime (currently uses same limits as cash)
10. **Bill validation:** Real-time biller API check for account existence (offline mock assumes all accounts valid)

---

**End of Design Document**
