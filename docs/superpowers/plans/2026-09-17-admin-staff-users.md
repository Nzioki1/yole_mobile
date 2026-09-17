# Admin Staff Users + Roles (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ADMIN-only `/dashboard/users` so staff can be created and assigned `ADMIN` | `OPS` | `SUPPORT` | `FINANCE` in the offline demo store (session until Reset).

**Architecture:** Extend `OfflineDemoStore` with `createStaff` / `updateStaffRole` and a password-stripped `listStaff`. Wire `api` offline branches, gate the route in `rbac.ts` (ADMIN only), add sidebar **Users**, and ship a Color Admin page mirroring Agents. Login already uses `authenticateStaff` against the same store array — no login rewrite.

**Tech Stack:** Next.js 15 App Router, TypeScript, Vitest, Color Admin Panel components, existing `StaffRole` / `authService`.

**Spec:** `docs/superpowers/specs/2026-09-17-admin-staff-users-design.md`

## Global Constraints

- Offline-first: mutations only when `NEXT_PUBLIC_OFFLINE_DEMO=true`; no dependency on `:3000`.
- Roles exactly: `ADMIN` | `OPS` | `SUPPORT` | `FINANCE` (match `StaffRole` enum).
- Only ADMIN may access `/dashboard/users`, create staff, or change roles.
- Never show passwords in the UI; `listStaff` must omit `password`.
- Cannot demote/change role away from the last remaining `ADMIN`.
- Default create password prefill: `Password1!`.
- Session JWT role updates only after re-login (document in UI helper text).
- **Reset demo** restores seed staff (created users disappear) — no `universe.json` write-back.
- User-visible brand remains Poste Finance; code paths may stay Yole.
- Phase 2 (corporate ↔ employer) is out of scope.

## File map

| File | Responsibility |
| --- | --- |
| `apps/admin_web/lib/offline/store.ts` | `createStaff`, `updateStaffRole`, password-stripped `listStaff` |
| `apps/admin_web/lib/offline/store.staff.test.ts` | Vitest for staff mutations |
| `apps/admin_web/lib/api.ts` | Offline `listStaff` / `createStaff` / `updateStaffRole` |
| `apps/admin_web/lib/rbac.ts` | Add `/dashboard/users` to `ModuleRoute` + ADMIN only |
| `apps/admin_web/components/sidebar/Sidebar.tsx` | Nav item **Users** under Configuration |
| `apps/admin_web/app/dashboard/users/page.tsx` | List + create form + role select |
| `docs/demo/DEM-SCRIPT.md` | Short optional walk note (fold into Task 4) |

---

### Task 1: OfflineDemoStore staff mutations (TDD)

**Files:**
- Create: `apps/admin_web/lib/offline/store.staff.test.ts`
- Modify: `apps/admin_web/lib/offline/store.ts` (methods near `listStaff` / `authenticateStaff` ~142–152)
- Test: `apps/admin_web/lib/offline/store.staff.test.ts`

**Interfaces:**
- Consumes: `OfflineDemoStore.createFresh()`, existing `Staff` from `demo_universe`
- Produces:
  - `listStaff(): Array<Omit<Staff, 'password'> & { password?: never }>` (no password field)
  - `createStaff(data: { firstName: string; lastName: string; email: string; password: string; role: string }): Omit<Staff, 'password'>`
  - `updateStaffRole(staffId: string, role: string): Omit<Staff, 'password'>`
  - `authenticateStaff` unchanged (still reads full `u.staff` including password)

- [ ] **Step 1: Write the failing tests**

