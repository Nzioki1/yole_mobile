# AML Ban List + Customers Directory + Staff Users View Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an offline AML ban list, a full customers directory (with Customer 360 deep link), and widen staff Users to view-for-all-roles while keeping create/role-change ADMIN-only.

**Architecture:** Seed `amlBanList[]` in `universe.json` (regenerate Dart embed). Extend `OfflineDemoStore` with ban + `listCustomers` APIs. Add two admin pages + RBAC/sidebar. Adjust Users page guards so non-ADMIN can read. Customer 360 already reads `?customerId=` — verify and use it.

**Tech Stack:** Next.js 15 admin_web, TypeScript, Vitest, demo_universe JSON + Dart embed, Color Admin Panels.

**Spec:** `docs/superpowers/specs/2026-09-18-admin-aml-ban-customers-directory-design.md`

## Global Constraints

- Offline-first; no live sanctions feed; honesty on ban page: `Offline demo — not a live sanctions feed`
- Ban seed entries are fictional demo names only (not real persons)
- Passwords never appear in staff/customer list UIs
- Users: **view** ADMIN/OPS/SUPPORT/FINANCE; **create/change role** ADMIN only
- Customers + AML ban routes: ADMIN, OPS, SUPPORT, FINANCE
- No auto-block of payments from ban list (out of scope)
- Regenerate `packages/demo_universe/dart/lib/universe_json.dart` after JSON edits
- Session mutations until Reset demo; no production persistence
- User-visible brand: Poste Finance

## File map

| File | Responsibility |
| --- | --- |
| `packages/demo_universe/data/universe.json` | Seed `amlBanList` |
| `packages/demo_universe/ts/types.ts` | `AmlBanEntry` + `Universe.amlBanList` |
| `packages/demo_universe/dart/lib/universe_json.dart` | Regenerated embed |
| `apps/admin_web/lib/offline/store.ts` | `listAmlBanList`, `addAmlBanEntry`, `liftAmlBanEntry`, `listCustomers` |
| `apps/admin_web/lib/offline/store.aml-ban.test.ts` | Vitest |
| `apps/admin_web/lib/api.ts` | Offline wrappers |
| `apps/admin_web/lib/rbac.ts` | New routes + Users on OPS/SUPPORT/FINANCE |
| `apps/admin_web/components/sidebar/Sidebar.tsx` | Nav items |
| `apps/admin_web/app/dashboard/layout.tsx` | Page titles |
| `apps/admin_web/app/dashboard/aml-ban-list/page.tsx` | Ban UI |
| `apps/admin_web/app/dashboard/customers/page.tsx` | Customers UI |
| `apps/admin_web/app/dashboard/users/page.tsx` | View vs mutate |
| `docs/demo/DEM-SCRIPT.md` | Short URL notes |

---

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

### Task 2: API + RBAC + sidebar + titles

**Files:**
- Modify: `apps/admin_web/lib/api.ts`
- Modify: `apps/admin_web/lib/rbac.ts`
- Modify: `apps/admin_web/components/sidebar/Sidebar.tsx`
- Modify: `apps/admin_web/app/dashboard/layout.tsx`

**Interfaces:**
- Produces: `api.listAmlBanList`, `api.addAmlBanEntry`, `api.liftAmlBanEntry`, `api.listCustomers`
- Routes: `'/dashboard/aml-ban-list'`, `'/dashboard/customers'` on ADMIN + OPS + SUPPORT + FINANCE
- `'/dashboard/users'` added to OPS, SUPPORT, FINANCE (already on ADMIN via ALL_ADMIN)

- [ ] **Step 1: API methods** (offline-only throw pattern)

```ts
async listAmlBanList() {
  if (OFFLINE_DEMO) return this.store().listAmlBanList();
  throw new Error('listAmlBanList is only available in offline demo');
}
async addAmlBanEntry(data: Parameters<OfflineDemoStore['addAmlBanEntry']>[0]) {
  if (OFFLINE_DEMO) return this.store().addAmlBanEntry(data);
  throw new Error('addAmlBanEntry is only available in offline demo');
}
async liftAmlBanEntry(id: string) {
  if (OFFLINE_DEMO) return this.store().liftAmlBanEntry(id);
  throw new Error('liftAmlBanEntry is only available in offline demo');
}
async listCustomers() {
  if (OFFLINE_DEMO) return this.store().listCustomers();
  throw new Error('listCustomers is only available in offline demo');
}
```

(Use inline param types if importing OfflineDemoStore is awkward.)

- [ ] **Step 2: RBAC**

Add to `ModuleRoute` union: `'/dashboard/aml-ban-list' | '/dashboard/customers'`.

Add both to `ALL_ADMIN`.

Add to OPS, SUPPORT, and FINANCE arrays:

