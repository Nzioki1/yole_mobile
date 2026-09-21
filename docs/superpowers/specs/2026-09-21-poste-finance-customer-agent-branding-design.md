# Poste Finance Customer + Agent App Branding Design

**Date:** 2026-09-21  
**Status:** Approved (Approach A)  
**Apps:** Customer (`lib/`) + Agent (`apps/agent_mobile`) offline mock only  
**Depends on:** Customer P0 + Agent P0 (login, home, bill pay, cash flows, history)

## 1. Overview

Unify customer and agent apps under Poste Finance DRC visual identity with teal primary color (`#00acac`), existing logo assets, and lifted patterns from MIT-licensed open-source Flutter banking/POS templates. This pass delivers a broader restyle covering Home + main flows in both apps, distinguishing customer and agent personas through subtle chip/badge styling while sharing core design tokens.

### 1.1 Approved Decisions

- **Scope:** Customer app (root `lib/`) + Agent app (`apps/agent_mobile`) only. **Admin web app untouched.**
- **Approach A:** Shared Poste design tokens; lift visual patterns from free MIT templates; **no hard dependency** on `bank_ui_kit` / `flutter_pos` / `cashere` / `PAYme` (clone patterns, not packages).
- **Depth:** Broader restyle — Home + main flows (Pay Bill, Send Money, History, Savings, Insurance for customer; Cash In/Out, Assisted Pay, History, Enroll for agent).
- **Primary color:** Teal `#00acac` + existing `assets/brand/poste-finance-*.png` logo assets.
- **Customer vs Agent distinction:** Outlined Customer chip vs filled Agent chip/badge (already present in agent mock — preserve).
- **MaterialApp retained:** Do **not** replace `MaterialApp`, mass-rename routes, or rewrite `app_router.dart` / `main.dart` navigation logic.
- **Offline logic preserved:** Demo credentials (`jean-paul@congo.cd` / `hashedpin_123456`), hardcoded agent PIN `123456`, repositories, offline universe unchanged.
- **Typography:** Inter or SF Pro fallback (system default). No custom font package unless already present.
- **Border radius:** Consistent 12px cards, 8px buttons, 16px modals.
- **Shadows:** Subtle elevation 2–4; avoid heavy drop shadows.
- **Dark mode:** Out of scope for this pass (time-based switcher deferred; implement light theme only).

### 1.2 Template Sources (Research Shortlist — Reference Only)

**Customer app inspiration:**
- Bank UI Kit: https://github.com/sayed3li97/bank-ui-kit (MIT)
- Bankit: https://github.com/znissou/bankit (MIT)
- FinanceWallet, FinUIX (layout reference only; no direct clone)

**Agent app inspiration:**
- flutter_pos: https://github.com/elrizwiraswara/flutter_pos (MIT)
- Cashere: https://github.com/MozartKato/cashere (MIT)
- PAYme / bKash (layout reference only; no direct clone)

**Clone-first priority:** bank-ui-kit → bankit → flutter_pos → PAYme Flutter only.

**Note:** Templates are reference for layout patterns (card structures, list tiles, balance displays). Do NOT import packages; clone and adapt widget patterns into `lib/widgets/brand/` and `apps/agent_mobile/lib/widgets/` with Poste Finance colors/branding.

### 1.3 Out of Scope

- Admin web app branding
- New features (beyond existing P0 flows)
- French i18n overhaul (EN only; FR strings stay as-is)
- Profile / KYC / Remittance / FX / Credit screens (deep restyle beyond theme inheritance)
- Float top-up / EOD declaration / agent locator screens
- Dark mode implementation (light theme only)
- Custom font packages (use system defaults)
- Animated splash screens / onboarding carousels
- Push notification styling
- Empty state illustrations (use text + icon placeholders)

## 2. Shared Design System

### 2.1 Design Tokens (Customer + Agent)

Both apps will duplicate these constants for this pass. Future refactor may lift to shared package, but Approach A keeps customer and agent codebases independent.

**Path (Customer):** `lib/constants/poste_design_tokens.dart`  
**Path (Agent):** `apps/agent_mobile/lib/constants/poste_design_tokens.dart`