```ts
import { OfflineDemoStore } from './store';

describe('OfflineDemoStore staff users', () => {
  test('listStaff omits password', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listStaff();
    expect(list.length).toBeGreaterThanOrEqual(4);
    for (const s of list) {
      expect(s).not.toHaveProperty('password');
      expect(s.email).toBeTruthy();
      expect(s.role).toBeTruthy();
    }
  });

  test('createStaff adds loginable OPS user', () => {
    const store = OfflineDemoStore.createFresh();
    const created = store.createStaff({
      firstName: 'Nova',
      lastName: 'Ops',
      email: 'nova.ops@postefinance.com',
      password: 'Password1!',
      role: 'OPS',
    });
    expect(created.id).toMatch(/^staff_demo_/);
    expect(created.role).toBe('OPS');
    expect(created).not.toHaveProperty('password');

    const auth = store.authenticateStaff('nova.ops@postefinance.com', 'Password1!');
    expect(auth?.id).toBe(created.id);
    expect(auth?.role).toBe('OPS');
  });

  test('createStaff rejects duplicate email case-insensitively', () => {
    const store = OfflineDemoStore.createFresh();
    expect(() =>
      store.createStaff({
        firstName: 'Dup',
        lastName: 'Admin',
        email: 'Admin@postefinance.com',
        password: 'Password1!',
        role: 'SUPPORT',
      }),
    ).toThrow(/already/i);
  });

  test('updateStaffRole changes role', () => {
    const store = OfflineDemoStore.createFresh();
    const created = store.createStaff({
      firstName: 'Sam',
      lastName: 'Support',
      email: 'sam.support@postefinance.com',
      password: 'Password1!',
      role: 'SUPPORT',
    });
    const updated = store.updateStaffRole(created.id, 'FINANCE');
    expect(updated.role).toBe('FINANCE');
    expect(store.listStaff().find((s) => s.id === created.id)?.role).toBe('FINANCE');
  });

  test('updateStaffRole refuses demoting the last ADMIN', () => {
    const store = OfflineDemoStore.createFresh();
    // Demote all ADMINs except one, then try to demote the last
    const admins = store.listStaff().filter((s) => s.role === 'ADMIN');
    expect(admins.length).toBeGreaterThanOrEqual(1);
    // Seed has exactly one ADMIN (staff_admin). Attempt demote.
    const onlyAdmin = admins[0];
    expect(() => store.updateStaffRole(onlyAdmin.id, 'OPS')).toThrow(/last.*ADMIN/i);
    expect(store.listStaff().find((s) => s.id === onlyAdmin.id)?.role).toBe('ADMIN');
  });

  test('reset restores seed staff (created users gone)', () => {
    const store = OfflineDemoStore.createFresh();
    store.createStaff({
      firstName: 'Temp',
      lastName: 'User',
      email: 'temp.user@postefinance.com',
      password: 'Password1!',
      role: 'OPS',
    });
    expect(store.listStaff().some((s) => s.email === 'temp.user@postefinance.com')).toBe(true);
    store.reset();
    expect(store.listStaff().some((s) => s.email === 'temp.user@postefinance.com')).toBe(false);
    expect(store.authenticateStaff('admin@postefinance.com', 'Password1!')?.role).toBe('ADMIN');
  });
});
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.staff.test.ts
```

Expected: FAIL (methods missing and/or `listStaff` still includes `password`).

- [ ] **Step 3: Implement store methods**

In `store.ts`, replace `listStaff` and add helpers after `authenticateStaff`:

```ts
private static readonly STAFF_ROLES = ['ADMIN', 'OPS', 'SUPPORT', 'FINANCE'] as const;

private stripStaffPassword(s: Staff): Omit<Staff, 'password'> {
  const { password: _p, ...rest } = s;
  return rest;
}

listStaff(): Omit<Staff, 'password'>[] {
  return this.u.staff.map((s) => this.stripStaffPassword(s));
}

createStaff(data: {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  role: string;
}): Omit<Staff, 'password'> {
  const email = data.email.trim().toLowerCase();
  const role = data.role.trim().toUpperCase();
  if (!OfflineDemoStore.STAFF_ROLES.includes(role as (typeof OfflineDemoStore.STAFF_ROLES)[number])) {
    throw new Error(`Invalid role: ${data.role}`);
  }
  if (!data.password || !data.firstName.trim() || !data.lastName.trim()) {
    throw new Error('firstName, lastName, and password are required');
  }
  if (this.u.staff.some((s) => s.email.toLowerCase() === email)) {
    throw new Error('Staff email already registered');
  }
  const staff: Staff = {
    id: `staff_demo_${Date.now()}`,
    email,
    password: data.password,
    role,
    firstName: data.firstName.trim(),
    lastName: data.lastName.trim(),
  };
  this.u.staff.push(staff);
  return this.stripStaffPassword(staff);
}

updateStaffRole(staffId: string, role: string): Omit<Staff, 'password'> {
  const next = role.trim().toUpperCase();
  if (!OfflineDemoStore.STAFF_ROLES.includes(next as (typeof OfflineDemoStore.STAFF_ROLES)[number])) {
    throw new Error(`Invalid role: ${role}`);
  }
  const staff = this.u.staff.find((s) => s.id === staffId);
  if (!staff) throw new Error(`Staff not found: ${staffId}`);
  if (staff.role === 'ADMIN' && next !== 'ADMIN') {
    const adminCount = this.u.staff.filter((s) => s.role === 'ADMIN').length;
    if (adminCount <= 1) {
      throw new Error('Cannot demote the last ADMIN');
    }
  }
  staff.role = next;
  return this.stripStaffPassword(staff);
}
```

