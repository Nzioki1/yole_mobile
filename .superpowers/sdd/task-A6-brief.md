### Task A6: Quote taxes + full debit breakdown; shareable receipt

**Files:**
- Modify: `lib/screens/payment_quote_screen.dart`, `lib/screens/payment_result_screen.dart`
- Modify: payments quote response to include `taxMinor` / `totalDebitMinor` if not present (`services/core-api/.../payments.service.ts`)
- Optional: `share_plus` or web share for receipt text

**Interfaces:**
- Quote shows amount, fee, tax, total debit
- Result offers Share / Copy receipt (payment id, rail, amounts, timestamp)

- [ ] **Step 1:** Extend mock quote payload with tax (can be 0 or fixed %).
- [ ] **Step 2:** Update quote UI breakdown.
- [ ] **Step 3:** Result screen share/copy receipt.
- [ ] **Step 4:** Commit `feat(customer): tax breakdown and shareable receipt`
