# Task 5: Fees & Limits Propose for Approval

**Date:** 2026-09-18  
**Branch:** cursor/task1-monorepo-scaffold-1d8a  
**Files Modified:** apps/admin_web/app/dashboard/config/page.tsx

## Summary

Implemented fee/limit proposal UI on the `/dashboard/config` page following the products page pattern.

## Changes

1. **Fixed table rendering** — corrected fee/limit tables to display store projection fields:
   - Fees: `paymentType`, `feePercent`, `minFeeMinor`, `maxFeeMinor`, `currency`, `status`
   - Limits: `limitType`, `currency`, `dailyLimitMinor`, `monthlyLimitMinor`, `status`
   - Added status badges (ACTIVE=teal, PENDING_APPROVAL=warning, SUPERSEDED=secondary)

2. **Added propose fee form** — calls `api.proposeFeeRule` with payment type, fee percent, min/max minor, currency, effective date

3. **Added propose limit form** — calls `api.proposeLimitRule` with limit type, currency, daily/monthly minor, effective date

4. **Success messaging** — displays approval ID with link to `/dashboard/approvals`

5. **Honesty line** — exact wording: "Offline demo — fee/limit changes are session-only until Reset demo"

## Manual Path

Propose → `/dashboard/approvals` → Approve → status becomes ACTIVE

## Risks / Assumptions

- Assumes store already returns `status` field (verified in feeForAdmin/limitForAdmin)
- No second approval engine invented — reuses existing Products methods
- No edit/supersede UI added (not in scope for Task 5)
