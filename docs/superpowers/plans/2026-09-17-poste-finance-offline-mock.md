# Poste Finance Offline Mock (Customer Core Banking) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter customer app a fully offline Poste Finance demo on Android for core banking (home/wallets, pay/send/withdraw, history, profile) using the existing seed + `OfflineDemoRepository`, without touching `apps/admin_web`.

**Architecture:** The repo already gates `CoreApiService` on `--dart-define=OFFLINE_DEMO=true` into `OfflineDemoRepository`, which loads `packages/demo_universe` (`universe.json` / embedded `kUniverseJson`). This plan finishes branding, login friction, favorites, docs, and tests for the approved v1 scope — it does **not** reinvent the mock layer.

**Tech Stack:** Flutter, Riverpod, `demo_universe` (path package), `flutter_test`, existing `CoreApiService` / `OfflineDemoRepository`.
    10|
## Global Constraints

- Do **not** modify any file under `apps/admin_web/`.
- Do **not** require `services/core-api` for the demo path when `OFFLINE_DEMO=true`.
- Product name in user-visible UI: **Poste Finance**; keep existing YOLE colors/layout (`lib/main.dart` themes).
- Market: DRC — CDF + USD; seed customer `cust_kasee` (`kasee.demo@yole.com` / `Password1!`) is the default demo persona.
- Canonical flag is **`OFFLINE_DEMO`** (already in code). Treat design-doc `USE_MOCK_DATA` as the same intent; do not introduce a second competing flag unless aliasing both to the same const.
- Spec: `docs/superpowers/specs/2026-09-17-poste-finance-offline-mock-design.md`.
- YAGNI: cards/credit/remittance/FX already offline via the same gate; do not expand their UX unless a core-banking screen is broken by them.
    20|
### File map (create / modify)

| Path | Role |
|------|------|
| `lib/services/core_api_service.dart` | Existing `offlineDemo` gate — only touch if alias/`bool.fromEnvironment` needs dual name |
| `lib/services/offline_demo_repository.dart` | Existing mock repo — extend tests / tiny helpers only |
| `packages/demo_universe/dart/assets/universe.json` | Seed source of truth (edit carefully; regenerate embedded JSON if package requires it) |
| `packages/demo_universe/dart/lib/universe_json.dart` | Regenerated embedded seed after JSON edits |
| `lib/providers/favorites_provider.dart` | Seed Congolese favorites for Pay/Send |
    30|| `lib/screens/splash_screen.dart`, `welcome_screen.dart`, `login_screen.dart` (and `login_screen_fixed.dart` if still routed) | Poste Finance copy + offline login UX |
| `lib/main.dart` | Already `title: 'Poste Finance'` — verify only |
| `lib/l10n/*.arb` (if present) | Replace user-visible YOLE product strings with Poste Finance where they are product name |
| `README_FLUTTER.md` | Document offline Android run + demo credentials |
| `test/offline_demo_repository_test.dart` | Expand unit coverage |

---

### Task 1: Confirm offline gate + document the flag

    40|**Files:**
- Modify: `README_FLUTTER.md`
- Modify (only if needed): `lib/services/core_api_service.dart`
- Test: `test/offline_demo_repository_test.dart` (smoke that `createFresh` loads)

**Interfaces:**
- Consumes: `CoreApiService.offlineDemo` (`bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false)`)
- Produces: documented run command for physical Android

- [ ] **Step 1: Verify the gate exists**
    50|
Open `lib/services/core_api_service.dart` and confirm:

```dart
static const bool offlineDemo =
    bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false);
```

Do **not** rename to `USE_MOCK_DATA`. Optionally accept both by OR-ing a second define **only if** product insists; default plan: keep `OFFLINE_DEMO` only and note the alias in README.

    60|- [ ] **Step 2: Write failing doc assertion via README section**

Add a section to `README_FLUTTER.md` titled `## Offline Poste Finance demo (Android)` containing at least:

```markdown
## Offline Poste Finance demo (Android)

Run without core-api:

```bash
    70|flutter run -d <android-device-id> --dart-define=OFFLINE_DEMO=true
