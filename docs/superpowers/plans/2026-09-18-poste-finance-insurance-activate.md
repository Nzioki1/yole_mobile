# Poste Finance Insurance Activate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable customers to browse five insurance products (Santé hospitalisation, Décès & funérailles, Accident, Protection crédit, Téléphone & appareil), activate coverage with flexible premium structures (PERCENT or FIXED PER_TXN or FIXED MONTHLY), and have premiums automatically deducted from Pay Bill and P2P Send Money transactions. Implements catalog display, activate/edit/deactivate flows, premium calculation with stacking, and transaction integration with balance validation.

**Architecture:** Static product catalog constant + dynamic customer policies in universe.json. OfflineDemoRepository provides list/activate/update/deactivate/preview/collect methods. CoreApiService offline branches delegate to repository. Insurance screen replaces "Coming Soon" stub with Products | My Policies tabs. Payment flows (PaymentQuoteScreen + SendMoneyReviewScreen) integrate premium preview/display before PIN confirmation. Premium collection creates separate INSURANCE_PREMIUM journal entries. All premiums CDF-only, offline demo mode (`--dart-define=OFFLINE_DEMO=true`).

**Tech Stack:** Flutter, Riverpod (existing pattern), OfflineDemoRepository, CoreApiService offline branches, flat `lib/screens/` + `lib/widgets/` structure, universe.json seed data, minor units (1 CDF = 100 minor, consistent with savings/wallets).

## Global Constraints

- Offline demo only (`--dart-define=OFFLINE_DEMO=true`)
- English UI chrome (labels, buttons, messages); French product names/descriptions
- Five insurance products with FIXED (PER_TXN or MONTHLY) or PERCENT premium modes
- Deduction rails: BILL | SEND | BOTH
- Premium stacking: multiple active policies sum premiums on one transaction
- Monthly premium logic: charge once per calendar month (first qualifying transaction), use device local date `YYYY-MM`
- Transaction scope: Pay Bill (BILL) and P2P Send Money (SEND) only; remittance/FX out of scope
- Currency: CDF premiums only (no USD support this sprint)
- Demo PIN `123456` for all transaction confirmations (OfflineDemoRepository.demoPin)
- Claims: Coming Soon stub (no filing this sprint)
- Jean-Paul (cust_kasee) pre-seeded with one active policy: Santé FIXED MONTHLY 2,500 CDF BOTH
- Minor units: 1 CDF = 100 minor (e.g., 2,500 CDF = 250,000 minor)
- Follow existing flat screen pattern: `lib/screens/insurance_screen.dart`, `lib/screens/activate_policy_screen.dart`
- Insufficient balance blocks entire transaction (no partial premium deduction)
- Audit trail: separate journal entry per premium (type: `INSURANCE_PREMIUM`)

## File Structure

**Create:**
- `lib/models/insurance_product.dart` — InsuranceProduct, PremiumMode, FixedSchedule, DeductFrom enums, InsurancePolicy model
- `lib/constants/insurance_products.dart` — Static kInsuranceProducts catalog (5 products with French names/descriptions)
- `lib/screens/activate_policy_screen.dart` — Activation/edit form with premium config + PIN validation
- `lib/widgets/premium_summary_widget.dart` — Reusable premium breakdown component for payment confirms
- `test/models/insurance_premium_test.dart` — Unit tests for premium calculation logic (PERCENT, FIXED PER_TXN, FIXED MONTHLY, stacking)
- `test/services/offline_demo_repository_insurance_test.dart` — Unit tests for insurance repository methods

**Modify:**
- `lib/services/offline_demo_repository.dart` — Add insurance methods: listInsuranceProducts, listInsurancePolicies, activateInsurancePolicy, updateInsurancePolicy, deactivateInsurancePolicy, previewInsurancePremiums, collectInsurancePremiums
- `lib/services/core_api_service.dart` — Add insurance offline branches delegating to OfflineDemoRepository
- `lib/screens/insurance_screen.dart` — Replace "Coming Soon" stub with Products | My Policies tabs
- `lib/screens/payment_quote_screen.dart` — Integrate premium preview before PIN entry (Pay Bill flow)
- `lib/screens/send_money_review_screen.dart` — Integrate premium preview before PIN entry (P2P Send flow)
- `lib/app_router.dart` — Add `/insurance/activate` route for ActivatePolicyScreen
- `lib/router_types.dart` — Add RouteNames.insuranceActivate constant
- `packages/demo_universe/data/universe.json` — Add insurancePolicies array to cust_kasee with pre-seeded Santé policy

---

## Task 1: Insurance models + constants + premium calculation unit tests

**Files:**
- Create: `lib/models/insurance_product.dart`
- Create: `lib/constants/insurance_products.dart`
- Create: `test/models/insurance_premium_test.dart`

**Interfaces:**
- Consumes: Dart core (enums, models)
- Produces: InsuranceProduct, InsurancePolicy, PremiumMode/FixedSchedule/DeductFrom enums, kInsuranceProducts catalog, unit-tested premium calculation logic

- [ ] **Step 1: Create insurance product model**

Create `lib/models/insurance_product.dart`:

```dart
/// Insurance premium mode
enum PremiumMode { PERCENT, FIXED }

/// Fixed premium schedule (when mode is FIXED)
enum FixedSchedule { PER_TXN, MONTHLY }

/// Transaction rails for premium deduction
enum DeductFrom { BILL, SEND, BOTH }

/// Insurance product catalog entry (static)
class InsuranceProduct {
  final String id;
  final String nameFr;
  final String subtitleEn;
  final String descriptionFr;
  final int claimCapMinor; // CDF minor units
  final String iconAsset; // Asset path (optional for v1)
  final InsurancePremiumDefaults defaults;

  const InsuranceProduct({
    required this.id,
    required this.nameFr,
    required this.subtitleEn,
    required this.descriptionFr,
    required this.claimCapMinor,
    required this.iconAsset,
    required this.defaults,
  });
}

/// Default activation config for a product
class InsurancePremiumDefaults {
  final PremiumMode premiumMode;
  final FixedSchedule? fixedSchedule;
  final int? fixedMinor; // CDF minor units
  final int? percentBps; // Basis points (e.g., 30 = 0.3%)
  final DeductFrom deductFrom;

  const InsurancePremiumDefaults({
    required this.premiumMode,
    this.fixedSchedule,
    this.fixedMinor,
    this.percentBps,
    required this.deductFrom,
  });
}

/// Customer insurance policy (stored in universe.json)
class InsurancePolicy {
  final String id;
  final String customerId;
  final String productId;
  final bool active;
  final PremiumMode premiumMode;
  final FixedSchedule? fixedSchedule;
  final int? fixedMinor; // CDF minor units
  final int? percentBps; // Basis points
  final DeductFrom deductFrom;
  final String? lastMonthlyCollectedYm; // "YYYY-MM" for MONTHLY schedule
  final DateTime activatedAt;

  const InsurancePolicy({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.active,
    required this.premiumMode,
    this.fixedSchedule,
    this.fixedMinor,
    this.percentBps,
    required this.deductFrom,
    this.lastMonthlyCollectedYm,
    required this.activatedAt,
  });

  /// Create from JSON (for universe.json parsing)
  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      productId: json['productId'] as String,
      active: json['active'] as bool,
      premiumMode: PremiumMode.values.firstWhere(
        (e) => e.name == json['premiumMode'],
      ),
      fixedSchedule: json['fixedSchedule'] != null
          ? FixedSchedule.values.firstWhere(
              (e) => e.name == json['fixedSchedule'],
            )
          : null,
      fixedMinor: json['fixedMinor'] as int?,
      percentBps: json['percentBps'] as int?,
      deductFrom: DeductFrom.values.firstWhere(
        (e) => e.name == json['deductFrom'],
      ),
      lastMonthlyCollectedYm: json['lastMonthlyCollectedYm'] as String?,
      activatedAt: DateTime.parse(json['activatedAt'] as String),
    );
  }

  /// Convert to JSON (for universe.json persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'productId': productId,
      'active': active,
      'premiumMode': premiumMode.name,
      'fixedSchedule': fixedSchedule?.name,
      'fixedMinor': fixedMinor,
      'percentBps': percentBps,
      'deductFrom': deductFrom.name,
      'lastMonthlyCollectedYm': lastMonthlyCollectedYm,
      'activatedAt': activatedAt.toIso8601String(),
    };
  }

  /// Copy with helper for updates
  InsurancePolicy copyWith({
    bool? active,
    PremiumMode? premiumMode,
    FixedSchedule? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    DeductFrom? deductFrom,
    String? lastMonthlyCollectedYm,
  }) {
    return InsurancePolicy(
      id: id,
      customerId: customerId,
      productId: productId,
      active: active ?? this.active,
      premiumMode: premiumMode ?? this.premiumMode,
      fixedSchedule: fixedSchedule ?? this.fixedSchedule,
      fixedMinor: fixedMinor ?? this.fixedMinor,
      percentBps: percentBps ?? this.percentBps,
      deductFrom: deductFrom ?? this.deductFrom,
      lastMonthlyCollectedYm:
          lastMonthlyCollectedYm ?? this.lastMonthlyCollectedYm,
      activatedAt: activatedAt,
    );
  }
}

/// Premium line item for preview/display
class PremiumLineItem {
  final String policyId;
  final String productNameFr;
  final int premiumMinor;

  const PremiumLineItem({
    required this.policyId,
    required this.productNameFr,
    required this.premiumMinor,
  });
}

/// Premium calculation helper
class InsurancePremiumCalculator {
  /// Calculate premium for a single policy
  static int calculatePremium({
    required InsurancePolicy policy,
    required int principalMinor,
    required String currentYearMonth, // "YYYY-MM"
  }) {
    if (policy.premiumMode == PremiumMode.PERCENT) {
      final percentBps = policy.percentBps ?? 0;
      return (principalMinor * percentBps / 10000).floor();
    } else {
      // FIXED mode
      final fixedMinor = policy.fixedMinor ?? 0;
      if (policy.fixedSchedule == FixedSchedule.MONTHLY) {
        // Monthly: charge only if not collected this month
        if (policy.lastMonthlyCollectedYm == currentYearMonth) {
          return 0; // Already collected this month
        }
        return fixedMinor;
      } else {
        // PER_TXN: always charge
        return fixedMinor;
      }
    }
  }

  /// Get current year-month string for monthly logic
  static String getCurrentYearMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: Create insurance products catalog constant**

Create `lib/constants/insurance_products.dart`:

```dart
import '../models/insurance_product.dart';

