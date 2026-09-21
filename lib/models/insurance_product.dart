/// Insurance premium mode
// ignore: constant_identifier_names
enum PremiumMode { PERCENT, FIXED }

/// Fixed premium schedule (when mode is FIXED)
// ignore: constant_identifier_names
enum FixedSchedule { PER_TXN, MONTHLY }

/// Transaction rails for premium deduction
// ignore: constant_identifier_names
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