```

Demo login (seeded customer `cust_kasee`):

- Email: `kasee.demo@yole.com`
- Password: `Password1!`

Wallets: CDF + USD with non-zero balances. History and pay flows use in-memory session state; restart resets to seed.
```
    80|
- [ ] **Step 3: Smoke test seed load still passes**

Run:

```bash
flutter test test/offline_demo_repository_test.dart
```

Expected: PASS (`walletsFor('cust_kasee')` length 2).
    90|
- [ ] **Step 4: Commit**

```bash
git add README_FLUTTER.md
git commit -m "docs: document OFFLINE_DEMO Android run for Poste Finance"
```

---

   100|### Task 2: Expand offline repository tests (TDD for session payments)

**Files:**
- Modify: `test/offline_demo_repository_test.dart`
- Modify only if tests reveal bugs: `lib/services/offline_demo_repository.dart`

**Interfaces:**
- Consumes: `OfflineDemoRepository.createFresh()`, `login`, `getMyWallets`, `quotePayment`, `confirmPayment`, `listPayments`
- Produces: proven in-memory debit + history prepend for W2W

   110|- [ ] **Step 1: Write failing tests**

Replace/extend `test/offline_demo_repository_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/services/offline_demo_repository.dart';

void main() {
  late OfflineDemoRepository repo;
   120|
  setUp(() {
    repo = OfflineDemoRepository.createFresh();
  });

  test("walletsFor('cust_kasee') length 2", () {
    expect(repo.walletsFor('cust_kasee'), hasLength(2));
  });

  test('login as kasee then getMyWallets has CDF and USD', () {
   130|    repo.login(email: 'kasee.demo@yole.com', password: 'Password1!');
    final wallets = (repo.getMyWallets()['wallets'] as List)
        .cast<Map<String, dynamic>>();
    final currencies = wallets.map((w) => w['currency']).toSet();
    expect(currencies, containsAll(['CDF', 'USD']));
    final usd = wallets.firstWhere((w) => w['currency'] == 'USD');
    expect(int.parse(usd['availableMinor'].toString()), greaterThan(0));
  });

  test('confirmPayment debits USD wallet and lists payment', () {
   140|    repo.login(email: 'kasee.demo@yole.com', password: 'Password1!');
    final before = (repo.getMyWallets()['wallets'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((w) => w['currency'] == 'USD');
    final beforeAvail = int.parse(before['availableMinor'].toString());

    final quote = repo.quotePayment(
      type: 'W2W',
      currency: 'USD',
      amountMinor: '1000',
   150|      metadata: {'destCustomerId': 'cust_jp_kabila'},
    );
    final paymentId = quote['paymentId'] as String;
    final confirmed = repo.confirmPayment(paymentId: paymentId);
    expect(confirmed['status'], 'POSTED');

    final after = (repo.getMyWallets()['wallets'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((w) => w['currency'] == 'USD');
    final afterAvail = int.parse(after['availableMinor'].toString());
   160|    final fee = int.parse(confirmed['feeMinor'].toString());
    expect(afterAvail, beforeAvail - 1000 - fee);

    final list = repo.listPayments();
    expect(list.any((p) => (p as Map)['id'] == paymentId), isTrue);
  });

  test('createFresh resets session mutations', () {
    repo.login(email: 'kasee.demo@yole.com', password: 'Password1!');
    final quote = repo.quotePayment(
   170|      type: 'W2W',
      currency: 'USD',
      amountMinor: '1000',
    );
    repo.confirmPayment(paymentId: quote['paymentId'] as String);
    final mutated = OfflineDemoRepository.instance;
    final mid = (mutated.getMyWallets()['wallets'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((w) => w['currency'] == 'USD');
    final midAvail = int.parse(mid['availableMinor'].toString());
   180|
    final fresh = OfflineDemoRepository.createFresh();
    fresh.login(email: 'kasee.demo@yole.com', password: 'Password1!');
    final reset = (fresh.getMyWallets()['wallets'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((w) => w['currency'] == 'USD');
    final resetAvail = int.parse(reset['availableMinor'].toString());
    expect(resetAvail, greaterThan(midAvail));
  });
}
   190|```

