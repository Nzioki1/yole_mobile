### Task A5: Limits on Profile (daily/monthly / KYC tier)

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Modify: `lib/services/core_api_service.dart`
- Use or add: `GET /v1/me/limits` or admin config limits filtered for customer; if missing, add thin mock endpoint returning KYC-tier defaults

**Interfaces:**
- Produces: Profile section “Limits” with daily/monthly remaining vs cap

- [ ] **Step 1:** Ensure mock limits endpoint exists (customer-readable).
- [ ] **Step 2:** Profile Limits card wired to API.
- [ ] **Step 3:** Commit `feat(customer): show KYC-tier limits on profile`
