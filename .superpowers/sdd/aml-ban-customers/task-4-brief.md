### Task 4: Customers directory page

**Files:**
- Create: `apps/admin_web/app/dashboard/customers/page.tsx`
- Verify: `apps/admin_web/app/dashboard/customer360/page.tsx` already uses `searchParams.get('customerId')` — if yes, only link; if broken, fix mount effect

- [ ] **Step 1: Customers page**

- `api.listCustomers()` in useEffect
- Table: ID | Name (first+last) | Email | Phone | Segment | KYC | Status | Action
- Action: Link `href={`/dashboard/customer360?customerId=${c.id}`}` label **Open 360**
- Never render password

- [ ] **Step 2: Verify 360 deep link**

Open `/dashboard/customer360?customerId=cust_kasee` — should auto-load. If not, fix the existing `useEffect` on `searchParams`.

- [ ] **Step 3: Commit**

```bash
git add apps/admin_web/app/dashboard/customers/page.tsx apps/admin_web/app/dashboard/customer360/page.tsx
git commit -m "feat(admin): customers directory with Customer 360 deep link"
```

---
