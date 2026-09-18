# Task 4: Customers Directory Page - Implementation Report

**Date:** 2026-09-18  
**Task:** Task 4 of 5 (Customers directory UI)  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a`  
**Commit:** 220728e

---

## Implementation Summary

Successfully implemented Task 4 customers directory page:
- Created `/dashboard/customers` page with table listing all customers
- Integrated with existing `api.listCustomers()` from Task 1
- Table columns: ID, Name, Email, Phone, Segment, KYC, Status, Action
- Action column links to Customer 360 with deep-link query parameter
- Verified Customer 360 already handles `?customerId=` deep link correctly
- Followed Panel/table styling pattern from Agents page
- Password field never rendered (handled by `listCustomers()` API)

---

## Current Code Findings

### Existing Infrastructure (Already in Place)
1. **API Method**: `api.listCustomers()` exists in `lib/api.ts` (line 484-487)
   - Returns `Omit<Customer, 'password'>[]` via OfflineDemoStore
   - Only works in OFFLINE_DEMO mode

2. **Route Access**: `/dashboard/customers` already in RBAC and sidebar
   - RBAC permissions: ADMIN, OPS, SUPPORT, FINANCE
   - Sidebar navigation: "Customers" link already present

3. **Customer 360 Deep Link**: Already functional
   - `useSearchParams()` reads `customerId` query param (line 32)
   - `useEffect` auto-loads customer on mount (lines 31-43)
   - No changes needed to customer360 page

4. **Customer Data Structure** (from `demo_universe/ts/types.ts`):
   ```typescript
   interface Customer {
     id: string;
     email: string;
     password: string;      // OMITTED by listCustomers()
     phoneE164?: string | null;
     firstName: string;
     lastName: string;
     segment: string;
     status?: string;
     kycStatus: string;
     employerId?: string | null;
     enrolledByAgentId?: string | null;
     createdAt?: string;
   }
   ```

---

## Implementation Plan

### Minimal Changes Required
1. **Create**: `apps/admin_web/app/dashboard/customers/page.tsx`
   - Client component with useEffect → api.listCustomers()
   - Table with 8 columns per spec
   - Link to Customer 360 with query param
   - Follow Agents page Panel/table pattern

2. **Verify**: Customer 360 deep link (already working, no changes needed)

3. **Commit**: Single commit with message from brief

---

## Files Modified

### 1. `apps/admin_web/app/dashboard/customers/page.tsx` (NEW)

**Implementation Details:**
- **Pattern**: Mirrored Agents page structure (`app/dashboard/agents/page.tsx`)
- **Client Component**: `'use client'` directive for React hooks
- **State Management**: Single `customers` state array
- **Data Loading**: `useEffect` calls `api.listCustomers()` on mount
- **Panel Component**: Reused existing `Panel`, `PanelHeader`, `PanelBody`
- **Table Styling**: Bootstrap classes (`table-striped`, `table-hover`, `align-middle`)

**Table Columns Implemented:**
1. **ID**: `font-monospace small` styling
2. **Name**: Combined `firstName + lastName`, `fw-semibold` styling
3. **Email**: Plain text
4. **Phone**: `phoneE164` with fallback to em dash (`—`)
5. **Segment**: Badge with `bg-info` color
6. **KYC**: Color-coded badge (green=VERIFIED, yellow=PENDING, gray=other)
7. **Status**: Color-coded badge (teal=ACTIVE, gray=inactive)
8. **Action**: Next.js Link to `/dashboard/customer360?customerId=${c.id}` with button styling

**Badge Color Logic:**
- **KYC Status**:
  - `VERIFIED` → `bg-success` (green)
  - `PENDING` → `bg-warning` (yellow)
  - Other → `bg-secondary` (gray)
- **Customer Status**:
  - `ACTIVE` → `bg-teal`
  - Other → `bg-secondary`

**Password Security**: Never rendered (already omitted by `api.listCustomers()`)

---

## Risks & Assumptions

### Assumptions Made
1. **OFFLINE_DEMO**: Customers page only works in offline demo mode (consistent with `api.listCustomers()` implementation)
2. **Status Field**: Customer `status` field may be undefined, defaulting to 'ACTIVE' for display
3. **Phone Optional**: `phoneE164` may be null, displaying em dash (`—`) as fallback
4. **Link vs Next Link**: Used Next.js `Link` component for client-side navigation (preferred over `<a>` tag)

### No Changes Needed
- ✅ **Customer 360**: Deep link already functional, no fixes required
- ✅ **RBAC**: Route already configured for ADMIN, OPS, SUPPORT, FINANCE
- ✅ **Sidebar**: Navigation link already present
- ✅ **API**: `listCustomers()` method already implemented in Task 1

### No Blocking Concerns
- No breaking changes to existing code
- No RBAC expansion needed
- No API contract changes
- No customer360 modifications required

---

## Self-Review Checklist

✅ **Page created** at correct path (`apps/admin_web/app/dashboard/customers/page.tsx`)  
✅ **API integration** using existing `api.listCustomers()`  
✅ **Table columns** match spec (ID, Name, Email, Phone, Segment, KYC, Status, Action)  
✅ **Name rendering** combines `firstName + lastName`  
✅ **Phone rendering** uses `phoneE164` field  
✅ **Deep link format** uses `?customerId=` query parameter  
✅ **Action button** labeled "Open 360" per spec  
✅ **Password security** never rendered (omitted by API)  
✅ **Panel styling** follows Agents page pattern  
✅ **Table styling** uses Bootstrap classes (`table-striped`, `table-hover`)  
✅ **Customer 360 verified** already handles deep link correctly  
✅ **Global constraints followed:**
  - Passwords never appear in customer list UI
  - Route restricted to ADMIN/OPS/SUPPORT/FINANCE
  - Offline demo mode only
✅ **Pattern consistency:**
  - Mirrored Agents page structure
  - Used Next.js Link for navigation
  - Color-coded badges for status fields
  - Responsive table wrapper
✅ **Commit message** follows brief (`feat(admin): customers directory with Customer 360 deep link`)  
✅ **Changes pushed** to `origin/cursor/task1-monorepo-scaffold-1d8a`  
✅ **No expansion** beyond Task 4 scope (no Users page, AML ban page, or RBAC changes)

---

## Verification Steps

### Manual Testing (In Browser)
1. Start dev server: `cd apps/admin_web && pnpm dev`
2. Login as ADMIN, OPS, SUPPORT, or FINANCE user
3. Navigate to `/dashboard/customers` via sidebar
4. Verify table displays all customers with 8 columns
5. Click "Open 360" button for any customer
6. Verify Customer 360 page auto-loads the selected customer
7. Verify password field never appears in customers table

### Expected Behavior
- **Table Load**: Displays 4 demo customers (cust_kasee, cust_lucie, cust_mado, cust_emma)
- **Name Column**: Shows full name (e.g., "Kasee Tshimanga")
- **KYC Badges**: Color-coded (green for VERIFIED, yellow for PENDING)
- **Status Badges**: Teal for ACTIVE status
- **Phone Column**: Shows E.164 format or em dash if missing
- **Deep Link**: Customer 360 auto-loads without manual search

---

## Commit Details

**SHA:** 220728e  
**Message:** `feat(admin): customers directory with Customer 360 deep link`  
**Files Changed:** 1 file, 94 insertions(+)  
**Created:** `apps/admin_web/app/dashboard/customers/page.tsx`  
**Pushed:** ✅ `origin/cursor/task1-monorepo-scaffold-1d8a`

---

## Code Snippet

```typescript
// Key implementation: Deep link to Customer 360
<Link
  href={`/dashboard/customer360?customerId=${c.id}`}
  className="btn btn-sm btn-theme"
>
  Open 360
</Link>
```

---

**Status:** ✅ **DONE**  
**Task 4 Implementation:** Complete, UI follows Agents page pattern, deep link verified, committed and pushed.
