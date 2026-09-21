# Poste Finance Customer + Agent Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify customer and agent Flutter apps under Poste Finance DRC visual identity with teal primary color (`#00acac`), existing logo assets, and lifted patterns from MIT-licensed open-source Flutter banking/POS templates. Restyle Home + main flows in both apps (Pay Bill, Send Money, History, Savings, Insurance for customer; Cash In/Out, Assisted Pay, History, Enroll for agent), distinguishing customer and agent personas through subtle chip/badge styling while sharing core design tokens.

**Architecture:** Shared Poste design tokens duplicated in both apps (no hard dependency on external UI packages); lift visual patterns into `lib/widgets/brand/` (customer) and `apps/agent_mobile/lib/widgets/` (agent); apply via Material3 ThemeData without replacing MaterialApp or rewriting navigation.

**Tech Stack:** Flutter customer `lib/` + agent `apps/agent_mobile`, Material3, duplicated design tokens, light theme only (dark mode deferred)

**Spec:** `docs/superpowers/specs/2026-09-21-poste-finance-customer-agent-branding-design.md`

## Global Constraints

- Shared tokens duplicated in both apps; NO hard dependencies on `bank_ui_kit` / `flutter_pos` / `cashere` / `PAYme` packages (clone patterns only)
- Admin web untouched
- Do NOT replace MaterialApp, mass-rename routes, or rewrite `app_router.dart` / navigation
- Offline demo logic unchanged (credentials `jean-paul@congo.cd` / `hashedpin_123456`, agent PIN `123456`, repositories, universe)
- Light theme only; no dark mode this pass
- Preserve Customer outlined chip vs Agent filled chip/badge distinction
- Primary teal `#00acac`; existing `assets/brand/poste-finance-*.png` logo assets
- Border radii: 8px buttons, 12px cards, 16px modals; elevation 2–4 only
- Typography: Inter if already in pubspec else system fallback — do not add a new font package unless Inter already present
- Branch: `cursor/task1-monorepo-scaffold-1d8a`
- Out of scope deep restyles (Profile/KYC/Remittance/FX/Credit, float top-up, EOD, locator, FR i18n, empty illustrations) — theme inheritance only; no dedicated deep-restyle tasks for those

## File map

| File | Role |
|------|------|
| `lib/constants/poste_design_tokens.dart` | Customer design tokens constant class |
| `lib/theme/poste_theme.dart` | Customer `buildPosteTheme()` ThemeData factory |
| `lib/main.dart` | Wire customer MaterialApp theme |
| `test/theme/poste_theme_test.dart` | Customer theme unit test |
| `apps/agent_mobile/lib/constants/poste_design_tokens.dart` | Agent design tokens (duplicate) |
| `apps/agent_mobile/lib/theme/agent_poste_theme.dart` | Agent `buildAgentPosteTheme()` ThemeData factory |
| `apps/agent_mobile/lib/main.dart` | Wire agent MaterialApp theme |
| `apps/agent_mobile/test/theme/agent_poste_theme_test.dart` | Agent theme unit test |
| `lib/widgets/brand/poste_balance_card.dart` | Customer balance card with teal gradient |
| `lib/widgets/brand/poste_quick_action.dart` | Customer quick action grid tile |
| `lib/widgets/brand/poste_txn_tile.dart` | Customer transaction list tile |
| `lib/widgets/brand/poste_primary_button.dart` | Customer primary button with loading state |
| `lib/widgets/brand/poste_product_card.dart` | Customer savings/insurance product card |
| `test/widgets/brand/poste_balance_card_test.dart` | PosteBalanceCard widget test |
| `test/widgets/brand/poste_quick_action_test.dart` | PosteQuickAction widget test |
| `test/widgets/brand/poste_txn_tile_test.dart` | PosteTxnTile widget test |
| `test/widgets/brand/poste_product_card_test.dart` | PosteProductCard widget test |
| `lib/screens/login_screen.dart` | Customer login screen restyle |
| `lib/screens/home_screen.dart` | Customer home screen restyle with brand widgets |
| `lib/screens/pay_bill_screen.dart` | Customer pay bill screen restyle |
| `lib/screens/send_money_screen.dart` | Customer send money screen restyle |
| `lib/screens/history_screen.dart` | Customer history screen restyle |
| `lib/screens/savings_screen.dart` | Customer savings screen restyle |
| `lib/screens/insurance_screen.dart` | Customer insurance screen restyle |
| `apps/agent_mobile/lib/widgets/agent_float_card.dart` | Agent float card with teal gradient |
| `apps/agent_mobile/lib/widgets/agent_action_tile.dart` | Agent quick action list tile |
| `apps/agent_mobile/lib/widgets/agent_txn_tile.dart` | Agent transaction list tile |
| `apps/agent_mobile/lib/widgets/agent_receipt_card.dart` | Agent receipt dialog |
| `apps/agent_mobile/test/widgets/agent_float_card_test.dart` | AgentFloatCard widget test |
| `apps/agent_mobile/test/widgets/agent_action_tile_test.dart` | AgentActionTile widget test |
| `apps/agent_mobile/test/widgets/agent_receipt_card_test.dart` | AgentReceiptCard widget test |
| `apps/agent_mobile/lib/screens/agent_login_screen.dart` | Agent login screen restyle |
| `apps/agent_mobile/lib/screens/agent_home_screen.dart` | Agent home screen restyle with brand widgets |
| `apps/agent_mobile/lib/screens/cash_in_out_screen.dart` | Agent cash in/out screen restyle |
| `apps/agent_mobile/lib/screens/assisted_pay_screen.dart` | Agent assisted pay screen restyle |
| `apps/agent_mobile/lib/screens/agent_history_screen.dart` | Agent history screen restyle |
| `apps/agent_mobile/lib/screens/enroll_screen.dart` | Agent enroll screen restyle |

