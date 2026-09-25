### Task 3: AML ban list page

**Files:**
- Create: `apps/admin_web/app/dashboard/aml-ban-list/page.tsx`

- [ ] **Step 1: Build page** (Agents/Users Panel pattern)

- Honesty: `Offline demo — not a live sanctions feed`
- Load `api.listAmlBanList()` on mount
- Table: Name | ID/ref | Match | Reason | Source | Status | Added | Actions
- Status badge: BANNED → danger, LIFTED → secondary
- **+ Add to ban list** form: fullName, idRef, matchType select, reason, sourceList (default DEMO_SANCTIONS)
- **Lift** button when status === BANNED → `api.liftAmlBanEntry`
- Auth-after-mount not required for list data (API client-side only in useEffect)

- [ ] **Step 2: Manual check** `:3001/dashboard/aml-ban-list` returns 200; seeded rows visible

- [ ] **Step 3: Commit**

```bash
git add apps/admin_web/app/dashboard/aml-ban-list/page.tsx
git commit -m "feat(admin): AML ban list page with add and lift"
```

---
