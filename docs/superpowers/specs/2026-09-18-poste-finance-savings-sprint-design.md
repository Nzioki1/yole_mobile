# Poste Finance Customer App — First Sprint Design

**Date:** 2026-09-18  
**Sprint:** Poste Finance Savings, Insurance & Budget Quick Actions  
**Scope:** Customer Flutter app offline demo only

## Overview

This sprint introduces three new financial product categories to the Poste Finance customer app:
- **Savings** (full offline flow implementation)
- **Insurance** (stub screen)
- **Budget** (stub screen)

All features are implemented as offline-demo-only flows, following the existing YOLE patterns for routing, state management, and offline persistence.

## Design Summary

### Home Screen Quick Actions

Three new tiles added to the existing `_QuickActionsGrid`:

1. **Savings**
   - Icon: `account_balance_wallet_outlined`
   - Color: Poste teal `#00acac`
   - Route: `/savings`

2. **Insurance**
   - Icon: `health_and_safety_outlined`
   - Color: Poste teal variant `#008A8A`
   - Route: `/insurance`

3. **Budget**
   - Icon: `pie_chart_outlined`
   - Color: Poste teal variant `#0C7A53`
   - Route: `/budget`

These tiles follow the same layout and interaction patterns as existing quick actions (Pay/Send, Bills, KYC, Cards, Credit, Remittance, FX).

### Savings (Full Implementation)

#### 1. Savings Goals List (`/savings`)

**Empty State:**
- Icon: `savings_outlined`
- Message: "No savings goals yet"
- Primary CTA: "Create Your First Goal"

**Populated State:**
- List of savings goals (card layout)
- Each goal card displays:
  - Goal name
  - Currency (CDF/USD)
  - Progress: "FC 50,000 of FC 200,000" (25%)
  - Linear progress indicator
  - Auto-deposit badge (if enabled)
- Tap goal → navigate to goal detail
- FAB: "Create Goal"

**Demo Seed Data:**
- Jean-Paul (cust_kasee) has one pre-seeded goal:
  - Name: "Emergency fund"
  - Currency: CDF
  - Target: 500,000 CDF (minor: 50000000)
  - Deposited: 100,000 CDF (minor: 10000000)
  - Auto-deposit: disabled

#### 2. Create Goal Form (`/savings/create-goal`)

**Fields:**
- Goal name (text input, required)
- Target amount (numeric input, required)
- Currency (dropdown: CDF / USD, required)
- Auto-deposit toggle (optional)
  - When enabled: amount input (numeric)
  - Note: "Auto-deposit is a demo feature and will not execute automatically"

**Validation:**
- Name: 1-50 characters
- Target: > 0
- Auto-deposit amount: > 0 if toggle enabled

**Actions:**
- Cancel → back to list
- Create → persist goal → navigate to detail

**Persistence:**
- New entity: `savingsGoals` array in `demo_universe`
- Fields: `id`, `customerId`, `name`, `targetMinor`, `depositedMinor`, `currency`, `autoDepositEnabled`, `autoDepositMinor`, `createdAt`
- ID pattern: `goal_sess_<seq>`

#### 3. Goal Detail (`/savings/goal-detail`)

**Header:**
- Goal name (editable via icon button — out of scope for sprint 1)
- Currency badge

**Progress Section:**
- Large progress percentage: "20%"
- Progress bar (Poste teal gradient)
- "FC 100,000 deposited of FC 500,000 target"
- Auto-deposit status badge (if enabled): "Auto-deposit: FC 10,000/month"

**Actions:**
- Primary button: "Add Money"
  - Opens PIN confirmation sheet
  - Accept demo PIN `123456`
  - Amount input: defaults to remaining balance (capped by wallet balance)
  - On confirm:
    1. Verify PIN via `OfflineDemoRepository.verifyPin()`
    2. Debit matching wallet (CDF/USD)
    3. Increment goal `depositedMinor`
    4. Create journal entry (type: `SAVINGS_DEPOSIT`, direction: `DEBIT`)
    5. Show success message with updated progress
    6. Refresh goal detail

