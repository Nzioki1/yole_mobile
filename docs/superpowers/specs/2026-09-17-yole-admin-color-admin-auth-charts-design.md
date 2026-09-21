# Poste Finance Admin: Color Admin Redesign with Staff Auth & Charts

**Date**: 2026-09-17  
**Target**: Branch `cursor/task1-monorepo-scaffold-1d8a` (PR #1)  
**Status**: Implementation  

## Overview

Transform Poste Finance Admin from a basic dev UI into a production-ready staff tool with:
- **Color Admin default+teal skin** (professional bank-grade look)
- **Staff JWT authentication** with role-based access control
- **Interactive dashboard** with KPI widgets and drill-down charts

## Design System

### Theme: Color Admin v5.5.2 — default + teal
- **Skin**: `default` (not dark mode)
- **Primary theme**: `#00acac` (teal)
- **Secondary accent**: `#348fe2` (blue)
- **Theme class**: `app-theme-teal`
- **Gradient**: teal → blue for highlight elements

### Reference materials
- `THEME_NOTES.md` — token definitions
- `css/default/app.min.css` — compiled CSS (vendored selectively)
- `nextjs-sample/` — React component patterns for sidebar, header, panel, login-v2, dashboard-v3

### Licensing approach
Adapt Color Admin patterns into `apps/admin_web`. Use:
- CSS tokens + shell structure
- Class naming conventions (`.app-sidebar`, `.app-header`, `.panel`, etc.)
- Login-v2 and dashboard-v3 layouts

**DO NOT** vendor entire Color Admin plugin tree (POS, calendar, email, etc.). Keep only:
- Core shell CSS (sidebar, header, panel, forms)
- Teal theme tokens
- Login page styles

## 1. Staff Authentication

### Backend: `/v1/admin/auth/*`

#### Endpoints
```
POST /v1/admin/auth/login
  Body: { email, password }
  Returns: { accessToken, user: { id, email, role } }

GET /v1/admin/auth/me
  Headers: Authorization: Bearer <token>
  Returns: { id, email, role }
```

#### Staff roles & permissions
```typescript
enum StaffRole {
  ADMIN = 'ADMIN',       // All access
  OPS = 'OPS',           // Operations focus
  SUPPORT = 'SUPPORT',   // Customer support
  FINANCE = 'FINANCE'    // Financial operations
}
```

**Route access matrix**:
| Module | ADMIN | OPS | SUPPORT | FINANCE |
|--------|-------|-----|---------|---------|
| Dashboard | Full | Full | Limited KPIs | Money KPIs |
| Customer 360 | ✓ | - | ✓ | - |
| KYC Queue | ✓ | ✓ | - | - |
| Agents | ✓ | ✓ | - | - |
| Payments | ✓ | ✓ | - | ✓ |
| Cards | ✓ | - | - | ✓ |
| Payroll | ✓ | - | - | ✓ |
| Fees & Limits | ✓ | - | - | ✓ |
| Recon | ✓ | ✓ | - | ✓ |
| Cases | ✓ | ✓ | ✓ | - |
| Config | ✓ | - | - | - |

#### Seed users (in-memory mock)
```typescript
const STAFF_USERS = [
  { id: 'admin-001', email: 'admin@yole.com', password: 'Password1!', role: 'ADMIN' },
  { id: 'ops-001', email: 'ops@yole.com', password: 'Password1!', role: 'OPS' },
  { id: 'support-001', email: 'support@yole.com', password: 'Password1!', role: 'SUPPORT' },
  { id: 'finance-001', email: 'finance@yole.com', password: 'Password1!', role: 'FINANCE' },
];
```

Password: `Password1!` for all demo accounts.

#### Implementation constraints
- **In-memory only** (no database persistence)
- JWT signing with existing NestJS `@nestjs/jwt`
- Separate guard from customer auth (`AdminJwtAuthGuard`)
- Replace sole reliance on `X-Admin-API-Key` for web UI (API key may remain for scripts)

### Frontend: `/login` → `/dashboard`

#### Login page
- Route: `/login` (Color Admin login-v2 style)
- Email + password form
- Store JWT in `localStorage` or secure cookie
- Redirect to `/dashboard` on success

#### Route protection
- Middleware: check JWT presence & validity
- Redirect to `/login` if unauthenticated
- Show 403 or redirect if role lacks access to deep-linked route

#### Navigation filtering
- Hide nav items user's role cannot access
- E.g. SUPPORT user sees: Overview, Customer 360, Cases only

## 2. Color Admin Shell

### Layout structure
```
apps/admin_web/
  app/
    login/
      page.tsx              # Color Admin login-v2 style
    dashboard/
      layout.tsx            # Color Admin sidebar + header shell
      page.tsx              # Home charts (upgraded)
      [existing modules]/   # Wrapped in panels
  components/
    sidebar/
      Sidebar.tsx
      SidebarNav.tsx
      SidebarProfile.tsx
    header/
      Header.tsx
      ProfileDropdown.tsx
  styles/
    color-admin-yole.css    # Trimmed Color Admin CSS + teal tokens
```

### Key components
- **Sidebar**: Color Admin `.app-sidebar` with teal accent, collapsible, profile widget
- **Header**: `.app-header` with breadcrumb, search, profile dropdown
- **Panel**: Card-like `.panel .panel-heading .panel-body` wrapper for module pages
- **Forms**: Bootstrap form-floating, buttons with `.btn-theme`

## 3. Dashboard Home: Charts & Drill-Down

### KPI Widgets (top row)
- **Pending KYC** → link to `/dashboard/kyc?status=PENDING_REVIEW`
- **Open Cases** → link to `/dashboard/cases?status=OPEN`
- **Payments Today** → link to `/dashboard/payments?dateFrom=today`
- **Active Agents** → link to `/dashboard/agents`

### Charts
1. **Payment Status Distribution** (donut chart)
   - Segments: COMPLETED, PENDING, FAILED
   - Click segment → `/dashboard/payments?status=X`

2. **Payment Types Last 7 Days** (bar chart)
   - Types: CASHIN, CASHOUT, TRANSFER, PAYROLL
   - Click bar → `/dashboard/payments?type=X&dateFrom=-7d`

3. **KYC Queue Trend** (line chart, optional)
   - Show pending/approved/rejected over last 30 days

### Chart library
- **recharts** (recommended: lightweight, responsive, good TypeScript support)
- Alternative: Chart.js (if team prefers canvas-based)

### Data source
- **Option A**: New endpoint `GET /v1/admin/dashboard/summary`
  - Returns: `{ kpis: {...}, paymentsByStatus: [...], paymentsByType: [...] }`
- **Option B**: Client-side aggregation of existing list endpoints
  - Use existing `searchPayments`, `listKycSubmissions`, `listCases`

### Module list updates
- Payments, KYC, Cases pages honor query params (`?status=`, `?type=`, etc.)
- Filter lists based on URL params if easy to implement

## 4. Out of Scope (Phase 1)

- ❌ Database persistence for staff users
- ❌ Staff user CRUD UI
- ❌ Audit logging (note: audit hooks should be marked for future integration)
- ❌ Color Admin POS/calendar/email/gallery modules
- ❌ Multi-tenancy or organization switching
- ❌ Advanced charts (heatmaps, pivot tables)
- ❌ Export to Excel/PDF
- ❌ Real-time notifications

## 5. Technical Constraints

### Monorepo hygiene
- Stay on branch `cursor/task1-monorepo-scaffold-1d8a`
- Do not break existing module functionality
- Keep mocks in-memory (no new database tables)

### Dependency additions allowed
- `recharts` or `chart.js` (charting)
- `jwt-decode` (frontend JWT parsing)
- `react-perfect-scrollbar` (Color Admin sidebar scroll, if not already present)

### Git commits (suggested)
1. `docs: admin Color Admin auth+charts design`
2. `feat(api): staff JWT auth and roles`
3. `feat(admin): Color Admin teal shell, login, home charts`

## 6. Acceptance Criteria

### Authentication
- ✅ Login at `/login` with seed credentials
- ✅ JWT stored and included in API requests
- ✅ Unauthenticated users redirected to login
- ✅ `/dashboard/layout.tsx` shows user email and role

### Authorization
- ✅ Nav menu filtered by role
- ✅ 403 or redirect on unauthorized route access
- ✅ SUPPORT user sees only allowed modules

### Color Admin Theme
- ✅ Teal accent on sidebar active items, buttons
- ✅ Professional bank-grade look (no bright emojis unless existing)
- ✅ Responsive sidebar (collapse on mobile)
- ✅ Module pages wrapped in `.panel` cards

### Dashboard Charts
- ✅ 4+ KPI widgets with live counts
- ✅ 2–3 interactive charts (donut, bar, line)
- ✅ Clicking KPI/chart navigates to filtered module page
- ✅ Charts display real data from API (even if mocked)

### Run & Test
- ✅ `pnpm dev` starts core-api (`:3000`) and admin_web (`:3001` or `:3000`)
- ✅ Can log in as each role and see appropriate UI
- ✅ Charts render without errors

## 7. Risks & Assumptions

### Risks
- **Color Admin CSS conflicts**: Vendored CSS may override Tailwind. Mitigation: namespace or use scoped imports.
- **Chart performance**: Large datasets may slow rendering. Mitigation: limit to last 30 days or paginate.
- **Role drift**: If roles expand, RBAC matrix needs maintenance. Mitigation: centralize role definitions.

### Assumptions
- Current API endpoints return JSON arrays that can be aggregated client-side (or new summary endpoint is trivial to add)
- JWT secret already configured in NestJS (reuse identity module's JWT setup)
- Frontend can decode JWT to get role without server roundtrip (or calls `/me` once)

## 8. Files to Modify/Create

### Backend (`services/core-api`)
- `src/modules/admin/admin.module.ts` — register auth sub-module
- `src/modules/admin/auth/admin-auth.controller.ts` — NEW: staff login/me endpoints
- `src/modules/admin/auth/admin-auth.service.ts` — NEW: staff user lookup, JWT sign
- `src/modules/admin/auth/admin-jwt.guard.ts` — NEW: Bearer JWT guard for admin
- `src/modules/admin/auth/staff-roles.enum.ts` — NEW: role definitions
- `src/modules/admin/admin.controller.ts` — add dashboard summary endpoint (optional)

### Frontend (`apps/admin_web`)
- `app/login/page.tsx` — NEW: Color Admin login-v2
- `app/dashboard/layout.tsx` — REFACTOR: Color Admin shell
- `app/dashboard/page.tsx` — UPGRADE: add charts
- `components/sidebar/` — NEW: Sidebar, SidebarNav, SidebarProfile
- `components/header/` — NEW: Header, ProfileDropdown
- `lib/auth.ts` — NEW: JWT storage, decode, role helpers
- `lib/rbac.ts` — NEW: role → routes map
- `styles/color-admin-yole.css` — NEW: trimmed Color Admin CSS + teal tokens
- `public/` — copy any required Color Admin assets (fonts, icons)

## 9. Testing Plan

### Manual testing checklist
1. **Login flow**
   - [ ] Visit `/login`, enter `admin@yole.com` / `Password1!`, redirects to `/dashboard`
   - [ ] Invalid credentials show error
   - [ ] Logout clears token, redirects to `/login`

2. **RBAC**
   - [ ] Login as SUPPORT, see only: Overview, Customer 360, Cases
   - [ ] Attempt to visit `/dashboard/kyc`, gets 403 or redirect
   - [ ] Login as FINANCE, see money modules

3. **Charts**
   - [ ] Dashboard shows 4 KPI widgets with non-zero counts (if data exists)
   - [ ] Donut chart renders, click segment navigates with `?status=`
   - [ ] Bar chart renders, click bar navigates with `?type=`

4. **Styling**
   - [ ] Sidebar has teal active state
   - [ ] Buttons use teal theme
   - [ ] Mobile: sidebar collapses, burger menu works

### Automated tests (optional, future)
- Unit: `admin-auth.service.spec.ts` (JWT sign, role validation)
- E2E: `admin-auth.e2e-spec.ts` (login, protected routes)

## 10. Report Format

```
Status: DONE | DONE_WITH_CONCERNS | BLOCKED

Commits:
- docs: admin Color Admin auth+charts design (abc1234)
- feat(api): staff JWT auth and roles (def5678)
- feat(admin): Color Admin teal shell, login, home charts (ghi9012)

Pushed to: origin/cursor/task1-monorepo-scaffold-1d8a
Remote tip: ghi9012

Seed credentials:
- admin@yole.com / Password1!
- ops@yole.com / Password1!
- support@yole.com / Password1!
- finance@yole.com / Password1!

How to run:
1. cd services/core-api && pnpm dev  # runs on :3000
2. cd apps/admin_web && pnpm dev      # runs on :3001 (or check package.json)
3. Visit http://localhost:3001/login

Files changed: X files
Backend: Y files (auth, dashboard)
Frontend: Z files (login, layout, charts, components)

Concerns (if any):
- Note any known issues or follow-up needed
```

---

**Approved for implementation**: Yes  
**Merge strategy**: Squash to `cursor/task1-monorepo-scaffold-1d8a`, then PR to main
