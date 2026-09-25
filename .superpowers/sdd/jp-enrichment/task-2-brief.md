### Task 2: Store — employer employee projection + salary history (TDD)

**Files:**
- Modify: `apps/admin_web/lib/offline/store.ts`
- Modify: `apps/admin_web/lib/api.ts`
- Modify: `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts`

**Interfaces:**
- Produces:
  - `listEmployers()` employees with `employeeId`, `customerId?`, `employeeNumber`, `displayName`, `jobTitle`, `grossSalaryCdfMinor`, `netSalaryCdfMinor`, `eligibleAdvanceMaxCdfMinor`, `status`, plus `salaryMinor`/`currency` aliases for import/credit compatibility
  - `listSalaryHistory(employerId: string)` rows with `displayName`

- [ ] **Step 1: Extend failing tests** for `displayName` on Amina row and `listSalaryHistory('emp_poste')` length >= 3

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement projection in `listEmployers`** and `listSalaryHistory`

- [ ] **Step 4: API wrapper `listSalaryHistory`**

- [ ] **Step 5: Tests PASS → Commit**

```bash
git commit -m "feat(admin): project payroll employees and salary history for offline store"
```

---