- `'/dashboard/aml-ban-list'`
- `'/dashboard/customers'`
- `'/dashboard/users'`

Also add `'/dashboard/customer360'` to OPS/FINANCE if missing (SUPPORT already has it) so Open 360 works for those roles — **add customer360 to OPS and FINANCE**.

- [ ] **Step 3: Sidebar**

Customers group:

```ts
{ name: 'Customers', href: '/dashboard/customers', icon: 'fa fa-address-book' },
{ name: 'Customer 360', href: '/dashboard/customer360', icon: 'fa fa-user' },
...
```

Operations group:

```ts
{ name: 'AML ban list', href: '/dashboard/aml-ban-list', icon: 'fa fa-ban' },
```

(Keep Cases nearby.)

- [ ] **Step 4: layout titles**

```ts
'/dashboard/customers': 'Customers',
'/dashboard/aml-ban-list': 'AML Ban List',
```

- [ ] **Step 5: Commit**

```bash
git add apps/admin_web/lib/api.ts apps/admin_web/lib/rbac.ts apps/admin_web/components/sidebar/Sidebar.tsx apps/admin_web/app/dashboard/layout.tsx
git commit -m "feat(admin): RBAC and nav for AML ban list and customers directory"
```

---

### Task 3: AML ban list page

**Files:**
- Create: `apps/admin_web/app/dashboard/aml-ban-list/page.tsx`

- [ ] **Step 1: Build page** (Agents/Users Panel pattern)

- Honesty: `Offline demo — not a live sanctions feed`
- Load `api.listAmlBanList()` on mount
- Table: Name | ID/ref | Match | Reason | Source | Status | Added | Actions
- Status badge: BANNED → danger, LIFTED → secondary
- **+ Add to ban list** form: fullName, idRef, matchType select, reason, sourceList (default DEMO_SANCTIONS)
- **Lift** button when status === BANNED → `api.liftAmlBanEntry`
- Auth-after-mount not required for list data (API client-side only in useEffect)

- [ ] **Step 2: Manual check** `:3001/dashboard/aml-ban-list` returns 200; seeded rows visible

- [ ] **Step 3: Commit**

```bash
git add apps/admin_web/app/dashboard/aml-ban-list/page.tsx
git commit -m "feat(admin): AML ban list page with add and lift"
```

---

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

### Task 5: Users page — view for all roles, mutate ADMIN-only

**Files:**
- Modify: `apps/admin_web/app/dashboard/users/page.tsx`
- Optional: `docs/demo/DEM-SCRIPT.md` URLs for ban list + customers

- [ ] **Step 1: Change auth guard**

```ts
const [currentUser, setCurrentUser] = useState<ReturnType<typeof authService.getCurrentUser>>(null);
const isAdmin = currentUser?.role === StaffRole.ADMIN;

useEffect(() => {
  const user = authService.getCurrentUser();
  if (!user) {
    router.replace('/login');
    return;
  }
  setCurrentUser(user);
  loadStaff();
}, [router]);
```

Remove redirect that sent non-ADMIN to `/dashboard`.

- [ ] **Step 2: Conditional mutate UI**

- Show **+ Create staff** form only if `isAdmin`
- Role column: if `isAdmin` → `<select>` as today; else → badge text only
- Helper text: non-ADMIN sees “View only — ask an ADMIN to create users or change roles.”

- [ ] **Step 3: DEM-SCRIPT one-liners**

```
| — | `/dashboard/aml-ban-list` | AML ban list |
| — | `/dashboard/customers` | Customers directory |
```

- [ ] **Step 4: Manual acceptance**

1. Admin: see ban list, customers, users mutate
2. Login as `support@postefinance.com`: see Customers, AML ban, Users list; no create/role select
3. Reset demo restores bans
4. No hydration error on shell (auth already deferred)

- [ ] **Step 5: Commit + push when asked**

```bash
git add apps/admin_web/app/dashboard/users/page.tsx docs/demo/DEM-SCRIPT.md
git commit -m "feat(admin): allow all staff roles to view Users list"
```

---

## Spec coverage checklist

| Spec requirement | Task |
| --- | --- |
| `amlBanList` seed + types + Dart embed | Task 1 |
| list/add/lift ban + listCustomers | Task 1 |
| API + RBAC + sidebar | Task 2 |
| Ban page + honesty | Task 3 |
| Customers page + 360 link | Task 4 |
| Users view-all / mutate ADMIN | Task 5 |
| No payment auto-block | Global |
| Reset restores bans | Task 1 test |

## Placeholder / consistency scan

- Routes: `/dashboard/aml-ban-list`, `/dashboard/customers` — consistent
- Methods: `listAmlBanList`, `addAmlBanEntry`, `liftAmlBanEntry`, `listCustomers`
- Honesty string exact: `Offline demo — not a live sanctions feed`
