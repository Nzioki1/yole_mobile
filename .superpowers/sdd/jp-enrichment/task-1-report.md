# Jean-Paul Demo Enrichment - Task 1 Implementation Report

**Date:** 2026-09-18  
**Task:** Task 1 — Seed Jean-Paul cleanup + payroll roster + exceptions  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a`  
**Commit:** 1db2982  
**Status:** ✅ DONE

## Summary

Successfully implemented Task 1 of the Jean-Paul demo enrichment plan using TDD methodology. All acceptance criteria met with passing tests.

## Changes Made

### 1. Test-Driven Development (RED → GREEN)

**Created:** `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts`

Three test cases covering:
- Single Jean-Paul identity validation (cust_kasee, no duplicate)
- Payroll employee count (≥6 at emp_poste)
- Credit exceptions queue (≥4 pending, including Jean-Paul)

**RED state:** All 3 tests failed initially
**GREEN state:** All 3 tests pass after seed changes

### 2. Universe Seed Changes (`packages/demo_universe/data/universe.json`)

#### Identity Cleanup
- ❌ Removed duplicate customer `cust_jp_kabila` and wallets `wal_jp_usd`, `wal_jp_cdf`
- ✅ Confirmed canonical customer `cust_kasee` (Jean-Paul Kabila, jp.kabila@gmail.com)
- 🔧 Fixed payment reference pointing to deleted duplicate

#### Payroll Expansion
**emp_poste (Poste Demo SARL):**
- Added 5 new employees (total 6 including existing Amina):
  - PD-10043: Teller Supervisor
  - PD-10044: Customer Service Rep
  - PD-10045: Compliance Officer
  - PD-10046: Marketing Coordinator
  - PD-10047: IT Support Specialist

**emp_congo_mining (Congo Mining Corp):**
- Added 3 employees:
  - CM-5501: Mine Operations Manager
  - CM-5502: Safety Engineer
  - CM-5503: Equipment Operator

**Salary History:**
- Maintained 3 periods for Amina (existing)
- Added 1-2 periods for new Poste employees
- Added 1 period for Congo Mining employees

#### Credit Exceptions Queue
Added 3 new customers and PENDING_EXCEPTION loans:

1. **Marie Tshala** (`cust_marie_tshala` — existing)
   - Loan: `loan_marie_exception_001` (4.5M CDF)
   - Reason: KYC pending review - manual approval required

2. **Pierre Lumbu** (`cust_pierre_lumbu` — new)
   - Loan: `loan_pierre_exception_001` (3.5M CDF)
   - Reason: First-time borrower - credit history review needed

3. **Julie Nkandu** (`cust_julie_nkandu` — new)
   - Loan: `loan_julie_exception_001` (5.5M CDF)
   - Reason: Amount significantly above threshold

Each loan has matching CREDIT_EXCEPTION `pendingApprovals`:
- `apr_loan_exception_002` (Marie)
- `apr_loan_exception_003` (Pierre)
- `apr_loan_exception_004` (Julie)

Total pending exceptions: 4 (including existing Jean-Paul exception)

### 3. Dart Embed Regeneration

- ✅ Regenerated `packages/demo_universe/dart/lib/universe_json.dart`
- ✅ Synced to `packages/demo_universe/dart/assets/universe.json`

## Test Results

```
✓ lib/offline/store.jean-paul-enrichment.test.ts (3 tests) 3ms

Test Files  1 passed (1)
     Tests  3 passed (3)
```

All acceptance criteria validated:
- ✅ Single Jean-Paul customer (cust_kasee)
- ✅ No duplicate cust_jp_kabila in customer list
- ✅ emp_poste has 6 employees
- ✅ 4 pending credit exceptions including Jean-Paul

## Constraints Honored

- ✅ Jean-Paul NOT added as payroll employee (remains OPEN/retail)
- ✅ No UI changes (seed-only task)
- ✅ No listSalaryHistory projection added (reserved for Task 2)
- ✅ Employee.customerId set to null for non-Open 360 employees
- ✅ Followed existing patterns (OfflineDemoStore, test conventions)
- ✅ Dart embed regenerated after JSON changes

## Files Modified

1. `packages/demo_universe/data/universe.json` — seed changes
2. `packages/demo_universe/dart/lib/universe_json.dart` — regenerated
3. `packages/demo_universe/dart/assets/universe.json` — synced
4. `apps/admin_web/lib/offline/store.jean-paul-enrichment.test.ts` — new test

**Total:** 4 files changed, 759 insertions(+), 96 deletions(-)

## Commit

```
1db2982 feat(demo): Jean-Paul single identity + rich payroll/exception seed
```

## Risks & Assumptions

**Risks Mitigated:**
- JSON syntax validated before regeneration
- Tests verify seed shape matches store projections
- No breaking changes to existing store methods

**Assumptions:**
- Employee.customerId null is acceptable for demo-only staff
- Salary history can be sparse (not all employees have full 3-month history)
- New thin customers (Pierre, Julie) don't need wallet/payment history for exception demo

## Next Steps (Out of Scope for Task 1)

Task 2+ will handle:
- Payroll detail UI updates
- listSalaryHistory projection
- Salary history panel rendering
- Open 360 links from employee rows
- Fees & Limits propose UI

---

**Report Path:** `docs/superpowers/sdd-reports/2026-09-18-jp-task-1-report.md`  
**Implementation Time:** < 15 minutes  
**TDD Cycle:** RED (3 failures) → Seed → GREEN (3 passes)