---

### Task 1: Customer tokens + theme + unit test

**Files:**
- Create: `lib/constants/poste_design_tokens.dart`
- Create: `lib/theme/poste_theme.dart`
- Modify: `lib/main.dart`
- Create: `test/theme/poste_theme_test.dart`

**Interfaces:**
- Produces: `PosteDesignTokens` static const class with colors, typography, spacing, border radii, shadows
- Produces: `buildPosteTheme()` returning Material3 ThemeData with teal primary

- [ ] **Step 1:** Create `lib/constants/poste_design_tokens.dart` with full `PosteDesignTokens` class from spec §2.1 (lines 60–249): primary teal `#00acac`, teal shades (light/dark/pale), accent colors (orange/green/red/yellow), neutrals (900–50), backgrounds, text colors, borders, typography styles (heading1/heading2/heading3/body/bodyBold/caption/label/amountLarge/amountMedium with Inter fontFamily), spacing constants (4/8/12/16/20/24/32/40), border radius constants (8/12/16/24 → BorderRadius.all), shadows (shadowSmall/shadowMedium/shadowLarge), elevation lists (elevation2/elevation4/elevation8)
- [ ] **Step 2:** Create `lib/theme/poste_theme.dart` with `buildPosteTheme()` from spec §2.2 (lines 260–405): return ThemeData with `useMaterial3: true`, colorScheme using `PosteDesignTokens.primaryTeal` primary, `scaffoldBackgroundColor: PosteDesignTokens.backgroundPrimary`, AppBarTheme (white background, elevation 0, heading2 title), CardTheme (white, elevation 0, borderRadiusMedium, borderDefault side), ElevatedButtonTheme (teal background, white foreground, elevation 0, borderRadiusSmall, spacing24/spacing16 padding, bodyBold textStyle), OutlinedButtonTheme (teal foreground, teal border, borderRadiusSmall, bodyBold textStyle), TextButtonTheme (teal foreground, bodyBold textStyle), InputDecorationTheme (filled backgroundTertiary, borderRadiusSmall, borderDefault/borderFocus/accentRed borders, spacing16/spacing12 padding, body labelStyle, caption hintStyle), ListTileThemeData (spacing16/spacing8 padding), DividerThemeData (borderDefault color, thickness 1), TextTheme mapping (displayLarge/Medium/Small → heading1/2/3, bodyLarge/Medium/Small → body/body/caption, labelLarge/Medium → bodyBold/label)
- [ ] **Step 3:** Update `lib/main.dart` MaterialApp: import `theme/poste_theme.dart`, set `theme: buildPosteTheme()` without changing routes, `go_router`, or navigation logic
- [ ] **Step 4:** Create `test/theme/poste_theme_test.dart`: test `buildPosteTheme()` returns ThemeData with `colorScheme.primary == PosteDesignTokens.primaryTeal`, `scaffoldBackgroundColor == PosteDesignTokens.backgroundPrimary`, `cardTheme.shape.borderRadius == PosteDesignTokens.borderRadiusMedium`, `elevatedButtonTheme.style.backgroundColor == PosteDesignTokens.primaryTeal`, `inputDecorationTheme.focusedBorder.borderSide.color == PosteDesignTokens.borderFocus`
- [ ] **Step 5:** Run `flutter test test/theme/poste_theme_test.dart` — expect pass
- [ ] **Step 6:** Commit `feat(branding): customer PosteDesignTokens + buildPosteTheme`

