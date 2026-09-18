# Task 2 Implementation Report: API + RBAC + Navigation

**Date:** 2026-09-18
**Task:** AML Ban List & Customers Directory - Phase 2 (API + RBAC + Navigation)
**Commit:** 186be3e - "feat(admin): RBAC and nav for AML ban list and customers directory"
**Branch:** cursor/task1-monorepo-scaffold-1d8a

---

## What Changed

Implemented the API wrappers, RBAC routes, sidebar navigation, and layout titles for the AML ban list and customers directory features. This builds upon Task 1's `OfflineDemoStore` implementation.

### 1. API Layer (`apps/admin_web/lib/api.ts`)

Added four offline-only API methods following the existing pattern:

- `listAmlBanList()` - retrieves all AML ban entries
- `addAmlBanEntry(data)` - adds a new ban entry  
- `liftAmlBanEntry(id)` - removes/lifts a ban entry
- `listCustomers()` - retrieves all customers for directory view

All methods throw an error if not in `OFFLINE_DEMO` mode, consistent with similar methods like `listStaff()` and `proposeFeeRule()`.

### 2. RBAC Configuration (`apps/admin_web/lib/rbac.ts`)

Extended role-based access control:

**ModuleRoute union extended:**
- Added `/dashboard/aml-ban-list`
- Added `/dashboard/customers`

**Route permissions updated:**
- **ADMIN:** Both new routes added to `ALL_ADMIN`
- **OPS:** Added `aml-ban-list`, `customers`, `users`, and `customer360` 
- **SUPPORT:** Added `aml-ban-list`, `customers`, `users` (plus existing `kyc`, `agents`, `remittance`)
- **FINANCE:** Added `aml-ban-list`, `customers`, `users`, and `customer360`

This ensures all four roles (ADMIN, OPS, SUPPORT, FINANCE) can access both new features, and fixes gaps where OPS/FINANCE couldn't access customer360 (needed for "Open 360" links).

### 3. Sidebar Navigation (`apps/admin_web/components/sidebar/Sidebar.tsx`)

**Customers group:**
- Added "Customers" link (icon: `fa-address-book`) before "Customer 360"
- Maintains logical flow: directory → individual → queue → agents

**Operations group:**
- Added "AML ban list" link (icon: `fa-ban`) between "Cases" and "Resilience"
- Placed near Cases as both are compliance/operations tools

### 4. Layout Titles (`apps/admin_web/app/dashboard/layout.tsx`)

Added page title mappings:
- `/dashboard/customers`: "Customers"
- `/dashboard/aml-ban-list`: "AML Ban List"

---

## Files Modified

1. `apps/admin_web/lib/api.ts` - Added 4 API wrapper methods
2. `apps/admin_web/lib/rbac.ts` - Extended routes and permissions for 4 roles
3. `apps/admin_web/components/sidebar/Sidebar.tsx` - Added 2 navigation entries
4. `apps/admin_web/app/dashboard/layout.tsx` - Added 2 page titles

**Total changes:** 43 insertions, 1 deletion

---

## Self-Review

### ✅ Completed Requirements

- [x] API methods use offline-only throw pattern matching existing code
- [x] All four roles (ADMIN, OPS, SUPPORT, FINANCE) have access to new routes
- [x] `/dashboard/users` added to OPS, SUPPORT, FINANCE (was ADMIN-only)
- [x] `/dashboard/customer360` added to OPS and FINANCE (SUPPORT already had it)
- [x] Sidebar entries added in correct groups with appropriate icons
- [x] Layout page titles defined for both new routes
- [x] Changes committed and pushed to correct branch
- [x] No new page components created (Tasks 3-4 will handle UI)

### ✅ Pattern Adherence

- Followed exact offline wrapper pattern from `listStaff()` / `proposeFeeRule()`
- Used `Parameters<ReturnType<typeof getOfflineStore>['addAmlBanEntry']>[0]` for type safety
- Maintained existing sidebar group structure and icon conventions
- Consistent with RBAC extension patterns (added to union, ALL_ADMIN, then specific roles)

### ✅ Global Constraints Honored

- No passwords in UI (not applicable at this layer)
- Customers + AML routes accessible to all four roles as specified
- No production persistence mentioned (session-only via offline store)
- Brand-neutral implementation (no hardcoded "Poste Finance" in these files)

---

## Concerns & Assumptions

### None Critical

No blocking issues. Implementation is straightforward infrastructure wiring.

### Minor Observations

1. **Type inference:** Used `ReturnType<typeof getOfflineStore>` to avoid importing `OfflineDemoStore` type directly. This works but is verbose. Could be cleaned up if/when types are centralized.

2. **RBAC ordering:** Added new routes at the end of each role's array. Could be alphabetized later for maintainability, but current ordering matches sidebar hierarchy.

3. **SUPPORT role expansion:** The brief specified adding several routes to SUPPORT (`kyc`, `agents`, `remittance`). These were already present, so only the three new routes were added. This suggests Task 1 or earlier work already extended SUPPORT permissions.

4. **Customer360 already on SUPPORT:** Brief mentioned adding it to OPS/FINANCE, correctly noting SUPPORT already has it. Verified and added to the two roles as specified.

---

## Next Steps (Out of Scope)

Tasks 3-4 will implement:
- `/dashboard/aml-ban-list/page.tsx` - Ban list UI with add/lift controls
- `/dashboard/customers/page.tsx` - Customer directory with Open 360 links
- Users page mutate guards (ADMIN-only for create/role change)

These require no changes to the files modified in Task 2.

---

## Status: DONE ✅

All Task 2 requirements implemented, committed (186be3e), and pushed.
