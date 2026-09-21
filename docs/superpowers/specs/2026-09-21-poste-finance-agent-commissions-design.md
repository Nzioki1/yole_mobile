# Poste Finance Agent Commission Tracking Design

**Date:** 2026-09-21  
**Status:** Approved (Approach A)  
**App:** `apps/agent_mobile` offline mock only  
**Depends on:** Agent mock P0 (login, home/float, cash-in/out, history)

## 1. Overview

Agents earn a commission on each successful cash-in and cash-out. The offline demo accrues commission ledger rows at post time, shows today’s totals on Agent Home, and surfaces the amount on cash receipts and History.

### 1.1 Approved decisions

- **Approach A:** Accrue on each cash-in/out (not display-only estimate; not full settle cycle).
- **Math:** `commissionMinor = floor(principalMinor × commissionBps / 10000)`.
- **Default seed:** `commissionBps: 50` (0.5%) on each agent.
- **Separate from customer fees:** Fees stay as today; commission is agent earnings on principal.
- **Currencies:** CDF and USD tracked separately; Home shows both.
- **Period:** Today only for this pass (calendar day in device local / box local Africa/Nairobi). No settle button.

### 1.2 Out of scope

- Assisted bill pay / airtime commissions
- Float top-up, EOD declaration, agent locator
- Multi-day history filters / pagination for commissions
- Settling commission into float or payout wallet
- Live API / HTTP commission endpoints

## 2. Screens and flow

### 2.1 Agent Home

- New card **Today’s commissions** below float balances.
- Shows: CDF total (formatted), USD total, transaction count.
- Tap → navigate to History (today’s list; commission visible on rows).

### 2.2 Cash-in / cash-out receipt

- After successful PIN + post, receipt dialog adds line:  
  `Your commission: FC X` or `$ X` (matching txn currency).
- Amount must match the ledger row written for that `txnId`.

### 2.3 History list

- Each `AGENT_CASH_IN` / `AGENT_CASH_OUT` row shows a secondary line:  
  `Commission: …` when a matching `agentCommissions` row exists.

### 2.4 History detail sheet

- Fields: principal, fee (customer), **commission**, **bps used**, currency, time, customer, reference.

## 3. Data model

### 3.1 Agent seed (`universe.json`)

On each agent object add:

```json
"commissionBps": 50
```

### 3.2 Universe root collection

```json
"agentCommissions": []
```

Runtime-only growth in the in-memory `OfflineAgentRepository` (same pattern as session journals / agent transactions).

### 3.3 Commission row shape

| Field | Type | Notes |
|-------|------|--------|
| `id` | string | e.g. `acm_…` via `_nextId` |
| `agentId` | string | Current agent |
| `txnId` | string | Links to agent transaction / journal `refId` |
| `customerId` | string | Counterparty |
| `type` | `AGENT_CASH_IN` \| `AGENT_CASH_OUT` | Same as cash move |
| `currency` | `CDF` \| `USD` | |
| `principalMinor` | int | Amount moved (not fee) |
| `commissionMinor` | int | Floor of principal × bps / 10000 |
| `bps` | int | Snapshot of agent `commissionBps` at post |
| `createdAt` | ISO-8601 UTC | |

### 3.4 Math rules

- Missing / null `commissionBps` → treat as `0` (no row or zero commission; prefer still writing row with 0 only if principal posted — **decision: skip row when bps ≤ 0 or commissionMinor == 0** to keep History clean).
- Floor toward zero for positive amounts (`~/` in Dart after multiply).
- Do not accrue on enroll or failed PIN attempts.

## 4. Architecture

### 4.1 `OfflineAgentRepository`

- `_accrueCommission(...)` invoked at end of successful `_moveCash` after journal/txn ids exist.
- `listCommissionsToday({String? currency})` — filter by `_currentAgentId` and local calendar day of `createdAt`.
- `commissionSummaryToday()` → `{ 'cdfMinor': int, 'usdMinor': int, 'count': int }`.
- Cash receipt return map includes `commissionMinor` and `commissionBps` (string/int consistent with existing `amountMinor` string style where applicable).

### 4.2 `AgentApiService`

- Offline-only:
  - `getCommissionSummaryToday()`
  - Receipt fields already on cash-in/out responses
- Online: `UnimplementedError` or omit until backend exists.

### 4.3 UI wiring

- `agent_home_screen.dart` — load summary with float refresh / pull-to-refresh.
- `cash_in_out_screen.dart` — receipt uses response `commissionMinor`.
- `agent_history_screen.dart` — join commissions by `txnId` / `refId` for list + detail.

### 4.4 Tests

- Floor math: e.g. 10000 minor × 50 bps → 50; small principals that floor to 0 → no row.
- Cash-in and cash-out each create one commission row with correct type/currency.
- `commissionSummaryToday` aggregates CDF/USD and count.
- Empty day → zeros.

## 5. Acceptance criteria

1. Seed agents have `commissionBps: 50`.
2. Successful CDF cash-in for Jean-Paul accrues a commission row; Home “Today’s commissions” CDF increases by that amount.
3. Receipt and History show the same commission for that txn.
4. USD cash path accrues USD commission independently.
5. App restart clears in-memory commissions (same offline mock lifetime as other session mutations).
6. Unit tests above pass under `apps/agent_mobile`.

## 6. Implementation notes

- Regenerate `packages/demo_universe/dart` only if the package requires typed fields; otherwise dynamic `_list('agentCommissions')` is enough (preferred for parity with journals).
- Branding: reuse Poste teal; no new demo banners.
- French i18n deferred.

---

**End of design**