---

### Task 2: Agent tokens + theme + unit test

**Files:**
- Create: `apps/agent_mobile/lib/constants/poste_design_tokens.dart`
- Create: `apps/agent_mobile/lib/theme/agent_poste_theme.dart`
- Modify: `apps/agent_mobile/lib/main.dart`
- Create: `apps/agent_mobile/test/theme/agent_poste_theme_test.dart`

**Interfaces:**
- Produces: Agent `PosteDesignTokens` duplicate (same values as customer)
- Produces: `buildAgentPosteTheme()` returning Material3 ThemeData with teal primary

- [ ] **Step 1:** Create `apps/agent_mobile/lib/constants/poste_design_tokens.dart` by duplicating customer `PosteDesignTokens` class (identical values from spec §2.1)
- [ ] **Step 2:** Create `apps/agent_mobile/lib/theme/agent_poste_theme.dart` with `buildAgentPosteTheme()` function (duplicate structure from customer `buildPosteTheme()` spec §2.2 / §2.3, identical theme configuration)
- [ ] **Step 3:** Update `apps/agent_mobile/lib/main.dart` MaterialApp: import `theme/agent_poste_theme.dart`, set `theme: buildAgentPosteTheme()` without changing routes or navigation
- [ ] **Step 4:** Create `apps/agent_mobile/test/theme/agent_poste_theme_test.dart`: test `buildAgentPosteTheme()` returns ThemeData with teal primary, backgroundPrimary scaffold, borderRadiusMedium cards, teal buttons, borderFocus inputs (same assertions as customer test)
- [ ] **Step 5:** Run `cd apps/agent_mobile && flutter test test/theme/agent_poste_theme_test.dart` — expect pass
- [ ] **Step 6:** Commit `feat(branding): agent PosteDesignTokens + buildAgentPosteTheme`

---

### Task 3: Customer brand widgets + widget tests

**Files:**
- Create: `lib/widgets/brand/poste_balance_card.dart`
- Create: `lib/widgets/brand/poste_quick_action.dart`
- Create: `lib/widgets/brand/poste_txn_tile.dart`
- Create: `lib/widgets/brand/poste_primary_button.dart`
- Create: `test/widgets/brand/poste_balance_card_test.dart`
- Create: `test/widgets/brand/poste_quick_action_test.dart`
- Create: `test/widgets/brand/poste_txn_tile_test.dart`

**Interfaces:**
- Produces: `PosteBalanceCard({cdfBalance, usdBalance, balanceVisible, onToggleVisibility})` from spec §3.3.1
- Produces: `PosteQuickAction({icon, label, onTap})` from spec §3.3.2
- Produces: `PosteTxnTile({time, title, amount, subtitle, icon, onTap?})` from spec §3.3.3
- Produces: `PostePrimaryButton({label, onPressed?, loading})` from spec §3.3.4

