### Task A8: Notifications center (mock)

**Files:**
- Create: `lib/screens/notifications_screen.dart`
- Modify: Home header bell → notifications
- API: in-memory `GET /v1/notifications` (+ seed on payment/KYC events) or client-local list fed after actions

**Interfaces:**
- Produces: Bell opens list of mock notifications (payment posted, KYC status)

- [ ] **Step 1:** Minimal notifications store + list UI.
- [ ] **Step 2:** Emit notification on payment success / KYC submit.
- [ ] **Step 3:** Commit `feat(customer): notifications center mock`
