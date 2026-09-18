# Admin Staff Users + Roles (Phase 1) — Design

**Date:** 2026-09-17  
**Status:** Approved for spec (Approach A)  
**Product:** Poste Finance offline admin (`apps/admin_web`)  
**Depends on:** Offline demo universe (`NEXT_PUBLIC_OFFLINE_DEMO=true`), existing `StaffRole` RBAC

## Goal

Let an **ADMIN** create internal staff users and attach them to roles (`ADMIN` | `OPS` | `SUPPORT` | `FINANCE`) from the admin UI, without calling core-api.

## Non-goals (Phase 1)

- Delete staff / deactivate
- Password reset / MFA
- Persisting creates into `packages/demo_universe/data/universe.json`
- Audit trail beyond offline store mutation
- Corporate customer ↔ employer attach (**Phase 2**, separate design)

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Surface | `/dashboard/users` (Agents-like Panel UI) |
| Who creates / changes roles | **ADMIN only** |
| Persistence | Session offline store until **Reset demo** |
| Roles | Existing enum only — no custom roles |
| Last ADMIN | Cannot demote or role-change away the last remaining `ADMIN` |

## Current state

- Seed staff live in `universe.json` → `staff[]` (4 users: admin/ops/support/finance).
- `OfflineDemoStore.listStaff()` / `authenticateStaff()` exist; **no** `createStaff` / `updateStaffRole`.
- `ROLE_PERMISSIONS` in `apps/admin_web/lib/rbac.ts` gates sidebar routes; no `/dashboard/users` yet.
- Login already authenticates against store staff email + password.

## UX

### Nav

- Sidebar group (e.g. Overview or Config): **Users** → `/dashboard/users`
- Visible only when `canAccessRoute(role, '/dashboard/users')` — **ADMIN only**
- Direct URL as non-ADMIN → redirect to `/dashboard`

### List

Columns: Name | Email | Role (badge) | Staff ID  
Never display password.

### Create staff

Toggle form (same pattern as Agents enroll):

- firstName, lastName (required)
- email (required, unique case-insensitive)
- password (required; default prefill `Password1!` for demo convenience)
- role select: `ADMIN` | `OPS` | `SUPPORT` | `FINANCE`

Submit → create → refresh list. New credentials work on `/login` in the same browser session (same offline store).

### Change role

Per-row `<select>` of roles. On change → `updateStaffRole(id, role)`.

- If target is the sole remaining `ADMIN` and new role ≠ `ADMIN` → reject with clear error.
- Short helper text: changing your own role may lock you out of Users until another ADMIN restores you (demo honesty).

## Data / API (offline)

### Store (`OfflineDemoStore`)

```ts
createStaff(data: {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  role: 'ADMIN' | 'OPS' | 'SUPPORT' | 'FINANCE';
}): Staff  // omit password from return shape used by UI list if desired; login still uses store password

updateStaffRole(staffId: string, role: StaffRole): Staff
```

Rules:

- `createStaff`: trim email; reject if email already exists; id = `staff_demo_${Date.now()}` (or sequential); push onto `u.staff`.
- `updateStaffRole`: validate role; enforce last-ADMIN guard; mutate in place.
- `listStaff()` for UI: return staff **without** password field (map strip).

### `api` client

When `OFFLINE_DEMO`:

- `listStaff()` → store
- `createStaff(...)` → store
- `updateStaffRole(...)` → store  

Online path: out of scope for Phase 1 (may stub throw or no-op); page is demo-first.

### RBAC

- Add `'/dashboard/users'` to `ModuleRoute` and **only** `ROLE_PERMISSIONS[ADMIN]`.
- Page client guard: if `user.role !== ADMIN` → `router.replace('/dashboard')`.

## Honesty / demo behavior

- Global badge remains `Offline demo — no live API`.
- Created staff vanish on **Reset demo** (reload from universe seed).
- Cheat-sheet / permanent personas still authored in `universe.json` when needed for print.

## Acceptance

- [ ] ADMIN sees **Users** in sidebar; OPS/SUPPORT/FINANCE do not
- [ ] ADMIN creates staff with each role; duplicate email rejected
- [ ] New OPS user can log in and sees OPS-scoped nav only
- [ ] Role change updates badge and affects nav after re-login (or soft refresh of auth claims if token embeds role — see note)
- [ ] Cannot remove the last ADMIN role
- [ ] Reset demo restores original four seed staff
- [ ] No requests to `:3000` during the walk

### Auth token note

Staff JWT / session today embeds `role` at login (`mintDemoStaffToken`). After `updateStaffRole`, **existing session keeps old role until re-login** unless we refresh the stored user. Phase 1 acceptance: document “re-login to apply role change to your own session”; list UI shows updated role immediately from store.

## Phase 2 preview (not in this build)

Payroll UI to create `CORPORATE` customers + `employees[]` rows linked to an employer (`emp_poste`, etc.). Separate design after Phase 1 ships.

## Files likely touched

- `apps/admin_web/app/dashboard/users/page.tsx` (new)
- `apps/admin_web/components/sidebar/Sidebar.tsx`
- `apps/admin_web/lib/rbac.ts`
- `apps/admin_web/lib/offline/store.ts` (+ tests)
- `apps/admin_web/lib/api.ts`
- Optional: short note in `docs/demo/DEM-SCRIPT.md` (Users walk)

## Open points (none blocking)

- Default password prefill vs empty field — **prefill `Password1!`** for demo speed (locked above).