- [ ] **Step 1:** Create `lib/widgets/brand/poste_balance_card.dart` with full `PosteBalanceCard` widget from spec §3.3.1 (lines 520–594): Container with spacing16 horizontal / spacing8 vertical margin, spacing20 padding, LinearGradient primaryTeal→tealDark, borderRadiusMedium, elevation4 boxShadow; Column with Row (caption "Total Balance" tealPale, IconButton visibility/visibility_off white), spacing8 SizedBox, amountLarge white cdfBalance or "FC ••••••", spacing4 SizedBox, amountMedium tealPale usdBalance or "\$ ••••••"
- [ ] **Step 2:** Create `lib/widgets/brand/poste_quick_action.dart` with full `PosteQuickAction` widget from spec §3.3.2 (lines 616–672): InkWell with borderRadiusMedium, Container spacing16 padding, white background, borderRadiusMedium, borderDefault border, elevation2 boxShadow; Column with Container tealPale background borderRadiusSmall spacing12 padding Icon primaryTeal 28, spacing8 SizedBox, label Text label style center
- [ ] **Step 3:** Create `lib/widgets/brand/poste_txn_tile.dart` with full `PosteTxnTile` widget from spec §3.3.3 (lines 718–798): InkWell → Container spacing16 horizontal / spacing4 vertical margin, spacing12 padding, white background, borderRadiusMedium, borderDefault border; Row with Container tealPale borderRadiusSmall spacing8 padding Icon primaryTeal 20, spacing12 SizedBox, Expanded Column with Row (label time, bodyBold amount colored accentRed if starts with '-' else accentGreen), spacing4 SizedBox, body title, caption subtitle
- [ ] **Step 4:** Create `lib/widgets/brand/poste_primary_button.dart` with full `PostePrimaryButton` widget from spec §3.3.4 (lines 820–856): SizedBox width infinity, ElevatedButton onPressed (null if loading else onPressed), child loading ? SizedBox 20×20 CircularProgressIndicator strokeWidth 2 white : Text label
- [ ] **Step 5:** Create `test/widgets/brand/poste_balance_card_test.dart`: wrap in MaterialApp with `buildPosteTheme()`, test displays cdfBalance/usdBalance when balanceVisible true, displays "FC ••••••"/"\$ ••••••" when false, tapping IconButton calls onToggleVisibility
- [ ] **Step 6:** Create `test/widgets/brand/poste_quick_action_test.dart`: wrap in MaterialApp, test displays icon/label, tapping calls onTap
- [ ] **Step 7:** Create `test/widgets/brand/poste_txn_tile_test.dart`: wrap in MaterialApp, test displays time/title/amount/subtitle/icon, amount colored red if starts with '-' else green, tapping calls onTap
- [ ] **Step 8:** Run `flutter test test/widgets/brand/` — expect all pass
- [ ] **Step 9:** Commit `feat(branding): customer brand widgets + tests`

---

### Task 4: Customer login + Home + Pay Bill + Send + History

**Files:**
- Modify: `lib/screens/login_screen.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/screens/pay_bill_screen.dart`
- Modify: `lib/screens/send_money_screen.dart`
- Modify: `lib/screens/history_screen.dart`

**Interfaces:**
- Consumes: `PosteBalanceCard`, `PosteQuickAction`, `PosteTxnTile`, `PostePrimaryButton` from Task 3
- Enhances: login with logo + teal accents; home with balance card + quick actions grid + recent txn list; pay/send with theme inputs + primary button; history with txn tiles + teal outlined selected chips

- [ ] **Step 1:** Update `lib/screens/login_screen.dart`: center Poste Finance logo (`assets/brand/poste-finance-logo.png`), apply theme InputDecoration to email/PIN TextFormFields (inherited from `buildPosteTheme()`), replace existing button with `PostePrimaryButton(label: 'Login', onPressed: _handleLogin, loading: _isLoading)`, preserve `OfflineDemoBanner` widget
- [ ] **Step 2:** Update `lib/screens/home_screen.dart`: replace balance display with `PosteBalanceCard(cdfBalance: 'FC 15,832,157.85', usdBalance: '\$ 8,000.00', balanceVisible: _balanceVisible, onToggleVisibility: () => setState(() => _balanceVisible = !_balanceVisible))`, replace quick actions with GridView.count crossAxisCount 2 mainAxisSpacing/crossAxisSpacing spacing12 padding spacing16 horizontal, children: `PosteQuickAction(icon: Icons.send, label: 'Send Money', onTap: () => context.go('/send'))`, `PosteQuickAction(icon: Icons.receipt_long, label: 'Pay Bill', onTap: () => context.go('/pay-bill'))`, `PosteQuickAction(icon: Icons.savings, label: 'Savings', onTap: () => context.go('/savings'))`, `PosteQuickAction(icon: Icons.shield, label: 'Insurance', onTap: () => context.go('/insurance'))`; replace recent transactions list with `PosteTxnTile(time: '14:32', title: 'SNEL Bill Pay', amount: '- FC 5,000', subtitle: 'Electricity', icon: Icons.receipt_long, onTap: () => _showTransactionDetail(context, txn))` for each txn
- [ ] **Step 3:** Update `lib/screens/pay_bill_screen.dart`: apply theme InputDecoration (inherited) to biller dropdown, account number field, amount field; show fee preview row using `PosteDesignTokens.caption` for "Transaction Fee: FC 25.00" and "Total: FC 5,025.00"; replace continue button with `PostePrimaryButton(label: 'Continue', onPressed: _handleContinue, loading: _isProcessing)`; preserve all business logic and navigation
- [ ] **Step 4:** Update `lib/screens/send_money_screen.dart`: apply theme InputDecoration to recipient lookup, amount field; replace button with `PostePrimaryButton(label: 'Send', onPressed: _handleSend, loading: _isProcessing)`; preserve all business logic
- [ ] **Step 5:** Update `lib/screens/history_screen.dart`: filter chips → outlined with teal border when selected (use `OutlinedButton` or `ChoiceChip` styled with `PosteDesignTokens.primaryTeal` selected border, white background), replace transaction list items with `PosteTxnTile` widgets; section headers use `PosteDesignTokens.heading3` style
- [ ] **Step 6:** Verify no compile errors: `flutter analyze lib/screens/login_screen.dart lib/screens/home_screen.dart lib/screens/pay_bill_screen.dart lib/screens/send_money_screen.dart lib/screens/history_screen.dart`
- [ ] **Step 7:** Commit `feat(branding): restyle customer login home pay send history`

