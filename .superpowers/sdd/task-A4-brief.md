### Task A4: Pending / blocked balances on Home

**Files:**
- Modify: `lib/screens/home_screen.dart` (`_WalletCard` / pocket flattening)
- Optional: `services/core-api/.../wallets.service.ts` already exposes `blockedMinor`, `pendingOutMinor`, `pendingInMinor`

**Interfaces:**
- Consumes: `GET /v1/wallets/me` pocket fields
- Produces: Home shows Available + Pending (and Blocked if > 0)

- [ ] **Step 1:** Extend pocket display maps to include pending/blocked.
- [ ] **Step 2:** Update wallet card UI (secondary lines under available).
- [ ] **Step 3:** Commit `feat(customer): show pending/blocked wallet balances`
