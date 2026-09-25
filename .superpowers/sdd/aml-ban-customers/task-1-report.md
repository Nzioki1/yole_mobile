# Task 1: AML Ban List + Customers Directory - Implementation Report

**Date:** 2026-09-18  
**Task:** Task 1 of 5 (AML ban list + customers directory plan)  
**Branch:** `cursor/task1-monorepo-scaffold-1d8a`  
**Commit:** f9e0966 (rebased to 8ebdf5d)

---

## Implementation Summary

Successfully implemented Task 1 following TDD methodology:
- Added `AmlBanEntry` TypeScript type
- Seeded 5 demo ban list entries in `universe.json`
- Regenerated Dart embed and synced assets
- Implemented 4 OfflineDemoStore methods with full test coverage
- Included `amlBanList` in export pack for DEM-12 completeness

---

## TDD RED/GREEN Evidence

### RED Phase (Tests Fail)
```bash
cd /workspace/apps/admin_web && pnpm test lib/offline/store.aml-ban.test.ts
```

**Output:**
```
 FAIL  lib/offline/store.aml-ban.test.ts > OfflineDemoStore AML ban + customers directory > listAmlBanList returns seeded BANNED and LIFTED entries
TypeError: store.listAmlBanList is not a function

 FAIL  lib/offline/store.aml-ban.test.ts > OfflineDemoStore AML ban + customers directory > addAmlBanEntry appends BANNED row
TypeError: store.listAmlBanList is not a function

 FAIL  lib/offline/store.aml-ban.test.ts > OfflineDemoStore AML ban + customers directory > liftAmlBanEntry sets LIFTED
TypeError: store.liftAmlBanEntry is not a function

 FAIL  lib/offline/store.aml-ban.test.ts > OfflineDemoStore AML ban + customers directory > listCustomers omits passwords and includes cust_kasee
TypeError: store.listCustomers is not a function

 FAIL  lib/offline/store.aml-ban.test.ts > OfflineDemoStore AML ban + customers directory > reset restores ban seed
TypeError: store.addAmlBanEntry is not a function

 Test Files  1 failed (1)
      Tests  5 failed (5)
```

All 5 tests failed as expected — methods not yet implemented.

### GREEN Phase (Tests Pass)
```bash
cd /workspace/apps/admin_web && pnpm test lib/offline/store.aml-ban.test.ts
```

**Output:**
```
 ✓ lib/offline/store.aml-ban.test.ts (5 tests) 4ms

 Test Files  1 passed (1)
      Tests  5 passed (5)
   Duration  364ms
```

All 5 tests passing after implementation.

### Universe Load Test
```bash
cd /workspace/packages/demo_universe && pnpm exec vitest run ts/load.test.ts
```

**Output:**
```
 ✓ ts/load.test.ts (1 test) 2ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
```

JSON loading works correctly with new `amlBanList` field.

---

## Files Changed

### 1. `packages/demo_universe/ts/types.ts`
- Added `AmlBanEntry` interface before `UniverseMeta`
- Added `amlBanList: AmlBanEntry[]` to `Universe` interface

### 2. `packages/demo_universe/data/universe.json`
- Added `amlBanList` array with 5 seed entries:
  - `ban_demo_001`: ID match, BANNED (Internal fraud demo)
  - `ban_demo_002`: Entity match, BANNED (Shell trading SARL demo)
  - `ban_demo_003`: Name match, BANNED (Alias match demo)
  - `ban_demo_004`: ID match, LIFTED (Cleared after review demo)
  - `ban_demo_005`: Name match, BANNED (PEP association demo)
- All entries use clearly fictional DEMO names per global constraints

### 3. `packages/demo_universe/dart/lib/universe_json.dart`
- Regenerated with node script (25474 bytes)
- Header preserved: `/// Auto-generated embedded universe.json — do not edit by hand.`

### 4. `packages/demo_universe/dart/assets/universe.json`
- Synced from `data/universe.json`

### 5. `apps/admin_web/lib/offline/store.ts`
- Added `AmlBanEntry` import from `demo_universe`
- Implemented `listAmlBanList()`: Returns defensive slice of ban list
- Implemented `addAmlBanEntry(data)`: Appends new BANNED entry with timestamp ID
- Implemented `liftAmlBanEntry(id)`: Mutates status to LIFTED, throws if not found
- Implemented `listCustomers()`: Returns customers without password field
- Modified `buildExportPack()`: Included `amlBanList` in export pack

