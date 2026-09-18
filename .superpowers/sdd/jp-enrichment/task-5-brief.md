### Task 5: Fees & Limits propose UI on config page

**Files:**
- Modify: `apps/admin_web/app/dashboard/config/page.tsx`

- [ ] **Step 1: Fix list rendering** to store projection fields (`paymentType`, `feePercent`/`value`, `status`, limit minors)

- [ ] **Step 2: Propose fee form** → `api.proposeFeeRule` → message + link `/dashboard/approvals`

- [ ] **Step 3: Propose limit form** → `api.proposeLimitRule`

- [ ] **Step 4: Honesty** — `Offline demo — fee/limit changes are session-only until Reset demo`

- [ ] **Step 5: Manual path** propose → Approvals → Approve → ACTIVE

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(admin): Fees & Limits propose fee/limit for approval"
```

---