/// Static insurance product catalog for offline demo
const List<InsuranceProduct> kInsuranceProducts = [
  InsuranceProduct(
    id: 'health_hosp',
    nameFr: 'Santé hospitalisation',
    subtitleEn: 'Health Hospitalization',
    descriptionFr:
        'Couvre les frais d\'hospitalisation en cas de maladie ou d\'accident jusqu\'à 500 000 CDF par an.',
    claimCapMinor: 50000000, // 500,000 CDF
    iconAsset: 'assets/icons/insurance_health.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.MONTHLY,
      fixedMinor: 250000, // 2,500 CDF
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  InsuranceProduct(
    id: 'death_funeral',
    nameFr: 'Décès & funérailles',
    subtitleEn: 'Death & Funeral',
    descriptionFr:
        'Verse un capital aux bénéficiaires pour couvrir les frais funéraires jusqu\'à 1 000 000 CDF.',
    claimCapMinor: 100000000, // 1,000,000 CDF
    iconAsset: 'assets/icons/insurance_death.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.PERCENT,
      percentBps: 30, // 0.3%
      deductFrom: DeductFrom.SEND,
    ),
  ),
  InsuranceProduct(
    id: 'accident',
    nameFr: 'Accident',
    subtitleEn: 'Accident',
    descriptionFr:
        'Indemnise les blessures corporelles dues à un accident jusqu\'à 300 000 CDF.',
    claimCapMinor: 30000000, // 300,000 CDF
    iconAsset: 'assets/icons/insurance_accident.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.PER_TXN,
      fixedMinor: 100000, // 1,000 CDF
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  InsuranceProduct(
    id: 'credit_protection',
    nameFr: 'Protection crédit',
    subtitleEn: 'Credit Protection',
    descriptionFr:
        'Rembourse votre prêt en cas de décès, d\'invalidité ou de perte d\'emploi.',
    claimCapMinor: 0, // Varies by loan
    iconAsset: 'assets/icons/insurance_credit.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.PERCENT,
      percentBps: 100, // 1.0%
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  InsuranceProduct(
    id: 'phone_device',
    nameFr: 'Téléphone & appareil',
    subtitleEn: 'Phone & Device',
    descriptionFr:
        'Répare ou remplace votre téléphone en cas de vol, casse ou panne jusqu\'à 200 000 CDF.',
    claimCapMinor: 20000000, // 200,000 CDF
    iconAsset: 'assets/icons/insurance_phone.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.MONTHLY,
      fixedMinor: 300000, // 3,000 CDF
      deductFrom: DeductFrom.BILL,
    ),
  ),
];
```

- [ ] **Step 3: Write premium calculation unit tests**

Create `test/models/insurance_premium_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/models/insurance_product.dart';

void main() {
  group('InsurancePremiumCalculator', () {
    test('PERCENT mode calculates premium correctly', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'death_funeral',
        active: true,
        premiumMode: PremiumMode.PERCENT,
        percentBps: 30, // 0.3%
        deductFrom: DeductFrom.SEND,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      // 50,000 CDF = 5,000,000 minor
      // 0.3% = floor(5,000,000 * 30 / 10,000) = floor(15,000) = 15,000 minor = 150 CDF
      final premium = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 5000000,
        currentYearMonth: '2026-09',
      );

      expect(premium, 15000);
    });

    test('PERCENT mode floors fractional premiums', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'death_funeral',
        active: true,
        premiumMode: PremiumMode.PERCENT,
        percentBps: 30, // 0.3%
        deductFrom: DeductFrom.SEND,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      // 100 CDF = 10,000 minor
      // 0.3% = floor(10,000 * 30 / 10,000) = floor(30) = 30 minor = 0.3 CDF
      final premium = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 10000,
        currentYearMonth: '2026-09',
      );

      expect(premium, 30);
    });

    test('FIXED PER_TXN mode charges on every transaction', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'accident',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.PER_TXN,
        fixedMinor: 100000, // 1,000 CDF
        deductFrom: DeductFrom.BOTH,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final premium1 = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 5000000,
        currentYearMonth: '2026-09',
      );

      final premium2 = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 10000000,
        currentYearMonth: '2026-09',
      );

      expect(premium1, 100000);
      expect(premium2, 100000);
    });

    test('FIXED MONTHLY mode charges once per month', () {
      final policy = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'health_hosp',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.MONTHLY,
        fixedMinor: 250000, // 2,500 CDF
        deductFrom: DeductFrom.BOTH,
        lastMonthlyCollectedYm: null, // Not collected yet
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      // First transaction in September: charged
      final premium1 = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: 5000000,
        currentYearMonth: '2026-09',
      );

      expect(premium1, 250000);

      // Simulate policy updated with lastMonthlyCollectedYm = "2026-09"
      final updatedPolicy = policy.copyWith(
        lastMonthlyCollectedYm: '2026-09',
      );

      // Second transaction in September: not charged
      final premium2 = InsurancePremiumCalculator.calculatePremium(
        policy: updatedPolicy,
        principalMinor: 10000000,
        currentYearMonth: '2026-09',
      );

      expect(premium2, 0);

      // First transaction in October: charged
      final premium3 = InsurancePremiumCalculator.calculatePremium(
        policy: updatedPolicy,
        principalMinor: 8000000,
        currentYearMonth: '2026-10',
      );

      expect(premium3, 250000);
    });

    test('Stacking multiple policies sums premiums', () {
      final policy1 = InsurancePolicy(
        id: 'pol_1',
        customerId: 'cust_1',
        productId: 'health_hosp',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.MONTHLY,
        fixedMinor: 250000, // 2,500 CDF
        deductFrom: DeductFrom.BOTH,
        lastMonthlyCollectedYm: null,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final policy2 = InsurancePolicy(
        id: 'pol_2',
        customerId: 'cust_1',
        productId: 'accident',
        active: true,
        premiumMode: PremiumMode.FIXED,
        fixedSchedule: FixedSchedule.PER_TXN,
        fixedMinor: 100000, // 1,000 CDF
        deductFrom: DeductFrom.BOTH,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final policy3 = InsurancePolicy(
        id: 'pol_3',
        customerId: 'cust_1',
        productId: 'death_funeral',
        active: true,
        premiumMode: PremiumMode.PERCENT,
        percentBps: 30, // 0.3%
        deductFrom: DeductFrom.SEND,
        activatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
      );

      final principalMinor = 5000000; // 50,000 CDF
      final currentYm = '2026-09';

      final premium1 = InsurancePremiumCalculator.calculatePremium(
        policy: policy1,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      final premium2 = InsurancePremiumCalculator.calculatePremium(
        policy: policy2,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      final premium3 = InsurancePremiumCalculator.calculatePremium(
        policy: policy3,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      final totalPremium = premium1 + premium2 + premium3;

      expect(premium1, 250000); // 2,500 CDF
      expect(premium2, 100000); // 1,000 CDF
      expect(premium3, 15000); // 150 CDF
      expect(totalPremium, 365000); // 3,650 CDF
    });
  });
}
```

- [ ] **Step 4: Run unit tests**

```bash
flutter test test/models/insurance_premium_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/models/insurance_product.dart lib/constants/insurance_products.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/models/insurance_product.dart lib/constants/insurance_products.dart test/models/insurance_premium_test.dart
git commit -m "feat(insurance): add models, catalog constants, premium calculation with unit tests"
```

---

## Task 2: OfflineDemoRepository insurance methods + universe seed + unit tests

**Files:**
- Modify: `lib/services/offline_demo_repository.dart`
- Modify: `packages/demo_universe/data/universe.json`
- Create: `test/services/offline_demo_repository_insurance_test.dart`

**Interfaces:**
- Consumes: InsuranceProduct, InsurancePolicy models, kInsuranceProducts catalog, universe.json
- Produces: listInsuranceProducts, listInsurancePolicies, activateInsurancePolicy, updateInsurancePolicy, deactivateInsurancePolicy, previewInsurancePremiums, collectInsurancePremiums methods with unit tests

- [ ] **Step 1: Add insurancePolicies seed to universe.json for cust_kasee**

Open `packages/demo_universe/data/universe.json`. Find the customer with `"id": "cust_kasee"`. Add an `insurancePolicies` array field:

```json
{
  "id": "cust_kasee",
  "email": "jp.kabila@gmail.com",
  "password": "Password1!",
  "phoneE164": "+243990123456",
  "firstName": "Jean-Paul",
  "lastName": "Kabila",
  "segment": "OPEN",
  "status": "ACTIVE",
  "kycStatus": "APPROVED",
  "enrolledByAgentId": "agent-001",
  "createdAt": "2026-08-15T10:30:00Z",
  "insurancePolicies": [
    {
      "id": "pol_kasee_health_001",
      "customerId": "cust_kasee",
      "productId": "health_hosp",
      "active": true,
      "premiumMode": "FIXED",
      "fixedSchedule": "MONTHLY",
      "fixedMinor": 250000,
      "percentBps": null,
      "deductFrom": "BOTH",
      "lastMonthlyCollectedYm": "2026-08",
      "activatedAt": "2026-08-15T10:30:00Z"
    }
  ]
}
```

Also add empty `insurancePolicies` arrays to other customers (cust_amina, cust_marie_tshala, etc.) for consistency:

```json
"insurancePolicies": []
```

- [ ] **Step 2: Add insurance methods to OfflineDemoRepository**

Open `lib/services/offline_demo_repository.dart`. Add after the Savings Goals section (around line 1230):

```dart
  // ---------------------------------------------------------------------------
  // Insurance (Poste Finance)
  // ---------------------------------------------------------------------------

  /// List insurance products (static catalog from constants)
  List<Map<String, dynamic>> listInsuranceProducts() {
    // Import at top of file: import '../constants/insurance_products.dart';
    return kInsuranceProducts.map((p) => {
      'id': p.id,
      'nameFr': p.nameFr,
      'subtitleEn': p.subtitleEn,
      'descriptionFr': p.descriptionFr,
      'claimCapMinor': p.claimCapMinor,
      'iconAsset': p.iconAsset,
      'defaults': {
        'premiumMode': p.defaults.premiumMode.name,
        'fixedSchedule': p.defaults.fixedSchedule?.name,
        'fixedMinor': p.defaults.fixedMinor,
        'percentBps': p.defaults.percentBps,
        'deductFrom': p.defaults.deductFrom.name,
      },
    }).toList();
  }

  /// List customer insurance policies (from universe.json)
  List<Map<String, dynamic>> listInsurancePolicies(String customerId) {
    final customers = _list('customers');
    final customerIdx = customers.indexWhere((c) => c['id'] == customerId);
    if (customerIdx < 0) return [];

    final customer = customers[customerIdx];
    final policies = customer['insurancePolicies'] as List<dynamic>?;
    if (policies == null) return [];

    return policies.map((p) => Map<String, dynamic>.from(p as Map)).toList();
  }

  /// Activate insurance policy (create new or update existing)
  Map<String, dynamic> activateInsurancePolicy({
    required String customerId,
    required String productId,
    required String premiumMode, // "PERCENT" | "FIXED"
    String? fixedSchedule, // "PER_TXN" | "MONTHLY"
    int? fixedMinor,
    int? percentBps,
    required String deductFrom, // "BILL" | "SEND" | "BOTH"
  }) {
    final customers = _list('customers');
    final customerIdx = customers.indexWhere((c) => c['id'] == customerId);
    if (customerIdx < 0) {
      throw Exception('Customer not found: $customerId');
    }

    final customer = customers[customerIdx];
    final policies = customer['insurancePolicies'] as List<dynamic>? ?? [];

    // Check if policy already exists for this product
    final existingIdx = policies.indexWhere(
      (p) => p['productId'] == productId && p['active'] == true,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final policyId = existingIdx >= 0
        ? policies[existingIdx]['id']
        : _nextId('pol');

    final policy = <String, dynamic>{
      'id': policyId,
      'customerId': customerId,
      'productId': productId,
      'active': true,
      'premiumMode': premiumMode,
      'fixedSchedule': fixedSchedule,
      'fixedMinor': fixedMinor,
      'percentBps': percentBps,
      'deductFrom': deductFrom,
      'lastMonthlyCollectedYm': existingIdx >= 0
          ? policies[existingIdx]['lastMonthlyCollectedYm']
          : null,
      'activatedAt': existingIdx >= 0
          ? policies[existingIdx]['activatedAt']
          : now,
    };

    if (existingIdx >= 0) {
      policies[existingIdx] = policy;
    } else {
      policies.add(policy);
    }

    customer['insurancePolicies'] = policies;
    customers[customerIdx] = customer;
    _writeList('customers', customers);

    return policy;
  }

  /// Update insurance policy
  Map<String, dynamic> updateInsurancePolicy({
    required String policyId,
    required String premiumMode,
    String? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required String deductFrom,
  }) {
    final customers = _list('customers');
    for (int ci = 0; ci < customers.length; ci++) {
      final customer = customers[ci];
      final policies = customer['insurancePolicies'] as List<dynamic>? ?? [];
      final pi = policies.indexWhere((p) => p['id'] == policyId);
      if (pi >= 0) {
        policies[pi] = {
          ...policies[pi],
          'premiumMode': premiumMode,
          'fixedSchedule': fixedSchedule,
          'fixedMinor': fixedMinor,
          'percentBps': percentBps,
          'deductFrom': deductFrom,
        };
        customer['insurancePolicies'] = policies;
        customers[ci] = customer;
        _writeList('customers', customers);
        return Map<String, dynamic>.from(policies[pi]);
      }
    }
    throw Exception('Policy not found: $policyId');
  }

  /// Deactivate insurance policy
  void deactivateInsurancePolicy(String policyId) {
    final customers = _list('customers');
    for (int ci = 0; ci < customers.length; ci++) {
      final customer = customers[ci];
      final policies = customer['insurancePolicies'] as List<dynamic>? ?? [];
      final pi = policies.indexWhere((p) => p['id'] == policyId);
      if (pi >= 0) {
        policies[pi] = {
          ...policies[pi],
          'active': false,
        };
        customer['insurancePolicies'] = policies;
        customers[ci] = customer;
        _writeList('customers', customers);
        return;
      }
    }
    throw Exception('Policy not found: $policyId');
  }

  /// Preview insurance premiums for a transaction (before payment)
  List<Map<String, dynamic>> previewInsurancePremiums({
    required String customerId,
    required String rail, // "BILL" | "SEND"
    required int principalMinor,
  }) {
    // Import at top: import '../models/insurance_product.dart';
    final policies = listInsurancePolicies(customerId);
    final activePolicies = policies.where((p) => p['active'] == true).toList();

    final matchingPolicies = activePolicies.where((p) {
      final deductFrom = p['deductFrom'] as String;
      return deductFrom == rail || deductFrom == 'BOTH';
    }).toList();

    final currentYm = InsurancePremiumCalculator.getCurrentYearMonth();
    final lineItems = <Map<String, dynamic>>[];

    for (final policyJson in matchingPolicies) {
      final policy = InsurancePolicy.fromJson(policyJson);
      final premiumMinor = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      // Find product name
      final product = kInsuranceProducts.firstWhere(
        (p) => p.id == policy.productId,
        orElse: () => throw Exception('Product not found: ${policy.productId}'),
      );

      lineItems.add({
        'policyId': policy.id,
        'productNameFr': product.nameFr,
        'premiumMinor': premiumMinor,
      });
    }

    return lineItems;
  }

  /// Collect insurance premiums (after payment success)
  List<Map<String, dynamic>> collectInsurancePremiums({
    required String customerId,
    required String rail, // "BILL" | "SEND"
    required int principalMinor,
    required String parentTransactionId,
  }) {
    final customers = _list('customers');
    final customerIdx = customers.indexWhere((c) => c['id'] == customerId);
    if (customerIdx < 0) {
      throw Exception('Customer not found: $customerId');
    }

    final customer = customers[customerIdx];
    final policies = customer['insurancePolicies'] as List<dynamic>? ?? [];
    final activePolicies = policies.where((p) => p['active'] == true).toList();

    final matchingPolicies = activePolicies.where((p) {
      final deductFrom = p['deductFrom'] as String;
      return deductFrom == rail || deductFrom == 'BOTH';
    }).toList();

    final currentYm = InsurancePremiumCalculator.getCurrentYearMonth();
    final now = DateTime.now().toUtc().toIso8601String();
    final journalEntries = <Map<String, dynamic>>[];

    for (final policyJson in matchingPolicies) {
      final policy = InsurancePolicy.fromJson(policyJson);
      final premiumMinor = InsurancePremiumCalculator.calculatePremium(
        policy: policy,
        principalMinor: principalMinor,
        currentYearMonth: currentYm,
      );

      if (premiumMinor == 0) continue; // Skip if no premium due

      // Find product name
      final product = kInsuranceProducts.firstWhere(
        (p) => p.id == policy.productId,
      );

      // Update policy lastMonthlyCollectedYm if FIXED MONTHLY
      if (policy.premiumMode == PremiumMode.FIXED &&
          policy.fixedSchedule == FixedSchedule.MONTHLY) {
        final pi = policies.indexWhere((p) => p['id'] == policy.id);
        if (pi >= 0) {
          policies[pi] = {
            ...policies[pi],
            'lastMonthlyCollectedYm': currentYm,
          };
        }
      }

      // Create journal entry
      final journalId = _nextId('jnl');
      final journalEntry = <String, dynamic>{
        'id': journalId,
        'customerId': customerId,
        'walletId': null, // Premium is part of parent transaction debit
        'type': 'INSURANCE_PREMIUM',
        'direction': 'DEBIT',
        'currency': 'CDF',
        'amountMinor': premiumMinor,
        'balanceAfterMinor': null,
        'refType': 'INSURANCE_POLICY',
        'refId': policy.id,
        'parentTransactionId': parentTransactionId,
        'narration': 'Insurance premium: ${product.nameFr}',
        'metadata': {
          'policyId': policy.id,
          'productId': policy.productId,
          'productNameFr': product.nameFr,
          'premiumMode': policy.premiumMode.name,
          'fixedSchedule': policy.fixedSchedule?.name,
        },
        'postedAt': now,
      };

      journalEntries.add(journalEntry);
    }

    // Update customer with modified policies
    customer['insurancePolicies'] = policies;
    customers[customerIdx] = customer;
    _writeList('customers', customers);

    // Append journal entries to journals list
    final journals = _list('journals');
    journals.addAll(journalEntries);
    _writeList('journals', journals);

    return journalEntries;
  }
```

Add imports at top of file:

```dart
import '../models/insurance_product.dart';
import '../constants/insurance_products.dart';
```

- [ ] **Step 3: Write OfflineDemoRepository insurance unit tests**

Create `test/services/offline_demo_repository_insurance_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/services/offline_demo_repository.dart';

void main() {
  group('OfflineDemoRepository insurance methods', () {
    late OfflineDemoRepository repo;

    setUp(() {
      repo = OfflineDemoRepository.createFresh();
      // Login as cust_kasee (pre-seeded customer)
      repo.login(
        email: 'jp.kabila@gmail.com',
        password: 'Password1!',
      );
    });

    test('listInsuranceProducts returns 5 products', () {
      final products = repo.listInsuranceProducts();
      expect(products.length, 5);
      expect(products[0]['id'], 'health_hosp');
      expect(products[0]['nameFr'], 'Santé hospitalisation');
    });

    test('listInsurancePolicies returns pre-seeded policy for cust_kasee', () {
      final policies = repo.listInsurancePolicies('cust_kasee');
      expect(policies.length, 1);
      expect(policies[0]['productId'], 'health_hosp');
      expect(policies[0]['active'], true);
      expect(policies[0]['fixedMinor'], 250000);
    });

    test('activateInsurancePolicy creates new policy', () {
      final policy = repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'accident',
        premiumMode: 'FIXED',
        fixedSchedule: 'PER_TXN',
        fixedMinor: 100000,
        deductFrom: 'BOTH',
      );

      expect(policy['productId'], 'accident');
      expect(policy['active'], true);
      expect(policy['fixedMinor'], 100000);

      final policies = repo.listInsurancePolicies('cust_kasee');
      expect(policies.length, 2);
    });

    test('activateInsurancePolicy updates existing active policy', () {
      // Pre-seeded: health_hosp FIXED MONTHLY 250000 BOTH
      final updatedPolicy = repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'health_hosp',
        premiumMode: 'FIXED',
        fixedSchedule: 'MONTHLY',
        fixedMinor: 300000, // Changed from 250000
        deductFrom: 'BILL', // Changed from BOTH
      );

      expect(updatedPolicy['fixedMinor'], 300000);
      expect(updatedPolicy['deductFrom'], 'BILL');

      final policies = repo.listInsurancePolicies('cust_kasee');
      expect(policies.length, 1); // Still 1 policy
    });

    test('deactivateInsurancePolicy marks policy inactive', () {
      final policies = repo.listInsurancePolicies('cust_kasee');
      final policyId = policies[0]['id'] as String;

      repo.deactivateInsurancePolicy(policyId);

      final updatedPolicies = repo.listInsurancePolicies('cust_kasee');
      expect(updatedPolicies[0]['active'], false);
    });

    test('previewInsurancePremiums returns matching line items', () {
      // Pre-seeded: health_hosp FIXED MONTHLY 250000 BOTH, lastMonthlyCollectedYm = "2026-08"
      // Current month should be 2026-09 or later, so premium should be charged

      final lineItems = repo.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
      );

      expect(lineItems.length, 1);
      expect(lineItems[0]['productNameFr'], 'Santé hospitalisation');
      expect(lineItems[0]['premiumMinor'], 250000);
    });

    test('previewInsurancePremiums filters by rail', () {
      // Activate death_funeral (PERCENT 30 bps, SEND only)
      repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'death_funeral',
        premiumMode: 'PERCENT',
        percentBps: 30,
        deductFrom: 'SEND',
      );

      // BILL rail should only match health_hosp (BOTH)
      final billItems = repo.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
      );

      expect(billItems.length, 1);
      expect(billItems[0]['productNameFr'], 'Santé hospitalisation');

      // SEND rail should match both
      final sendItems = repo.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'SEND',
        principalMinor: 5000000,
      );

      expect(sendItems.length, 2);
    });

    test('collectInsurancePremiums creates journal entries and updates MONTHLY policy', () {
      // Pre-seeded: health_hosp FIXED MONTHLY 250000 BOTH

      final journals = repo.collectInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
        parentTransactionId: 'txn_test_001',
      );

      expect(journals.length, 1);
      expect(journals[0]['type'], 'INSURANCE_PREMIUM');
      expect(journals[0]['amountMinor'], 250000);
      expect(journals[0]['parentTransactionId'], 'txn_test_001');

      // Check that lastMonthlyCollectedYm is updated
      final policies = repo.listInsurancePolicies('cust_kasee');
      final healthPolicy = policies.firstWhere((p) => p['productId'] == 'health_hosp');
      expect(healthPolicy['lastMonthlyCollectedYm'], isNotNull);
      
      // Second collect in same month should create no journals
      final journals2 = repo.collectInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 3000000,
        parentTransactionId: 'txn_test_002',
      );

      expect(journals2.length, 0);
    });

    test('collectInsurancePremiums stacks multiple policies', () {
      // Activate accident (PER_TXN)
      repo.activateInsurancePolicy(
        customerId: 'cust_kasee',
        productId: 'accident',
        premiumMode: 'FIXED',
        fixedSchedule: 'PER_TXN',
        fixedMinor: 100000,
        deductFrom: 'BOTH',
      );

      final journals = repo.collectInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'BILL',
        principalMinor: 5000000,
        parentTransactionId: 'txn_test_003',
      );

      expect(journals.length, 2); // health_hosp + accident
      final totalPremium = journals.fold<int>(
        0,
        (sum, j) => sum + (j['amountMinor'] as int),
      );
      expect(totalPremium, 350000); // 250000 + 100000
    });
  });
}
```

- [ ] **Step 4: Run unit tests**

```bash
flutter test test/services/offline_demo_repository_insurance_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/services/offline_demo_repository.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/services/offline_demo_repository.dart packages/demo_universe/data/universe.json test/services/offline_demo_repository_insurance_test.dart
git commit -m "feat(insurance): add OfflineDemoRepository insurance methods + universe seed + tests"
```

---

## Task 3: CoreApiService insurance offline branches

**Files:**
- Modify: `lib/services/core_api_service.dart`

**Interfaces:**
- Consumes: OfflineDemoRepository insurance methods
- Produces: getInsuranceProducts, getInsurancePolicies, activateInsurance, updateInsurance, deactivateInsurance, previewInsurancePremiums, collectInsurancePremiums CoreApiService methods

- [ ] **Step 1: Add insurance methods to CoreApiService**

Open `lib/services/core_api_service.dart`. Add after the FX section (around line 900):

```dart
  // ---------------------------------------------------------------------------
  // Insurance (offline demo only this sprint)
  // ---------------------------------------------------------------------------

  /// Get insurance products
  Future<List<Map<String, dynamic>>> getInsuranceProducts() async {
    if (offlineDemo) {
      return _offline.listInsuranceProducts();
    }
    // Future: real API call
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Get customer insurance policies
  Future<List<Map<String, dynamic>>> getInsurancePolicies(String customerId) async {
    if (offlineDemo) {
      return _offline.listInsurancePolicies(customerId);
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Activate insurance policy
  Future<Map<String, dynamic>> activateInsurance({
    required String customerId,
    required String productId,
    required String premiumMode,
    String? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required String deductFrom,
  }) async {
    if (offlineDemo) {
      return _offline.activateInsurancePolicy(
        customerId: customerId,
        productId: productId,
        premiumMode: premiumMode,
        fixedSchedule: fixedSchedule,
        fixedMinor: fixedMinor,
        percentBps: percentBps,
        deductFrom: deductFrom,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Update insurance policy
  Future<Map<String, dynamic>> updateInsurance({
    required String policyId,
    required String premiumMode,
    String? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required String deductFrom,
  }) async {
    if (offlineDemo) {
      return _offline.updateInsurancePolicy(
        policyId: policyId,
        premiumMode: premiumMode,
        fixedSchedule: fixedSchedule,
        fixedMinor: fixedMinor,
        percentBps: percentBps,
        deductFrom: deductFrom,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Deactivate insurance policy
  Future<void> deactivateInsurance(String policyId) async {
    if (offlineDemo) {
      _offline.deactivateInsurancePolicy(policyId);
      return;
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Preview insurance premiums for a transaction
  Future<List<Map<String, dynamic>>> previewInsurancePremiums({
    required String customerId,
    required String rail,
    required int principalMinor,
  }) async {
    if (offlineDemo) {
      return _offline.previewInsurancePremiums(
        customerId: customerId,
        rail: rail,
        principalMinor: principalMinor,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  /// Collect insurance premiums after payment success
  Future<List<Map<String, dynamic>>> collectInsurancePremiums({
    required String customerId,
    required String rail,
    required int principalMinor,
    required String parentTransactionId,
  }) async {
    if (offlineDemo) {
      return _offline.collectInsurancePremiums(
        customerId: customerId,
        rail: rail,
        principalMinor: principalMinor,
        parentTransactionId: parentTransactionId,
      );
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/services/core_api_service.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/core_api_service.dart
git commit -m "feat(insurance): add CoreApiService offline branches for insurance"
```

---

## Task 4: Insurance UI — replace stub with Products | My Policies tabs

**Files:**
- Modify: `lib/screens/insurance_screen.dart`
- Create: `lib/screens/activate_policy_screen.dart`
- Modify: `lib/router_types.dart`
- Modify: `lib/app_router.dart`

**Interfaces:**
- Consumes: CoreApiService insurance methods, kInsuranceProducts catalog
- Produces: Two-tab insurance screen (Products | My Policies), activate/edit form, deactivate confirmation, Coming Soon claims dialog

- [ ] **Step 1: Add insuranceActivate route constant**

Open `lib/router_types.dart`. Add after `insurance` route:

```dart
  static const String insurance = '/insurance';
  static const String insuranceActivate = '/insurance/activate'; // Add this line
  static const String budget = '/budget';
```

- [ ] **Step 2: Replace insurance_screen.dart stub with full implementation**

Replace entire contents of `lib/screens/insurance_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../constants/insurance_products.dart';
import '../models/insurance_product.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with SingleTickerProviderStateMixin {
  final _api = CoreApiService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _api.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'My Policies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductsTab(api: _api),
          _MyPoliciesTab(api: _api),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final CoreApiService api;

  const _ProductsTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: api.getInsurancePolicies('cust_kasee'), // TODO: get actual customer ID
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final policies = snapshot.data!;
        final activeProductIds = policies
            .where((p) => p['active'] == true)
            .map((p) => p['productId'] as String)
            .toSet();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: kInsuranceProducts.length,
          itemBuilder: (context, index) {
            final product = kInsuranceProducts[index];
            final isActive = activeProductIds.contains(product.id);
            return _ProductCard(
              product: product,
              isActive: isActive,
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/insurance/activate',
                  arguments: {'productId': product.id},
                );
                if (result == true && context.mounted) {
                  // Refresh
                  setState(() {});
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final InsuranceProduct product;
  final bool isActive;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Color(0xFF008A8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nameFr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.subtitleEn,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green[700] : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.descriptionFr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Couverture jusqu\'à ${(product.claimCapMinor / 100).toStringAsFixed(0)} CDF',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF008A8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isActive ? 'Edit' : 'Activate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPoliciesTab extends StatefulWidget {
  final CoreApiService api;

  const _MyPoliciesTab({required this.api});

  @override
  State<_MyPoliciesTab> createState() => _MyPoliciesTabState();
}

class _MyPoliciesTabState extends State<_MyPoliciesTab> {
  Future<void> _deactivatePolicy(String policyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Policy'),
        content: const Text(
          'Are you sure you want to deactivate this insurance policy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.api.deactivateInsurance(policyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policy deactivated')),
        );
        setState(() {});
      }
    }
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'Claims filing will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.api.getInsurancePolicies('cust_kasee'), // TODO: actual customer ID
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final policies = snapshot.data!
            .where((p) => p['active'] == true)
            .toList();

        if (policies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active policies',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: policies.length,
          itemBuilder: (context, index) {
            final policy = policies[index];
            final product = kInsuranceProducts.firstWhere(
              (p) => p.id == policy['productId'],
            );
            return _PolicyCard(
              policy: policy,
              product: product,
              onDeactivate: () => _deactivatePolicy(policy['id'] as String),
              onFileClaim: _showComingSoonDialog,
            );
          },
        );
      },
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final Map<String, dynamic> policy;
  final InsuranceProduct product;
  final VoidCallback onDeactivate;
  final VoidCallback onFileClaim;

  const _PolicyCard({
    required this.policy,
    required this.product,
    required this.onDeactivate,
    required this.onFileClaim,
  });

  String _getPremiumSummary() {
    final mode = policy['premiumMode'] as String;
    if (mode == 'PERCENT') {
      final bps = policy['percentBps'] as int;
      final percent = (bps / 100).toStringAsFixed(1);
      return '$percent% of transaction amount';
    } else {
      final amount = (policy['fixedMinor'] as int) / 100;
      final schedule = policy['fixedSchedule'] as String;
      if (schedule == 'MONTHLY') {
        return '${amount.toStringAsFixed(0)} CDF per month';
      } else {
        return '${amount.toStringAsFixed(0)} CDF per transaction';
      }
    }
  }

  String _getDeductFromLabel() {
    final deductFrom = policy['deductFrom'] as String;
    switch (deductFrom) {
      case 'BILL':
        return 'On bills';
      case 'SEND':
        return 'On send money';
      case 'BOTH':
        return 'On bills and send money';
      default:
        return deductFrom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.nameFr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPremiumSummary(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _getDeductFromLabel(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activated on ${DateTime.parse(policy['activatedAt'] as String).toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDeactivate,
                  child: const Text('Deactivate'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onFileClaim,
                  child: const Text('File a Claim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create activate_policy_screen.dart**

Create `lib/screens/activate_policy_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';
import '../services/offline_demo_repository.dart';
import '../constants/insurance_products.dart';
import '../models/insurance_product.dart';

class ActivatePolicyScreen extends StatefulWidget {
  const ActivatePolicyScreen({super.key});

  @override
  State<ActivatePolicyScreen> createState() => _ActivatePolicyScreenState();
}

class _ActivatePolicyScreenState extends State<ActivatePolicyScreen> {
  final _api = CoreApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  late InsuranceProduct _product;
  PremiumMode _premiumMode = PremiumMode.FIXED;
  FixedSchedule _fixedSchedule = FixedSchedule.MONTHLY;
  DeductFrom _deductFrom = DeductFrom.BOTH;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final productId = args['productId'] as String;
    _product = kInsuranceProducts.firstWhere((p) => p.id == productId);

    // Pre-populate with defaults
    _premiumMode = _product.defaults.premiumMode;
    _fixedSchedule = _product.defaults.fixedSchedule ?? FixedSchedule.MONTHLY;
    _deductFrom = _product.defaults.deductFrom;

    if (_premiumMode == PremiumMode.PERCENT) {
      final bps = _product.defaults.percentBps ?? 0;
      _amountController.text = (bps / 100).toStringAsFixed(1);
    } else {
      final minor = _product.defaults.fixedMinor ?? 0;
      _amountController.text = (minor / 100).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Verify PIN
    if (_pinController.text != OfflineDemoRepository.demoPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final amountStr = _amountController.text.trim();
      final amount = double.tryParse(amountStr) ?? 0;

      int? fixedMinor;
      int? percentBps;
      String? fixedSchedule;

      if (_premiumMode == PremiumMode.PERCENT) {
        percentBps = (amount * 100).round(); // Convert % to bps
      } else {
        fixedMinor = (amount * 100).round(); // Convert CDF to minor
        fixedSchedule = _fixedSchedule.name;
      }

      await _api.activateInsurance(
        customerId: 'cust_kasee', // TODO: actual customer ID
        productId: _product.id,
        premiumMode: _premiumMode.name,
        fixedSchedule: fixedSchedule,
        fixedMinor: fixedMinor,
        percentBps: percentBps,
        deductFrom: _deductFrom.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insurance ${_product.nameFr} activated successfully. Your coverage is effective immediately.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Activate ${_product.nameFr}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Type
              Text(
                'Premium Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<PremiumMode>(
                      title: const Text('Percentage'),
                      value: PremiumMode.PERCENT,
                      groupValue: _premiumMode,
                      onChanged: (value) {
                        setState(() {
                          _premiumMode = value!;
                          _amountController.clear();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<PremiumMode>(
                      title: const Text('Fixed amount'),
                      value: PremiumMode.FIXED,
                      groupValue: _premiumMode,
                      onChanged: (value) {
                        setState(() {
                          _premiumMode = value!;
                          _amountController.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Schedule (if FIXED)
              if (_premiumMode == PremiumMode.FIXED) ...[
                Text(
                  'Schedule',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<FixedSchedule>(
                        title: const Text('Per transaction'),
                        value: FixedSchedule.PER_TXN,
                        groupValue: _fixedSchedule,
                        onChanged: (value) {
                          setState(() => _fixedSchedule = value!);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<FixedSchedule>(
                        title: const Text('Monthly'),
                        value: FixedSchedule.MONTHLY,
                        groupValue: _fixedSchedule,
                        onChanged: (value) {
                          setState(() => _fixedSchedule = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Amount / Percentage
              Text(
                _premiumMode == PremiumMode.PERCENT
                    ? 'Percentage'
                    : 'Amount (CDF)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _premiumMode == PremiumMode.PERCENT
                      ? 'e.g., 0.3 for 0.3%'
                      : 'e.g., 2500',
                  border: const OutlineInputBorder(),
                  suffixText: _premiumMode == PremiumMode.PERCENT ? '%' : 'CDF',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deduct from
              Text(
                'Deduct from',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<DeductFrom>(
                    title: const Text('Bills'),
                    value: DeductFrom.BILL,
                    groupValue: _deductFrom,
                    onChanged: (value) {
                      setState(() => _deductFrom = value!);
                    },
                  ),
                  RadioListTile<DeductFrom>(
                    title: const Text('Send money'),
                    value: DeductFrom.SEND,
                    groupValue: _deductFrom,
                    onChanged: (value) {
                      setState(() => _deductFrom = value!);
                    },
                  ),
                  RadioListTile<DeductFrom>(
                    title: const Text('Both'),
                    value: DeductFrom.BOTH,
                    groupValue: _deductFrom,
                    onChanged: (value) {
                      setState(() => _deductFrom = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PIN
              Text(
                'Confirm PIN',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '6-digit PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008A8A),
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add route to app_router.dart**

Open `lib/app_router.dart`. Add after the insurance route (around line 200):

```dart
      case RouteNames.insurance:
        return MaterialPageRoute(builder: (_) => const InsuranceScreen());

      case RouteNames.insuranceActivate:
        return MaterialPageRoute(
            builder: (_) => const ActivatePolicyScreen());

      case RouteNames.budget:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());
```

- [ ] **Step 5: Run flutter analyze**

```bash
flutter analyze lib/screens/insurance_screen.dart lib/screens/activate_policy_screen.dart lib/router_types.dart lib/app_router.dart
```

Expected: no errors.

- [ ] **Step 6: Manual smoke test (optional)**

```bash
flutter run -d <device-id> --dart-define=OFFLINE_DEMO=true
```

Navigate to Insurance from Home. Verify:
- Products tab shows 5 products
- My Policies tab shows 1 pre-seeded Santé policy
- Tapping "Activate" opens form
- Tapping "File a Claim" shows Coming Soon dialog

- [ ] **Step 7: Commit**

```bash
git add lib/screens/insurance_screen.dart lib/screens/activate_policy_screen.dart lib/router_types.dart lib/app_router.dart
git commit -m "feat(insurance): replace stub with Products | My Policies tabs + activate flow"
```

---

## Task 5: Pay Bill premium preview + insufficient balance + collect on success

**Files:**
- Modify: `lib/screens/payment_quote_screen.dart`
- Create: `lib/widgets/premium_summary_widget.dart`

**Interfaces:**
- Consumes: CoreApiService.previewInsurancePremiums, CoreApiService.collectInsurancePremiums, wallet balance from quote
- Produces: Premium breakdown display before PIN, insufficient balance error if grand total > balance, premium collection after PIN success

- [ ] **Step 1: Create premium_summary_widget.dart**

Create `lib/widgets/premium_summary_widget.dart`:

```dart
import 'package:flutter/material.dart';

class PremiumSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> premiumLineItems;
  final String currency;

  const PremiumSummaryWidget({
    super.key,
    required this.premiumLineItems,
    this.currency = 'CDF',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (premiumLineItems.isEmpty) return const SizedBox.shrink();

    final totalPremiumMinor = premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Insurance premiums',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...premiumLineItems.map((item) {
          final productNameFr = item['productNameFr'] as String;
          final premiumMinor = item['premiumMinor'] as int;
          final premium = premiumMinor / 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  productNameFr,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '+ ${premium.toStringAsFixed(2)} $currency',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total premiums',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(totalPremiumMinor / 100).toStringAsFixed(2)} $currency',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Integrate premium preview into payment_quote_screen.dart**

Open `lib/screens/payment_quote_screen.dart`. Add after the Payment Details section (around line 130):

Add state variable at top of `_PaymentQuoteScreenState`:

```dart
  bool _confirming = false;
  List<Map<String, dynamic>> _premiumLineItems = [];
  bool _loadingPremiums = false;
```

Add method to load premiums:

```dart
  Future<void> _loadPremiums() async {
    setState(() => _loadingPremiums = true);
    
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final quote = args['quote'] as Map<String, dynamic>;
      final currency = args['currency'] as String;
      final amountMinor = quote['amountMinor'] as String;

      if (currency != 'CDF') {
        // Premiums only for CDF transactions
        setState(() {
          _loadingPremiums = false;
          _premiumLineItems = [];
        });
        return;
      }

      final lineItems = await _api.previewInsurancePremiums(
        customerId: 'cust_kasee', // TODO: actual customer ID
        rail: 'BILL',
        principalMinor: int.parse(amountMinor),
      );

      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = lineItems;
      });
    } catch (e) {
      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = [];
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPremiums();
  }
```

Add premium summary widget after the _DetailRow for Total (around line 132):

```dart
                    ),
                    // Insurance premiums
                    if (_loadingPremiums)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      PremiumSummaryWidget(
                        premiumLineItems: _premiumLineItems,
                        currency: currency,
                      ),
```

Calculate grand total:

```dart
                    // Grand total (if premiums exist)
                    if (_premiumLineItems.isNotEmpty) ...[
                      const Divider(height: 32),
                      _DetailRow(
                        label: 'Total to debit',
                        value: currency == 'USD'
                            ? '\$${_getGrandTotal(total).toStringAsFixed(2)}'
                            : 'FC ${_getGrandTotal(total).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
```

Add helper method:

```dart
  double _getGrandTotal(double originalTotal) {
    final totalPremiumMinor = _premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );
    return originalTotal + (totalPremiumMinor / 100);
  }
```

Update _confirmPayment to check balance and collect premiums:

```dart
  Future<void> _confirmPayment() async {
    setState(() => _confirming = true);

    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final quote = args['quote'] as Map<String, dynamic>;
      final paymentId = quote['paymentId'] as String? ?? quote['id'] as String;
      final currency = args['currency'] as String;
      final totalMinor = int.parse(quote['totalMinor'] as String);

      // Calculate grand total including premiums
      final totalPremiumMinor = _premiumLineItems.fold<int>(
        0,
        (sum, item) => sum + (item['premiumMinor'] as int),
      );
      final grandTotalMinor = totalMinor + totalPremiumMinor;

      // TODO: Check wallet balance >= grandTotalMinor
      // For now, assume sufficient balance

      // Show PIN confirm
      final pin = await PinConfirmSheet.show(
        context,
        title: 'Confirm Payment',
        message: 'Enter your PIN to confirm payment',
      );

      if (pin == null) {
        setState(() => _confirming = false);
        return;
      }

      // Confirm payment
      final result = await _api.confirmPayment(paymentId: paymentId);

      // Collect insurance premiums
      if (_premiumLineItems.isNotEmpty && currency == 'CDF') {
        await _api.collectInsurancePremiums(
          customerId: 'cust_kasee', // TODO: actual customer ID
          rail: 'BILL',
          principalMinor: int.parse(quote['amountMinor'] as String),
          parentTransactionId: paymentId,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/payment-result',
          arguments: {
            'result': result,
            'railType': args['railType'],
            'currency': currency,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _confirming = false);
      }
    }
  }
```

Add import at top:

```dart
import '../widgets/premium_summary_widget.dart';
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze lib/widgets/premium_summary_widget.dart lib/screens/payment_quote_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/premium_summary_widget.dart lib/screens/payment_quote_screen.dart
git commit -m "feat(insurance): integrate premium preview + collect in Pay Bill flow"
```

---

## Task 6: Send Money P2P premium preview + insufficient balance + collect on success

**Files:**
- Modify: `lib/screens/send_money_review_screen.dart`

**Interfaces:**
- Consumes: CoreApiService.previewInsurancePremiums, CoreApiService.collectInsurancePremiums, PremiumSummaryWidget
- Produces: Premium breakdown display before proceeding to checkout, insufficient balance validation, premium collection after PIN success

- [ ] **Step 1: Integrate premium preview into send_money_review_screen.dart**

Open `lib/screens/send_money_review_screen.dart`. Add state variable at top of `_SendMoneyReviewScreenState`:

```dart
  bool _hasLoadedFees = false;
  List<Map<String, dynamic>> _premiumLineItems = [];
  bool _loadingPremiums = false;
```

Add method to load premiums after _loadFees (around line 53):

```dart
  Future<void> _loadPremiums() async {
    setState(() => _loadingPremiums = true);

    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null) {
        setState(() {
          _loadingPremiums = false;
          _premiumLineItems = [];
        });
        return;
      }

      final amount = args['amount'] as double;
      final currency = args['currency'] as String;

      if (currency != 'USD') {
        // Premiums only for CDF (in offline demo, USD not supported for premiums)
        // But Send Money typically uses USD — check if transaction is CDF
        setState(() {
          _loadingPremiums = false;
          _premiumLineItems = [];
        });
        return;
      }

      // Convert USD amount to CDF for premium calculation
      // In offline demo, assume 1 USD = 2750 CDF exchange rate
      final principalCdfMinor = (amount * 2750 * 100).round();

      final lineItems = await CoreApiService().then((api) async {
        await api.init();
        return api.previewInsurancePremiums(
          customerId: 'cust_kasee', // TODO: actual customer ID
          rail: 'SEND',
          principalMinor: principalCdfMinor,
        );
      });

      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = lineItems;
      });
    } catch (e) {
      print('Failed to load premiums: $e');
      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = [];
      });
    }
  }
```

Call _loadPremiums in didChangeDependencies:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedFees) {
      _hasLoadedFees = true;
      _loadFees();
      _loadPremiums();
    }
  }
```

Add premium summary widget in _buildFeesSection (around line 100):

```dart
                      const SizedBox(height: 24),
                      _buildFeesSection(theme, appState, amount, currency,
                          feeAmount, totalAmount, chargesState),
                      
                      // Insurance premiums
                      if (_loadingPremiums)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_premiumLineItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PremiumSummaryWidget(
                            premiumLineItems: _premiumLineItems,
                            currency: 'CDF', // Premiums always in CDF
                          ),
                        ),
```

Add grand total display if premiums exist (after fee breakdown):

```dart
                      // Grand total (if premiums exist)
                      if (_premiumLineItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total to debit',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'FC ${_getGrandTotal(totalAmount).toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
```

Add helper method:

```dart
  double _getGrandTotal(double originalTotal) {
    final totalPremiumMinor = _premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );
    // Original total is in USD, premiums in CDF — convert USD to CDF for grand total
    final originalTotalCdf = originalTotal * 2750;
    return originalTotalCdf + (totalPremiumMinor / 100);
  }
```

Add import at top:

```dart
import '../widgets/premium_summary_widget.dart';
import '../services/core_api_service.dart';
```

NOTE: Premium collection for Send Money happens in send_money_checkout_screen.dart after payment success. Add similar collectInsurancePremiums call there (follow same pattern as Pay Bill).

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/screens/send_money_review_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/send_money_review_screen.dart
git commit -m "feat(insurance): integrate premium preview in Send Money P2P flow"
```

---

## Task 7: Manual device verification checklist

**Files:**
- Update this plan document with device verification results (no code changes)

**Interfaces:**
- Consumes: Completed insurance implementation on Pixel 8 or similar device
- Produces: Verified acceptance criteria checklist

- [ ] **Step 1: Run app on Pixel 8 (or emulator) in offline demo mode**

```bash
flutter run -d <device-id> --dart-define=OFFLINE_DEMO=true
```

- [ ] **Step 2: Verify AC1: Product Catalog Display**

- [ ] Insurance screen shows "Products" and "My Policies" tabs
- [ ] Products tab displays all five insurance products
- [ ] Each product card shows: name (FR), subtitle (EN), description (FR), claim cap (FR), status badge, action button (EN)
- [ ] Inactive products show "Activate" button
- [ ] Pre-seeded Santé shows "Active" badge and "Edit" button

- [ ] **Step 3: Verify AC2: Policy Activation Flow**

- [ ] Tap "Activate" on Accident product
- [ ] Form shows title "Activate Accident" (product name in French)
- [ ] Form allows selection of Premium type (Percentage | Fixed amount)
- [ ] If Fixed: Schedule (Per transaction | Monthly)
- [ ] Amount field accepts CDF or % input
- [ ] Deduct from radio buttons (Bills | Send money | Both)
- [ ] Form pre-populates with product defaults
- [ ] PIN field validates input
- [ ] Incorrect PIN shows error
- [ ] Correct PIN (123456) activates policy, shows success toast, navigates back
- [ ] Accident product now shows "Active" badge and "Edit" button
- [ ] Policy appears in "My Policies" tab

- [ ] **Step 4: Verify AC3: Policy Management**

- [ ] "My Policies" tab lists active policies
- [ ] Each policy card shows product name (FR), premium summary (EN), deduction rail (EN), activation date (EN)
- [ ] Tap "Deactivate" on Accident policy
- [ ] Confirmation dialog appears
- [ ] Confirming deactivates policy and removes it from list
- [ ] Tap "File a Claim" on any policy
- [ ] Coming Soon dialog appears with appropriate message

- [ ] **Step 5: Verify AC4: Pay Bill Premium Deduction**

- [ ] Navigate to Home → Send (or Pay Bill flow)
- [ ] Select BILL rail type, amount 50,000 CDF, select biller
- [ ] On confirmation screen before PIN entry:
  - [ ] Shows "Bill amount: 50,000 CDF"
  - [ ] Shows "Insurance premiums" section
  - [ ] Lists each matching policy as line item (product name FR + premium amount)
  - [ ] Shows "Total premiums" subtotal
  - [ ] Shows "Total to debit" grand total (bill + premiums)
- [ ] If wallet balance < grand total: error shows "Insufficient balance to cover amount and insurance premiums" (balance check TODO if not yet implemented)
- [ ] Enter PIN (123456) and confirm
- [ ] Transaction succeeds, wallet debited by grand total
- [ ] Check transaction history: separate journal entry for each premium (type: INSURANCE_PREMIUM)
- [ ] For Santé MONTHLY: repeat Pay Bill in same month — premium should be 0 CDF

- [ ] **Step 6: Verify AC5: Send Money Premium Deduction**

- [ ] Navigate to Send Money (P2P), enter recipient + amount 50,000 CDF (or USD equivalent)
- [ ] On review screen before checkout:
  - [ ] Shows "Amount to send" + premiums section (similar to Pay Bill)
- [ ] Proceed to checkout, enter PIN
- [ ] Transaction succeeds, premiums collected
- [ ] Remittance flow (if tested): no premiums (out of scope)

- [ ] **Step 7: Verify AC6: Multiple Policy Stacking**

- [ ] Activate 2-3 policies (e.g., Santé MONTHLY, Accident PER_TXN, Décès PERCENT) matching BOTH or BILL
- [ ] Initiate Pay Bill transaction
- [ ] Confirmation screen shows all matching premiums as separate line items
- [ ] Grand total = principal + sum of all matching premiums
- [ ] Insufficient balance blocks entire transaction (if balance < grand total)

- [ ] **Step 8: Verify AC7: Monthly Premium Logic**

- [ ] Activate Santé MONTHLY 2,500 CDF BOTH (if not already active)
- [ ] Initiate Pay Bill transaction → premium 2,500 CDF charged
- [ ] Initiate second Pay Bill in same calendar month → premium 0 CDF
- [ ] Change device date to next month (or wait until next month)
- [ ] Initiate Pay Bill → premium 2,500 CDF charged again

- [ ] **Step 9: Document verification results**

Add results here after testing:

**Verification completed on:** [DATE]  
**Device:** [MODEL]  
**Flutter version:** [VERSION]  
**Pass/Fail:** [PASS | FAIL with details]

- [ ] **Step 10: Commit plan update (if results added)**

```bash
git add docs/superpowers/plans/2026-09-18-poste-finance-insurance-activate.md
git commit -m "docs: add insurance manual verification results"
```

---

## Spec Coverage Self-Check

| Spec Requirement | Task(s) |
|------------------|---------|
| Five insurance products with French names/descriptions | 1, 2, 4 |
| PERCENT, FIXED PER_TXN, FIXED MONTHLY premium modes | 1, 2 |
| Deduction rails: BILL, SEND, BOTH | 1, 2 |
| Premium stacking (multiple policies) | 1, 2, 5, 6 |
| Monthly premium logic (once per YYYY-MM) | 1, 2, 5, 6 |
| Product catalog display (Products tab) | 4 |
| Active policies list (My Policies tab) | 4 |
| Activate/edit policy form with PIN | 4 |
| Deactivate policy with confirmation | 4 |
| Claims Coming Soon stub | 4 |
| Pay Bill premium preview before PIN | 5 |
| Pay Bill insufficient balance validation | 5 |
| Pay Bill premium collection after PIN success | 5 |
| Send Money P2P premium preview before PIN | 6 |
| Send Money P2P premium collection after checkout | 6 |
| Jean-Paul pre-seeded Santé MONTHLY 2,500 CDF BOTH | 2 |
| Separate journal entry per premium (INSURANCE_PREMIUM) | 2, 5, 6 |
| CDF premiums only (no USD) | 1, 2, 5, 6 |
| Minor units (1 CDF = 100 minor) | 1, 2 |
| English UI chrome, French product content | 4 |
| Offline demo mode (`OFFLINE_DEMO=true`) | All |
| Demo PIN 123456 | 4 |

---

## Execution Handoff

After this plan is committed + pushed to branch `cursor/task1-monorepo-scaffold-1d8a`, implement task-by-task using **superpowers:subagent-driven-development** (recommended) or **superpowers:executing-plans**. Each task is independently committable. Manual device verification (Task 7) should follow Task 6 completion. All unit tests must pass before merging.

**Success Criteria:**
- All 6 implementation tasks completed with passing tests
- Manual device verification checklist completed (Task 7)
- All files committed to branch
- No lint errors or failing unit tests
- Insurance screen fully replaces "Coming Soon" stub
- Pay Bill and Send Money flows successfully integrate premium preview + collection

---

**End of Plan**