```dart
import 'package:flutter/material.dart';

/// Poste Finance DRC design tokens
class PosteDesignTokens {
  PosteDesignTokens._();

  // === COLORS ===
  
  /// Primary brand teal
  static const Color primaryTeal = Color(0xFF00acac);
  
  /// Primary teal shades
  static const Color tealLight = Color(0xFF33BDBD);
  static const Color tealDark = Color(0xFF008A8A);
  static const Color tealPale = Color(0xFFE0F7F7);
  
  /// Accent colors
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentYellow = Color(0xFFFFCC00);
  
  /// Neutrals
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF333333);
  static const Color neutral700 = Color(0xFF4D4D4D);
  static const Color neutral600 = Color(0xFF666666);
  static const Color neutral500 = Color(0xFF808080);
  static const Color neutral400 = Color(0xFF999999);
  static const Color neutral300 = Color(0xFFCCCCCC);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);
  
  /// Background
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Colors.white;
  static const Color backgroundTertiary = Color(0xFFF5F5F5);
  
  /// Text
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textTertiary = neutral400;
  static const Color textOnPrimary = Colors.white;
  
  /// Borders
  static const Color borderDefault = neutral200;
  static const Color borderFocus = primaryTeal;
  
  // === TYPOGRAPHY ===
  
  static const String fontFamily = 'Inter'; // Fallback to system if unavailable
  
  /// Heading 1 (Page titles)
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );
  
  /// Heading 2 (Section titles)
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  /// Heading 3 (Card titles)
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  /// Body (Default text)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Body bold
  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Caption (Secondary info)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  /// Label (Small labels, tags)
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.3,
  );
  
  /// Amount large (Balance displays)
  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// Amount medium (Transaction amounts)
  static const TextStyle amountMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  // === SPACING ===
  
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  
  // === BORDER RADIUS ===
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));
  
  // === SHADOWS ===
  
  static const BoxShadow shadowSmall = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow shadowLarge = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  
  // === ELEVATION (Lists of shadows for cards) ===
  
  static const List<BoxShadow> elevation2 = [shadowSmall];
  static const List<BoxShadow> elevation4 = [shadowMedium];
  static const List<BoxShadow> elevation8 = [shadowLarge];
}
```

**Notes:**
- Inter font: If not already in `pubspec.yaml`, use system default (no package dependency for this pass).
- Agent app: Duplicate tokens file; use same values.
- Future: Extract to `packages/design_system` if both apps stabilize.

---

### 2.2 ThemeData Integration (Customer)

**Path:** `lib/theme/poste_theme.dart`

```dart
import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

ThemeData buildPosteTheme() {
  return ThemeData(
    useMaterial3: true,
    
    // Color scheme
    colorScheme: ColorScheme.light(
      primary: PosteDesignTokens.primaryTeal,
      secondary: PosteDesignTokens.accentOrange,
      surface: PosteDesignTokens.backgroundSecondary,
      error: PosteDesignTokens.accentRed,
      onPrimary: PosteDesignTokens.textOnPrimary,
      onSurface: PosteDesignTokens.textPrimary,
    ),
    
    scaffoldBackgroundColor: PosteDesignTokens.backgroundPrimary,
    
    // App bar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: PosteDesignTokens.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: PosteDesignTokens.heading2,
    ),
    
    // Card
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        side: const BorderSide(color: PosteDesignTokens.borderDefault),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
    ),
    
    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PosteDesignTokens.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing24,
          vertical: PosteDesignTokens.spacing16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: PosteDesignTokens.borderRadiusSmall,
        ),
        textStyle: PosteDesignTokens.bodyBold,
      ),
    ),
    
    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PosteDesignTokens.primaryTeal,
        side: const BorderSide(color: PosteDesignTokens.primaryTeal),
        padding: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing24,
          vertical: PosteDesignTokens.spacing16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: PosteDesignTokens.borderRadiusSmall,
        ),
        textStyle: PosteDesignTokens.bodyBold,
      ),
    ),
    
    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PosteDesignTokens.primaryTeal,
        padding: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing16,
          vertical: PosteDesignTokens.spacing12,
        ),
        textStyle: PosteDesignTokens.bodyBold,
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PosteDesignTokens.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.accentRed),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing12,
      ),
      labelStyle: PosteDesignTokens.body,
      hintStyle: PosteDesignTokens.caption.copyWith(color: PosteDesignTokens.textTertiary),
    ),
    
    // List tile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: PosteDesignTokens.borderDefault,
      thickness: 1,
      space: 1,
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: PosteDesignTokens.heading1,
      displayMedium: PosteDesignTokens.heading2,
      displaySmall: PosteDesignTokens.heading3,
      bodyLarge: PosteDesignTokens.body,
      bodyMedium: PosteDesignTokens.body,
      bodySmall: PosteDesignTokens.caption,
      labelLarge: PosteDesignTokens.bodyBold,
      labelMedium: PosteDesignTokens.label,
    ),
  );
}
```

**Integration:**

Update `lib/main.dart` MaterialApp:

```dart
import 'theme/poste_theme.dart';

// ...

MaterialApp(
  theme: buildPosteTheme(),
  // ... rest of MaterialApp config
)
```

**Note:** Preserve existing `theme_provider.dart` time-based dark/light switcher logic; this pass implements light theme only. Dark theme deferred to future sprint.

---

### 2.3 ThemeData Integration (Agent)

**Path:** `apps/agent_mobile/lib/theme/agent_poste_theme.dart`

Same structure as customer theme; duplicate `buildPosteTheme()` → `buildAgentPosteTheme()` with identical tokens. Agent-specific chip styles (filled vs outlined) handled at widget level, not theme level.

**Integration:**

Update `apps/agent_mobile/lib/main.dart` MaterialApp:

```dart
import 'theme/agent_poste_theme.dart';

// ...

MaterialApp(
  theme: buildAgentPosteTheme(),
  // ... rest of MaterialApp config
)
```

---

## 3. Customer App Screens & Widgets

### 3.1 Screens in Scope