---

### Task 5: Customer Savings + Insurance + PosteProductCard

**Files:**
- Create: `lib/widgets/brand/poste_product_card.dart`
- Create: `test/widgets/brand/poste_product_card_test.dart`
- Modify: `lib/screens/savings_screen.dart`
- Modify: `lib/screens/insurance_screen.dart`

**Interfaces:**
- Produces: `PosteProductCard({title, description, onActivate})` from spec §3.7.1
- Enhances: savings/insurance screens with product cards

- [ ] **Step 1:** Create `lib/widgets/brand/poste_product_card.dart` with full `PosteProductCard` widget from spec §3.7.1 (lines 965–1010): Container spacing16 horizontal / spacing8 vertical margin, spacing16 padding, white background, borderRadiusMedium, borderDefault border, elevation2 boxShadow; Column with heading3 title, spacing8 SizedBox, caption description, spacing12 SizedBox, OutlinedButton 'Activate' onActivate
- [ ] **Step 2:** Create `test/widgets/brand/poste_product_card_test.dart`: wrap in MaterialApp, test displays title/description, tapping Activate button calls onActivate
- [ ] **Step 3:** Update `lib/screens/savings_screen.dart`: replace product list items with `PosteProductCard(title: 'Epargne Scolaire', description: '2% APY • Min FC 10,000', onActivate: () => _handleActivate('EPARGNE_SCOLAIRE'))`, `PosteProductCard(title: 'Compte Economie', description: '1.5% APY • Min FC 5,000', onActivate: () => _handleActivate('COMPTE_ECONOMIE'))`; preserve all business logic
- [ ] **Step 4:** Update `lib/screens/insurance_screen.dart`: replace premium product displays with `PosteProductCard` widgets for each insurance product; preserve all business logic
- [ ] **Step 5:** Run `flutter test test/widgets/brand/poste_product_card_test.dart` — expect pass
- [ ] **Step 6:** Verify no compile errors: `flutter analyze lib/screens/savings_screen.dart lib/screens/insurance_screen.dart`
- [ ] **Step 7:** Commit `feat(branding): PosteProductCard + savings/insurance restyle`

---

### Task 6: Agent brand widgets + widget tests

**Files:**
- Create: `apps/agent_mobile/lib/widgets/agent_float_card.dart`
- Create: `apps/agent_mobile/lib/widgets/agent_action_tile.dart`
- Create: `apps/agent_mobile/lib/widgets/agent_txn_tile.dart`
- Create: `apps/agent_mobile/lib/widgets/agent_receipt_card.dart`
- Create: `apps/agent_mobile/test/widgets/agent_float_card_test.dart`
- Create: `apps/agent_mobile/test/widgets/agent_action_tile_test.dart`
- Create: `apps/agent_mobile/test/widgets/agent_receipt_card_test.dart`

**Interfaces:**
- Produces: `AgentFloatCard({cdfFloat, usdFloat})` from spec §4.3.1
- Produces: `AgentActionTile({icon, label, onTap})` from spec §4.3.2
- Produces: `AgentTxnTile({time, title, amount, subtitle, icon, onTap?})` from spec §4.6.1 (same structure as PosteTxnTile)
- Produces: `AgentReceiptCard({title, fields, onDone})` from spec §4.8

