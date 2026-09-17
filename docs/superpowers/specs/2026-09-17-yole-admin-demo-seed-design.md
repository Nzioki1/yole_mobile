# YOLE Admin Demo Seed

## Goal
Demo the admin portal end-to-end without depending on the mock API.

## Approach
- `NEXT_PUBLIC_DEMO_SEED=true` (default in `.env.local`) short-circuits `apps/admin_web/lib/api.ts` to `lib/demo-seed.ts`.
- Staff login uses local seed credentials and mints an unsigned JWT the client can decode for RBAC.
- Header shows a **Demo data** badge.
- Set `NEXT_PUBLIC_DEMO_SEED=false` to restore live API calls (with empty/fail fallback still available in most methods).

## Seed credentials
Password for all: `Password1!`
- admin@yole.com (ADMIN)
- ops@yole.com (OPS)
- support@yole.com (SUPPORT)
- finance@yole.com (FINANCE)

## Demo customer IDs
- cust_kasee, cust_amina, cust_jean, cust_grace (quick-picks on Customer 360)

## Covered modules
Overview KPIs/charts, Payments, KYC, Agents, Cases, Cards, Payroll employers, Fees & Limits, Recon, Customer 360.
