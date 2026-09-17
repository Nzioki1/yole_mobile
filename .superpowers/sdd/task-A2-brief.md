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