- [ ] **Step 1:** Create `apps/agent_mobile/lib/widgets/agent_float_card.dart` with full `AgentFloatCard` widget from spec §4.3.1 (lines 1095–1150): Container spacing16 horizontal / spacing8 vertical margin, spacing20 padding, LinearGradient primaryTeal→tealDark, borderRadiusMedium, elevation4 boxShadow; Column with caption "Agent Float" tealPale, spacing8 SizedBox, amountLarge white "CDF: $cdfFloat", spacing4 SizedBox, amountMedium tealPale "USD: $usdFloat"
- [ ] **Step 2:** Create `apps/agent_mobile/lib/widgets/agent_action_tile.dart` with full `AgentActionTile` widget from spec §4.3.2 (lines 1158–1208): Container spacing16 horizontal / spacing4 vertical margin, ListTile with leading Container tealPale borderRadiusSmall spacing8 padding Icon primaryTeal 24, title bodyBold label, trailing chevron_right textTertiary, onTap, shape RoundedRectangleBorder borderRadiusMedium borderDefault side, tileColor white
- [ ] **Step 3:** Create `apps/agent_mobile/lib/widgets/agent_txn_tile.dart`: duplicate structure from customer `PosteTxnTile` (same widget spec §3.3.3 but in agent path); filled chip badge for txn type preserved in existing agent screens
- [ ] **Step 4:** Create `apps/agent_mobile/lib/widgets/agent_receipt_card.dart` with full `AgentReceiptCard` widget from spec §4.8 (lines 1309–1368): Dialog shape borderRadiusMedium, Padding spacing24, Column mainAxisSize min: Icon check_circle accentGreen 48, spacing12 SizedBox, heading2 title, spacing16 SizedBox, fields map → Padding spacing4 vertical Row mainAxisAlignment spaceBetween (caption key, bodyBold value), spacing24 SizedBox, SizedBox width infinity ElevatedButton 'Done' onDone
- [ ] **Step 5:** Create `apps/agent_mobile/test/widgets/agent_float_card_test.dart`: wrap in MaterialApp with `buildAgentPosteTheme()`, test displays cdfFloat/usdFloat with correct styles
- [ ] **Step 6:** Create `apps/agent_mobile/test/widgets/agent_action_tile_test.dart`: wrap in MaterialApp, test displays icon/label, tapping calls onTap
- [ ] **Step 7:** Create `apps/agent_mobile/test/widgets/agent_receipt_card_test.dart`: wrap in MaterialApp, test displays title/fields, tapping Done calls onDone
- [ ] **Step 8:** Run `cd apps/agent_mobile && flutter test test/widgets/` — expect all pass
- [ ] **Step 9:** Commit `feat(branding): agent brand widgets + tests`

---

### Task 7: Agent screens restyle

**Files:**
- Modify: `apps/agent_mobile/lib/screens/agent_login_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/agent_home_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/assisted_pay_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/agent_history_screen.dart`
- Modify: `apps/agent_mobile/lib/screens/enroll_screen.dart`

**Interfaces:**
- Consumes: `AgentFloatCard`, `AgentActionTile`, `AgentTxnTile`, `AgentReceiptCard` from Task 6
- Enhances: agent login with logo + teal accents; home with float card + action tiles vertical list; cash in/out + assisted pay with theme inputs; history with txn tiles; enroll with theme; receipts use receipt card

