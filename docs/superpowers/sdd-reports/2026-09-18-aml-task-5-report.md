# SDD Report: Task 5 - Users Page View-for-All / Mutate ADMIN-Only

**Date:** 2026-09-18  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a`  
**Commit:** `153366b`

## 1. Current Code Findings

### Before Changes
- **File:** `apps/admin_web/app/dashboard/users/page.tsx`
- **Auth guard:** Redirected both unauthenticated users AND non-ADMIN staff to `/dashboard`
- **UI:** All mutate actions (create staff form, role select) visible to all authenticated users with ADMIN check
- **Problem:** Non-ADMIN staff roles (OPS, SUPPORT, FINANCE) could not view the Users list at all

### DEM-SCRIPT.md
- Users row labeled as `Users (ADMIN)` suggesting ADMIN-only access
- Missing entries for AML ban list and Customers directory pages

## 2. Minimal Implementation Plan

1. Change auth guard to redirect only unauthenticated users to `/login`
2. Add `currentUser` state and `isAdmin` derived boolean
3. Conditionally render create staff form only for ADMIN
4. Conditionally render role select (ADMIN) vs badge (non-ADMIN)
5. Add helper text for non-ADMIN users
6. Update DEM-SCRIPT.md with corrected labels and missing routes

## 3. Files Modified

1. `apps/admin_web/app/dashboard/users/page.tsx`
2. `docs/demo/DEM-SCRIPT.md`

## 4. Code Changes

### apps/admin_web/app/dashboard/users/page.tsx

**Auth Guard Changes:**
- Added `currentUser` state variable
- Derived `isAdmin = currentUser?.role === StaffRole.ADMIN`
- Changed redirect logic: only redirect if `!user` (unauthenticated)
- Removed role check that sent non-ADMIN to `/dashboard`
- Added `setCurrentUser(user)` before `loadStaff()`

**UI Changes:**
- Create staff button: wrapped in `{isAdmin && ...}` conditional
- Added helper text for non-ADMIN: `"View only — ask an ADMIN to create users or change roles."`
- Role column: ternary renders `<select>` if `isAdmin`, else `<span className="badge bg-secondary">{row.role}</span>`

### docs/demo/DEM-SCRIPT.md

**Admin URLs Table:**
- Updated Users row label from `Users (ADMIN)` to `Users (view all; create/role ADMIN)`
- Added row: `| — | /dashboard/aml-ban-list | AML ban list |`
- Added row: `| — | /dashboard/customers | Customers directory |`

## 5. Tests to Add/Update

**Manual acceptance criteria from brief:**

1. **Admin role:**
   - Login as `admin@postefinance.com`
   - Verify: can see Users list, create staff form, role select dropdowns

2. **Non-ADMIN role (e.g., SUPPORT):**
   - Login as `support@postefinance.com`
   - Verify: can see Users list
   - Verify: helper text visible: "View only — ask an ADMIN to create users or change roles."
   - Verify: no create staff form
   - Verify: role column shows badges, not selects
   - Verify: can still access Customers, AML ban list, other pages

3. **Unauthenticated:**
   - Verify: redirected to `/login`

## 6. Checklist Items Covered

- [x] Step 1: Changed auth guard to only redirect unauthenticated users
- [x] Step 1: Added `isAdmin = currentUser?.role === StaffRole.ADMIN`
- [x] Step 2: Show create staff form only if `isAdmin`
- [x] Step 2: Role column conditional: select for ADMIN, badge for others
- [x] Step 2: Helper text exact: "View only — ask an ADMIN to create users or change roles."
- [x] Step 3: Added two DEM-SCRIPT.md rows for ban list + customers
- [x] Step 3: Updated Users label from "(ADMIN)" to "(view all; create/role ADMIN)"
- [x] Step 5: Committed and pushed changes

## 7. Risks / Assumptions

### Risks
1. **State timing:** `currentUser` is set asynchronously; initial render may briefly show empty/incorrect UI
   - **Mitigation:** React re-renders after `setCurrentUser`, so final UI is correct
   
2. **No server-side validation:** API endpoints assume RBAC is enforced at API layer
   - **Assumption:** This is offline demo mode; production would have server-side guards

3. **Existing AML/Customers pages:** Not verified in this task whether those routes exist or need RBAC changes
   - **Constraint:** Task explicitly states "Do not change AML ban or customers pages"

### Assumptions
1. Existing `api.listStaff()`, `api.createStaff()`, `api.updateStaffRole()` handle RBAC server-side
2. Non-ADMIN roles should see read-only view (no delete, no password reset, etc.)
3. Helper text placement above Create button section is appropriate for UX
4. Badge styling (`bg-secondary`) is acceptable for read-only role display
5. DEM-SCRIPT.md routes `/dashboard/aml-ban-list` and `/dashboard/customers` already exist (or will be created in other tasks)

## 8. Implementation Notes

### Pattern Adherence
- **Followed existing auth pattern:** Used `authService.getCurrentUser()` and router redirect
- **Followed existing conditional rendering:** Used React conditional rendering with `&&` and ternary operators
- **Bootstrap classes:** Consistent with existing UI (badge, form-select, text-muted)
- **No new files:** Extended existing page component only

### RBAC Scope
- **Users page only:** This task touches only the Users list view
- **No expansion:** Did not add RBAC to other pages as per constraints
- **View-all, mutate-ADMIN:** Aligns with global-constraints.md requirement

### DEM-SCRIPT.md Maintenance
- Updated admin URLs table to reflect correct access patterns
- Added missing routes for completeness
- Maintained existing table structure and formatting

## 9. Next Steps (Out of Scope)

1. Verify AML ban list and Customers pages exist and have correct RBAC (separate task)
2. Add automated tests for RBAC on Users page (if test framework exists)
3. Consider loading state UI while `currentUser` is being fetched
4. Consider server-side route guards in addition to client-side UI guards

## 10. Summary

✅ **Completed Task 5:**
- All staff roles (ADMIN, OPS, SUPPORT, FINANCE) can now view Users list
- Only ADMIN can create staff or change roles
- Non-ADMIN users see helper text and read-only role badges
- DEM-SCRIPT.md updated with correct labels and missing routes
- Changes committed and pushed to `cursor/task1-monorepo-scaffold-1d8a`

**Commit message:** `feat(admin): allow all staff roles to view Users list`  
**Files changed:** 2 (users page + DEM-SCRIPT.md)  
**Lines changed:** +36 insertions, -19 deletions

---

## Fix Applied (Post-Review)

**Issue:** Create form conditional was `{showForm && (` instead of `{isAdmin && showForm && (`  
**Risk:** Non-ADMIN could potentially see form if `showForm` state got set inappropriately

**Changes:**
- Updated form conditional to `{isAdmin && showForm && (`
- Added early guard in `handleCreate`: `if (!isAdmin) return;`

**Commit:** `fix(admin): gate Users create form with isAdmin`
