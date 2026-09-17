### Task A3: Transaction PIN on confirm (+ optional biometric stub)

**Files:**
- Create: `lib/widgets/pin_confirm_sheet.dart` (or `lib/screens/pin_confirm_screen.dart`)
- Modify: `lib/screens/payment_quote_screen.dart` (and fund/withdraw confirm)
- Modify: `lib/services/core_api_service.dart` / identity mocks if PIN set/verify endpoints needed
- Optional API: `POST /v1/auth/pin/set`, `POST /v1/auth/pin/verify` in-memory

**Interfaces:**
- Consumes: Confirm payment/fund/withdraw actions
- Produces: No debit without successful PIN (mock: 4–6 digit PIN stored hashed or plain in memory for demo)

- [ ] **Step 1:** Add mock PIN set on first use (profile or post-register prompt).
- [ ] **Step 2:** Gate Confirm behind PIN sheet; wrong PIN blocks API call.
- [ ] **Step 3:** Optional “Use device biometrics” button that succeeds in mock/Chrome stub.
- [ ] **Step 4:** Commit `feat(customer): PIN gate before payment confirm`
