### Task A9: Favorites → multi-rail; retire legacy send-money primary paths

**Files:**
- Modify: `lib/screens/favorites_screen.dart`
- Modify: router — stop using `RouteNames.sendMoneyEnterDetails` as default from favorites/home
- Optional: hide or gate legacy `send_money_*` screens behind debug flag

**Interfaces:**
- Favorites “Send” opens `/payment/w2w` (or picker) with prefilled destination

- [ ] **Step 1:** Retarget favorite send to `/payment/*`.
- [ ] **Step 2:** Remove legacy CTAs from Home/Favorites; keep files but unused or debug-only.
- [ ] **Step 3:** Commit `refactor(customer): favorites use multi-rail payments`
