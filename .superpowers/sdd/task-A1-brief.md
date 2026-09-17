### Task A1: Fund wallet (Add money) — MNO-in / bank-in mocks

**Files:**
- Create: `lib/screens/fund_wallet_screen.dart`
- Modify: `lib/screens/home_screen.dart` (Add money CTA)
- Modify: `lib/app_router.dart`, `lib/router_types.dart`
- Modify: `lib/services/core_api_service.dart` (if inbound rails missing, add quote/confirm helpers)
- Modify / Create: `services/core-api/src/modules/payments/*` only if `MNO_IN` / `BANK_IN` (or equivalent) not already supported

**Interfaces:**
- Consumes: JWT via `CoreApiService`; payment quote/confirm pattern already used by outbound rails
- Produces: Customer can credit CDF/USD wallet via mock inbound rail; home refresh shows new available balance

- [ ] **Step 1:** Confirm whether payments service already accepts inbound types; if not, add mock inbound quote/confirm that credits `CUST_WALLET` from a mock rail liability account (ledger-balanced).
- [ ] **Step 2:** Add `FundWalletScreen` — pick rail (MNO / Bank), amount, currency, mock source fields → quote → confirm → result.
- [ ] **Step 3:** Wire Home “Add money” / fund CTA to `/fund`.
- [ ] **Step 4:** Manual test: register → fund $50 USD → wallets/me shows availableMinor increased.
- [ ] **Step 5:** Commit `feat(customer): fund wallet MNO/bank mock inbound`