- [ ] **Step 1:** Update `apps/agent_mobile/lib/screens/agent_login_screen.dart`: center Poste Finance logo, apply theme InputDecoration to agent ID/PIN fields (inherited), replace button with agent version of `PostePrimaryButton` (or reuse from customer by adjusting import), preserve `OfflineDemoBanner`
- [ ] **Step 2:** Update `apps/agent_mobile/lib/screens/agent_home_screen.dart`: replace float display with `AgentFloatCard(cdfFloat: 'FC 5,000,000', usdFloat: '\$ 10,000')`, preserve commission card (existing; inherits theme), replace quick actions with vertical Column of `AgentActionTile` widgets from spec §4.3.2 usage (lines 1212–1239): `AgentActionTile(icon: Icons.arrow_downward, label: 'Cash In', onTap: () => Navigator.pushNamed(context, '/cash-in'))`, `AgentActionTile(icon: Icons.arrow_upward, label: 'Cash Out', onTap: () => Navigator.pushNamed(context, '/cash-out'))`, `AgentActionTile(icon: Icons.payment, label: 'Pay for customer', onTap: () => Navigator.pushNamed(context, '/assisted-pay'))`, `AgentActionTile(icon: Icons.person_add, label: 'Enroll', onTap: () => Navigator.pushNamed(context, '/enroll'))`, `AgentActionTile(icon: Icons.history, label: 'History', onTap: () => Navigator.pushNamed(context, '/history'))`; preserve filled Agent chip/badge in existing fields
- [ ] **Step 3:** Update `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`: apply theme InputDecoration (inherited), use existing `CustomerLookupField` widget (inherits theme), replace continue button with agent primary button; preserve all offline behavior
- [ ] **Step 4:** Update `apps/agent_mobile/lib/screens/assisted_pay_screen.dart`: apply theme tokens to Bill/Airtime toggle, biller dropdown, amount input; replace button with agent primary button; preserve all business logic
- [ ] **Step 5:** Update `apps/agent_mobile/lib/screens/agent_history_screen.dart`: filter chips → filled Agent chip/badge style when selected (preserve existing distinction), replace transaction list items with `AgentTxnTile` widgets; section headers use `PosteDesignTokens.heading3`; receipt dialogs use `AgentReceiptCard` from spec §4.8 usage (lines 1372–1390): `showDialog(context: context, builder: (context) => AgentReceiptCard(title: 'Bill Payment Successful', fields: [MapEntry('Customer', 'Jean-Paul Kabila'), MapEntry('Biller', 'SNEL Kinshasa'), MapEntry('Amount', 'FC 50.00'), MapEntry('Fee', 'FC 0.25'), MapEntry('Total', 'FC 50.25'), MapEntry('Float left', 'FC 4,999,949.75'), MapEntry('Journal', 'jnl_assistbill_s_17')], onDone: () => Navigator.pop(context)))`
- [ ] **Step 6:** Update `apps/agent_mobile/lib/screens/enroll_screen.dart`: apply theme InputDecoration to customer registration fields; replace submit button with agent primary button; preserve all business logic
- [ ] **Step 7:** Verify no compile errors: `cd apps/agent_mobile && flutter analyze lib/screens/`
- [ ] **Step 8:** Commit `feat(branding): restyle agent login home flows history enroll`

---

### Task 8: Polish / acceptance

**Files:**
- Create: `test/theme/theme_consistency_test.dart` (optional if adding tests)
- Create: `apps/agent_mobile/test/theme/theme_consistency_test.dart` (optional if adding tests)

**Interfaces:**
- Validates: theme consistency notes for in-scope screens; golden/screenshot tests ONLY if repo already uses goldens; accessibility as manual checklist

