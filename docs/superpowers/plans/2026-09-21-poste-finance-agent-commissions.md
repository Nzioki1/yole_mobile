# Agent Commission Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Accrue agent commissions on cash-in/out in the offline `agent_mobile` mock, show today’s totals on Home, and surface amounts on receipts and History.

**Architecture:** Inside `OfflineAgentRepository._moveCash`, after a successful post, write an `agentCommissions` row using `floor(principal × commissionBps / 10000)`. Expose summary + list helpers; wire Home, receipt, and History UI. No settle cycle.

**Tech Stack:** Flutter, `apps/agent_mobile`, `packages/demo_universe`, in-memory offline repository (no HTTP).

**Spec:** `docs/superpowers/specs/2026-09-21-poste-finance-agent-commissions-design.md`

## Global Constraints

- Offline mock only (`--dart-define=OFFLINE_DEMO=true` path).
- Branch: `cursor/task1-monorepo-scaffold-1d8a` (or current PR branch tip).
- Skip commission row when `commissionBps <= 0` or computed `commissionMinor == 0`.
- Default seed `commissionBps: 50` on each agent.
- Do not touch customer APK except if shared universe seed requires it.
- Keep Poste Finance branding; no offline demo banner.
- Commit after each task; run `flutter test` in `apps/agent_mobile`.

## File map

| File | Role |
|------|------|
| `packages/demo_universe/data/universe.json` | `commissionBps` on agents; `agentCommissions: []` |
| `apps/agent_mobile/lib/services/offline_agent_repository.dart` | Accrue + query APIs |
| `apps/agent_mobile/lib/services/agent_api_service.dart` | Offline wrappers |
| `apps/agent_mobile/lib/screens/agent_home_screen.dart` | Today’s commissions card |
| `apps/agent_mobile/lib/screens/cash_in_out_screen.dart` | Receipt commission line |
| `apps/agent_mobile/lib/screens/agent_history_screen.dart` | List + detail commission |
| `apps/agent_mobile/test/offline_agent_repository_test.dart` | Unit tests (extend) |

---

### Task 1: Seed + repository accrue/summary + tests

**Files:**
- Modify: `packages/demo_universe/data/universe.json`
- Modify: `apps/agent_mobile/lib/services/offline_agent_repository.dart`
- Modify: `apps/agent_mobile/test/offline_agent_repository_test.dart`

**Interfaces:**
- Produces: `_accrueCommission`, `listCommissionsToday`, `commissionSummaryToday`, receipt fields `commissionMinor` / `commissionBps` on `_moveCash` return

- [ ] **Step 1:** Add failing tests for floor math (10000×50→50), cash-in/out create rows, summary CDF/USD/count, skip when floors to 0
- [ ] **Step 2:** Run tests — expect fail
- [ ] **Step 3:** Add `commissionBps: 50` to each agent; add root `"agentCommissions": []`
- [ ] **Step 4:** Implement accrue at end of `_moveCash`; implement list/summary helpers (today = local calendar day of `createdAt`)
- [ ] **Step 5:** Run tests — expect pass
- [ ] **Step 6:** Commit `feat(agent): accrue commissions on cash-in/out`

---

### Task 2: AgentApiService offline branches

**Files:**
- Modify: `apps/agent_mobile/lib/services/agent_api_service.dart`

**Interfaces:**
- Consumes: `commissionSummaryToday`, cash receipt maps
- Produces: `Future<Map<String, dynamic>> getCommissionSummaryToday()`

- [ ] **Step 1:** Add offline `getCommissionSummaryToday()` routing to repository
- [ ] **Step 2:** Ensure cash-in/out API methods pass through commission fields from repository
- [ ] **Step 3:** Commit `feat(agent): expose commission summary via AgentApiService`

---

### Task 3: Home + receipt + History UI

**Files:**
- Modify: `apps/agent_mobile/lib/screens/agent_home_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/agent_history_screen.dart`

- [ ] **Step 1:** Home card “Today’s commissions” with CDF, USD, count; refresh with float load / pull-to-refresh; tap → History
- [ ] **Step 2:** Receipt dialog shows “Your commission: …” from response
- [ ] **Step 3:** History rows + detail sheet show commission (join by txnId/refId)
- [ ] **Step 4:** Smoke: `flutter test` still green
- [ ] **Step 5:** Commit `feat(agent): show commissions on Home, receipt, History`

---

### Task 4: Device verify notes

- [ ] Document Pixel checklist in commit message or short `apps/agent_mobile` note: login agent001 → cash-in Jean-Paul → Home CDF commission up → History/receipt match
- [ ] Commit if any polish fixes

---

## Done when

- Spec acceptance criteria §5 all met
- `flutter test` in `apps/agent_mobile` passes
- Commits pushed to branch
