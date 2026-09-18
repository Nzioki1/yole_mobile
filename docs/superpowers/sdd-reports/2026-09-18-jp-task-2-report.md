# Task 2: OfflineDemoStore Employer Employee Projection + Salary History

**Date:** 2026-09-18  
**Engineer:** Cloud Agent  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a`

## Objective

Implement TDD RED→GREEN for payroll employee projection with `displayName` and salary history retrieval.

## Implementation Summary

### Modified Files
1. `apps/admin_web/lib/offline/store.ts`
2. `apps/admin_web/lib/api.ts`
3. `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts`

### Changes Made

#### 1. Enhanced `listEmployers()` Employee Projection
- Added `employeeId` field (employee row id)
- Added `displayName` calculation:
  - If `customerId` links to customer: `firstName + lastName`
  - Else if `jobTitle` exists: use `jobTitle`
  - Else: use `employeeNumber`
- Added all salary fields: `grossSalaryCdfMinor`, `netSalaryCdfMinor`, `eligibleAdvanceMaxCdfMinor`
- Added import compatibility aliases: `salaryMinor` (string), `currency` ('CDF')
- Preserved `customerId`, `employeeNumber`, `jobTitle`, `status`

#### 2. Added `listSalaryHistory(employerId: string)` Method
- Filters `salaryHistory` by employer's employee IDs
- Projects `displayName` using same logic as `listEmployers()`
- Returns all original salary history fields plus `displayName`

#### 3. Added API Wrapper
- Added `api.listSalaryHistory(employerId)` in `apps/admin_web/lib/api.ts`
- Routes to offline store when `OFFLINE_DEMO` is true
- Throws error for non-offline mode (not yet implemented in live API)

### Test Coverage

Extended `store.jean-paul-enrichment.test.ts` with:
- ✅ Employee projection with `displayName` for customer-linked employee (Amina Payroll)
- ✅ All projected fields present and correct
- ✅ Import aliases `salaryMinor` and `currency` present
- ✅ `displayName` falls back to `jobTitle` for non-customer employees
- ✅ `listSalaryHistory` filters by employer correctly
- ✅ Salary history entries include `displayName`
- ✅ All existing Task 1 tests continue to pass

**Test Results:** 27/27 passing (5 tests for Task 2, 22 existing)

## TDD Process

1. **RED Phase:** Added failing tests expecting `displayName` and `listSalaryHistory` method
2. **GREEN Phase:** Implemented projection logic and new method to pass all tests
3. **Commit:** Single atomic commit with passing tests

## Commit

```
commit a848788
feat(admin): project payroll employees and salary history for offline store

- Extend listEmployers employees with displayName and all salary fields
- Add listSalaryHistory(employerId) with displayName projection
- Add api.listSalaryHistory offline wrapper
- Add TDD tests for employee projection and salary history
```

## Compliance

- ✅ No UI changes (Task 3 scope)
- ✅ Extends existing patterns (no rewrite)
- ✅ displayName logic: customer name → jobTitle → employeeNumber fallback
- ✅ Import compatibility aliases present (`salaryMinor`, `currency`)
- ✅ TDD RED→GREEN workflow followed
- ✅ All tests passing
- ✅ Single commit on correct branch
- ✅ Changes pushed to remote

## Next Steps

Task 3 will implement the Payroll UI consuming these new projections.
