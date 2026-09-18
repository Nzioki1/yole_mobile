### Task 1: Seed + types + store ban/customers (TDD)

**Files:**
- Modify: `packages/demo_universe/data/universe.json`
- Modify: `packages/demo_universe/ts/types.ts`
- Modify: `packages/demo_universe/dart/lib/universe_json.dart` (regen)
- Modify: `apps/admin_web/lib/offline/store.ts`
- Create: `apps/admin_web/lib/offline/store.aml-ban.test.ts`
- Optional: include `amlBanList` in `buildExportPack()` for DEM-12 completeness

**Interfaces:**
- Produces:
  - `AmlBanEntry` type
  - `listAmlBanList(): AmlBanEntry[]`
  - `addAmlBanEntry(data): AmlBanEntry`
  - `liftAmlBanEntry(id: string): AmlBanEntry`
  - `listCustomers(): Omit<Customer, 'password'>[]`

- [ ] **Step 1: Add TypeScript type**

In `packages/demo_universe/ts/types.ts`, before `export interface Universe`:

```ts
export interface AmlBanEntry {
  id: string;
  fullName: string;
  idRef?: string;
  matchType: 'NAME' | 'ID' | 'ENTITY';
  reason: string;
  sourceList: string;
  status: 'BANNED' | 'LIFTED';
  notes?: string;
  createdAt: string;
}
```

Add to `Universe`: `amlBanList: AmlBanEntry[];`

- [ ] **Step 2: Seed JSON**

Append to `universe.json` (sibling of `notifications`):

```json
"amlBanList": [
  {
    "id": "ban_demo_001",
    "fullName": "DEMO BLOCKED PERSON ONE",
    "idRef": "ID-BAN-0001",
    "matchType": "ID",
    "reason": "Internal fraud — demo entry",
    "sourceList": "INTERNAL_FRAUD",
    "status": "BANNED",
    "notes": "Fictional demo identity only",
    "createdAt": "2026-08-01T10:00:00Z"
  },
  {
    "id": "ban_demo_002",
    "fullName": "ACME SHELL TRADING SARL",
    "idRef": "RCCM-DEMO-999",
    "matchType": "ENTITY",
    "reason": "Suspected mule network — demo",
    "sourceList": "DEMO_SANCTIONS",
    "status": "BANNED",
    "createdAt": "2026-08-15T12:00:00Z"
  },
  {
    "id": "ban_demo_003",
    "fullName": "DEMO ALIAS MATCH",
    "matchType": "NAME",
    "reason": "Partial name match on demo sanctions list",
    "sourceList": "DEMO_SANCTIONS",
    "status": "BANNED",
    "createdAt": "2026-09-01T09:00:00Z"
  },
  {
    "id": "ban_demo_004",
    "fullName": "FORMERLY BLOCKED DEMO",
    "idRef": "ID-BAN-0004",
    "matchType": "ID",
    "reason": "Cleared after review — demo",
    "sourceList": "INTERNAL_FRAUD",
    "status": "LIFTED",
    "createdAt": "2026-07-01T08:00:00Z"
  },
  {
    "id": "ban_demo_005",
    "fullName": "DEMO PEPS PROXY",
    "matchType": "NAME",
    "reason": "PEP association — demo hold",
    "sourceList": "DEMO_SANCTIONS",
    "status": "BANNED",
    "createdAt": "2026-09-10T14:00:00Z"
  }
]
```

Bump `meta.version` if the package treats it as a cache key (optional; keep `1` if unused).

- [ ] **Step 3: Regenerate Dart embed**

```bash
cd packages/demo_universe
node <<'NODE'
const fs = require('fs');
const raw = fs.readFileSync('data/universe.json', 'utf8').replace(/\s*$/, '');
fs.writeFileSync(
  'dart/lib/universe_json.dart',
  "/// Auto-generated embedded universe.json — do not edit by hand.\\n" +
    "const String kUniverseJson = r'''\\n" + raw + "\\n''';\\n"
);
console.log('Wrote dart/lib/universe_json.dart', raw.length);
NODE
```

Also copy/sync `packages/demo_universe/dart/assets/universe.json` if the repo keeps a duplicate asset (overwrite from `data/universe.json`).

- [ ] **Step 4: Write failing store tests**

