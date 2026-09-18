# Products & rules — Fee/Limit create + edit (maker-checker) — Design

**Date:** 2026-09-17  
**Status:** Approved (Approach A)  
**Surface:** `http://localhost:3001/dashboard/products`  
**Related:** DEM-02; existing `approvePending` FEE_CHANGE; Approvals at `/dashboard/approvals`

## Goal

Let staff **create and edit fee and limit rules** from Products & rules. New/changed rules land as **`PENDING_APPROVAL`** with a matching **`pendingApprovals`** row; activation happens only via **Pending approvals** Approve/Reject (maker-checker). Offline session only until **Reset demo**.

## Non-goals

- Create/edit **product catalog** rows (`products[]`)
- Persist into `universe.json`
- Change `/dashboard/config` beyond optional note that Products is the authoring surface for DEM-02
- Online/core-api fee APIs (offline-first; online may stub/throw)

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Where | `/dashboard/products` (not Config) |
| What | Fees (`kind: FEE`) + Limits (`kind: LIMIT`) |
| Apply path | Maker-checker: pending row → Approvals queue |
| Edit model | Clone ACTIVE → new pending superseder; do **not** mutate ACTIVE until Approve |
| Who | Roles that already see Products + Approvals: **ADMIN, OPS, FINANCE** (SUPPORT unchanged) |

## Current state

- Products page is **list-only** (products, fees, limits).
- `OfflineDemoStore.createFeeConfig` inserts an ACTIVE fee (no approval) — insufficient for DEM-02 story.
- `approvePending` already activates/supersedes on `type === 'FEE_CHANGE'`; **no** `LIMIT_CHANGE` branch yet.
- Seed example: `apr_fee_w2w_001` → `fee_w2w_pending` (`PENDING_APPROVAL`).

## UX

### Products page additions

1. **+ Fee rule** toggle form  
   Fields: `paymentType` (W2W | MNO | BANK | BILL), `feePercent`, `minFeeMinor`, `maxFeeMinor`, `currency` (optional/default USD), `effectiveFrom` (date, default today).  
   Submit → pending fee + approval; refresh tables; toast/alert with approval id.

2. **+ Limit rule** toggle form  
   Fields: `limitType` (e.g. CUSTOMER_DAILY), `currency`, `dailyLimitMinor`, `monthlyLimitMinor`, `effectiveFrom`.  
   Submit → pending limit + approval.

3. **Edit** on each ACTIVE fee/limit row  
   Opens form prefilled from the ACTIVE row. Submit → **new** pending fee/limit (new id) + approval summarizing the change. ACTIVE unchanged until Approve.

4. PENDING_APPROVAL / REJECTED / SUPERSEDED rows remain visible in the fee/limit tables (badges already exist for fees). No edit on non-ACTIVE (or Edit disabled).

5. Helper copy: “New and edited rules go to Pending approvals. Approve there to activate. Reset demo restores seed.”

### Approvals page

No new UI required if `listPendingApprovals` already shows all PENDING rows and Approve/Reject call `approvePending`. Extend store so **LIMIT_CHANGE** behaves like FEE_CHANGE (activate pending limit; supersede other ACTIVE limits of same `limitType`+`currency`).

## Data / store API

### Propose (replace bare ACTIVE create for this flow)

```ts
proposeFeeRule(data: {
  paymentType: string;
  feePercent: number;
  minFeeMinor: number;
  maxFeeMinor: number;
  currency?: string;
  effectiveFrom?: string;
  summary?: string;
  makerStaffId?: string;
  supersedesId?: string; // when editing an ACTIVE fee
}): { fee: FeeLimitView; approval: PendingApproval }

proposeLimitRule(data: {
  limitType: string;
  currency: string;
  dailyLimitMinor: number;
  monthlyLimitMinor: number;
  effectiveFrom?: string;
  summary?: string;
  makerStaffId?: string;
  supersedesId?: string;
}): { limit: FeeLimitView; approval: PendingApproval }
```

Behavior:

- Insert `feeLimits` row with `status: 'PENDING_APPROVAL'`, id `fee_demo_${Date.now()}` / `lim_demo_${Date.now()}`.
- Insert `pendingApprovals` with `type: 'FEE_CHANGE' | 'LIMIT_CHANGE'`, `targetId` = new row id, `status: 'PENDING'`, `makerStaffId` from current user when available (else `staff_admin`), `summary` human-readable.
- Do not change existing ACTIVE rows on propose.

### `approvePending` extension

When `apr.type === 'LIMIT_CHANGE'`:

- On APPROVE: set pending limit ACTIVE; set other ACTIVE limits with same `limitType` + `currency` to SUPERSEDED.
- On REJECT: set pending limit REJECTED.

FEE_CHANGE path unchanged.

### `api` offline

Wire `proposeFeeRule` / `proposeLimitRule` (names may match store). Keep or deprecate UI use of ACTIVE-only `createFeeConfig` on Products (Config page may still call it — out of scope to remove).

## Honesty / demo

- Works under **Offline demo — no live API**.
- **Reset demo** restores seed fees/limits/approvals.
- Do not claim live core-banking product factory.

## Acceptance

- [ ] ADMIN/OPS/FINANCE on Products can create a fee → appears PENDING_APPROVAL + new row on Approvals
- [ ] Approve on Approvals → fee ACTIVE; previous ACTIVE same paymentType SUPERSEDED
- [ ] Reject → pending fee REJECTED; ACTIVE unchanged
- [ ] Edit ACTIVE fee proposes superseder; same approve path
- [ ] Create/edit limit + LIMIT_CHANGE approve/reject works analogously
- [ ] SUPPORT does not gain new Products access
- [ ] Reset demo restores seed; no `:3000` calls

## Files likely touched

- `apps/admin_web/lib/offline/store.ts` (+ vitest)
- `apps/admin_web/lib/api.ts`
- `apps/admin_web/app/dashboard/products/page.tsx`
- Optional: `docs/demo/DEM-SCRIPT.md` DEM-02 step note for create-from-UI

## Open points (none blocking)

- `createFeeConfig` left as-is for Config/legacy; Products uses propose* only.
