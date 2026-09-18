# Poste Finance Customer App — Insurance Activate & Premium Deductions Design

**Date:** 2026-09-18  
**Author:** Cloud Agent (via Product Requirements)  
**Status:** Approved  
**Scope:** Customer Flutter app offline demo only (`OFFLINE_DEMO=true`)

---

## Executive Summary

This design document specifies the implementation of insurance product activation and premium deduction functionality in the Poste Finance customer mobile app. The feature enables customers to browse five insurance products, activate coverage with flexible premium structures, and have premiums automatically deducted from bill payments and P2P money transfers.

**Approach:** Catalog-based product display + activate/configure flow + premium deduction helper integrated into Pay Bill and Send Money transaction flows.

---

## Table of Contents

1. [Business Context](#business-context)
2. [Product Decisions](#product-decisions)
3. [User Experience Design](#user-experience-design)
4. [Data Model](#data-model)
5. [Premium Calculation Rules](#premium-calculation-rules)
6. [Technical Architecture](#technical-architecture)
7. [Integration Points](#integration-points)
8. [Out of Scope](#out-of-scope)
9. [Acceptance Criteria](#acceptance-criteria)
10. [Risks & Mitigations](#risks--mitigations)
11. [Relation to Prior Work](#relation-to-prior-work)

---

## 1. Business Context

Poste Finance offers embedded insurance products to protect customers from financial shocks related to health, death, accidents, credit obligations, and device damage. This sprint delivers the foundational capability for customers to:

- Discover five insurance products
- Activate coverage with a one-time configuration flow
- Have premiums automatically collected during bill payments and P2P transfers
- View and manage their active policies

This is an **offline demo** feature (`OFFLINE_DEMO=true`) for stakeholder validation before API integration.

---

## 2. Product Decisions (Approved)

### 2.1 Insurance Product Segments

Five insurance products will be offered:

1. **Santé hospitalisation** (Health Hospitalization)
2. **Décès & funérailles** (Death & Funeral)
3. **Accident** (Accident)
4. **Protection crédit** (Credit Protection)
5. **Téléphone & appareil** (Phone & Device)

### 2.2 Premium Structure

Customers can choose from two premium modes:

#### A. FIXED Premium
When customer selects FIXED, they must also choose a schedule:
- **PER_TXN** (Per Transaction): Deducted on every qualifying transaction
- **MONTHLY**: Deducted once per calendar month on the first qualifying transaction

#### B. PERCENT Premium
- Premium is calculated as a percentage (in basis points) of the transaction principal amount
- Example: 0.3% = 30 basis points; 1.0% = 100 basis points

### 2.3 Deduction Rails

Customer configures which transaction types trigger premium deduction:
- **BILL**: Pay Bill transactions only
- **SEND**: Send Money (P2P) transactions only
- **BOTH**: Both Pay Bill and Send Money transactions

### 2.4 Multiple Policies (Stacking)

- Customers can activate one policy per product (maximum 5 active policies total)
- If multiple policies match a transaction (e.g., two products configured for BOTH), **all matching premiums stack**
- Each policy appears as a separate line item on the payment confirmation screen
- Total debit = principal + sum of all applicable premiums

### 2.5 Scope: Activate, Configure, List; Claims = Coming Soon

This sprint delivers:
- ✅ Product catalog browsing
- ✅ Policy activation and configuration
- ✅ Active policies list and deactivation
- ✅ Premium deduction on Pay Bill and Send Money
- 🔜 **Claims filing:** Coming Soon stub (future sprint)

### 2.6 Transaction Scope: Bill Pay & P2P Send Only

- **In scope:** Pay Bill and Send Money (P2P domestic transfers)
- **Out of scope this sprint:** Remittance, FX, airtime top-up, and other payment rails

### 2.7 Currency: CDF Only

All premiums are denominated and collected in **CDF** (Congolese Franc) only. USD premium support is deferred.

---

## 3. User Experience Design

### 3.1 Navigation

**Insurance tab** in main bottom navigation (already stubbed in savings sprint), containing two sub-tabs:

- **Products**: Browse and activate insurance products
- **My Policies**: View active policies and manage subscriptions

### 3.2 Products Tab

**Layout:** Vertical scrollable list of five product cards.

**Each card displays:**
- Product icon (illustrative)
- Product name (French primary, e.g., "Santé hospitalisation")
- Subtitle (English, e.g., "Health Hospitalization")
- Brief description (1-2 sentences explaining coverage)
- Illustrative claim cap (e.g., "Couverture jusqu'à 500 000 CDF")
- Status badge: **Inactive** (gray) or **Active** (green)
- Action button:
  - **"Activer"** (Activate) if inactive
  - **"Modifier"** (Edit) if active

**Interaction:**
Tapping "Activer" or "Modifier" navigates to the Activate/Edit form.

### 3.3 Activate / Edit Policy Form

**Screen title:**
- "Activer [Product Name]" (when activating)
- "Modifier [Product Name]" (when editing)

**Form fields:**

1. **Type de prime** (Premium Type)
   - Radio buttons: `Pourcentage` | `Montant fixe`
   - Default per product (see section 4.5)

2. **If FIXED selected: Fréquence** (Schedule)
   - Radio buttons: `Par transaction` | `Mensuel`
   - Default per product

3. **Montant / Pourcentage**
   - If FIXED: Currency input (CDF, integer, e.g., "2 500 CDF")
   - If PERCENT: Percentage input (decimal, e.g., "0,3%" or "1,0%")
   - Default per product

4. **Déduire sur** (Deduct From)
   - Radio buttons: `Paiements de factures` | `Envois d'argent` | `Les deux`
   - Default per product

5. **PIN de confirmation**
   - 6-digit PIN input
   - Validation: must match hardcoded offline demo PIN `123456`

**Actions:**
- **"Annuler"** (Cancel): Dismiss form, no changes
- **"Confirmer"** (Confirm): Validate PIN, save policy, show success toast, navigate back to Products tab

**Success message:**
"Assurance [Product Name] activée avec succès. Votre couverture est effective immédiatement."

**Edit behavior:**
When editing an existing active policy, the form pre-populates with current values. Confirming updates the policy in place. Only one active policy per product is allowed; re-activation overwrites the previous configuration.

### 3.4 My Policies Tab

**Layout:** Vertical list of active policies (empty state if none active).

**Each policy card displays:**
- Product name (French)
- Premium summary:
  - FIXED PER_TXN: "1 000 CDF par transaction"
  - FIXED MONTHLY: "2 500 CDF par mois"
  - PERCENT: "0,3% du montant de la transaction"
- Deduction rail: "Sur paiements de factures" | "Sur envois d'argent" | "Sur paiements et envois"
- Activation date: "Activé le [DD/MM/YYYY]"
- Action buttons:
  - **"Désactiver"** (Deactivate)
  - **"Faire une réclamation"** (File a Claim) — disabled, shows Coming Soon dialog

**Deactivate interaction:**
1. User taps "Désactiver"
2. Confirmation dialog: "Êtes-vous sûr de vouloir désactiver [Product Name]?"
3. If confirmed, policy is marked inactive, card removed from list, success toast shown
4. Policy reappears as "Inactive" on Products tab

**File a Claim interaction:**
Tapping shows a dialog:
- Title: "Réclamations à venir"
- Body: "La fonctionnalité de réclamation sera disponible dans une prochaine version."
- Button: "D'accord"

### 3.5 Pay Bill Confirmation Screen (Enhanced)

**Location:** After user enters bill amount and taps "Continuer," before PIN entry.

**Premium display:**
If one or more active policies match (product is active AND deductFrom is BILL or BOTH):
- Original bill amount shown as "Montant de la facture: [amount] CDF"
- Below that, a new section: **"Primes d'assurance"**
- Each matching policy appears as a line item:
  - Product name (French)
  - Premium amount: "+ [premium] CDF"
- Subtotal: "Total des primes: [sum of premiums] CDF"
- **Grand total** (bold): "Montant total à débiter: [bill amount + total premiums] CDF"

**Example:**
```
Montant de la facture: 50 000 CDF

Primes d'assurance:
  Santé hospitalisation       + 2 500 CDF
  Accident                    + 1 000 CDF
  Total des primes:             3 500 CDF

Montant total à débiter:      53 500 CDF
```

**Validation:**
Before showing PIN entry, system checks if wallet balance ≥ grand total. If insufficient, show error: "Solde insuffisant pour couvrir le montant et les primes d'assurance."

**After PIN success:**
- Debit wallet by grand total
- Create main transaction journal entry (type: `BILL_PAYMENT`)
- Create separate journal entry for each premium (type: `INSURANCE_PREMIUM`, referencing policy and product)
- For FIXED MONTHLY premiums: update policy `lastMonthlyCollectedYm` to current `YYYY-MM`
- Show success screen with transaction receipt

### 3.6 Send Money Confirmation Screen (Enhanced)

**Location:** In P2P send flow, after user enters recipient and amount, before PIN entry.

**Premium display logic:** Identical to Pay Bill, except:
- Matches policies where deductFrom is SEND or BOTH
- Label: "Montant à envoyer: [amount] CDF" instead of "Montant de la facture"

**Validation, debit, and journal logic:** Same as Pay Bill.

---

## 4. Data Model

### 4.1 Insurance Product Catalog (Static)

Products are defined as a static constant in the app (no API/database in offline demo). Each product has:

```dart
class InsuranceProduct {
  final String id;                  // e.g., "health_hosp"
  final String nameFr;              // e.g., "Santé hospitalisation"
  final String subtitleEn;          // e.g., "Health Hospitalization"
  final String descriptionFr;       // 1-2 sentence coverage blurb
  final int claimCapMinor;          // Illustrative max claim in CDF minor units
  final String iconAsset;           // Asset path for product icon
  final InsurancePremiumDefaults defaults; // Suggested activation config
}
```

### 4.2 Insurance Policy (Customer Configuration)

Each active or inactive policy is stored in `universe.json` under customer data. Schema:

```dart
class InsurancePolicy {
  final String id;                  // UUID
  final String customerId;          // FK to customer
  final String productId;           // FK to product catalog id
  final bool active;                // true if policy is active
  final PremiumMode premiumMode;    // PERCENT | FIXED
  final FixedSchedule? fixedSchedule; // PER_TXN | MONTHLY | null (null if PERCENT)
  final int? fixedMinor;            // Fixed premium amount in CDF minor units (null if PERCENT)
  final int? percentBps;            // Percentage in basis points (null if FIXED)
  final DeductFrom deductFrom;      // BILL | SEND | BOTH
  final String? lastMonthlyCollectedYm; // "YYYY-MM" for MONTHLY schedule, null otherwise
  final DateTime activatedAt;       // Timestamp of activation or last edit
}

enum PremiumMode { PERCENT, FIXED }
enum FixedSchedule { PER_TXN, MONTHLY }
enum DeductFrom { BILL, SEND, BOTH }
```

### 4.3 Product Catalog Definitions

| Product ID           | Name (FR)                  | Subtitle (EN)             | Claim Cap (CDF) |
|----------------------|----------------------------|---------------------------|-----------------|
| `health_hosp`        | Santé hospitalisation      | Health Hospitalization    | 500,000         |
| `death_funeral`      | Décès & funérailles        | Death & Funeral           | 1,000,000       |
| `accident`           | Accident                   | Accident                  | 300,000         |
| `credit_protection`  | Protection crédit          | Credit Protection         | Varies by loan  |
| `phone_device`       | Téléphone & appareil       | Phone & Device            | 200,000         |

### 4.4 Product Descriptions (French)

- **Santé hospitalisation:** Couvre les frais d'hospitalisation en cas de maladie ou d'accident jusqu'à 500 000 CDF par an.
- **Décès & funérailles:** Verse un capital aux bénéficiaires pour couvrir les frais funéraires jusqu'à 1 000 000 CDF.
- **Accident:** Indemnise les blessures corporelles dues à un accident jusqu'à 300 000 CDF.
- **Protection crédit:** Rembourse votre prêt en cas de décès, d'invalidité ou de perte d'emploi.
- **Téléphone & appareil:** Répare ou remplace votre téléphone en cas de vol, casse ou panne jusqu'à 200 000 CDF.

### 4.5 Suggested Activation Defaults

When user taps "Activer" on a product, the form pre-populates with these suggested values:

| Product               | Premium Mode | Schedule      | Amount/Percent | Deduct From |
|-----------------------|--------------|---------------|----------------|-------------|
| Santé hospitalisation | FIXED        | MONTHLY       | 2,500 CDF      | BOTH        |
| Décès & funérailles   | PERCENT      | N/A           | 0.3% (30 bps)  | SEND        |
| Accident              | FIXED        | PER_TXN       | 1,000 CDF      | BOTH        |
| Protection crédit     | PERCENT      | N/A           | 1.0% (100 bps) | BOTH        |
| Téléphone & appareil  | FIXED        | MONTHLY       | 3,000 CDF      | BILL        |

**Note on Protection crédit:** This sprint calculates premium as 1.0% of transaction amount. Future sprints will add loan-specific auto-attachment (e.g., attaching to a specific loan and calculating premium based on outstanding balance).

### 4.6 Seed Data for Demo

**Customer:** Jean-Paul (existing demo customer)

**Pre-seeded active policy:**
- Product: Santé hospitalisation
- Mode: FIXED MONTHLY
- Amount: 2,500 CDF
- Deduct From: BOTH
- Activated: [timestamp at universe.json init]

**Other products:** Inactive (no policies). User can activate them during demo.

---

## 5. Premium Calculation Rules

### 5.1 Matching Logic

When a customer initiates a payment (Pay Bill or Send Money), the system:

1. Retrieves all active policies for the customer (`active = true`)
2. Filters policies where:
   - `deductFrom = BILL` and transaction is Pay Bill, OR
   - `deductFrom = SEND` and transaction is Send Money, OR
   - `deductFrom = BOTH` (matches all transaction types in scope)
3. For each matching policy, calculates the premium amount per section 5.2

### 5.2 Premium Amount Calculation

#### A. PERCENT Mode

```
premiumMinor = floor(principalMinor * percentBps / 10_000)
```

- `principalMinor`: Transaction amount in minor units (e.g., 50,000 CDF = 5,000,000 minor)
- `percentBps`: Percentage in basis points (e.g., 0.3% = 30 bps, 1.0% = 100 bps)
- Use integer floor division to avoid fractional currency

**Example:**
- Principal: 50,000 CDF (5,000,000 minor)
- Percent: 0.3% (30 bps)
- Premium: floor(5,000,000 * 30 / 10,000) = floor(15,000) = 15,000 minor = 150 CDF

#### B. FIXED PER_TXN Mode

```
premiumMinor = fixedMinor
```

Premium is the configured fixed amount, deducted on every matching transaction.

**Example:**
- Fixed amount: 1,000 CDF per transaction
- Premium: 1,000 CDF

#### C. FIXED MONTHLY Mode

```
if lastMonthlyCollectedYm != currentYearMonth:
    premiumMinor = fixedMinor
    # After successful debit, update lastMonthlyCollectedYm = currentYearMonth
else:
    premiumMinor = 0  # Already collected this month
```

- `currentYearMonth`: Derived from device local date, formatted as `YYYY-MM`
- Premium is only charged once per calendar month on the first matching transaction
- After debit, the policy's `lastMonthlyCollectedYm` is updated to prevent double-charging

**Example:**
- Fixed monthly: 2,500 CDF
- Transaction on 2026-09-18, policy.lastMonthlyCollectedYm = "2026-08"
- Premium: 2,500 CDF (charged)
- After debit: policy.lastMonthlyCollectedYm = "2026-09"
- Next transaction on 2026-09-25, policy.lastMonthlyCollectedYm = "2026-09"
- Premium: 0 CDF (already collected this month)

### 5.3 Stacking Multiple Policies

If multiple policies match a transaction, **all premiums are calculated and summed**.

**Example:**
Customer has three active policies:
1. Santé hospitalisation: FIXED MONTHLY 2,500 CDF, BOTH (not yet collected this month)
2. Accident: FIXED PER_TXN 1,000 CDF, BOTH
3. Décès & funérailles: PERCENT 0.3% (30 bps), SEND

Transaction: Send Money 50,000 CDF

- Santé: 2,500 CDF (MONTHLY, first txn this month)
- Accident: 1,000 CDF (PER_TXN)
- Décès: floor(5,000,000 * 30 / 10,000) = 150 CDF (PERCENT)
- **Total premiums:** 3,650 CDF
- **Grand total debit:** 50,000 + 3,650 = 53,650 CDF

### 5.4 Insufficient Balance Handling

Before prompting for PIN, the system checks:

```
walletBalanceMinor >= (principalMinor + totalPremiumsMinor)
```

If insufficient:
- Block the transaction **entirely** (no partial payment)
- Show error message: "Solde insuffisant pour couvrir le montant et les primes d'assurance."
- User must either:
  - Reduce principal amount
  - Deactivate one or more policies
  - Top up wallet balance

**Rationale:** Partial premium deduction creates inconsistent coverage and accounting complexity. Full blockage ensures clarity.

---

## 6. Technical Architecture

### 6.1 Offline Demo Repository Layer

**Current state:** Insurance screen shows "Coming Soon" stub (per savings sprint design).

**This sprint:** Replace stub with full implementation.

**OfflineDemoRepository enhancements:**

Add methods:

```dart
class OfflineDemoRepository {
  // ... existing methods ...

  // Insurance product catalog (static)
  List<InsuranceProduct> listInsuranceProducts();

  // Customer policies (from universe.json)
  List<InsurancePolicy> listInsurancePolicies(String customerId);

  // Activation (creates new policy or updates existing)
  Future<InsurancePolicy> activateInsurancePolicy({
    required String customerId,
    required String productId,
    required PremiumMode premiumMode,
    FixedSchedule? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required DeductFrom deductFrom,
  });

  // Update existing active policy
  Future<InsurancePolicy> updateInsurancePolicy({
    required String policyId,
    required PremiumMode premiumMode,
    FixedSchedule? fixedSchedule,
    int? fixedMinor,
    int? percentBps,
    required DeductFrom deductFrom,
  });

  // Deactivate policy
  Future<void> deactivateInsurancePolicy(String policyId);

  // Premium calculation preview (before payment)
  List<PremiumLineItem> previewInsurancePremiums({
    required String customerId,
    required TransactionRail rail, // BILL | SEND
    required int principalMinor,
  });

  // Collect premiums (called during payment success)
  Future<List<JournalEntry>> collectInsurancePremiums({
    required String customerId,
    required TransactionRail rail,
    required int principalMinor,
    required String parentTransactionId,
  });
}

class PremiumLineItem {
  final String policyId;
  final String productNameFr;
  final int premiumMinor;
}
```

**universe.json structure:**

Add `insurancePolicies` array to customer objects:

```json
{
  "customers": [
    {
      "id": "cust_jeanpaul",
      "name": "Jean-Paul Mukendi",
      "insurancePolicies": [
        {
          "id": "pol_123",
          "customerId": "cust_jeanpaul",
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
  ]
}
```

**Catalog constants:**

Define static product catalog in `lib/core/constants/insurance_products.dart`:

```dart
const List<InsuranceProduct> kInsuranceProducts = [
  InsuranceProduct(
    id: 'health_hosp',
    nameFr: 'Santé hospitalisation',
    subtitleEn: 'Health Hospitalization',
    descriptionFr: 'Couvre les frais d\'hospitalisation en cas de maladie ou d\'accident jusqu\'à 500 000 CDF par an.',
    claimCapMinor: 50000000, // 500,000 CDF
    iconAsset: 'assets/icons/insurance_health.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.MONTHLY,
      fixedMinor: 250000, // 2,500 CDF
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  // ... other products ...
];
```

### 6.2 CoreApiService Offline Branches

**Current state:** CoreApiService routes real API calls in production, offline stubs in demo.

**This sprint:** Add insurance offline branches similar to savings implementation.

Add methods to `CoreApiService`:

```dart
class CoreApiService {
  // ... existing methods ...

  Future<List<InsuranceProduct>> getInsuranceProducts() async {
    if (_offlineDemo) {
      return _offlineRepo.listInsuranceProducts();
    }
    // Future: real API call
    throw UnimplementedError('Insurance API not yet implemented');
  }

  Future<List<InsurancePolicy>> getInsurancePolicies(String customerId) async {
    if (_offlineDemo) {
      return _offlineRepo.listInsurancePolicies(customerId);
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  Future<InsurancePolicy> activateInsurance({...}) async {
    if (_offlineDemo) {
      return _offlineRepo.activateInsurancePolicy(...);
    }
    throw UnimplementedError('Insurance API not yet implemented');
  }

  // ... deactivate, update, preview, collect ...
}
```

### 6.3 Flutter UI Layer

**File structure:**

```
lib/
  features/
    insurance/
      screens/
        insurance_screen.dart           # Tabbed parent (Products | My Policies)
        products_tab.dart               # Product catalog list
        policies_tab.dart               # Active policies list
        activate_policy_screen.dart     # Activation/edit form
      widgets/
        product_card.dart               # Product catalog card
        policy_card.dart                # Active policy summary card
        premium_line_item.dart          # Premium breakdown line on confirm
      models/
        insurance_product.dart
        insurance_policy.dart
        premium_line_item.dart
      providers/
        insurance_provider.dart         # State management (Riverpod or Provider)
```

**State management:**

Use existing pattern (Riverpod or Provider). Example:

```dart
final insuranceProductsProvider = FutureProvider<List<InsuranceProduct>>((ref) async {
  final api = ref.read(coreApiServiceProvider);
  return api.getInsuranceProducts();
});

final insurancePoliciesProvider = FutureProvider.family<List<InsurancePolicy>, String>(
  (ref, customerId) async {
    final api = ref.read(coreApiServiceProvider);
    return api.getInsurancePolicies(customerId);
  },
);
```

### 6.4 Payment Flow Integration Hooks

#### Pay Bill Flow

**Current screen:** `lib/features/payments/screens/pay_bill_confirm_screen.dart` (example path)

**Enhancement:**

Before showing confirm screen:
1. Call `previewInsurancePremiums(rail: BILL, principalMinor: billAmount)`
2. Display premium line items
3. Calculate grand total
4. Check wallet balance ≥ grand total
5. If insufficient, show error and block PIN entry

After PIN success:
1. Debit wallet by grand total
2. Call `collectInsurancePremiums(rail: BILL, principalMinor: billAmount, parentTransactionId: txnId)`
3. Append insurance journal entries to transaction

#### Send Money Flow (P2P only)

**Current screen:** `lib/features/send_money/screens/send_confirm_screen.dart` (example path)

**Enhancement:** Same logic as Pay Bill, but:
- Use `rail: SEND`
- Label adjustments ("Montant à envoyer" instead of "Montant de la facture")

**Out of scope:** Remittance and FX send flows remain unchanged. Only domestic P2P send integrates premiums.

### 6.5 Journal Entry Schema for Premiums

Each collected premium generates a separate journal entry:

```json
{
  "id": "jrn_456",
  "customerId": "cust_jeanpaul",
  "type": "INSURANCE_PREMIUM",
  "amountMinor": 250000,
  "currency": "CDF",
  "direction": "DEBIT",
  "parentTransactionId": "txn_789",
  "metadata": {
    "policyId": "pol_123",
    "productId": "health_hosp",
    "productNameFr": "Santé hospitalisation",
    "premiumMode": "FIXED",
    "fixedSchedule": "MONTHLY"
  },
  "createdAt": "2026-09-18T12:45:00Z"
}
```

**Parent transaction:** The main bill payment or send money transaction (type: `BILL_PAYMENT` or `P2P_TRANSFER`).

**Ledger impact:**
- Customer wallet balance decreases by grand total (one atomic debit operation at payment layer)
- Journal entries provide granular audit trail (one entry for principal, one per premium)

---

## 7. Integration Points

### 7.1 Existing Features

**Savings Sprint Integration:**
- Savings sprint delivered Insurance tab stub with "Coming Soon" placeholder
- This sprint **replaces** the stub with full insurance implementation
- No changes needed to savings feature or bottom navigation structure

**Wallet & Payments:**
- Wallet balance checks integrated into payment confirmation flows
- Journal entry pattern follows existing transaction journal architecture

**PIN Validation:**
- Reuses existing offline demo PIN validation (`123456`)
- Same security flow as other transaction confirmations

### 7.2 Device Date Dependency

**Monthly premium logic** relies on device local date to determine current calendar month (`YYYY-MM`).

**Implications:**
- If device date is incorrect, monthly premiums may be double-charged or skipped
- Acceptable for offline demo; production will use server-side date
- Consider warning user if device date appears significantly off (e.g., year < 2026 or > 2030)

### 7.3 Future API Integration Points

When transitioning from offline demo to production API:

**Backend endpoints to implement:**
- `GET /insurance/products` — return product catalog
- `GET /insurance/policies?customerId={id}` — return customer policies
- `POST /insurance/policies` — activate policy
- `PATCH /insurance/policies/{id}` — update policy
- `DELETE /insurance/policies/{id}` — deactivate policy
- `POST /payments/preview-premiums` — preview premiums for a transaction
- `POST /payments/{id}/collect-premiums` — collect premiums post-payment

**Backend responsibilities:**
- Enforce one active policy per product per customer
- Calculate premiums server-side (client calculation is for preview only)
- Use server timestamp for monthly deduction tracking (not device date)
- Generate insurance journal entries atomically with payment transaction

---

## 8. Out of Scope

The following are explicitly **out of scope** for this sprint:

### 8.1 Claims Processing
- Claims submission form
- Claims status tracking
- Claims approval workflow
- Payout disbursement

**Mitigation:** "File a Claim" button shows Coming Soon dialog. Full claims feature scheduled for future sprint.

### 8.2 Loan-Specific Credit Protection
- Attaching Protection crédit policy to a specific loan
- Calculating premium based on loan outstanding balance
- Auto-activating credit protection at loan origination

**Mitigation:** This sprint treats Protection crédit as transaction-percentage-based (1.0% of payment amount). Future sprint will add loan-specific logic.

### 8.3 Remittance, FX, and Airtime Rails
- International remittance premiums
- FX transaction premiums
- Airtime/mobile credit recharge premiums

**Mitigation:** Only Pay Bill (domestic) and Send Money (P2P domestic) support premiums. Other rails unaffected.

### 8.4 USD Premium Support
- Configuring premiums in USD
- Multi-currency premium calculation
- USD wallet premium deduction

**Mitigation:** All premiums are CDF-only. Multi-currency support deferred to future sprint.

### 8.5 Agent & Admin Apps
- Agent app insurance product offerings
- Admin app policy management dashboard
- Bulk policy import/export

**Mitigation:** This sprint is **customer app only**. Agent and admin insurance features are separate epics.

---

## 9. Acceptance Criteria

The feature is considered complete when all of the following are verified:

### AC1: Product Catalog Display
- [ ] Insurance tab shows "Products" and "My Policies" sub-tabs
- [ ] Products tab displays all five insurance products (Santé, Décès, Accident, Protection crédit, Téléphone)
- [ ] Each product card shows: name (FR), subtitle (EN), description, claim cap, status badge, and action button
- [ ] Inactive products show "Activer" button; active products show "Modifier" button

### AC2: Policy Activation Flow
- [ ] Tapping "Activer" opens activation form with correct product name in title
- [ ] Form allows selection of:
  - Premium type: Pourcentage or Montant fixe
  - If Fixed: Fréquence (Par transaction or Mensuel)
  - Amount (CDF input) or Percentage (% input)
  - Deduct from: Paiements de factures, Envois d'argent, or Les deux
- [ ] Form pre-populates with product-specific default values
- [ ] PIN field validates input (must be `123456` for offline demo)
- [ ] Incorrect PIN shows error; correct PIN activates policy, shows success toast, navigates back to Products tab
- [ ] After activation, product status badge changes to "Active" and button changes to "Modifier"
- [ ] Policy appears in "My Policies" tab

### AC3: Policy Management
- [ ] "My Policies" tab lists all active policies
- [ ] Each policy card shows: product name, premium summary, deduction rail, activation date
- [ ] "Désactiver" button shows confirmation dialog; confirming deactivates policy and removes it from list
- [ ] "Faire une réclamation" button shows Coming Soon dialog with appropriate message

### AC4: Pay Bill Premium Deduction
- [ ] Pay Bill flow: after entering bill amount and tapping "Continuer," confirmation screen shows:
  - Bill amount
  - "Primes d'assurance" section with each matching policy as a line item (product name + premium amount)
  - Total premiums subtotal
  - Grand total (bill amount + total premiums)
- [ ] If wallet balance < grand total, show insufficient balance error and block PIN entry
- [ ] If balance sufficient, PIN entry proceeds
- [ ] After correct PIN:
  - Wallet debited by grand total
  - Main transaction journal entry created (type: `BILL_PAYMENT`)
  - Separate journal entry created for each premium (type: `INSURANCE_PREMIUM`)
  - Success screen shows transaction details
- [ ] For FIXED MONTHLY policies: premium charged only once per calendar month; `lastMonthlyCollectedYm` updated after debit

### AC5: Send Money Premium Deduction
- [ ] Send Money (P2P) flow: confirmation screen shows premiums for policies with deductFrom = SEND or BOTH
- [ ] Premium display, balance check, debit, and journal logic identical to Pay Bill (AC4)
- [ ] Remittance and other non-P2P send flows remain unchanged (no premiums)

### AC6: Multiple Policy Stacking
- [ ] Customer can activate multiple products (up to 5)
- [ ] Transaction matching two or more active policies shows all matching premiums as separate line items
- [ ] Grand total = principal + sum of all matching premiums
- [ ] Insufficient balance for grand total blocks entire transaction

### AC7: Monthly Premium Logic
- [ ] FIXED MONTHLY premium charged on first qualifying transaction of calendar month
- [ ] Subsequent transactions in same month: premium = 0 CDF
- [ ] First transaction of next month: premium charged again
- [ ] `lastMonthlyCollectedYm` correctly updated after each monthly collection

### AC8: Seed Data
- [ ] Demo customer (Jean-Paul) starts with one active policy:
  - Santé hospitalisation
  - FIXED MONTHLY 2,500 CDF
  - Deduct from: BOTH
- [ ] Other four products start inactive

### AC9: Edit Policy
- [ ] Tapping "Modifier" on active product opens activation form pre-populated with current policy values
- [ ] Editing and confirming updates policy in place (same policy ID)
- [ ] Only one active policy per product allowed (re-activation overwrites previous config)

### AC10: French/English Localization
- [ ] All UI labels, product names, descriptions, buttons, and messages display in French (primary)
- [ ] Subtitles and some technical terms display in English (secondary)
- [ ] Text matches approved copy in section 3 and 4

---

## 10. Risks & Mitigations

### Risk 1: Bill Pay and Send Money Confirm Screens — Multiple Hook Points

**Risk:** Pay Bill and Send Money flows may have different screen architectures or state management patterns, requiring non-trivial refactoring to insert premium preview and collection logic.

**Mitigation:**
- Inspect existing payment confirm screens early in implementation
- Abstract premium logic into a reusable widget/component (`PremiumSummaryWidget`)
- If screens diverge significantly, implement hooks separately per flow but use shared business logic service

### Risk 2: Monthly Premium Uses Device Local Date

**Risk:** Device date tampering or incorrect time zone settings could cause double-charging or missed monthly premiums.

**Impact:** Low for offline demo (controlled environment). High for production.

**Mitigation:**
- For demo: Acceptable as-is. Document limitation in release notes.
- For production: Backend must calculate monthly eligibility using server-side UTC timestamp. Client `lastMonthlyCollectedYm` becomes advisory only.

### Risk 3: Insufficient Balance Handling — User Confusion

**Risk:** Users may not understand why their payment is blocked when they see "Solde insuffisant" message, especially if they forget they have active insurance policies.

**Mitigation:**
- Error message explicitly mentions "primes d'assurance" (insurance premiums)
- Confirmation screen clearly shows premium breakdown before PIN entry
- Future enhancement: Deep link from error to My Policies screen to allow quick deactivation

### Risk 4: Stacking Policies — Unexpected High Premiums

**Risk:** Customer activates multiple PERCENT policies (e.g., 0.3% + 1.0% = 1.3% total), leading to higher-than-expected premiums on large transactions.

**Mitigation:**
- Confirmation screen shows each premium as a separate line item with product name, making stacking transparent
- Consider adding a "Total premium rate" summary for PERCENT policies (e.g., "Taux total: 1,3%")
- Future enhancement: Warn user during activation if total premium rate exceeds threshold (e.g., >2%)

### Risk 5: Coming Soon Claims — Customer Expectation Mismatch

**Risk:** Customers activate insurance expecting immediate claims capability, then discover claims are "Coming Soon."

**Mitigation:**
- Product card descriptions focus on coverage and premiums, not claims process
- Claims UI is clearly marked as "Coming Soon" with explicit future availability message
- Business stakeholder communication: Ensure sales/support teams clarify that this sprint is "coverage activation only; claims coming in Q4" (adjust timeline as appropriate)

### Risk 6: Protection Crédit — Ambiguous Scope

**Risk:** Product managers or customers may expect Protection crédit to auto-attach to loans and calculate premiums based on loan balance. This sprint implements simple transaction-percentage-based premiums instead.

**Mitigation:**
- Design explicitly documents Protection crédit as 1.0% of transaction amount (not loan-specific) for this sprint
- Backend schema includes `linkedLoanId` field (nullable) for future loan-attachment feature
- UI description for Protection crédit is generic: "Rembourse votre prêt en cas de décès, d'invalidité ou de perte d'emploi" (does not specify calculation method)

---

## 11. Relation to Prior Work

### 11.1 Savings Sprint

**Delivered:**
- Bottom navigation with Insurance tab
- Insurance screen stub showing "Coming Soon" message
- Architecture foundation: OfflineDemoRepository, CoreApiService offline branches, universe.json data structure

**This Sprint Builds On:**
- Replaces "Coming Soon" stub with full insurance implementation
- Follows same offline demo pattern established by savings feature
- Reuses same UI component library, state management pattern, and journal entry architecture

**No Breaking Changes:**
- Savings feature remains unaffected
- Bottom navigation structure unchanged
- Wallet balance and transaction flows extended, not replaced

### 11.2 Payment Flows

**Current State:**
- Pay Bill and Send Money flows support principal amount entry, PIN confirmation, wallet debit, and journal entry creation
- Transaction receipts display principal amount and success message

**This Sprint Extends:**
- Confirmation screens now display premium breakdown
- Wallet debit logic sums principal + premiums
- Journal entry creation appends premium entries
- Receipt optionally shows premium line items (design decision: show or omit from receipt?)

**Future Work:**
- Remittance, FX, and airtime flows will follow similar pattern when insurance is extended to those rails

---

## 12. Appendices

### Appendix A: Glossary

- **Basis Points (bps):** 1/100th of a percent. 30 bps = 0.3%, 100 bps = 1.0%
- **CDF:** Congolese Franc, national currency of Democratic Republic of Congo
- **Minor Units:** Smallest currency denomination (e.g., CDF minor = 1/100 CDF, so 100 minor = 1 CDF)
- **P2P:** Peer-to-peer, person-to-person domestic money transfer
- **Premium:** Periodic payment for insurance coverage
- **Stacking:** Applying multiple insurance premiums to a single transaction

### Appendix B: Open Questions (Resolved)

| Question | Resolution |
|----------|-----------|
| Should Protection crédit be loan-specific this sprint? | No. Simple transaction-percentage (1.0%) this sprint. Loan-attachment in future sprint. |
| Should transaction receipt show premium breakdown? | Yes, briefly. "Primes d'assurance: [total] CDF" line. Detailed breakdown optional (future UX enhancement). |
| Can customer activate multiple policies for same product? | No. One active policy per product. Re-activation overwrites previous config. |
| What if wallet has CDF and USD, but premiums are CDF-only? | Only CDF wallet balance is checked. USD wallet remains separate. Multi-currency premium support is out of scope. |
| Should we validate premium percentages (e.g., max 5%)? | No validation this sprint (offline demo, controlled environment). Backend should enforce reasonable limits in production. |

### Appendix C: Future Enhancements (Post-Sprint Backlog)

- Claims submission and tracking workflow
- Loan-specific Protection crédit with balance-based premiums
- Remittance, FX, and airtime rail premium support
- USD premium configuration and multi-currency deduction
- Agent app: Offer insurance products during customer onboarding
- Admin app: Policy management dashboard, bulk operations, analytics
- Premium payment history and downloadable statements
- Push notifications for policy activation, monthly deduction, and claim status
- Grace period for monthly premiums (e.g., allow 3-day lapse without coverage cancellation)
- Bundled insurance packages (e.g., "Comprehensive Protection" = Health + Accident + Credit for discounted rate)

---

## Sign-off

**Design Status:** Approved for implementation  
**Approved By:** Product Owner, Engineering Lead  
**Implementation Sprint:** Current  
**Target Demo Date:** [TBD based on sprint planning]

---

**End of Document**