- [ ] **Step 2: Run tests — expect FAIL only if implementation bugs**

```bash
flutter test test/offline_demo_repository_test.dart
```

If FAIL, fix the smallest bug in `offline_demo_repository.dart` (do not rewrite the class).

   200|- [ ] **Step 3: Re-run until PASS**

```bash
flutter test test/offline_demo_repository_test.dart
```

Expected: all PASS.

- [ ] **Step 4: Commit**

   210|```bash
git add test/offline_demo_repository_test.dart lib/services/offline_demo_repository.dart
git commit -m "test: cover offline demo login wallets and payment debit"
```

---

### Task 3: Poste Finance branding on splash / welcome / login

**Files:**
   220|- Modify: `lib/screens/splash_screen.dart`
- Modify: `lib/screens/welcome_screen.dart`
- Modify: `lib/screens/login_screen.dart` (and `login_screen_fixed.dart` if `app_router.dart` still routes to it)
- Optionally: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` for product-name strings only
- Verify: `lib/main.dart` already has `title: 'Poste Finance'`

**Interfaces:**
- Consumes: router routes `/splash`, welcome, login
- Produces: user-visible product name Poste Finance on cold start path

   230|- [ ] **Step 1: Inventory YOLE product-name strings on the cold-start path**

Search under `lib/screens/` and `lib/l10n/` for user-visible `Yole` / `YOLE` / `Yole Mobile` used as the **product name** (not package identifiers). List hits; change only product-name copy.

- [ ] **Step 2: Update splash / welcome / login copy**

Examples of acceptable replacements:

- App heading: `Poste Finance`
- Subtitle may keep existing layout; avoid inventing new marketing slogans
   240|- Do **not** change theme colors in `lib/main.dart`

- [ ] **Step 3: Offline login hint on login screen when `CoreApiService.offlineDemo`**

On the login screen used by the router, when offline demo is on, show a small helper text (not a modal):

```dart
if (CoreApiService.offlineDemo)
  Text(
    'Offline demo — kasee.demo@yole.com / Password1!',
   250|    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall,
  ),
```

Prefer showing credentials over inventing auto-login unless splash already auto-navigates authenticated users and you can set session from seed with ≤20 lines. Spec prefers auto-login if clean; credentials hint is the acceptable fallback.

- [ ] **Step 4: Manual sanity**

```bash
   260|flutter analyze lib/screens/splash_screen.dart lib/screens/welcome_screen.dart lib/screens/login_screen.dart
```

Expected: no new errors in those files.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/splash_screen.dart lib/screens/welcome_screen.dart lib/screens/login_screen.dart lib/l10n/
git commit -m "feat: Poste Finance branding on splash welcome login"
   270|```

---

### Task 4: Seed favorites for Pay/Send (Congolese contacts)

**Files:**
- Modify: `lib/providers/favorites_provider.dart`

**Interfaces:**
   280|- Consumes: existing favorites model used by send/pay screens
- Produces: 3–5 DRC contacts available offline without device contacts permission

- [ ] **Step 1: Read current favorites seed**

Open `lib/providers/favorites_provider.dart`. Note current hardcoded Marie/Joseph/Grace (or similar).

- [ ] **Step 2: Align favorites with seed universe contacts**

Ensure at least these appear (names/phones consistent with `universe.json` where possible):
   290|
```dart
// Example shape — match the existing Favorite model fields exactly
Favorite(name: 'Jean-Paul Kabila', phone: '+243990123456'),
Favorite(name: 'Marie Tshala', phone: '+243991234567'),
Favorite(name: 'Amina Payroll', phone: '+243990000002'),
```

Keep 3–5 entries. Do not require contacts permission for the offline demo path.

   300|- [ ] **Step 3: Commit**

```bash
git add lib/providers/favorites_provider.dart
git commit -m "feat: seed Congolese favorites for offline Pay/Send"
```