Keep `authenticateStaff` reading `this.u.staff` (with passwords) unchanged.

Confirm `reset()` already reloads universe (existing) so the reset test passes without new reset code.

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.staff.test.ts
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/admin_web/lib/offline/store.ts apps/admin_web/lib/offline/store.staff.test.ts
git commit -m "feat(admin): offline createStaff + updateStaffRole with last-ADMIN guard"
```

---

### Task 2: API + RBAC + sidebar

**Files:**
- Modify: `apps/admin_web/lib/api.ts` (near `listAgents` / `enrollAgent`)
- Modify: `apps/admin_web/lib/rbac.ts`
- Modify: `apps/admin_web/components/sidebar/Sidebar.tsx`
- Test: manual + existing vitest still green; optional thin api not required

**Interfaces:**
- Consumes: store methods from Task 1
- Produces:
  - `api.listStaff()`, `api.createStaff(...)`, `api.updateStaffRole(staffId, role)`
  - `ModuleRoute` includes `'/dashboard/users'`
  - `ROLE_PERMISSIONS[StaffRole.ADMIN]` includes `'/dashboard/users'` only (not OPS/SUPPORT/FINANCE)

- [ ] **Step 1: Add api methods**

In `api.ts` class (same offline branching style as agents):

```ts
async listStaff() {
  if (OFFLINE_DEMO) return this.store().listStaff();
  throw new Error('listStaff is only available in offline demo');
}

async createStaff(data: {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  role: string;
}) {
  if (OFFLINE_DEMO) return this.store().createStaff(data);
  throw new Error('createStaff is only available in offline demo');
}

async updateStaffRole(staffId: string, role: string) {
  if (OFFLINE_DEMO) return this.store().updateStaffRole(staffId, role);
  throw new Error('updateStaffRole is only available in offline demo');
}
```

- [ ] **Step 2: Gate RBAC**

In `rbac.ts`:

1. Add `'/dashboard/users'` to `ModuleRoute` union.
2. Add `'/dashboard/users'` to `ALL_ADMIN` array (ADMIN gets it via `ALL_ADMIN`).
3. Do **not** add it to OPS, SUPPORT, or FINANCE arrays.

- [ ] **Step 3: Sidebar nav**

In `Sidebar.tsx` Configuration group, add:

```ts
{
  title: 'Configuration',
  items: [
    { name: 'Users', href: '/dashboard/users', icon: 'fa fa-user-shield' },
    { name: 'Fees & Limits', href: '/dashboard/config', icon: 'fa fa-cog' },
  ],
},
```

Existing `canAccess` filter hides **Users** from non-ADMIN automatically.

- [ ] **Step 4: Sanity check vitest**

```bash
cd apps/admin_web && pnpm exec vitest run lib/offline/store.staff.test.ts lib/offline/store.mutations.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/admin_web/lib/api.ts apps/admin_web/lib/rbac.ts apps/admin_web/components/sidebar/Sidebar.tsx
git commit -m "feat(admin): Users API + ADMIN-only RBAC and sidebar link"
```

---

### Task 3: `/dashboard/users` page

**Files:**
- Create: `apps/admin_web/app/dashboard/users/page.tsx`
- Modify (optional one-liner): `docs/demo/DEM-SCRIPT.md` — add Users under admin URLs if a DEM table exists; otherwise skip

**Interfaces:**
- Consumes: `api.listStaff`, `api.createStaff`, `api.updateStaffRole`, `authService.getCurrentUser`, `StaffRole`
- Produces: working ADMIN page at `http://localhost:3001/dashboard/users`

- [ ] **Step 1: Create page** (Agents pattern)