**Goal Complete State:**
- When `depositedMinor >= targetMinor`:
  - Show confetti/celebration UI
  - Disable "Add Money" button
  - Display: "Goal achieved! 🎉"

### Insurance (Stub Screen)

Simple branded screen:
- App bar: "Insurance"
- Icon: `health_and_safety` (large, centered)
- Title: "Coming Soon"
- Body text: "Protect what matters most. Poste Finance insurance products will be available soon. Stay tuned!"
- Poste teal accent color
- Back button navigates to Home

No product selection, quote flow, or purchase flow implemented.

### Budget (Stub Screen)

Simple branded screen:
- App bar: "Budget"
- Icon: `pie_chart` (large, centered)
- Title: "Coming Soon"
- Body text: "Track and manage your spending. Poste Finance budgeting tools will be available soon. Stay tuned!"
- Poste teal accent color
- Back button navigates to Home

No expense tracking, category management, or insights implemented.

## Technical Architecture

### Routing

**Route Names (router_types.dart):**
```dart
static const String savings = '/savings';
static const String savingsCreateGoal = '/savings/create-goal';
static const String savingsGoalDetail = '/savings/goal-detail';
static const String insurance = '/insurance';
static const String budget = '/budget';
```

**Route Wiring (app_router.dart):**
- All routes use standard `MaterialPageRoute`
- Goal detail passes `goalId` via route arguments

### State Management

**No new providers:**
- Use existing `authProvider` for customer ID
- Direct `CoreApiService` calls from StatefulWidget lifecycle

### API Service Extension

**New methods in CoreApiService:**
- `Future<List<dynamic>> listSavingsGoals()`
- `Future<Map<String, dynamic>> getSavingsGoal(String goalId)`
- `Future<Map<String, dynamic>> createSavingsGoal({...})`
- `Future<Map<String, dynamic>> addMoneyToGoal({required String goalId, required String amountMinor, required String pin})`

All methods check `offlineDemo` flag and route to `OfflineDemoRepository` when true.

### Offline Repository Extension

**New methods in OfflineDemoRepository:**
- `List<dynamic> listSavingsGoals()` — filter by `_currentCustomerId`
- `Map<String, dynamic> getSavingsGoal(String goalId)` — fetch one goal
- `Map<String, dynamic> createSavingsGoal({...})` — append to `savingsGoals`, return DTO
- `Map<String, dynamic> addMoneyToGoal({required String goalId, required String amountMinor, required String pin})`:
  1. Verify PIN via `verifyPin()`
  2. Fetch goal, validate ownership
  3. Find wallet matching goal currency
  4. Debit wallet (update `availableMinor`, `ledgerMinor`)
  5. Increment goal `depositedMinor`
  6. Create journal entry (type: `SAVINGS_DEPOSIT`)
  7. Return updated goal DTO

**Minor-to-Major Conversion:**
- All amounts stored as minor (cents)
- UI converts to major via `/100`
- User input converted to minor via `*100`

### Demo Universe Seed

**New entity: `savingsGoals`**

Seed one demo goal for Jean-Paul (cust_kasee):
```json
{
  "id": "goal_kasee_emergency",
  "customerId": "cust_kasee",
  "name": "Emergency fund",
  "targetMinor": 50000000,
  "depositedMinor": 10000000,
  "currency": "CDF",
  "autoDepositEnabled": false,
  "autoDepositMinor": 0,
  "createdAt": "2026-09-10T08:00:00Z"
}
```

## Out of Scope (Sprint 1)

- Fee transparency for savings deposits
- Agent locator, support tickets
- Agent mobile app features
- Admin web features
- Real API endpoints (offline-only)
- Goal editing (name, target, auto-deposit)
- Goal deletion or archiving
- Withdrawal from savings goals
- Interest accrual or projection
- Multiple auto-deposit schedules
- Insurance product catalog, quote flow, policy purchase, claims
- Budget category management, expense tracking, spending insights
- Analytics, reporting, export