- [ ] **Step 1:** Audit in-scope customer screens (login, home, pay bill, send, history, savings, insurance) for theme consistency: all use PosteDesignTokens colors/spacing/radii/typography; no hardcoded colors beyond tokens
- [ ] **Step 2:** Audit in-scope agent screens (login, home, cash in/out, assisted pay, history, enroll) for theme consistency: all use PosteDesignTokens colors/spacing/radii/typography; Customer outlined chip vs Agent filled chip distinction preserved
- [ ] **Step 3:** Check if repo already has golden test infrastructure (search for `matchesGoldenFile` or `.png` golden files): if yes, create golden tests for customer home / agent home screens; if no, skip introducing golden harness and document manual Pixel verification steps below
- [ ] **Step 4:** Document manual accessibility verification steps: color contrast ratios ≥ 4.5:1 for body text (test with contrast checker tool on primaryTeal #00acac vs white), touch targets ≥ 48×48 logical pixels (verify buttons/list tiles meet minimum), screen reader labels present on IconButtons (verify onToggleVisibility button has semantic label)
- [ ] **Step 5:** Run full test suite: `flutter test` (customer) and `cd apps/agent_mobile && flutter test` (agent) — expect all pass
- [ ] **Step 6:** Commit only if code/tests added: `test(branding): theme consistency + polish checks` (skip commit if no code changes in this task, only audit/documentation)

---

## Done when

**Spec §6 acceptance criteria all met:**

### 6.1 Shared Tokens
- [ ] `PosteDesignTokens` exists in customer (`lib/constants/`) and agent (`apps/agent_mobile/lib/constants/`) apps (duplicate files)
- [ ] `buildPosteTheme()` (customer) and `buildAgentPosteTheme()` (agent) return Material3 `ThemeData`
- [ ] Both apps use teal `#00acac` primary color
- [ ] All border radii consistent: 8px buttons, 12px cards, 16px modals
- [ ] Shadows subtle: elevation 2–4 only
- [ ] Typography uses Inter fallback or system default
- [ ] `MaterialApp` theme applied in both `main.dart`; existing screens inherit theme without manual edits (except in-scope screens explicitly restyled)

### 6.2 Customer Screens
- [ ] Login screen shows Poste logo (`assets/brand/poste-finance-logo.png`) + teal accent
- [ ] Home screen uses `PosteBalanceCard` (teal gradient, balance toggle)
- [ ] Home quick actions grid uses `PosteQuickAction` widgets (4 tiles: Send/Pay Bill/Savings/Insurance)
- [ ] Recent transactions list uses `PosteTxnTile` widgets
- [ ] Pay Bill screen uses theme input fields + `PostePrimaryButton`
- [ ] Send Money screen uses theme input fields + `PostePrimaryButton`
- [ ] History screen filter chips outlined with teal border when selected
- [ ] History transaction list uses `PosteTxnTile` widgets
- [ ] Savings screen uses `PosteProductCard` for products (Epargne Scolaire, Compte Economie)
- [ ] Insurance screen uses `PosteProductCard` for premiums
- [ ] All in-scope screens inherit theme tokens (no hardcoded colors beyond tokens)

### 6.3 Agent Screens
- [ ] Agent login shows Poste logo + teal accent
- [ ] Agent home uses `AgentFloatCard` (teal gradient, CDF + USD)
- [ ] Agent home quick actions use `AgentActionTile` vertical list (Cash In/Out, Pay for customer, Enroll, History)
- [ ] Cash in/out screens use theme input fields + agent button
- [ ] Assisted pay screen uses theme tokens (Bill/Airtime toggle, inputs, button)
- [ ] Agent history uses `AgentTxnTile` widgets
- [ ] Enroll screen uses theme tokens (registration form, submit button)
- [ ] Receipt dialogs use `AgentReceiptCard` widget

### 6.4 Customer vs Agent Distinction
- [ ] Customer app uses outlined status chips (preserve existing)
- [ ] Agent app uses filled status chips/badges (preserve existing)
- [ ] No cross-contamination of chip styles

### 6.5 Visual Regression
- [ ] Screenshot comparison (manual Pixel verification): before/after shows consistent branding
- [ ] No broken layouts (text overflow, alignment issues)
- [ ] Color contrast ratios ≥ 4.5:1 for body text, ≥ 3:1 for large text (WCAG AA) — manual check with contrast tool
- [ ] Touch targets ≥ 48×48 logical pixels (Material Design spec) — manual check on buttons/tiles

### 6.6 Tests
- [ ] Theme unit test (customer): `buildPosteTheme()` returns `ThemeData` with teal primary — `flutter test test/theme/poste_theme_test.dart` passes
- [ ] Theme unit test (agent): `buildAgentPosteTheme()` returns `ThemeData` with teal primary — `cd apps/agent_mobile && flutter test test/theme/agent_poste_theme_test.dart` passes
- [ ] Widget tests (customer): `PosteBalanceCard`, `PosteQuickAction`, `PosteTxnTile`, `PosteProductCard` render correctly — `flutter test test/widgets/brand/` passes
- [ ] Widget tests (agent): `AgentFloatCard`, `AgentActionTile`, `AgentReceiptCard` render correctly — `cd apps/agent_mobile && flutter test test/widgets/` passes
- [ ] Screenshot tests (optional): customer home, agent home, pay bill, history (golden file comparison) — only if repo already has golden test infrastructure

### Final Validation
- [ ] All commits pushed to `cursor/task1-monorepo-scaffold-1d8a`
- [ ] `flutter analyze` passes for customer and agent
- [ ] `flutter test` passes for customer and agent
- [ ] No MaterialApp replacement, no route mass-rename, no app_router rewrite
- [ ] Offline demo logic unchanged (credentials, PIN 123456, repositories, universe)
- [ ] Profile/KYC/Remittance/FX/Credit screens inherit theme only (no dedicated restyle; acceptable visual inconsistency for P0)
- [ ] Admin web app untouched