```tsx
'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { authService, StaffRole } from '@/lib/auth';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

const ROLES: StaffRole[] = [
  StaffRole.ADMIN,
  StaffRole.OPS,
  StaffRole.SUPPORT,
  StaffRole.FINANCE,
];

type StaffRow = {
  id: string;
  email: string;
  role: string;
  firstName?: string;
  lastName?: string;
};

export default function UsersPage() {
  const router = useRouter();
  const [staff, setStaff] = useState<StaffRow[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: 'Password1!',
    role: StaffRole.OPS as string,
  });

  useEffect(() => {
    const user = authService.getCurrentUser();
    if (!user || user.role !== StaffRole.ADMIN) {
      router.replace('/dashboard');
      return;
    }
    loadStaff();
  }, [router]);

  const loadStaff = async () => {
    try {
      const data = await api.listStaff();
      setStaff(Array.isArray(data) ? data : []);
      setError(null);
    } catch (e) {
      setError(String(e));
    }
  };

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    try {
      await api.createStaff(formData);
      setShowForm(false);
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        password: 'Password1!',
        role: StaffRole.OPS,
      });
      await loadStaff();
    } catch (err) {
      setError(String(err));
    }
  };

  const handleRoleChange = async (staffId: string, role: string) => {
    try {
      await api.updateStaffRole(staffId, role);
      await loadStaff();
    } catch (err) {
      setError(String(err));
      await loadStaff();
    }
  };

  return (
    <div>
      <p className="text-muted small mb-3">
        Offline demo staff. Role changes apply to login on next sign-in.
        Cannot demote the last ADMIN. Reset demo restores seed users.
      </p>
      {error && (
        <div className="alert alert-danger py-2" role="alert">
          {error}
        </div>
      )}
      <div className="mb-3">
        <button className="btn btn-theme" type="button" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancel' : '+ Create staff'}
        </button>
      </div>

      {showForm && (
        <Panel>
          <PanelHeader>Create staff</PanelHeader>
          <PanelBody>
            <form onSubmit={handleCreate} className="row g-3">
              <div className="col-md-6">
                <input
                  className="form-control"
                  placeholder="First name"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <input
                  className="form-control"
                  placeholder="Last name"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <input
                  className="form-control"
                  type="email"
                  placeholder="Email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <input
                  className="form-control"
                  type="text"
                  placeholder="Password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <select
                  className="form-select"
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                >
                  {ROLES.map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </div>
              <div className="col-12">
                <button type="submit" className="btn btn-success">
                  Create staff
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>{staff.length} Staff</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped table-hover mb-0 align-middle">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>ID</th>
                </tr>
              </thead>
              <tbody>
                {staff.map((row) => (
                  <tr key={row.id}>
                    <td className="fw-semibold">
                      {row.firstName} {row.lastName}
                    </td>
                    <td>{row.email}</td>
                    <td style={{ minWidth: 140 }}>
                      <select
                        className="form-select form-select-sm"
                        value={row.role}
                        onChange={(e) => handleRoleChange(row.id, e.target.value)}
                      >
                        {ROLES.map((r) => (
                          <option key={r} value={r}>
                            {r}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td className="font-monospace small">{row.id}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </PanelBody>
      </Panel>
    </div>
  );
}
```

- [ ] **Step 2: Manual acceptance (browser)**

With admin already on `:3001` and `NEXT_PUBLIC_OFFLINE_DEMO=true`:

1. Login `admin@postefinance.com` / `Password1!` → sidebar shows **Users**.
2. Open `/dashboard/users` → see ≥4 seed staff; no passwords.
3. Create `nova.ops@postefinance.com` / `Password1!` / OPS → appears in list.
4. Logout → login as nova → sidebar has OPS routes; **Users** hidden; `/dashboard/users` redirects to `/dashboard`.
5. Re-login as admin → change nova to FINANCE → list updates.
6. Try changing the sole ADMIN to OPS → error; role stays ADMIN.
7. **Reset demo** → nova gone; seed four restored.

- [ ] **Step 3: Optional DEM-SCRIPT one-liner**

Under admin URLs table in `docs/demo/DEM-SCRIPT.md`, add:

`| — | `/dashboard/users` | Users (ADMIN) |`

- [ ] **Step 4: Commit**

```bash
git add apps/admin_web/app/dashboard/users/page.tsx docs/demo/DEM-SCRIPT.md
git commit -m "feat(admin): Users page for create staff and change roles"
```

- [ ] **Step 5: Push when user asks** (do not force-push)

```bash
git push origin HEAD
```

---

## Spec coverage checklist (self-review)

| Spec requirement | Task |
| --- | --- |
| `/dashboard/users` Agents-like UI | Task 3 |
| ADMIN-only sidebar + URL bounce | Tasks 2–3 |
| List without passwords | Task 1 `listStaff` + Task 3 |
| Create staff + default password | Tasks 1 + 3 |
| Change role dropdown | Tasks 1 + 3 |
| Last ADMIN guard | Task 1 |
| Session until Reset | Task 1 reset test |
| No universe.json write-back | Global / no task writes seed |
| Re-login note for own role | Task 3 helper copy |
| Offline / no `:3000` | api offline-only throws online |
| Phase 2 out of scope | Global Constraints |

## Placeholder / consistency scan

- No TBD/TODO left in steps.
- Method names consistent: `createStaff`, `updateStaffRole`, `listStaff`.
- Role strings match `StaffRole` enum values.
