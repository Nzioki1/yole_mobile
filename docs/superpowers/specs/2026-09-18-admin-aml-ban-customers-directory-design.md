# Admin AML Ban List + Customers Directory + Staff Users View — Design

**Date:** 2026-09-18  
**Status:** Approved  
**Product:** Poste Finance offline admin (`apps/admin_web`)  
**Depends on:** Offline demo universe, existing `listStaff` / Users page, Customer 360

## Goal

Give operators three clear lists:

1. **AML ban list** — parties not allowed to transact (demo watchlist / ban entries).
2. **Internal users** — all staff (existing Users page; **view** for all staff roles; create/role-change stays ADMIN-only).
3. **Customers** — all app customers with a jump into Customer 360.

## Non-goals

- Live sanctions / OFAC / world-check feed
- Automatic payment blocking from the ban list (can follow later)
- Corporate customer ↔ employer attach (Phase 2, separate)
- Writing ban entries back to production systems

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Shipping shape | Three nav surfaces (not one tabbed page) |
| Ban route | `/dashboard/aml-ban-list` |
| Customers route | `/dashboard/customers` |
| Staff | Keep `/dashboard/users`; widen **read** to ADMIN/OPS/SUPPORT/FINANCE; mutate ADMIN-only |
| Seed | New `amlBanList[]` in `universe.json` (+ Dart embed regen) |
| Honesty | Ban page shows offline demo disclaimer (not a live sanctions feed) |

## 1. Data — `amlBanList`

Add to `packages/demo_universe/data/universe.json` and TypeScript `Universe` / Dart types:

```ts
interface AmlBanEntry {
  id: string;
  fullName: string;
  idRef?: string;           // national id / passport / entity reg
  matchType: 'NAME' | 'ID' | 'ENTITY';
  reason: string;
  sourceList: string;       // e.g. DEMO_SANCTIONS, INTERNAL_FRAUD
  status: 'BANNED' | 'LIFTED';
  notes?: string;
  createdAt: string;
}
```

Seed **4–5** `BANNED` rows (fictional DRC/demo names — not real persons), plus optionally one `LIFTED` for contrast.

Regenerate `packages/demo_universe/dart/lib/universe_json.dart` from JSON (existing node embed script).

### Store / API

```ts
listAmlBanList(): AmlBanEntry[]
addAmlBanEntry(data: Omit<AmlBanEntry, 'id' | 'createdAt' | 'status'> & { status?: 'BANNED' }): AmlBanEntry
// optional for demo:
liftAmlBanEntry(id: string): AmlBanEntry  // status → LIFTED
```

Offline `api` mirrors these. Online: throw / stub offline-only.

## 2. Page — AML ban list

**Path:** `/dashboard/aml-ban-list`  
**Sidebar:** Operations group — **AML ban list** (icon e.g. `fa fa-ban`)  
**RBAC:** add route to ADMIN, OPS, SUPPORT, FINANCE (view + add for all those; YAGNI fine-grained SoD for demo).

UI (Color Admin Panel):

- Honesty strip: `Offline demo — not a live sanctions feed`
- Table columns: Name | ID/ref | Match | Reason | Source | Status | Added
- **+ Add to ban list** form: fullName, idRef, matchType, reason, sourceList (default DEMO_SANCTIONS)
- Optional **Lift** on BANNED rows → LIFTED
- Reset demo restores seed bans

## 3. Page — Customers directory

**Path:** `/dashboard/customers`  
**Sidebar:** Customers group — **Customers** (above Customer 360)  
**RBAC:** same as Customer 360 (ADMIN + SUPPORT today; also add OPS/FINANCE if useful for demo — **include ADMIN, OPS, SUPPORT, FINANCE** so payroll/ops can browse).

### Store / API

```ts
listCustomers(): Array<Omit<Customer, 'password'>>
```

UI:

- Table: ID | Name | Email | Phone | Segment | KYC | Status
- Action: **Open 360** → `/dashboard/customer360` (prefill query `?id=` or document paste — prefer `?customerId=` if Customer 360 can read search params; else copy id + link to 360)
- Passwords never shown
- No create-customer on this page (agent enroll / customer register remain the create paths)

### Customer 360 deep link

If `customer360/page.tsx` uses local state for id input only, add reading `useSearchParams().get('customerId')` on mount to auto-load. Small additive change in same delivery.

## 4. Enhance — Users (staff)

**Path:** `/dashboard/users` (unchanged URL)

| Capability | Who |
| --- | --- |
| View staff list | ADMIN, OPS, SUPPORT, FINANCE |
| Create staff / change role | ADMIN only (existing) |

RBAC: add `/dashboard/users` to OPS, SUPPORT, FINANCE route arrays (view). Page already redirects non-ADMIN away — **change guard** so non-ADMIN can view but hide create form + role `<select>` (show role as badge only).

Hydration: keep auth-after-mount pattern (already fixed on Header/Sidebar).

## 5. DEM / docs

- Short note in `docs/demo/DEM-SCRIPT.md`: AML ban list URL; customers directory; staff Users view.
- Optional DEM-09 cross-link: ban list complements confidential AML case workflow (not a replacement).

## Acceptance

- [ ] `/dashboard/aml-ban-list` lists seeded bans; Add works session-only; Reset restores
- [ ] Honesty string visible on ban page
- [ ] `/dashboard/customers` lists all seed customers without passwords; Open 360 works
- [ ] OPS (non-ADMIN) can open Users list but cannot create/change role
- [ ] ADMIN retains create/role-change on Users
- [ ] Sidebar items gated by RBAC; no `:3000` calls
- [ ] Dart universe embed regenerated after JSON seed change

## Files likely touched

- `packages/demo_universe/data/universe.json` (+ types TS/Dart + embed)
- `apps/admin_web/lib/offline/store.ts` (+ tests)
- `apps/admin_web/lib/api.ts`
- `apps/admin_web/lib/rbac.ts`
- `apps/admin_web/components/sidebar/Sidebar.tsx`
- `apps/admin_web/app/dashboard/aml-ban-list/page.tsx` (new)
- `apps/admin_web/app/dashboard/customers/page.tsx` (new)
- `apps/admin_web/app/dashboard/users/page.tsx` (view vs mutate)
- `apps/admin_web/app/dashboard/customer360/page.tsx` (optional `customerId` query)
- `apps/admin_web/app/dashboard/layout.tsx` (page titles)
- `docs/demo/DEM-SCRIPT.md`

## Open points (none blocking)

- Auto-block payments when counterparty matches ban list — **out of scope** this delivery.
