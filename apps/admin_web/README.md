# YOLE Admin Web

Admin dashboard for YOLE platform built with Next.js 14, TypeScript, and Tailwind CSS.

## Features

- **Dashboard**: Overview with counts for customers, payments, KYC, agents
- **Customer 360**: Full customer view with wallets and transactions
- **KYC Queue**: Review and approve/reject KYC submissions
- **Agent Management**: Enroll and manage field agents
- **Payments Search**: Filter and view payment transactions
- **Fees & Limits Config**: Configure payment fees and transaction limits
- **Payroll**: Manage employers and salary disbursements
- **Recon & Cases**: Daily reconciliation and AML case management

## Running

### Development

```bash
cd apps/admin_web
pnpm install
pnpm dev
```

Admin UI runs on `http://localhost:3001` (or next available port)

### Configuration

Set API base URL:

```bash
# .env.local
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
```

### Login

Default admin API key: `dev-admin-key`

This is the Phase 1 simple API key guard. In production, implement proper admin authentication.

## API Integration

All endpoints use `X-Admin-API-Key` header for authentication.

Backend must be running:
```bash
cd services/core-api
pnpm dev
```

## Architecture

- **Client-side rendering** for all admin pages (use client directive)
- **API client** in `lib/api.ts` handles all backend communication
- **No database** - all data from core-api in-memory stores
- **Tailwind CSS** for styling

## Production Build

```bash
pnpm build
pnpm start
```