```ts
import { OfflineDemoStore } from './store';

describe('OfflineDemoStore AML ban + customers directory', () => {
  test('listAmlBanList returns seeded BANNED and LIFTED entries', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listAmlBanList();
    expect(list.length).toBeGreaterThanOrEqual(5);
    expect(list.some((e) => e.status === 'BANNED')).toBe(true);
    expect(list.some((e) => e.id === 'ban_demo_001')).toBe(true);
  });

  test('addAmlBanEntry appends BANNED row', () => {
    const store = OfflineDemoStore.createFresh();
    const before = store.listAmlBanList().length;
    const row = store.addAmlBanEntry({
      fullName: 'NEW DEMO BAN',
      matchType: 'NAME',
      reason: 'Demo add',
      sourceList: 'DEMO_SANCTIONS',
    });
    expect(row.status).toBe('BANNED');
    expect(row.id).toMatch(/^ban_demo_/);
    expect(store.listAmlBanList().length).toBe(before + 1);
  });

  test('liftAmlBanEntry sets LIFTED', () => {
    const store = OfflineDemoStore.createFresh();
    const updated = store.liftAmlBanEntry('ban_demo_001');
    expect(updated.status).toBe('LIFTED');
    expect(store.listAmlBanList().find((e) => e.id === 'ban_demo_001')?.status).toBe('LIFTED');
  });

  test('listCustomers omits passwords and includes cust_kasee', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listCustomers();
    expect(list.length).toBeGreaterThanOrEqual(4);
    for (const c of list) {
      expect(c).not.toHaveProperty('password');
    }
    expect(list.some((c) => c.id === 'cust_kasee')).toBe(true);
  });

  test('reset restores ban seed', () => {
    const store = OfflineDemoStore.createFresh();
    store.addAmlBanEntry({
      fullName: 'TEMP',
      matchType: 'NAME',
      reason: 'x',
      sourceList: 'DEMO_SANCTIONS',
    });
    store.reset();
    expect(store.listAmlBanList().some((e) => e.fullName === 'TEMP')).toBe(false);
    expect(store.listAmlBanList().some((e) => e.id === 'ban_demo_001')).toBe(true);
  });
});
```

- [ ] **Step 5: Run — expect FAIL**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.aml-ban.test.ts
```

- [ ] **Step 6: Implement store methods**

Ensure `loadUniverse()` typing accepts `amlBanList` (comes from JSON). Initialize safely:

```ts
listAmlBanList() {
  return (this.u.amlBanList ?? []).slice();
}

addAmlBanEntry(data: {
  fullName: string;
  idRef?: string;
  matchType: 'NAME' | 'ID' | 'ENTITY';
  reason: string;
  sourceList: string;
  notes?: string;
  status?: 'BANNED' | 'LIFTED';
}) {
  if (!this.u.amlBanList) this.u.amlBanList = [];
  const row = {
    id: `ban_demo_${Date.now()}`,
    fullName: data.fullName.trim(),
    idRef: data.idRef,
    matchType: data.matchType,
    reason: data.reason.trim(),
    sourceList: data.sourceList.trim() || 'DEMO_SANCTIONS',
    status: data.status || 'BANNED',
    notes: data.notes,
    createdAt: nowIso(),
  };
  this.u.amlBanList.push(row);
  return row;
}

liftAmlBanEntry(id: string) {
  const row = (this.u.amlBanList ?? []).find((e) => e.id === id);
  if (!row) throw new Error(`Ban entry not found: ${id}`);
  row.status = 'LIFTED';
  return row;
}

listCustomers() {
  return this.u.customers.map(({ password: _p, ...rest }) => rest);
}
```

Import `AmlBanEntry` type in store if needed. Add `amlBanList` to `buildExportPack()` optionally.

- [ ] **Step 7: Run — expect PASS**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.aml-ban.test.ts
cd packages/demo_universe && pnpm exec vitest run ts/load.test.ts
```

- [ ] **Step 8: Commit**

```bash
git add packages/demo_universe apps/admin_web/lib/offline/store.ts apps/admin_web/lib/offline/store.aml-ban.test.ts
git commit -m "feat(demo): seed AML ban list + store list/add/lift and listCustomers"
```

---
