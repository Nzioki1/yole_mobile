# Poste Finance Admin Operations Shell Design

**Date:** 2026-09-17  
**Status:** Approved  
**Type:** Layout & Navigation Infrastructure

## Overview

Full back-office shell with classic left sidebar and grouped navigation. This is a layout-only shell that wraps existing module page logic without redesigning internal functionality.

## Design Principles

- **Classic ops layout:** Fixed left sidebar (~240px) with grouped navigation
- **Non-invasive:** Preserve existing module page logic and functionality
- **Progressive enhancement:** Light home page polish to show meaningful data instead of zeros
- **Intentional styling:** Clean, professional look using existing Tailwind utilities

## Layout Structure

### Left Sidebar
- **Width:** ~240px fixed
- **Colors:** slate/white theme
- **Brand:** "Poste Finance Admin" mark at top
- **Navigation groups:**
  - **Overview** → `/dashboard`
  - **Customers**
    - Customer 360 → `/dashboard/customer360`
    - KYC Queue → `/dashboard/kyc`
    - Agents → `/dashboard/agents`
  - **Money Movement**
    - Payments Search → `/dashboard/payments`
    - Cards → `/dashboard/cards`
    - Payroll → `/dashboard/payroll`
  - **Operations**
    - Reconciliation → `/dashboard/recon`
    - Cases → `/dashboard/cases`
  - **Configuration**
    - Fees & Limits → `/dashboard/config`
- **Active state:** Highlight current route using `usePathname()`

### Top Bar
- **Page title:** Derived from current route
- **API indicator:** Chip showing `localhost:3000` (or `NEXT_PUBLIC_API_BASE_URL`)
- **Auth hint:** Display `dev-admin-key` as current auth mode

### Main Content Area
- Renders `{children}` from nested pages
- Clean background, proper padding
- No fighting with page-level styling

## Module Page Updates

### Chrome Removal
Strip duplicate full-viewport wrappers from module pages:
- Remove `min-h-screen bg-gray-100` containers that conflict with shell
- Keep page-level headings where useful, or rely on top-bar title
- Preserve all page functionality (forms, tables, buttons, etc.)

### Affected Pages
- `/dashboard/agents/page.tsx`
- `/dashboard/kyc/page.tsx`
- `/dashboard/payments/page.tsx`
- `/dashboard/cards/page.tsx`
- `/dashboard/payroll/page.tsx`
- `/dashboard/recon/page.tsx`
- `/dashboard/cases/page.tsx`
- `/dashboard/config/page.tsx`
- `/dashboard/customer360/page.tsx`

## Home Page Polish

### Current State
Stub with zero counts that don't reflect real data.

### Enhancement
- **Aggregate counts** from existing client methods where possible:
  - `listAgents()` → total agents
  - `listKycSubmissions('PENDING_REVIEW')` → pending KYC
  - `searchPayments()` → recent payments count
  - `listCases()` → open cases
  - `listCards()` → active cards
  - `listEmployers()` → payroll employers
- **Graceful degradation:** Show "—" if endpoint fails, don't crash
- **Primary nav:** Sidebar is primary; home shows KPI cards + optional recent shortcuts
- **Optional API enhancement:** Consider thin `GET /v1/admin/dashboard/summary` in core-api for aggregated counts (only if client aggregation is ugly; prefer client-first)

## Technical Implementation

### Path Alias Configuration
Ensure `apps/admin_web/tsconfig.json` includes:
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

### Styling Approach
- Use existing Tailwind utilities
- Minimal custom CSS only where needed for intentional sidebar appearance
- No heavy UI kit introduction

## Out of Scope

❌ Real admin authentication/login flow  
❌ Chart libraries or complex visualizations  
❌ Remittance/FX admin list pages (no APIs exist)  
❌ Redesigning module internal forms or workflows  
❌ Mobile responsive sidebar (desktop-first for ops tools)

## Migration Path

1. Create layout component with sidebar + top bar
2. Update tsconfig.json with path aliases
3. Strip duplicate chrome from module pages
4. Polish home page with real data aggregation
5. Test all routes render correctly within shell
6. Deploy behind feature flag if needed (or direct to dev environment)

## Success Criteria

- [x] All navigation routes accessible from sidebar
- [x] Active route visually indicated
- [x] Page titles derive from route automatically
- [x] Module pages render without layout conflicts
- [x] Home page shows meaningful counts (not zeros)
- [x] Clean, professional appearance
- [x] No broken functionality in existing modules