### 6. `apps/admin_web/lib/offline/store.aml-ban.test.ts` (NEW)
- Created 5 test cases:
  1. List returns seeded BANNED and LIFTED entries
  2. Add appends BANNED row with generated ID
  3. Lift sets LIFTED status
  4. List customers omits passwords
  5. Reset restores ban seed

---

## Self-Review Checklist

✅ **TypeScript types added** (`AmlBanEntry`, `Universe.amlBanList`)  
✅ **JSON seed data added** (5 fictional demo entries)  
✅ **Dart embed regenerated** (universe_json.dart + assets/universe.json synced)  
✅ **TDD RED phase executed** (5 tests failed as expected)  
✅ **Store methods implemented** (4 new methods following existing patterns)  
✅ **TDD GREEN phase executed** (5 tests passing)  
✅ **Universe load test passing** (JSON parsing works)  
✅ **Export pack includes amlBanList** (DEM-12 completeness)  
✅ **Global constraints followed:**
  - Ban entries are clearly fictional demo identities
  - Passwords omitted from customer list
  - Offline-first design (no live API)
  - Session mutations until reset (no persistence)
✅ **Pattern consistency:**
  - Mirrored staff TDD pattern from `store.staff.test.ts`
  - Used `loadUniverse()` for seed initialization
  - Used `nowIso()` helper for timestamps
  - Defensive slice returns from list methods
  - Throw Error for not-found scenarios
✅ **Commit message follows brief** (`feat(demo): seed AML ban list + store list/add/lift and listCustomers`)  
✅ **Changes pushed to origin** on `cursor/task1-monorepo-scaffold-1d8a`

---

## Concerns & Assumptions

### Assumptions Made
1. **Ban list is optional in Universe**: Initialized with `this.u.amlBanList ?? []` to handle legacy data without the field
2. **ID generation pattern**: Used `ban_demo_${Date.now()}` consistent with other store methods
3. **Fictional names**: All 5 seed entries use CLEARLY DEMO/FICTIONAL names per global constraints
4. **Export pack inclusion**: Added `amlBanList` to `buildExportPack()` for DEM-12 completeness (marked optional in brief)
5. **No customer password in list**: `listCustomers()` strips password field consistent with `listStaff()` pattern

### No Blocking Concerns
- All tests passing (RED → GREEN cycle complete)
- Dart embed regenerated successfully
- No breaking changes to existing store methods
- Pre-existing clone test failure unrelated to this task

### Future Considerations (Out of Scope for Task 1)
- Task 2-5: API endpoints, pages, RBAC (not implemented per brief)
- No auto-block of payments from ban list (out of scope per global constraints)
- No live sanctions feed integration (offline demo only)

---

## Test Coverage Summary

**Total Tests:** 5  
**Passing:** 5 (100%)  
**Duration:** 4ms (unit tests), 364ms (total with setup)

**Test Cases:**
1. ✅ `listAmlBanList` returns seeded BANNED and LIFTED entries
2. ✅ `addAmlBanEntry` appends BANNED row with generated ID
3. ✅ `liftAmlBanEntry` sets LIFTED status
4. ✅ `listCustomers` omits passwords and includes cust_kasee
5. ✅ `reset` restores ban seed (mutations cleared)

---

## Commit Details

**SHA:** f9e0966 (rebased to 8ebdf5d after remote sync)  
**Message:** `feat(demo): seed AML ban list + store list/add/lift and listCustomers`  
**Files Changed:** 6 files, 271 insertions(+), 4 deletions(-)  
**Pushed:** ✅ `origin/cursor/task1-monorepo-scaffold-1d8a`

---

## Verification Commands

```bash
# Run AML ban tests
cd apps/admin_web && pnpm test lib/offline/store.aml-ban.test.ts

# Run universe load test
cd packages/demo_universe && pnpm exec vitest run ts/load.test.ts

# Verify seed data
node -e "console.log(JSON.parse(require('fs').readFileSync('packages/demo_universe/data/universe.json')).amlBanList.length)"
# Expected: 5

# Verify Dart embed
wc -c packages/demo_universe/dart/lib/universe_json.dart
# Expected: ~25474 bytes
```

---

**Status:** ✅ **DONE**  
**Task 1 Implementation:** Complete with TDD evidence, all tests passing, committed and pushed.