1. **Login / Splash** (`login_screen.dart`) — Poste logo + teal accent
2. **Home** (`home_screen.dart`) — Balance card + quick actions grid
3. **Pay Bill** (`pay_bill_screen.dart`) — Biller list + form
4. **Send Money** (`send_money_screen.dart`) — Recipient lookup + amount input
5. **History** (`history_screen.dart`) — Transaction list with chips
6. **Savings** (`savings_screen.dart`) — Product cards + activate flow
7. **Insurance** (`insurance_screen.dart`) — Premium cards + enroll flow

**Out of scope (inherit theme only):** Profile, KYC, Remittance, FX, Credit, Settings.

---

### 3.2 Login / Splash Screen

**Path:** `lib/screens/login_screen.dart`

**Layout goals:**
- Center Poste Finance logo (`assets/brand/poste-finance-logo.png`)
- Teal gradient background (optional; or white with teal accents)
- Email + PIN input fields (use `InputDecoration` from theme)
- Primary button "Login" (teal `ElevatedButton`)
- Offline demo banner (existing `OfflineDemoBanner` widget; preserve)

**No new widgets required.** Apply theme tokens to existing widgets.

---

### 3.3 Home Screen

**Path:** `lib/screens/home_screen.dart`

**Layout goals:**

```
┌────────────────────────────────────────┐
│  Good morning, Jean-Paul  [Avatar]     │
│  [Offline Demo Banner]                 │
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ Total Balance                    │  │
│  │ FC 15,832,157.85                 │  │  ← PosteBalanceCard widget
│  │ $ 8,000.00                       │  │
│  │ [👁 Show/Hide]                    │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Quick Actions                         │
│  [💸 Send]  [📄 Pay Bill]              │  ← PosteQuickAction grid
│  [💰 Save]  [🛡 Insure]                │
│                                        │
│  Recent Transactions                   │
│  ┌──────────────────────────────────┐  │
│  │ 14:32  SNEL Bill Pay             │  │  ← PosteTxnTile list
│  │ FC 5,000 • Electricity           │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ 12:15  Sent to Marie Dupont      │  │
│  │ $ 50.00 • Send Money             │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

**New shared widgets:**

#### 3.3.1 PosteBalanceCard

**Path:** `lib/widgets/brand/poste_balance_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteBalanceCard extends StatelessWidget {
  final String cdfBalance;
  final String usdBalance;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;

  const PosteBalanceCard({
    super.key,
    required this.cdfBalance,
    required this.usdBalance,
    required this.balanceVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
      padding: const EdgeInsets.all(PosteDesignTokens.spacing20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PosteDesignTokens.primaryTeal, PosteDesignTokens.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        boxShadow: PosteDesignTokens.elevation4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: PosteDesignTokens.caption.copyWith(
                  color: PosteDesignTokens.tealPale,
                ),
              ),
              IconButton(
                icon: Icon(
                  balanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: PosteDesignTokens.spacing8),
          Text(
            balanceVisible ? cdfBalance : 'FC ••••••',
            style: PosteDesignTokens.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: PosteDesignTokens.spacing4),
          Text(
            balanceVisible ? usdBalance : '\$ ••••••',
            style: PosteDesignTokens.amountMedium.copyWith(
              color: PosteDesignTokens.tealPale,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Usage in `home_screen.dart`:**

```dart
PosteBalanceCard(
  cdfBalance: 'FC 15,832,157.85',
  usdBalance: '\$ 8,000.00',
  balanceVisible: _balanceVisible,
  onToggleVisibility: () {
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
  },
)
```

---

#### 3.3.2 PosteQuickAction

**Path:** `lib/widgets/brand/poste_quick_action.dart`

```dart
import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PosteQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PosteDesignTokens.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(PosteDesignTokens.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: PosteDesignTokens.borderRadiusMedium,
          border: Border.all(color: PosteDesignTokens.borderDefault),
          boxShadow: PosteDesignTokens.elevation2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(PosteDesignTokens.spacing12),
              decoration: BoxDecoration(
                color: PosteDesignTokens.tealPale,
                borderRadius: PosteDesignTokens.borderRadiusSmall,
              ),
              child: Icon(
                icon,
                color: PosteDesignTokens.primaryTeal,
                size: 28,
              ),
            ),
            const SizedBox(height: PosteDesignTokens.spacing8),
            Text(
              label,
              style: PosteDesignTokens.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Usage in `home_screen.dart`:**

```dart
GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: PosteDesignTokens.spacing12,
  crossAxisSpacing: PosteDesignTokens.spacing12,
  padding: const EdgeInsets.symmetric(horizontal: PosteDesignTokens.spacing16),
  children: [
    PosteQuickAction(
      icon: Icons.send,
      label: 'Send Money',
      onTap: () => context.go('/send'),
    ),
    PosteQuickAction(
      icon: Icons.receipt_long,
      label: 'Pay Bill',
      onTap: () => context.go('/pay-bill'),
    ),
    PosteQuickAction(
      icon: Icons.savings,
      label: 'Savings',
      onTap: () => context.go('/savings'),
    ),
    PosteQuickAction(
      icon: Icons.shield,
      label: 'Insurance',
      onTap: () => context.go('/insurance'),
    ),
  ],
)
```

---

#### 3.3.3 PosteTxnTile

**Path:** `lib/widgets/brand/poste_txn_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteTxnTile extends StatelessWidget {
  final String time;
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const PosteTxnTile({
    super.key,
    required this.time,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing16,
          vertical: PosteDesignTokens.spacing4,
        ),
        padding: const EdgeInsets.all(PosteDesignTokens.spacing12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: PosteDesignTokens.borderRadiusMedium,
          border: Border.all(color: PosteDesignTokens.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(PosteDesignTokens.spacing8),
              decoration: BoxDecoration(
                color: PosteDesignTokens.tealPale,
                borderRadius: PosteDesignTokens.borderRadiusSmall,
              ),
              child: Icon(
                icon,
                color: PosteDesignTokens.primaryTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: PosteDesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(time, style: PosteDesignTokens.label),
                      Text(
                        amount,
                        style: PosteDesignTokens.bodyBold.copyWith(
                          color: amount.startsWith('-')
                              ? PosteDesignTokens.accentRed
                              : PosteDesignTokens.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PosteDesignTokens.spacing4),
                  Text(title, style: PosteDesignTokens.body),
                  Text(subtitle, style: PosteDesignTokens.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Usage in `home_screen.dart` and `history_screen.dart`:**

```dart
PosteTxnTile(
  time: '14:32',
  title: 'SNEL Bill Pay',
  amount: '- FC 5,000',
  subtitle: 'Electricity',
  icon: Icons.receipt_long,
  onTap: () => _showTransactionDetail(context, txn),
)
```

---

#### 3.3.4 PostePrimaryButton

**Path:** `lib/widgets/brand/poste_primary_button.dart`

```dart
import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PostePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PostePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}
```

---

### 3.4 Pay Bill Screen

**Path:** `lib/screens/pay_bill_screen.dart`

**Layout goals:**

```
┌────────────────────────────────────────┐
│  Pay Bill                    [< Back]  │
├────────────────────────────────────────┤
│  From Wallet                           │
│  [CDF ▼]                               │
│  Balance: FC 15,832,157.85             │
│                                        │
│  Select Biller                         │
│  [SNEL Kinshasa          ▼]            │
│                                        │
│  Account Number                        │
│  [12345678______________]              │
│                                        │
│  Amount                                │
│  [5000___]                             │
│                                        │
│  Transaction Fee:    FC 25.00          │
│  Total:              FC 5,025.00       │
│                                        │
│  [Continue]  ← PostePrimaryButton      │
└────────────────────────────────────────┘
```

**Changes:**
- Apply theme `InputDecoration` to all text fields
- Use `PostePrimaryButton` for "Continue"
- Dropdown styled with teal accent when focused
- Fee preview row uses `PosteDesignTokens.caption`

**No new widgets required beyond shared widgets.**

---

### 3.5 Send Money Screen

**Path:** `lib/screens/send_money_screen.dart`

Similar to Pay Bill; apply theme tokens + `PostePrimaryButton`.

---

### 3.6 History Screen

**Path:** `lib/screens/history_screen.dart`

**Layout:**

```
┌────────────────────────────────────────┐
│  History                     [< Back]  │
├────────────────────────────────────────┤
│ [All] [Send] [Receive] [Bill] [More]   │  ← Filter chips (outlined)
│                                        │
│  Today                                 │
│  [PosteTxnTile]                        │
│  [PosteTxnTile]                        │
│                                        │
│  Yesterday                             │
│  [PosteTxnTile]                        │
└────────────────────────────────────────┘
```

**Changes:**
- Filter chips: Outlined with teal border when selected
- Transaction list: Use `PosteTxnTile` widget
- Section headers: `PosteDesignTokens.heading3`

---

### 3.7 Savings Screen

**Path:** `lib/screens/savings_screen.dart`

**Layout:**

```
┌────────────────────────────────────────┐
│  Savings                     [< Back]  │
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ Epargne Scolaire                 │  │  ← PosteProductCard
│  │ 2% APY • Min FC 10,000           │  │
│  │ [Activate]                       │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ Compte Economie                  │  │
│  │ 1.5% APY • Min FC 5,000          │  │
│  │ [Activate]                       │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

**New widget:**

#### 3.7.1 PosteProductCard

**Path:** `lib/widgets/brand/poste_product_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteProductCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onActivate;

  const PosteProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
      padding: const EdgeInsets.all(PosteDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        border: Border.all(color: PosteDesignTokens.borderDefault),
        boxShadow: PosteDesignTokens.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PosteDesignTokens.heading3),
          const SizedBox(height: PosteDesignTokens.spacing8),
          Text(description, style: PosteDesignTokens.caption),
          const SizedBox(height: PosteDesignTokens.spacing12),
          OutlinedButton(
            onPressed: onActivate,
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
}
```

---

### 3.8 Insurance Screen

**Path:** `lib/screens/insurance_screen.dart`

Similar to Savings; use `PosteProductCard` for premium products.

---

### 3.9 Customer vs Agent Distinction (Preserve Existing)

**Customer app:** Uses outlined status chips (e.g., profile badge, customer ID display).

**Agent app:** Uses filled chips/badges (already present in agent mock — preserve).

**No changes required.** Existing `StatusChip` widget styles are retained; new branding applies to card backgrounds, buttons, and input fields.

---

## 4. Agent App Screens & Widgets

### 4.1 Screens in Scope

1. **Login** (`agent_login_screen.dart`) — Poste logo + teal accent
2. **Home** (`agent_home_screen.dart`) — Float card + quick actions
3. **Cash In / Out** (`cash_in_out_screen.dart`) — Customer lookup + amount
4. **Assisted Pay** (`assisted_pay_screen.dart`) — Bill | Airtime toggle
5. **History** (`agent_history_screen.dart`) — Transaction list with filters
6. **Enroll** (`enroll_screen.dart`) — Customer registration form

**Out of scope:** Float top-up, EOD declaration, agent locator, Settings.

---

### 4.2 Login Screen

**Path:** `apps/agent_mobile/lib/screens/agent_login_screen.dart`

Same as customer login; apply agent theme tokens.

---

### 4.3 Agent Home

**Path:** `apps/agent_mobile/lib/screens/agent_home_screen.dart`

**Layout:**

```
┌────────────────────────────────────────┐
│  Agent 001                   [Avatar]  │
│  [Offline Demo Banner]                 │
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ Agent Float                      │  │  ← AgentFloatCard
│  │ CDF: FC 5,000,000                │  │
│  │ USD: $ 10,000                    │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ Today's Commissions              │  │  ← Existing commission card
│  │ CDF: FC 1,250 • USD: $ 5         │  │
│  │ 12 transactions                  │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Quick Actions                         │
│  [AgentActionTile Cash In]             │  ← Vertical list tiles
│  [AgentActionTile Cash Out]            │
│  [AgentActionTile Pay for customer]    │
│  [AgentActionTile Enroll]              │
│  [AgentActionTile History]             │
└────────────────────────────────────────┘
```

**New widgets:**

#### 4.3.1 AgentFloatCard

**Path:** `apps/agent_mobile/lib/widgets/agent_float_card.dart`

```dart
import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

class AgentFloatCard extends StatelessWidget {
  final String cdfFloat;
  final String usdFloat;

  const AgentFloatCard({
    super.key,
    required this.cdfFloat,
    required this.usdFloat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
      padding: const EdgeInsets.all(PosteDesignTokens.spacing20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PosteDesignTokens.primaryTeal, PosteDesignTokens.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        boxShadow: PosteDesignTokens.elevation4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent Float',
            style: PosteDesignTokens.caption.copyWith(
              color: PosteDesignTokens.tealPale,
            ),
          ),
          const SizedBox(height: PosteDesignTokens.spacing8),
          Text(
            'CDF: $cdfFloat',
            style: PosteDesignTokens.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: PosteDesignTokens.spacing4),
          Text(
            'USD: $usdFloat',
            style: PosteDesignTokens.amountMedium.copyWith(
              color: PosteDesignTokens.tealPale,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

#### 4.3.2 AgentActionTile

**Path:** `apps/agent_mobile/lib/widgets/agent_action_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

class AgentActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AgentActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing4,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(PosteDesignTokens.spacing8),
          decoration: BoxDecoration(
            color: PosteDesignTokens.tealPale,
            borderRadius: PosteDesignTokens.borderRadiusSmall,
          ),
          child: Icon(
            icon,
            color: PosteDesignTokens.primaryTeal,
            size: 24,
          ),
        ),
        title: Text(label, style: PosteDesignTokens.bodyBold),
        trailing: const Icon(
          Icons.chevron_right,
          color: PosteDesignTokens.textTertiary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: PosteDesignTokens.borderRadiusMedium,
          side: const BorderSide(color: PosteDesignTokens.borderDefault),
        ),
        tileColor: Colors.white,
      ),
    );
  }
}
```

**Usage in `agent_home_screen.dart`:**

```dart
AgentActionTile(
  icon: Icons.arrow_downward,
  label: 'Cash In',
  onTap: () => Navigator.pushNamed(context, '/cash-in'),
),
AgentActionTile(
  icon: Icons.arrow_upward,
  label: 'Cash Out',
  onTap: () => Navigator.pushNamed(context, '/cash-out'),
),
AgentActionTile(
  icon: Icons.payment,
  label: 'Pay for customer',
  onTap: () => Navigator.pushNamed(context, '/assisted-pay'),
),
AgentActionTile(
  icon: Icons.person_add,
  label: 'Enroll',
  onTap: () => Navigator.pushNamed(context, '/enroll'),
),
AgentActionTile(
  icon: Icons.history,
  label: 'History',
  onTap: () => Navigator.pushNamed(context, '/history'),
),
```

---

### 4.4 Cash In / Out Screen

**Path:** `apps/agent_mobile/lib/screens/cash_in_out_screen.dart`

**Changes:**
- Apply agent theme tokens
- Use existing `CustomerLookupField` widget (no visual changes; inherits theme)
- Use `PostePrimaryButton` equivalent (agent version) for "Continue"

**No new widgets required.**

---

### 4.5 Assisted Pay Screen

**Path:** `apps/agent_mobile/lib/screens/assisted_pay_screen.dart`

Apply agent theme; use `PostePrimaryButton` for "Continue".

---

### 4.6 Agent History Screen

**Path:** `apps/agent_mobile/lib/screens/agent_history_screen.dart`

**Layout:**

```
┌────────────────────────────────────────┐
│  History                     [< Back]  │
├────────────────────────────────────────┤
│ [All] [Cash In] [Cash Out]             │
│ [Enroll] [Bill] [Airtime]              │  ← Filter chips
│                                        │
│  Today                                 │
│  [AgentTxnTile]                        │
│  [AgentTxnTile]                        │
└────────────────────────────────────────┘
```

**New widget:**

#### 4.6.1 AgentTxnTile

**Path:** `apps/agent_mobile/lib/widgets/agent_txn_tile.dart`

Same structure as `PosteTxnTile` (customer); duplicate with agent-specific styling (filled chip badge for txn type).

---

### 4.7 Enroll Screen

**Path:** `apps/agent_mobile/lib/screens/enroll_screen.dart`

Apply agent theme; use `PostePrimaryButton` for "Submit".

---

### 4.8 Agent Receipt Card

**Widget:** Receipt dialog after successful cash / bill / airtime transaction.

**Path:** `apps/agent_mobile/lib/widgets/agent_receipt_card.dart`

```dart
import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

class AgentReceiptCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> fields;
  final VoidCallback onDone;

  const AgentReceiptCard({
    super.key,
    required this.title,
    required this.fields,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: PosteDesignTokens.borderRadiusMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(PosteDesignTokens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: PosteDesignTokens.accentGreen,
              size: 48,
            ),
            const SizedBox(height: PosteDesignTokens.spacing12),
            Text(title, style: PosteDesignTokens.heading2),
            const SizedBox(height: PosteDesignTokens.spacing16),
            ...fields.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PosteDesignTokens.spacing4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: PosteDesignTokens.caption),
                  Text(entry.value, style: PosteDesignTokens.bodyBold),
                ],
              ),
            )),
            const SizedBox(height: PosteDesignTokens.spacing24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Usage in receipt flow:**

```dart
showDialog(
  context: context,
  builder: (context) => AgentReceiptCard(
    title: 'Bill Payment Successful',
    fields: [
      MapEntry('Customer', 'Jean-Paul Kabila'),
      MapEntry('Biller', 'SNEL Kinshasa'),
      MapEntry('Amount', 'FC 50.00'),
      MapEntry('Fee', 'FC 0.25'),
      MapEntry('Total', 'FC 50.25'),
      MapEntry('Float left', 'FC 4,999,949.75'),
      MapEntry('Journal', 'jnl_assistbill_s_17'),
    ],
    onDone: () => Navigator.pop(context),
  ),
);
```

---

## 5. Rollout Order

### Phase 1: Shared Tokens + ThemeData (Week 1)
1. Create `PosteDesignTokens` in customer + agent apps
2. Create `buildPosteTheme()` and `buildAgentPosteTheme()`
3. Update `main.dart` MaterialApp in both apps
4. Verify existing screens inherit theme (no manual widget edits yet)

### Phase 2: Customer Home + Core Flows (Week 2)
1. Create `PosteBalanceCard`, `PosteQuickAction`, `PosteTxnTile`, `PostePrimaryButton`
2. Update `home_screen.dart` layout
3. Update `pay_bill_screen.dart` and `send_money_screen.dart`
4. Update `history_screen.dart`

### Phase 3: Customer Savings + Insurance (Week 3)
1. Create `PosteProductCard`
2. Update `savings_screen.dart`
3. Update `insurance_screen.dart`

### Phase 4: Agent Home + Core Flows (Week 4)
1. Create `AgentFloatCard`, `AgentActionTile`, `AgentTxnTile`, `AgentReceiptCard`
2. Update `agent_home_screen.dart`
3. Update `cash_in_out_screen.dart`, `assisted_pay_screen.dart`
4. Update `agent_history_screen.dart`, `enroll_screen.dart`

### Phase 5: Polish + Testing (Week 5)
1. Visual regression testing (screenshot comparison)
2. Theme consistency audit (all screens match tokens)
3. Accessibility audit (color contrast, touch targets)
4. Demo video recording (customer + agent flows)

---

## 6. Acceptance Criteria

### 6.1 Shared Tokens
- [ ] `PosteDesignTokens` exists in customer and agent apps (duplicate files)
- [ ] `buildPosteTheme()` and `buildAgentPosteTheme()` return Material3 `ThemeData`
- [ ] Both apps use teal `#00acac` primary color
- [ ] All border radii consistent: 8px buttons, 12px cards, 16px modals
- [ ] Shadows subtle: elevation 2–4 only
- [ ] Typography uses Inter fallback or system default
- [ ] `MaterialApp` theme applied; existing screens inherit theme without manual edits

### 6.2 Customer Screens
- [ ] Login screen shows Poste logo + teal accent
- [ ] Home screen uses `PosteBalanceCard` (teal gradient, balance toggle)
- [ ] Home quick actions grid uses `PosteQuickAction` widgets
- [ ] Recent transactions list uses `PosteTxnTile` widgets
- [ ] Pay Bill screen uses theme input fields + `PostePrimaryButton`
- [ ] History screen filter chips outlined with teal border when selected
- [ ] Savings screen uses `PosteProductCard` for products
- [ ] Insurance screen uses `PosteProductCard` for premiums
- [ ] All screens inherit theme tokens (no hardcoded colors beyond tokens)

### 6.3 Agent Screens
- [ ] Agent login shows Poste logo + teal accent
- [ ] Agent home uses `AgentFloatCard` (teal gradient, CDF + USD)
- [ ] Agent home quick actions use `AgentActionTile` vertical list
- [ ] Cash in/out screens use theme input fields + agent button
- [ ] Assisted pay screen uses theme tokens
- [ ] Agent history uses `AgentTxnTile` widgets
- [ ] Enroll screen uses theme tokens
- [ ] Receipt dialogs use `AgentReceiptCard` widget

### 6.4 Customer vs Agent Distinction
- [ ] Customer app uses outlined status chips (preserve existing)
- [ ] Agent app uses filled status chips/badges (preserve existing)
- [ ] No cross-contamination of chip styles

### 6.5 Visual Regression
- [ ] Screenshot comparison: before/after shows consistent branding
- [ ] No broken layouts (text overflow, alignment issues)
- [ ] Color contrast ratios ≥ 4.5:1 for body text, ≥ 3:1 for large text (WCAG AA)
- [ ] Touch targets ≥ 48×48 logical pixels (Material Design spec)

### 6.6 Tests
- [ ] Theme unit test: `buildPosteTheme()` returns `ThemeData` with teal primary
- [ ] Widget tests: `PosteBalanceCard`, `PosteQuickAction`, `PosteTxnTile` render correctly
- [ ] Widget tests: `AgentFloatCard`, `AgentActionTile`, `AgentReceiptCard` render correctly
- [ ] Screenshot tests: customer home, agent home, pay bill, history (golden file comparison)

---

## 7. Files to Modify

### 7.1 New Files (Customer)
- `lib/constants/poste_design_tokens.dart` — Design tokens constant class
- `lib/theme/poste_theme.dart` — `buildPosteTheme()` function
- `lib/widgets/brand/poste_balance_card.dart` — Balance card with gradient
- `lib/widgets/brand/poste_quick_action.dart` — Quick action grid tile
- `lib/widgets/brand/poste_txn_tile.dart` — Transaction list tile
- `lib/widgets/brand/poste_primary_button.dart` — Primary button with loading state
- `lib/widgets/brand/poste_product_card.dart` — Savings/insurance product card

### 7.2 Enhanced Files (Customer)
- `lib/main.dart` — Update `MaterialApp` theme: `buildPosteTheme()`
- `lib/screens/login_screen.dart` — Apply theme tokens (logo, inputs, button)
- `lib/screens/home_screen.dart` — Use `PosteBalanceCard`, `PosteQuickAction`, `PosteTxnTile`
- `lib/screens/pay_bill_screen.dart` — Apply theme inputs + `PostePrimaryButton`
- `lib/screens/send_money_screen.dart` — Apply theme inputs + `PostePrimaryButton`
- `lib/screens/history_screen.dart` — Use `PosteTxnTile`, theme filter chips
- `lib/screens/savings_screen.dart` — Use `PosteProductCard`
- `lib/screens/insurance_screen.dart` — Use `PosteProductCard`

### 7.3 New Files (Agent)
- `apps/agent_mobile/lib/constants/poste_design_tokens.dart` — Design tokens (duplicate)
- `apps/agent_mobile/lib/theme/agent_poste_theme.dart` — `buildAgentPosteTheme()`
- `apps/agent_mobile/lib/widgets/agent_float_card.dart` — Float card with gradient
- `apps/agent_mobile/lib/widgets/agent_action_tile.dart` — Quick action list tile
- `apps/agent_mobile/lib/widgets/agent_txn_tile.dart` — Transaction list tile
- `apps/agent_mobile/lib/widgets/agent_receipt_card.dart` — Receipt dialog

### 7.4 Enhanced Files (Agent)
- `apps/agent_mobile/lib/main.dart` — Update `MaterialApp` theme: `buildAgentPosteTheme()`
- `apps/agent_mobile/lib/screens/agent_login_screen.dart` — Apply theme tokens
- `apps/agent_mobile/lib/screens/agent_home_screen.dart` — Use `AgentFloatCard`, `AgentActionTile`
- `apps/agent_mobile/lib/screens/cash_in_out_screen.dart` — Apply theme tokens
- `apps/agent_mobile/lib/screens/assisted_pay_screen.dart` — Apply theme tokens
- `apps/agent_mobile/lib/screens/agent_history_screen.dart` — Use `AgentTxnTile`
- `apps/agent_mobile/lib/screens/enroll_screen.dart` — Apply theme tokens

### 7.5 Tests
- `test/widgets/brand/poste_balance_card_test.dart` — Widget test
- `test/widgets/brand/poste_quick_action_test.dart` — Widget test
- `test/widgets/brand/poste_txn_tile_test.dart` — Widget test
- `test/widgets/brand/poste_product_card_test.dart` — Widget test
- `apps/agent_mobile/test/widgets/agent_float_card_test.dart` — Widget test
- `apps/agent_mobile/test/widgets/agent_action_tile_test.dart` — Widget test
- `apps/agent_mobile/test/widgets/agent_receipt_card_test.dart` — Widget test

### 7.6 Assets (No changes)
- `assets/brand/poste-finance-logo.png` — Existing (already present)
- `assets/brand/poste-finance-logo-light.png` — Existing
- `assets/brand/poste-finance-mark.png` — Existing
- `assets/brand/poste-finance-logo-header.png` — Existing

---

## 8. Implementation Notes

### 8.1 Token Duplication Strategy
- **Phase 1:** Duplicate `PosteDesignTokens` in customer and agent apps (separate files, same values).
- **Rationale:** Avoids premature shared package; customer and agent apps remain independently deployable.
- **Future:** Extract to `packages/design_system` if both apps stabilize and token drift becomes maintenance burden.

### 8.2 Theme Provider Integration
- **Existing:** `lib/providers/theme_provider.dart` handles time-based dark/light switcher.
- **This pass:** Implement light theme only; `buildPosteTheme()` returns light theme.
- **Dark mode:** Deferred to future sprint; `buildPosteDarkTheme()` will mirror token structure with dark palette.

### 8.3 Font Fallback
- **Default:** Use system font (SF Pro on iOS, Roboto on Android).
- **Inter:** If already in `pubspec.yaml`, use it; otherwise defer font package addition (not critical for P0 branding).

### 8.4 Migration Strategy
- **Incremental:** Apply theme tokens screen-by-screen (rollout order above).
- **No big-bang rewrite:** Preserve existing widget logic; update only visual styling.
- **Feature flags:** Not required (branding is visual-only; no behavioral changes).

### 8.5 Offline Demo Banner
- **Preserve:** Existing `OfflineDemoBanner` widget unchanged.
- **Styling:** Inherits theme tokens (background, text color).

### 8.6 Navigation / Routing
- **No changes:** Preserve `app_router.dart`, `go_router`, `main.dart` route config.
- **MaterialApp retained:** Do NOT replace with `CupertinoApp` or custom router.

### 8.7 PIN / Biometrics
- **No changes:** Hardcoded PIN `123456` for agent operations unchanged.
- **Customer PIN:** Hashed PIN validation unchanged.
- **Biometrics:** Out of scope (separate feature).

---

## 9. Risks & Assumptions

### 9.1 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Token duplication → drift over time | Medium — inconsistent branding if tokens diverge | Document single source of truth; periodic audit; future: extract to shared package |
| Theme inheritance incomplete → manual widget edits needed | High — increased implementation effort | Audit existing screens; identify hardcoded colors before rollout |
| Font fallback → inconsistent typography across devices | Low — acceptable for P0 | Document preferred font (Inter); defer custom font package to polish sprint |
| Visual regression in low-priority screens (Profile, Settings) | Medium — inconsistent UX | Accept for P0; audit out-of-scope screens in Phase 5 polish |
| Dark mode expectations from users | Low — light theme acceptable for P0 | Document dark mode as future feature; time-based switcher logic preserved |

### 9.2 Assumptions

1. **Existing logo assets (`assets/brand/poste-finance-*.png`) are production-ready** (correct dimensions, transparent background).
2. **Customer and agent apps are independently deployable** (no shared widget packages required for P0).
3. **Offline demo logic unchanged** (no API contract changes; branding is UI-only).
4. **Material3 supported** (Flutter SDK ≥ 3.16; `useMaterial3: true` in `ThemeData`).
5. **No internationalization (i18n) overhaul** (EN strings only; FR strings stay as-is).
6. **Out-of-scope screens (Profile, KYC, Remittance, FX, Credit) inherit theme without manual edits** (acceptable visual inconsistency for P0).
7. **Admin web app branding deferred** (customer + agent mobile only for this pass).
8. **No custom illustrations or empty state graphics** (use text + icon placeholders for P0).
9. **No animated splash screens or onboarding carousels** (defer to future polish sprint).
10. **Accessibility (color contrast, touch targets) validated in Phase 5 polish** (not blocking for Phase 1–4 rollout).

---

## 10. Future Enhancements (Out of Scope)

1. **Dark mode implementation** (`buildPosteDarkTheme()` with dark palette)
2. **Shared design system package** (`packages/design_system` extracted from duplicated tokens)
3. **Custom font package** (Inter or custom typeface; not system default)
4. **Animated splash screen** (Poste logo animation on app launch)
5. **Onboarding carousels** (Feature walkthrough for new users)
6. **Empty state illustrations** (Custom graphics for "No transactions", "No products", etc.)
7. **Admin web branding** (Color Admin dashboard restyle with Poste teal)
8. **French i18n overhaul** (Complete FR string coverage + locale switcher polish)
9. **Accessibility audit** (WCAG AAA compliance; screen reader optimization)
10. **Push notification styling** (Branded notification templates)
11. **Profile / KYC / Remittance / FX / Credit deep restyle** (Beyond theme inheritance; custom layouts)
12. **Float top-up / EOD / agent locator branding** (Agent-specific features)
13. **Receipt sharing polish** (SMS/email templates with Poste branding)
14. **Demo video production** (High-quality screen recordings for marketing)
15. **A/B testing framework** (Test teal vs alternative color palettes)

---

**End of Design Document**
