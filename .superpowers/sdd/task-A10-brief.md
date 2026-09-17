### Task A10: Transaction detail + History vs new ledger

**Files:**
- Create: `lib/screens/transaction_detail_screen.dart`
- Modify: `lib/screens/transactions_history_screen.dart`, Home recent activity tap
- Use: `GET /v1/payments` and `GET /v1/payments/:id`

**Interfaces:**
- History lists mock payments; tap → detail (status, ids, amounts, rail)

- [ ] **Step 1:** Wire history to `CoreApiService.listPayments`.
- [ ] **Step 2:** Detail screen from payment id.
- [ ] **Step 3:** Commit `feat(customer): payment history and detail`