---

### Task 5: Core screens offline smoke checklist (home, pay, history, profile)
   310|
**Files:**
- Modify only if broken: `lib/screens/home_screen.dart`, payment/send/withdraw screens, `lib/screens/transactions_history_screen.dart`, `lib/screens/profile_screen.dart`
- Do **not** edit `apps/admin_web/**`

**Interfaces:**
- Consumes: `CoreApiService` methods already offline-gated (`getMyWallets`, `listPayments`, `quotePayment`, `confirmPayment`, `getMyLimits`)
- Produces: core path works with airplane mode when `OFFLINE_DEMO=true`

- [ ] **Step 1: Trace home data source**
   320|
Confirm `home_screen.dart` loads wallets/recent via `CoreApiService` / Riverpod that ultimately hits `getMyWallets` + `listPayments`. If it still calls legacy `YoleApiService` for neo-bank home, switch that path to `coreApiServiceProvider` **only for those calls** (smallest change).

- [ ] **Step 2: Trace history and profile**

Same check for `transactions_history_screen.dart` and `profile_screen.dart` (limits / identity). Prefer core API offline gate over legacy services.

- [ ] **Step 3: Pay / Send / Withdraw**

Confirm quote → confirm uses `CoreApiService.quotePayment` / `confirmPayment`. Fix only call sites that bypass the gate.
   330|
- [ ] **Step 4: Non-core honesty**

If cards/credit/remittance/FX already work offline via the same gate, leave them. If a screen still hits legacy network and hangs, short-circuit with a SnackBar or inline text: `Not available in offline demo` — do not build new features.

- [ ] **Step 5: Commit any wiring fixes**

```bash
git add lib/screens/ lib/providers/
git commit -m "fix: route core banking screens through offline CoreApiService"
   340|```

(Skip commit if no code changes were required.)

---

### Task 6: Device verification notes + success criteria gate

**Files:**
- Modify: `README_FLUTTER.md` (add checklist)
   350|- Optional: add `docs/superpowers/specs/2026-09-17-poste-finance-offline-mock-design.md` note that flag name is `OFFLINE_DEMO` (one-line clarification under Architecture) — **no admin changes**

- [ ] **Step 1: Append verification checklist to README**

```markdown
### Offline demo verification checklist

With `--dart-define=OFFLINE_DEMO=true` and core-api **stopped**:

1. [ ] App title / splash / login show Poste Finance
   360|2. [ ] Login as `kasee.demo@yole.com` / `Password1!`
3. [ ] Home shows CDF + USD balances (not empty)
4. [ ] Home recent / History shows seeded payments
5. [ ] Pay/Send completes and updates balance + history this session
6. [ ] Profile shows seeded customer
7. [ ] Airplane mode does not break the above
8. [ ] `apps/admin_web` unchanged in the PR diff
```

- [ ] **Step 2: Run unit tests once more**
   370|
```bash
flutter test test/offline_demo_repository_test.dart
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
   380|git add README_FLUTTER.md docs/superpowers/specs/2026-09-17-poste-finance-offline-mock-design.md
git commit -m "docs: offline Poste Finance verification checklist"
```

---

## Spec coverage self-check

| Spec requirement | Task |
|------------------|------|
   390|| Fully offline / no core-api | 1, 5, 6 |
| Seed pack CDF+USD, history, profile | Existing universe + Tasks 2, 5 |
| Mock repos + in-memory session | Existing `OfflineDemoRepository` + Task 2 |
| Poste Finance name, YOLE colors | 3 (colors already in `main.dart`) |
| Core screens only for v1 focus | 4, 5 |
| Favorites Congolese contacts | 4 |
| Leave admin alone | Global constraint |
| Tests + Android verify | 2, 6 |
| Design `USE_MOCK_DATA` naming | Task 1 documents `OFFLINE_DEMO` as canonical |

   400|## Execution handoff

After this plan is merged to the branch/PR, implement task-by-task with subagent-driven-development (recommended) or executing-plans.