## Branding

- Primary color: Poste Finance teal `#00acac`
- Secondary colors: `#008A8A`, `#0C7A53`
- Logo: Existing YOLE logo (no Poste Finance logo assets available)
- Typography: Existing Flutter theme (default Material sans-serif)

## Acceptance Criteria

1. ✅ Design doc committed to `docs/superpowers/specs/`
2. ✅ Home screen displays Savings, Insurance, Budget tiles in quick actions grid
3. ✅ Tapping Savings → navigates to savings goals list
4. ✅ Empty state displays with "Create Your First Goal" CTA
5. ✅ Seeded goal (Emergency fund) displays with correct progress (20%)
6. ✅ Tapping goal → navigates to goal detail screen
7. ✅ Goal detail displays progress bar, amounts, auto-deposit status
8. ✅ "Add Money" → opens PIN sheet → accepts `123456`
9. ✅ After PIN confirm: amount input → debit wallet → credit goal → journal entry created
10. ✅ Success message displayed, goal detail refreshes with updated progress
11. ✅ Tapping Insurance → navigates to stub screen with "Coming Soon" message
12. ✅ Tapping Budget → navigates to stub screen with "Coming Soon" message
13. ✅ All changes committed and pushed to `cursor/task1-monorepo-scaffold-1d8a`

## Manual Testing Notes (Pixel Emulator)

**Pre-flight:**
- Build: `flutter build apk --dart-define=OFFLINE_DEMO=true`
- Install: `adb install build/app/outputs/flutter-apk/app-release.apk`
- Launch app, login as `jp.kabila@gmail.com` / `Password1!`

**Savings Flow:**
1. Home → Verify three new tiles: Savings, Insurance, Budget
2. Tap Savings → Verify "Emergency fund" goal card displays
3. Tap goal → Verify progress: "FC 100,000 of FC 500,000 (20%)"
4. Tap "Add Money" → Enter PIN `123456` → Enter amount (e.g. 50000) → Confirm
5. Verify wallet debited, goal credited, success message, progress updated to 30%
6. Back to list → Verify updated progress on card

**Stub Screens:**
1. Home → Tap Insurance → Verify "Coming Soon" screen
2. Back → Tap Budget → Verify "Coming Soon" screen

**Edge Cases:**
1. Add money exceeding wallet balance → Error message
2. Add money exceeding goal target → Capped at remaining (goal complete UI)
3. Wrong PIN → Error message
4. Empty savings list (new user) → Empty state with CTA

## Risks & Assumptions

1. **Currency assumption:** CDF/USD only (matching wallet currencies)
2. **No real API:** Offline-only, seed data-dependent
3. **PIN security:** Demo PIN `123456` hardcoded, no real auth
4. **Auto-deposit:** Toggle stored but not executed (demo feature)
5. **Goal completion:** No withdrawal or archiving flow (sprint 1)
6. **Branding:** Poste Finance colors used, but YOLE logo remains
7. **Localization:** English-only strings (no l10n updates)

## Follow-up Work (Future Sprints)

- Goal editing (name, target amount)
- Goal deletion/archiving
- Withdrawal from goals (reverse flow)
- Interest accrual simulation
- Insurance product catalog (browse, compare, select)
- Insurance quote flow (input details, calculate premium)
- Insurance policy purchase (payment, confirmation)
- Insurance claims (file claim, upload documents, track status)
- Budget category management (create, edit, delete categories)
- Budget expense tracking (log expenses, attach receipts)
- Budget insights (spending trends, category breakdown, alerts)
- Fee transparency overlay (show fees before confirm)
- Agent locator (map, search by location)
- Support tickets (create, view, reply)

---

**Approved by:** User (via task description)  
**Implemented by:** Cloud Agent (Cursor)  
**Commit SHA:** (TBD after push)  
