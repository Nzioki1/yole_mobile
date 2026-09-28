
import 'package:demo_universe/demo_universe.dart';

import '../constants/insurance_products.dart';
import '../models/insurance_product.dart';

/// Customer offline demo repository (DEM-01/03/06/07/08).
///
/// Backed by shared [DemoUniverse] seed. Session mutations stay in-memory;
/// [createFresh]/[reset] reload the seed. Wired from CoreApiService /
/// CoreAuthService when `--dart-define=OFFLINE_DEMO=true`.
class OfflineDemoRepository {
  OfflineDemoRepository._(this._universe);

  final DemoUniverse _universe;
  String? _currentCustomerId;
  final Map<String, String> _pins = {};
  final List<Map<String, dynamic>> _pendingPaymentQuotes = [];
  final List<Map<String, dynamic>> _pendingRemittanceQuotes = [];
  int _seq = 0;

  static OfflineDemoRepository? _instance;

  /// Shared session instance used by CoreApiService offline gates.
  static OfflineDemoRepository get instance =>
      _instance ??= createFresh();

  /// Load a fresh deep-cloned universe (also replaces [instance]).
  static OfflineDemoRepository createFresh() {
    final repo = OfflineDemoRepository._(
      DemoUniverse.load(),
    );
    _instance = repo;
    return repo;
  }

  /// Discard session mutations and reload seed into [instance].
  static void reset() {
    createFresh();
  }

  /// DEM-01 OTP — always accepted offline.
  static const String demoOtp = '123456';

  /// DEM transaction PIN — pre-seeded on offline login.
  static const String demoPin = '123456';

  /// DEM customer login credentials — Jean-Paul Kabila.
  static const String demoEmail = 'jp.kabila@gmail.com';
  static const String demoPassword = 'Password1!';

  /// DEM-07 honesty string (also shown on CardsScreen).
  static const String cardsMockBanner =
      'MOCK — not Visa/Mastercard certified';

  /// DEM-06 Kinshasa billers for offline Pay Bill picker.
  static const List<Map<String, String>> kKinshasaBillers = [
    {'code': 'SNEL', 'name': 'SNEL (Electricity)', 'hint': 'Account number', 'demoAccount': '123456789'},
    {'code': 'REGIDESO', 'name': 'REGIDESO (Water)', 'hint': 'Meter number', 'demoAccount': '987654321'},
    {'code': 'VODACOM', 'name': 'Vodacom Congo', 'hint': 'Phone number', 'demoAccount': '+243990123456'},
    {'code': 'AIRTEL', 'name': 'Airtel Congo', 'hint': 'Phone number', 'demoAccount': '+243991234567'},
    {'code': 'ORANGE', 'name': 'Orange RDC', 'hint': 'Phone number', 'demoAccount': '+243992345678'},
    {'code': 'CANAL', 'name': 'Canal+ Congo', 'hint': 'Decoder number', 'demoAccount': 'DEC0123456'},
    {'code': 'DGI', 'name': 'DGI (Tax Authority)', 'hint': 'Tax ID', 'demoAccount': 'TAX123456'},
    {'code': 'KINSHASA', 'name': 'City of Kinshasa', 'hint': 'Reference number', 'demoAccount': 'KIN20260918'},
  ];

  String? get currentCustomerId => _currentCustomerId;

  Map<String, dynamic> get _data => _universe.data;

  List<Map<String, dynamic>> _list(String key) {
    final raw = _data[key];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void _writeList(String key, List<Map<String, dynamic>> items) {
    _data[key] = items;
  }

  String _str(dynamic n) => n == null ? '0' : n.toString();

  int _int(dynamic n) {
    if (n is int) return n;
    if (n is num) return n.toInt();
    return int.tryParse(n?.toString() ?? '') ?? 0;
  }

  String _nextId(String prefix) {
    _seq += 1;
    return '${prefix}_sess_$_seq';
  }

  String _requireCustomer() {
    final cid = _currentCustomerId;
    if (cid == null || cid.isEmpty) {
      throw Exception('Not authenticated (offline demo)');
    }
    return cid;
  }

  void _requireKycApproved({String? customerId}) {
    final cid = customerId ?? _requireCustomer();
    final customer = _list('customers').firstWhere(
      (c) => c['id'] == cid,
      orElse: () => <String, dynamic>{},
    );
    final kycStatus = customer['kycStatus'] as String? ?? 'PENDING';
    if (kycStatus != 'APPROVED') {
      throw Exception('KYC not approved. Please complete KYC verification to activate your wallet.');
    }
  }

  bool isKycApproved({String? customerId}) {
    final cid = customerId ?? _currentCustomerId;
    if (cid == null) return false;
    final customer = _list('customers').firstWhere(
      (c) => c['id'] == cid,
      orElse: () => <String, dynamic>{},
    );
    return customer['kycStatus'] == 'APPROVED';
  }

  // ---------------------------------------------------------------------------
  // Credit Scoring & Affordability (DEM-19)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> getCreditScore({String? customerId}) {
    final cid = customerId ?? _requireCustomer();
    
    // Basic scoring model based on demo universe data
    int score = 500; // Base score
    
    // Factor 1: Salary history (30%)
    final salaryRows = _list('salaryHistory')
        .where((s) => s['customerId'] == cid)
        .toList();
    if (salaryRows.length >= 6) {
      score += 150;
    } else if (salaryRows.length >= 3) {
      score += 100;
    } else if (salaryRows.length >= 2) {
      score += 50;
    }
    
    // Factor 2: Loan repayment history (40%)
    final loans = _list('loans').where((l) => l['customerId'] == cid).toList();
    final schedules = _list('loanSchedules');
    int paidOnTime = 0;
    int totalDue = 0;
    
    for (final loan in loans) {
      final schedule = schedules.firstWhere(
        (s) => s['id'] == loan['scheduleId'],
        orElse: () => <String, dynamic>{},
      );
      if (schedule.isNotEmpty) {
        final installments = schedule['installments'] as List? ?? [];
        for (final inst in installments) {
          if (inst['status'] == 'PAID') {
            paidOnTime++;
            totalDue++;
          } else if (inst['status'] == 'OVERDUE') {
            totalDue++;
          }
        }
      }
    }
    
    if (totalDue > 0) {
      final repaymentRate = paidOnTime / totalDue;
      if (repaymentRate >= 0.95) {
        score += 200;
      } else if (repaymentRate >= 0.80) {
        score += 100;
      } else if (repaymentRate >= 0.60) {
        score += 50;
      } else {
        score -= 100; // Penalty for poor repayment
      }
    }
    
    // Factor 3: Account age (10%)
    final customer = _list('customers').firstWhere(
      (c) => c['id'] == cid,
      orElse: () => <String, dynamic>{},
    );
    final createdAt = customer['createdAt'] as String?;
    if (createdAt != null) {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final monthsSinceCreation = now.difference(created).inDays ~/ 30;
      if (monthsSinceCreation >= 12) {
        score += 50;
      } else if (monthsSinceCreation >= 6) {
        score += 30;
      }
    }
    
    // Factor 4: Wallet activity (10%)
    final payments = _list('payments')
        .where((p) => p['customerId'] == cid && p['status'] == 'POSTED')
        .toList();
    if (payments.length >= 20) {
      score += 50;
    } else if (payments.length >= 10) {
      score += 30;
    }
    
    // Factor 5: Savings behavior (10%)
    final goals = _list('savingsGoals')
        .where((g) => g['customerId'] == cid)
        .toList();
    if (goals.isNotEmpty) {
      score += 50;
    }
    
    // Cap score at 850
    if (score > 850) score = 850;
    if (score < 300) score = 300;
    
    String rating;
    if (score >= 750) {
      rating = 'EXCELLENT';
    } else if (score >= 650) {
      rating = 'GOOD';
    } else if (score >= 550) {
      rating = 'FAIR';
    } else {
      rating = 'POOR';
    }
    
    return {
      'score': score,
      'rating': rating,
      'factors': {
        'salaryHistory': salaryRows.length,
        'loanHistory': loans.length,
        'repaymentRate': totalDue > 0 ? (paidOnTime / totalDue * 100).round() : null,
        'accountAgeMonths': createdAt != null 
            ? DateTime.now().difference(DateTime.parse(createdAt)).inDays ~/ 30
            : 0,
        'transactionCount': payments.length,
        'hasSavings': goals.isNotEmpty,
      },
    };
  }

  Map<String, dynamic> checkAffordability({
    required String principalMinor,
    required int termMonths,
    String currency = 'CDF',
  }) {
    final cid = _requireCustomer();
    final principal = _int(principalMinor);
    
    // Get most recent salary
    final salaryRows = _list('salaryHistory')
        .where((s) => s['customerId'] == cid)
        .toList();
    
    if (salaryRows.isEmpty) {
      return {
        'affordable': false,
        'reason': 'No salary history found',
      };
    }
    
    // Calculate average salary from last 3 months
    final recentSalaries = salaryRows.take(3).toList();
    int totalSalary = 0;
    for (final s in recentSalaries) {
      totalSalary += _int(s['netPayCdfMinor']);
    }
    final avgMonthlySalary = totalSalary / recentSalaries.length;
    
    // Calculate monthly installment (simple interest)
    final interestRate = 0.15; // 15% annual
    final monthlyRate = interestRate / 12;
    final totalRepayment = principal * (1 + (interestRate * termMonths / 12));
    final monthlyInstallment = totalRepayment / termMonths;
    
    // Affordability: installment should not exceed 33% of net salary
    final maxInstallment = avgMonthlySalary * 0.33;
    final affordable = monthlyInstallment <= maxInstallment;
    
    return {
      'affordable': affordable,
      'monthlyInstallmentMinor': monthlyInstallment.round(),
      'avgMonthlySalaryMinor': avgMonthlySalary.round(),
      'maxInstallmentMinor': maxInstallment.round(),
      'installmentToIncomeRatio': (monthlyInstallment / avgMonthlySalary * 100).round(),
      'reason': affordable
          ? 'Installment is ${(monthlyInstallment / avgMonthlySalary * 100).round()}% of income (limit: 33%)'
          : 'Installment would be ${(monthlyInstallment / avgMonthlySalary * 100).round()}% of income (limit: 33%)',
    };
  }

  // ---------------------------------------------------------------------------
  // Wallets
  // ---------------------------------------------------------------------------

  /// Brief-mandated helper — seed has CDF+USD for cust_kasee.
  List<Map<String, dynamic>> walletsFor(String customerId) {
    return _list('wallets')
        .where((w) => w['customerId'] == customerId)
        .map(_walletDto)
        .toList();
  }

  Map<String, dynamic> _walletDto(Map<String, dynamic> w) {
    final id = w['id'] as String;
    final currency = w['currency'] as String? ?? 'USD';
    return {
      ...w,
      'availableMinor': _str(w['availableMinor']),
      'ledgerMinor': _str(w['ledgerMinor']),
      'blockedMinor': _str(w['blockedMinor']),
      'pendingMinor': _str(w['pendingMinor']),
      'pockets': [
        {
          'id': '${id}_pocket',
          'currency': currency,
          'availableMinor': _str(w['availableMinor']),
          'ledgerMinor': _str(w['ledgerMinor']),
          'blockedMinor': _str(w['blockedMinor']),
          'pendingOutMinor': _str(w['pendingMinor']),
          'pendingInMinor': '0',
        },
      ],
    };
  }

  Map<String, dynamic> getMyWallets() {
    final cid = _requireCustomer();
    return {'wallets': walletsFor(cid)};
  }

  // ---------------------------------------------------------------------------
  // Auth / OTP / PIN / KYC (DEM-01)
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? findCustomerByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final c in _list('customers')) {
      if ((c['email'] as String?)?.toLowerCase() == normalized) {
        return c;
      }
    }
    return null;
  }

  /// Seeded login — no HTTP. Shape matches CoreApiService / CoreAuthService.
  Map<String, dynamic> login({
    required String email,
    required String password,
  }) {
    final customer = findCustomerByEmail(email);
    if (customer == null || customer['password'] != password) {
      throw Exception('Login failed: invalid credentials');
    }
    _currentCustomerId = customer['id'] as String;
    _pins.putIfAbsent(_currentCustomerId!, () => demoPin);
    return {
      'accessToken': 'offline-demo-token-${customer['id']}',
      'customer': {
        'id': customer['id'],
        'email': customer['email'],
        'firstName': customer['firstName'],
        'lastName': customer['lastName'],
        'phoneE164': customer['phoneE164'],
        'kycStatus': customer['kycStatus'],
      },
    };
  }

  Map<String, dynamic> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneE164,
  }) {
    if (findCustomerByEmail(email) != null) {
      throw Exception('Register failed: email already registered');
    }
    final id = _nextId('cust');
    final now = DateTime.now().toUtc().toIso8601String();
    final customer = <String, dynamic>{
      'id': id,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phoneE164': phoneE164,
      'segment': 'OPEN',
      'status': 'ACTIVE',
      'kycStatus': 'PENDING',
      'createdAt': now,
    };
    _writeList('customers', _list('customers')..add(customer));

    final wallets = _list('wallets');
    wallets.add({
      'id': 'wal_${id}_cdf',
      'customerId': id,
      'currency': 'CDF',
      'availableMinor': 0,
      'ledgerMinor': 0,
      'blockedMinor': 0,
      'pendingMinor': 0,
    });
    wallets.add({
      'id': 'wal_${id}_usd',
      'customerId': id,
      'currency': 'USD',
      'availableMinor': 0,
      'ledgerMinor': 0,
      'blockedMinor': 0,
      'pendingMinor': 0,
    });
    _writeList('wallets', wallets);

    _currentCustomerId = id;
    _pins.putIfAbsent(id, () => demoPin);
    return {
      'accessToken': 'offline-demo-token-$id',
      'customer': {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneE164': phoneE164,
        'kycStatus': 'PENDING',
      },
    };
  }

  void setCurrentCustomer(String customerId) {
    _currentCustomerId = customerId;
  }

  void clearSession() {
    _currentCustomerId = null;
  }

  void requestOtp({required String phoneE164}) {
    if (phoneE164.trim().isEmpty) {
      throw Exception('Request OTP failed: phone required');
    }
  }

  Map<String, dynamic> verifyOtp({
    required String phoneE164,
    required String code,
  }) {
    if (code != demoOtp) {
      throw Exception('Verify OTP failed: invalid code (demo OTP is $demoOtp)');
    }
    return {'verified': true, 'phoneE164': phoneE164};
  }

  bool hasPin() {
    final cid = _currentCustomerId;
    if (cid == null) return false;
    return _pins.containsKey(cid);
  }

  void setPin({required String pin}) {
    final cid = _requireCustomer();
    _pins[cid] = pin;
  }

  bool verifyPin({required String pin}) {
    final cid = _currentCustomerId;
    if (cid == null) return false;
    if (!_pins.containsKey(cid)) return pin.length >= 4;
    return _pins[cid] == pin;
  }

  Map<String, dynamic> submitKyc({
    required String phoneE164,
    required String idNumber,
    String idType = 'NATIONAL_ID',
  }) {
    final cid = _requireCustomer();
    final now = DateTime.now().toUtc().toIso8601String();
    final kyc = _list('kyc');
    final idx = kyc.indexWhere((k) => k['customerId'] == cid);
    final row = <String, dynamic>{
      'id': idx >= 0 ? kyc[idx]['id'] : _nextId('kyc'),
      'customerId': cid,
      'phoneE164': phoneE164,
      'idNumber': idNumber,
      'idType': idType,
      'status': 'PENDING_REVIEW',
      'reviewNotes': 'Offline demo KYC submit',
      'screeningResult': 'CLEAR',
      'createdAt': idx >= 0 ? kyc[idx]['createdAt'] : now,
      'updatedAt': now,
    };
    if (idx >= 0) {
      kyc[idx] = row;
    } else {
      kyc.add(row);
    }
    _writeList('kyc', kyc);

    final customers = _list('customers');
    final ci = customers.indexWhere((c) => c['id'] == cid);
    if (ci >= 0) {
      customers[ci] = {...customers[ci], 'kycStatus': 'PENDING_REVIEW'};
      _writeList('customers', customers);
    }
    return {'success': true, 'kyc': row};
  }

  // ---------------------------------------------------------------------------
  // Limits / notifications
  // ---------------------------------------------------------------------------

  Map<String, dynamic> getMyLimits() {
    final limits = _list('feeLimits')
        .where((f) => f['kind'] == 'LIMIT')
        .map((f) => {
              ...f,
              'dailyLimitMinor': _str(f['dailyLimitMinor']),
              'monthlyLimitMinor': _str(f['monthlyLimitMinor']),
            })
        .toList();
    return {'limits': limits};
  }

  Map<String, dynamic> getNotifications() {
    final cid = _requireCustomer();
    final items =
        _list('notifications').where((n) => n['customerId'] == cid).toList();
    return {'notifications': items};
  }

  int getUnreadNotificationsCount() {
    final cid = _currentCustomerId;
    if (cid == null) return 0;
    return _list('notifications')
        .where((n) => n['customerId'] == cid && n['read'] != true)
        .length;
  }

  void markNotificationAsRead(String notificationId) {
    final items = _list('notifications');
    final i = items.indexWhere((n) => n['id'] == notificationId);
    if (i >= 0) {
      items[i] = {...items[i], 'read': true};
      _writeList('notifications', items);
    }
  }

  void markAllNotificationsAsRead() {
    final cid = _requireCustomer();
    _writeList(
      'notifications',
      _list('notifications')
          .map((n) => n['customerId'] == cid ? {...n, 'read': true} : n)
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Payments (DEM-06) — confirm appends journal
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _activeFee(String paymentType) {
    for (final f in _list('feeLimits')) {
      if (f['kind'] == 'FEE' &&
          f['paymentType'] == paymentType &&
          f['status'] == 'ACTIVE') {
        return f;
      }
    }
    return null;
  }

  int _calcFee(String type, int amountMinor) {
    final fee = _activeFee(type);
    if (fee == null) return 0;
    final pct = (fee['feePercent'] as num?)?.toDouble() ?? 0;
    var computed = (amountMinor * pct / 100).round();
    final minF = _int(fee['minFeeMinor']);
    final maxF = _int(fee['maxFeeMinor']);
    if (computed < minF) computed = minF;
    if (maxF > 0 && computed > maxF) computed = maxF;
    return computed;
  }

  Map<String, dynamic> quotePayment({
    required String type,
    required String currency,
    required String amountMinor,
    Map<String, dynamic>? metadata,
  }) {
    final cid = _requireCustomer();
    _requireKycApproved();
    final amount = _int(amountMinor);
    final fee = _calcFee(type, amount);
    final quoteId = _nextId('pay');
    final quote = <String, dynamic>{
      'paymentId': quoteId,
      'id': quoteId,
      'customerId': cid,
      'type': type,
      'status': 'QUOTED',
      'currency': currency,
      'amountMinor': _str(amount),
      'feeMinor': _str(fee),
      'totalMinor': _str(amount + fee),
      'metadata': metadata ?? {},
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _pendingPaymentQuotes.add(Map<String, dynamic>.from(quote));
    return quote;
  }

  Map<String, dynamic> confirmPayment({required String paymentId}) {
    final cid = _requireCustomer();
    final now = DateTime.now().toUtc().toIso8601String();

    Map<String, dynamic>? quote;
    final qi = _pendingPaymentQuotes.indexWhere(
      (q) => q['paymentId'] == paymentId || q['id'] == paymentId,
    );
    if (qi >= 0) {
      quote = _pendingPaymentQuotes.removeAt(qi);
    }

    final payments = _list('payments');
    final existingIdx = payments.indexWhere((p) => p['id'] == paymentId);

    final amount = _int(
      quote?['amountMinor'] ??
          (existingIdx >= 0 ? payments[existingIdx]['amountMinor'] : 0),
    );
    final fee = _int(
      quote?['feeMinor'] ??
          (existingIdx >= 0 ? payments[existingIdx]['feeMinor'] : 0),
    );
    final currency = (quote?['currency'] ??
            (existingIdx >= 0 ? payments[existingIdx]['currency'] : 'USD'))
        as String;
    final type = (quote?['type'] ??
            (existingIdx >= 0 ? payments[existingIdx]['type'] : 'W2W'))
        as String;

    final isInbound = type.endsWith('_IN');
    final wallets = _list('wallets');
    final wi = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    String? walletId;
    int? balanceAfter;
    if (wi >= 0) {
      walletId = wallets[wi]['id'] as String;
      final avail = _int(wallets[wi]['availableMinor']);
      final ledger = _int(wallets[wi]['ledgerMinor']);
      
      if (isInbound) {
        final credit = amount - fee;
        balanceAfter = avail + credit;
        wallets[wi] = {
          ...wallets[wi],
          'availableMinor': balanceAfter,
          'ledgerMinor': ledger + credit,
        };
      } else {
        final debit = amount + fee;
        balanceAfter = avail - debit;
        wallets[wi] = {
          ...wallets[wi],
          'availableMinor': balanceAfter,
          'ledgerMinor': ledger - debit,
        };
      }
      _writeList('wallets', wallets);
    }

    final journalId = _nextId('jnl');
    final journals = _list('journals');
    journals.add({
      'id': journalId,
      'customerId': cid,
      'walletId': walletId,
      'type': 'PAYMENT',
      'direction': isInbound ? 'CREDIT' : 'DEBIT',
      'currency': currency,
      'amountMinor': isInbound ? (amount - fee) : amount,
      'balanceAfterMinor': balanceAfter,
      'refType': 'PAYMENT',
      'refId': paymentId,
      'narration': 'Offline demo $type confirm',
      'postedAt': now,
    });
    _writeList('journals', journals);

    final payment = <String, dynamic>{
      'id': paymentId,
      'customerId': cid,
      'type': type,
      'status': 'POSTED',
      'currency': currency,
      'amountMinor': amount,
      'feeMinor': fee,
      'totalMinor': amount + fee,
      'sourceRef': walletId,
      'destRef': quote?['metadata'],
      'journalId': journalId,
      'idempotencyKey': 'idem_$paymentId',
      'createdAt': quote?['createdAt'] ?? now,
    };

    if (existingIdx >= 0) {
      payments[existingIdx] = {
        ...payments[existingIdx],
        ...payment,
        'status': 'POSTED',
        'journalId': journalId,
      };
    } else {
      payments.add(payment);
    }
    _writeList('payments', payments);

    return {
      ...payment,
      'amountMinor': _str(payment['amountMinor']),
      'feeMinor': _str(payment['feeMinor']),
      'totalMinor': _str(payment['totalMinor']),
    };
  }

  List<dynamic> listPayments() {
    final cid = _requireCustomer();
    return _list('payments')
        .where((p) => p['customerId'] == cid)
        .map((p) => {
              ...p,
              'amountMinor': _str(p['amountMinor']),
              'feeMinor': _str(p['feeMinor']),
              'totalMinor': _str(p['totalMinor']),
            })
        .toList();
  }

  Map<String, dynamic> getPayment(String paymentId) {
    final p = _list('payments').firstWhere(
      (x) => x['id'] == paymentId,
      orElse: () => throw Exception('Get payment failed: not found'),
    );
    return {
      ...p,
      'amountMinor': _str(p['amountMinor']),
      'feeMinor': _str(p['feeMinor']),
      'totalMinor': _str(p['totalMinor']),
    };
  }

  // ---------------------------------------------------------------------------
  // Credit (DEM-03) — Amina eligibility from salary history
  // ---------------------------------------------------------------------------

  Map<String, dynamic> checkCreditEligibility({required String type}) {
    final cid = _requireCustomer();
    final normalized = type.toUpperCase();

    if (normalized == 'SALARY_ADVANCE' || normalized == 'SALARY_ADVANCE'.replaceAll('_', '') ||
        normalized == 'SALARYADVANCE' ||
        normalized.contains('SALARY')) {
      Map<String, dynamic>? employee;
      for (final e in _list('employees')) {
        if (e['customerId'] == cid && e['status'] == 'ACTIVE') {
          employee = e;
          break;
        }
      }
      final salaryRows = _list('salaryHistory')
          .where((s) => s['customerId'] == cid)
          .toList();

      if (employee != null && salaryRows.length >= 2) {
        return {
          'eligible': true,
          'type': type,
          'maxAmountMinor': _str(employee['eligibleAdvanceMaxCdfMinor']),
          'currency': 'CDF',
          'salaryPeriods': salaryRows.length,
          'employerId': employee['employerId'],
          'reason':
              'Eligible from ${salaryRows.length} salary period(s) at ${employee['employerId']}',
        };
      }
      if (employee != null && salaryRows.isNotEmpty) {
        return {
          'eligible': false,
          'type': type,
          'maxAmountMinor': '0',
          'salaryPeriods': salaryRows.length,
          'reason':
              'Need at least 2 salary payments (you have ${salaryRows.length})',
        };
      }
      return {
        'eligible': false,
        'type': type,
        'maxAmountMinor': '0',
        'reason':
            'No payroll salary history linked — salary advance requires employer payroll',
      };
    }

    // MICRO_LOAN / other
    final customer = _list('customers').firstWhere(
      (c) => c['id'] == cid,
      orElse: () => <String, dynamic>{},
    );
    final approved = customer['kycStatus'] == 'APPROVED';
    return {
      'eligible': approved,
      'type': type,
      'maxAmountMinor': approved ? '50000' : '0',
      'currency': 'USD',
      'reason': approved
          ? 'KYC approved — micro loan available'
          : 'KYC not approved',
    };
  }

  Map<String, dynamic> requestLoan({
    required String type,
    required String principalMinor,
    required String currency,
    required int termMonths,
  }) {
    final cid = _requireCustomer();
    final eligibility = checkCreditEligibility(type: type);
    if (eligibility['eligible'] != true) {
      throw Exception('Request loan failed: ${eligibility['reason']}');
    }
    
    // Get credit score and affordability
    final creditScore = getCreditScore();
    final affordability = checkAffordability(
      principalMinor: principalMinor,
      termMonths: termMonths,
      currency: currency,
    );
    
    final loanId = _nextId('loan');
    final now = DateTime.now().toUtc().toIso8601String();
    final principal = _int(principalMinor);
    
    // Decision logic
    String status;
    String? declineReason;
    bool disburse = false;
    
    final score = creditScore['score'] as int;
    final affordable = affordability['affordable'] as bool;
    
    if (!affordable) {
      // DECLINED: Not affordable
      status = 'DECLINED';
      declineReason = affordability['reason'] as String;
    } else if (score >= 650) {
      // APPROVED: Good credit score and affordable
      status = 'ACTIVE';
      disburse = true;
    } else if (score >= 500) {
      // PENDING: Fair score, needs manual review
      status = 'PENDING_EXCEPTION';
      declineReason = 'Credit score ${score} requires manual review (threshold: 650)';
    } else {
      // DECLINED: Poor credit score
      status = 'DECLINED';
      declineReason = 'Credit score ${score} below minimum threshold (500)';
    }
    final loan = <String, dynamic>{
      'id': loanId,
      'customerId': cid,
      'employerId': eligibility['employerId'],
      'productId': type.toUpperCase().contains('SALARY')
          ? 'prod_salary_advance'
          : 'prod_micro_loan',
      'status': status,
      'principalMinor': principal,
      'currency': currency,
      'termMonths': termMonths,
      'scheduleId': status == 'ACTIVE' ? _nextId('sched') : null,
      'receivableMinor': status == 'ACTIVE' ? principal : 0,
      'disbursedAt': status == 'ACTIVE' ? now : null,
      'createdAt': now,
      'declineReason': declineReason,
      'creditScore': score,
      'affordabilityCheck': affordability,
    };
    _writeList('loans', _list('loans')..add(loan));
    
    // If PENDING, create approval record
    if (status == 'PENDING_EXCEPTION') {
      final approvals = _list('pendingApprovals');
      approvals.add({
        'id': _nextId('appr'),
        'type': 'CREDIT_EXCEPTION',
        'entityType': 'LOAN',
        'entityId': loanId,
        'requestedBy': cid,
        'requestedAt': now,
        'status': 'PENDING',
        'reason': declineReason,
        'metadata': {
          'principalMinor': principal,
          'termMonths': termMonths,
          'creditScore': score,
          'affordability': affordability,
        },
      });
      _writeList('pendingApprovals', approvals);
    }

    // Only disburse if APPROVED
    if (!disburse) {
      return {
        'loan': loan,
        'status': status,
        'reason': declineReason,
        'creditScore': creditScore,
      };
    }

    final wallets = _list('wallets');
    final wi = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    if (wi >= 0) {
      final avail = _int(wallets[wi]['availableMinor']);
      final ledger = _int(wallets[wi]['ledgerMinor']);
      wallets[wi] = {
        ...wallets[wi],
        'availableMinor': avail + principal,
        'ledgerMinor': ledger + principal,
      };
      _writeList('wallets', wallets);

      final journals = _list('journals');
      journals.add({
        'id': _nextId('jnl'),
        'customerId': cid,
        'walletId': wallets[wi]['id'],
        'type': 'LOAN_DISBURSEMENT',
        'direction': 'CREDIT',
        'currency': currency,
        'amountMinor': principal,
        'balanceAfterMinor': avail + principal,
        'refType': 'LOAN',
        'refId': loanId,
        'narration': 'Offline demo loan disbursement',
        'postedAt': now,
      });
      _writeList('journals', journals);
    }

    return {
      ...loan,
      'principalMinor': _str(principal),
      'receivableMinor': _str(principal),
    };
  }

  List<dynamic> listLoans() {
    final cid = _requireCustomer();
    return _list('loans')
        .where((l) => l['customerId'] == cid)
        .map((l) => {
              ...l,
              'principalMinor': _str(l['principalMinor']),
              'receivableMinor': _str(l['receivableMinor']),
            })
        .toList();
  }

  Map<String, dynamic> getLoan(String loanId) {
    final l = _list('loans').firstWhere(
      (x) => x['id'] == loanId,
      orElse: () => throw Exception('Get loan failed: not found'),
    );
    
    List<Map<String, dynamic>>? schedule;
    final scheduleId = l['scheduleId'];
    if (scheduleId != null) {
      final schedDoc = _list('loanSchedules').firstWhere(
        (s) => s['id'] == scheduleId,
        orElse: () => <String, dynamic>{},
      );
      if (schedDoc.isNotEmpty) {
        final installments = schedDoc['installments'] as List<dynamic>?;
        if (installments != null) {
          schedule = installments
              .map((inst) => Map<String, dynamic>.from(inst as Map))
              .toList();
        }
      }
    }
    
    return {
      ...l,
      'principalMinor': _str(l['principalMinor']),
      'receivableMinor': _str(l['receivableMinor']),
      if (schedule != null) 'repaymentSchedule': schedule,
    };
  }

  Map<String, dynamic> repayLoan({
    required String loanId,
    required String amountMinor,
  }) {
    final cid = _requireCustomer();
    final now = DateTime.now().toUtc().toIso8601String();
    final amount = _int(amountMinor);

    final loans = _list('loans');
    final loanIdx = loans.indexWhere((l) => l['id'] == loanId);
    if (loanIdx < 0) {
      throw Exception('Loan not found');
    }

    final loan = loans[loanIdx];
    final currency = loan['currency'] as String? ?? 'CDF';
    final receivable = _int(loan['receivableMinor']);

    if (amount > receivable) {
      throw Exception('Payment amount exceeds outstanding balance');
    }

    final wallets = _list('wallets');
    final walletIdx = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    if (walletIdx < 0) {
      throw Exception('Wallet not found');
    }

    final wallet = wallets[walletIdx];
    final avail = _int(wallet['availableMinor']);
    if (avail < amount) {
      throw Exception('Insufficient funds');
    }

    final newAvail = avail - amount;
    final ledger = _int(wallet['ledgerMinor']);
    wallets[walletIdx] = {
      ...wallet,
      'availableMinor': newAvail,
      'ledgerMinor': ledger - amount,
    };
    _writeList('wallets', wallets);

    final newReceivable = receivable - amount;
    loans[loanIdx] = {
      ...loan,
      'receivableMinor': newReceivable,
      if (newReceivable == 0) 'status': 'REPAID',
      if (newReceivable == 0) 'repaidAt': now,
    };
    _writeList('loans', loans);

    final scheduleId = loan['scheduleId'];
    if (scheduleId != null) {
      final schedules = _list('loanSchedules');
      final schedIdx = schedules.indexWhere((s) => s['id'] == scheduleId);
      if (schedIdx >= 0) {
        final sched = schedules[schedIdx];
        final installments = List<Map<String, dynamic>>.from(
          (sched['installments'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
              [],
        );

        int remaining = amount;
        for (final inst in installments) {
          if (remaining <= 0) break;
          if (inst['status'] == 'PAID') continue;

          final instAmount =
              _int(inst['principalMinor']) + _int(inst['interestMinor']);
          if (remaining >= instAmount) {
            inst['status'] = 'PAID';
            inst['paidAt'] = now;
            remaining -= instAmount;
          }
        }

        schedules[schedIdx] = {
          ...sched,
          'installments': installments,
        };
        _writeList('loanSchedules', schedules);
      }
    }

    final journals = _list('journals');
    journals.add({
      'id': _nextId('jnl'),
      'customerId': cid,
      'walletId': wallet['id'],
      'type': 'LOAN_REPAYMENT',
      'direction': 'DEBIT',
      'currency': currency,
      'amountMinor': amount,
      'balanceAfterMinor': newAvail,
      'refType': 'LOAN',
      'refId': loanId,
      'narration': 'Offline demo loan repayment',
      'postedAt': now,
    });
    _writeList('journals', journals);

    final notifications = _list('notifications');
    notifications.add({
      'id': _nextId('notif'),
      'customerId': cid,
      'type': 'LOAN_REPAYMENT',
      'title': 'Loan Repayment Successful',
      'message':
          'Payment of ${_formatMinor(amount, currency)} has been applied to your loan.',
      'read': false,
      'createdAt': now,
    });
    _writeList('notifications', notifications);

    return {
      'success': true,
      'loanId': loanId,
      'amountPaid': _str(amount),
      'remainingBalance': _str(newReceivable),
      'status': newReceivable == 0 ? 'REPAID' : loan['status'],
    };
  }

  String _formatMinor(int minor, String currency) {
    if (currency == 'CDF') {
      return 'FC ${(minor / 100).toStringAsFixed(0)}';
    } else {
      return '\$${(minor / 100).toStringAsFixed(2)}';
    }
  }

  // ---------------------------------------------------------------------------
  // Cards (DEM-07)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _cardDto(Map<String, dynamic> c) {
    final last4 = (c['last4'] ?? '0000').toString();
    final cid = c['customerId'] as String?;
    
    // Get cardholder name from customer
    String? cardholderName;
    if (cid != null) {
      for (final customer in _list('customers')) {
        if (customer['id'] == cid) {
          final firstName = customer['firstName'] ?? '';
          final lastName = customer['lastName'] ?? '';
          cardholderName = '$firstName $lastName'.trim();
          break;
        }
      }
    }
    
    return {
      ...c,
      'last4': last4,
      'cardNumber': c['cardNumber'] ?? '************$last4',
      'dailyLimitMinor': _str(c['dailyLimitMinor']),
      'monthlyLimitMinor': _str(c['monthlyLimitMinor']),
      'mockNetwork': 'VISA', // Changed from MOCK to VISA
      'cardholderName': cardholderName ?? 'Cardholder',
    };
  }

  Map<String, dynamic> issueCard({
    required String walletPocketId,
    required String currency,
    required String dailyLimitMinor,
    required String monthlyLimitMinor,
  }) {
    final cid = _requireCustomer();
    final cardId = _nextId('card');
    final card = <String, dynamic>{
      'id': cardId,
      'customerId': cid,
      'type': 'VIRTUAL_DEBIT',
      'last4': '4242',
      'cardNumber': '************4242',
      'currency': currency,
      'status': 'ACTIVE',
      'walletPocketId': walletPocketId,
      'dailyLimitMinor': _int(dailyLimitMinor),
      'monthlyLimitMinor': _int(monthlyLimitMinor),
      'mockNetwork': 'VISA', // Changed from MOCK to VISA
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _writeList('cards', _list('cards')..add(card));
    return _cardDto(card);
  }

  List<dynamic> listCards() {
    final cid = _requireCustomer();
    return _list('cards')
        .where((c) => c['customerId'] == cid)
        .map(_cardDto)
        .toList();
  }

  Map<String, dynamic> getCard(String cardId) {
    final c = _list('cards').firstWhere(
      (x) => x['id'] == cardId,
      orElse: () => throw Exception('Get card failed: not found'),
    );
    return _cardDto(c);
  }

  Map<String, dynamic> _setCardStatus(String cardId, String status) {
    final cards = _list('cards');
    final i = cards.indexWhere((c) => c['id'] == cardId);
    if (i < 0) throw Exception('Card not found: $cardId');
    cards[i] = {...cards[i], 'status': status};
    _writeList('cards', cards);
    return _cardDto(cards[i]);
  }

  Map<String, dynamic> freezeCard(String cardId) =>
      _setCardStatus(cardId, 'FROZEN');
  Map<String, dynamic> activateCard(String cardId) =>
      _setCardStatus(cardId, 'ACTIVE');
  Map<String, dynamic> blockCard(String cardId) =>
      _setCardStatus(cardId, 'BLOCKED');

  Map<String, dynamic> updateCardLimits({
    required String cardId,
    required String dailyLimitMinor,
    required String monthlyLimitMinor,
  }) {
    final cards = _list('cards');
    final i = cards.indexWhere((c) => c['id'] == cardId);
    if (i < 0) throw Exception('Card not found: $cardId');
    cards[i] = {
      ...cards[i],
      'dailyLimitMinor': _int(dailyLimitMinor),
      'monthlyLimitMinor': _int(monthlyLimitMinor),
    };
    _writeList('cards', cards);
    return _cardDto(cards[i]);
  }

  List<dynamic> getCardTransactions(String cardId) {
    return _list('cardAuths')
        .where((a) => a['cardId'] == cardId)
        .map((a) => {
              ...a,
              'amountMinor': _str(a['amountMinor']),
              'mock': true,
            })
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Remittance (DEM-08) — CLEAR + SCREENING_HIT
  // ---------------------------------------------------------------------------

  double _fxRate(String base, String quote) {
    for (final r in _list('fxRates')) {
      if (r['base'] == base && r['quote'] == quote) {
        return (r['rate'] as num).toDouble();
      }
    }
    if (base == 'USD' && quote == 'CDF') return 2750.0;
    if (base == 'CDF' && quote == 'USD') return 0.0003636;
    return 1.0;
  }

  Map<String, dynamic> quoteInboundRemittance({
    required String amountMinor,
    required String currency,
  }) {
    final cid = _requireCustomer();
    final amount = _int(amountMinor);
    // Demo heuristic: USD >= 200.00 triggers screening-hit path.
    final screeningHit = currency == 'USD' && amount >= 20000;
    final quoteId = _nextId('rmt');
    final rate = _fxRate(currency, 'CDF');
    final receiveCurrency = currency == 'USD' ? 'CDF' : currency;
    final receiveAmount =
        currency == 'USD' ? (amount * rate).round() : amount;

    final quote = <String, dynamic>{
      'quoteId': quoteId,
      'id': quoteId,
      'customerId': cid,
      'direction': 'INBOUND',
      'status': screeningHit ? 'SCREENING_HIT' : 'QUOTED',
      'sendCurrency': currency,
      'sendAmountMinor': _str(amount),
      'receiveCurrency': receiveCurrency,
      'receiveAmountMinor': _str(receiveAmount),
      'fxRate': rate,
      if (screeningHit) 'screeningHit': 'PARTIAL_NAME_MATCH',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _pendingRemittanceQuotes.add(Map<String, dynamic>.from(quote));
    return quote;
  }

  Map<String, dynamic> confirmInboundRemittance(String quoteId) {
    final cid = _requireCustomer();

    Map<String, dynamic>? quote;
    final qi = _pendingRemittanceQuotes.indexWhere(
      (q) => q['quoteId'] == quoteId || q['id'] == quoteId,
    );
    if (qi >= 0) {
      quote = _pendingRemittanceQuotes.removeAt(qi);
    }

    final remittances = _list('remittances');
    final existingIdx = remittances.indexWhere((r) => r['id'] == quoteId);

    final status = (quote?['status'] ??
            (existingIdx >= 0
                ? remittances[existingIdx]['status']
                : 'CLEAR'))
        .toString();

    if (status == 'SCREENING_HIT') {
      final row = <String, dynamic>{
        'id': quoteId,
        'customerId': cid,
        'direction': 'INBOUND',
        'partner': 'MOCK-MTO',
        'status': 'SCREENING_HIT',
        'sendCurrency': quote?['sendCurrency'] ??
            (existingIdx >= 0
                ? remittances[existingIdx]['sendCurrency']
                : 'USD'),
        'sendAmountMinor': _int(quote?['sendAmountMinor'] ??
            (existingIdx >= 0
                ? remittances[existingIdx]['sendAmountMinor']
                : 0)),
        'receiveCurrency': quote?['receiveCurrency'] ??
            (existingIdx >= 0
                ? remittances[existingIdx]['receiveCurrency']
                : 'USD'),
        'receiveAmountMinor': _int(quote?['receiveAmountMinor'] ??
            (existingIdx >= 0
                ? remittances[existingIdx]['receiveAmountMinor']
                : 0)),
        'walletId': null,
        'screeningHit':
            quote?['screeningHit'] ?? 'PARTIAL_NAME_MATCH',
        'createdAt': quote?['createdAt'] ??
            DateTime.now().toUtc().toIso8601String(),
      };
      if (existingIdx >= 0) {
        remittances[existingIdx] = {...remittances[existingIdx], ...row};
      } else {
        remittances.add(row);
      }
      _writeList('remittances', remittances);
      return {
        ...row,
        'sendAmountMinor': _str(row['sendAmountMinor']),
        'receiveAmountMinor': _str(row['receiveAmountMinor']),
        'message': 'Held for screening — offline demo SCREENING_HIT path',
      };
    }

    final receiveCurrency = (quote?['receiveCurrency'] ??
            (existingIdx >= 0
                ? remittances[existingIdx]['receiveCurrency']
                : 'CDF'))
        as String;
    final receiveAmount = _int(quote?['receiveAmountMinor'] ??
        (existingIdx >= 0
            ? remittances[existingIdx]['receiveAmountMinor']
            : 0));

    final wallets = _list('wallets');
    final wi = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == receiveCurrency,
    );
    String? walletId;
    if (wi >= 0) {
      walletId = wallets[wi]['id'] as String;
      final avail = _int(wallets[wi]['availableMinor']);
      final ledger = _int(wallets[wi]['ledgerMinor']);
      wallets[wi] = {
        ...wallets[wi],
        'availableMinor': avail + receiveAmount,
        'ledgerMinor': ledger + receiveAmount,
      };
      _writeList('wallets', wallets);
    }

    final row = <String, dynamic>{
      'id': quoteId,
      'customerId': cid,
      'direction': 'INBOUND',
      'partner': 'MOCK-MTO',
      'status': 'CLEAR',
      'sendCurrency': quote?['sendCurrency'] ?? 'USD',
      'sendAmountMinor': _int(quote?['sendAmountMinor'] ?? 0),
      'receiveCurrency': receiveCurrency,
      'receiveAmountMinor': receiveAmount,
      'walletId': walletId,
      'createdAt':
          quote?['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
    };
    if (existingIdx >= 0) {
      remittances[existingIdx] = {...remittances[existingIdx], ...row};
    } else {
      remittances.add(row);
    }
    _writeList('remittances', remittances);
    return {
      ...row,
      'sendAmountMinor': _str(row['sendAmountMinor']),
      'receiveAmountMinor': _str(row['receiveAmountMinor']),
    };
  }

  Map<String, dynamic> quoteOutboundRemittance({
    required String amountMinor,
    required String currency,
  }) {
    final cid = _requireCustomer();
    final amount = _int(amountMinor);
    final fee = (amount * 0.02).round().clamp(200, 20000);
    final quoteId = _nextId('rmt');
    return {
      'quoteId': quoteId,
      'id': quoteId,
      'customerId': cid,
      'direction': 'OUTBOUND',
      'status': 'QUOTED',
      'sendCurrency': currency,
      'sendAmountMinor': _str(amount),
      'feeMinor': _str(fee),
      'totalMinor': _str(amount + fee),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  List<dynamic> listRemittances() {
    final cid = _requireCustomer();
    return _list('remittances')
        .where((r) => r['customerId'] == cid)
        .map((r) => {
              ...r,
              'sendAmountMinor': _str(r['sendAmountMinor']),
              'receiveAmountMinor': _str(r['receiveAmountMinor']),
            })
        .toList();
  }

  /// Pre-seeded remittance screening-hit row (for DEM-08 walk).
  Map<String, dynamic>? remittanceScreeningHit({String? customerId}) {
    final cid = customerId ?? _currentCustomerId;
    for (final r in _list('remittances')) {
      if (r['status'] == 'SCREENING_HIT' &&
          (cid == null || r['customerId'] == cid)) {
        return {
          ...r,
          'sendAmountMinor': _str(r['sendAmountMinor']),
          'receiveAmountMinor': _str(r['receiveAmountMinor']),
        };
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // FX
  // ---------------------------------------------------------------------------

  List<dynamic> getFxRates() {
    return _list('fxRates')
        .map((r) => {
              ...r,
              // UI expects fromCurrency/toCurrency; seed uses base/quote
              'fromCurrency': r['fromCurrency'] ?? r['base'],
              'toCurrency': r['toCurrency'] ?? r['quote'],
              'rate': r['rate'],
            })
        .toList();
  }

  Map<String, dynamic> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required String fromAmountMinor,
  }) {
    final amount = _int(fromAmountMinor);
    final rate = _fxRate(fromCurrency, toCurrency);
    final toAmount = (amount * rate).round();
    String? asOf;
    for (final r in _list('fxRates')) {
      if (r['base'] == fromCurrency && r['quote'] == toCurrency) {
        asOf = r['asOf'] as String?;
        break;
      }
    }
    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'fromAmountMinor': _str(amount),
      'toAmountMinor': _str(toAmount),
      'rate': rate,
      'asOf': asOf ?? DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Savings Goals (Poste Finance)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _savingsGoalDto(Map<String, dynamic> goal) {
    return {
      ...goal,
      'targetMinor': _str(goal['targetMinor']),
      'depositedMinor': _str(goal['depositedMinor']),
      'autoDepositMinor': _str(goal['autoDepositMinor'] ?? 0),
    };
  }

  List<dynamic> listSavingsGoals() {
    final cid = _requireCustomer();
    return _list('savingsGoals')
        .where((g) => g['customerId'] == cid)
        .map(_savingsGoalDto)
        .toList();
  }

  Map<String, dynamic> getSavingsGoal(String goalId) {
    final goal = _list('savingsGoals').firstWhere(
      (g) => g['id'] == goalId,
      orElse: () => throw Exception('Savings goal not found: $goalId'),
    );
    return _savingsGoalDto(goal);
  }

  Map<String, dynamic> createSavingsGoal({
    required String name,
    required String targetMinor,
    required String currency,
    bool autoDepositEnabled = false,
    String? autoDepositMinor,
  }) {
    final cid = _requireCustomer();
    final goalId = _nextId('goal');
    final now = DateTime.now().toUtc().toIso8601String();
    
    final goal = <String, dynamic>{
      'id': goalId,
      'customerId': cid,
      'name': name,
      'targetMinor': _int(targetMinor),
      'depositedMinor': 0,
      'currency': currency,
      'autoDepositEnabled': autoDepositEnabled,
      'autoDepositMinor': autoDepositMinor != null ? _int(autoDepositMinor) : 0,
      'createdAt': now,
    };
    
    _writeList('savingsGoals', _list('savingsGoals')..add(goal));
    return _savingsGoalDto(goal);
  }

  Map<String, dynamic> addMoneyToGoal({
    required String goalId,
    required String amountMinor,
    required String pin,
  }) {
    final cid = _requireCustomer();
    _requireKycApproved();
    final now = DateTime.now().toUtc().toIso8601String();

    if (!verifyPin(pin: pin)) {
      throw Exception('Invalid PIN');
    }

    final goals = _list('savingsGoals');
    final goalIdx = goals.indexWhere((g) => g['id'] == goalId);
    if (goalIdx < 0) {
      throw Exception('Savings goal not found: $goalId');
    }
    
    final goal = goals[goalIdx];
    if (goal['customerId'] != cid) {
      throw Exception('Unauthorized: goal belongs to another customer');
    }

    final amount = _int(amountMinor);
    final currency = goal['currency'] as String;
    final currentDeposited = _int(goal['depositedMinor']);
    final target = _int(goal['targetMinor']);
    
    // Cap amount at remaining target
    final remaining = target - currentDeposited;
    final actualAmount = amount > remaining ? remaining : amount;

    // Find and debit wallet
    final wallets = _list('wallets');
    final walletIdx = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    
    if (walletIdx < 0) {
      throw Exception('No $currency wallet found');
    }
    
    final wallet = wallets[walletIdx];
    final availableMinor = _int(wallet['availableMinor']);
    
    if (availableMinor < actualAmount) {
      throw Exception('Insufficient balance: need ${actualAmount / 100}, have ${availableMinor / 100}');
    }

    final newAvailable = availableMinor - actualAmount;
    final newLedger = _int(wallet['ledgerMinor']) - actualAmount;
    
    wallets[walletIdx] = {
      ...wallet,
      'availableMinor': newAvailable,
      'ledgerMinor': newLedger,
    };
    _writeList('wallets', wallets);

    // Credit goal
    final newDeposited = currentDeposited + actualAmount;
    goals[goalIdx] = {
      ...goal,
      'depositedMinor': newDeposited,
    };
    _writeList('savingsGoals', goals);

    // Create journal entry
    final journalId = _nextId('jnl');
    final journals = _list('journals');
    journals.add({
      'id': journalId,
      'customerId': cid,
      'walletId': wallet['id'],
      'type': 'SAVINGS_DEPOSIT',
      'direction': 'DEBIT',
      'currency': currency,
      'amountMinor': actualAmount,
      'balanceAfterMinor': newAvailable,
      'refType': 'SAVINGS_GOAL',
      'refId': goalId,
      'narration': 'Deposit to ${goal['name']}',
      'postedAt': now,
    });
    _writeList('journals', journals);

    return _savingsGoalDto(goals[goalIdx]);
  }

  Map<String, dynamic> withdrawFromGoal({
    required String goalId,
    required String amountMinor,
    required String pin,
  }) {
    final cid = _requireCustomer();
    _requireKycApproved();
    final now = DateTime.now().toUtc().toIso8601String();

    if (!verifyPin(pin: pin)) {
      throw Exception('Invalid PIN');
    }

    final goals = _list('savingsGoals');
    final goalIdx = goals.indexWhere((g) => g['id'] == goalId);
    if (goalIdx < 0) {
      throw Exception('Savings goal not found: $goalId');
    }
    
    final goal = goals[goalIdx];
    if (goal['customerId'] != cid) {
      throw Exception('Unauthorized: goal belongs to another customer');
    }

    final amount = _int(amountMinor);
    final currency = goal['currency'] as String;
    final currentDeposited = _int(goal['depositedMinor']);
    
    if (amount > currentDeposited) {
      throw Exception('Insufficient balance in goal');
    }

    final wallets = _list('wallets');
    final walletIdx = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    
    if (walletIdx < 0) {
      throw Exception('No $currency wallet found');
    }
    
    final wallet = wallets[walletIdx];
    final availableMinor = _int(wallet['availableMinor']);
    final newAvailable = availableMinor + amount;
    final newLedger = _int(wallet['ledgerMinor']) + amount;
    
    wallets[walletIdx] = {
      ...wallet,
      'availableMinor': newAvailable,
      'ledgerMinor': newLedger,
    };
    _writeList('wallets', wallets);

    final newDeposited = currentDeposited - amount;
    goals[goalIdx] = {
      ...goal,
      'depositedMinor': newDeposited,
    };
    _writeList('savingsGoals', goals);

    final journals = _list('journals');
    journals.add({
      'id': _nextId('jnl'),
      'customerId': cid,
      'walletId': wallet['id'],
      'type': 'SAVINGS_WITHDRAWAL',
      'direction': 'CREDIT',
      'currency': currency,
      'amountMinor': amount,
      'balanceAfterMinor': newAvailable,
      'refType': 'SAVINGS_GOAL',
      'refId': goalId,
      'narration': 'Withdrawal from ${goal['name']}',
      'postedAt': now,
    });
    _writeList('journals', journals);

    final notifications = _list('notifications');
    notifications.add({
      'id': _nextId('notif'),
      'customerId': cid,
      'type': 'SAVINGS_WITHDRAWAL',
      'title': 'Savings Withdrawal',
      'message': 'Withdrew ${_formatMinor(amount, currency)} from ${goal['name']}',
      'read': false,
      'createdAt': now,
    });
    _writeList('notifications', notifications);

    return _savingsGoalDto(goals[goalIdx]);
  }

  // ---------------------------------------------------------------------------
  // Term Deposits (Poste Finance MVP1 Priority 5)
  // ---------------------------------------------------------------------------

  List<dynamic> listTermDeposits() {
    final cid = _requireCustomer();
    return _list('termDeposits')
        .where((td) => td['customerId'] == cid)
        .map((td) => {
              ...td,
              'principalMinor': _str(td['principalMinor']),
              'interestEarnedMinor': _str(td['interestEarnedMinor'] ?? 0),
              'maturityAmountMinor': _str(td['maturityAmountMinor']),
            })
        .toList();
  }

  Map<String, dynamic> createTermDeposit({
    required String principalMinor,
    required String currency,
    required int tenorMonths,
    required double annualRate,
    required String renewalChoice,
  }) {
    final cid = _requireCustomer();
    final now = DateTime.now().toUtc();
    final principal = _int(principalMinor);
    
    final maturityDate = DateTime(now.year, now.month + tenorMonths, now.day);
    final interestMinor = (principal * annualRate * tenorMonths / 12).round();
    final maturityAmount = principal + interestMinor;

    final wallets = _list('wallets');
    final walletIdx = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    
    if (walletIdx < 0) {
      throw Exception('No $currency wallet found');
    }
    
    final wallet = wallets[walletIdx];
    final availableMinor = _int(wallet['availableMinor']);
    
    if (availableMinor < principal) {
      throw Exception('Insufficient balance');
    }

    final newAvailable = availableMinor - principal;
    final newLedger = _int(wallet['ledgerMinor']) - principal;
    
    wallets[walletIdx] = {
      ...wallet,
      'availableMinor': newAvailable,
      'ledgerMinor': newLedger,
    };
    _writeList('wallets', wallets);

    final termDepositId = _nextId('td');
    final termDeposit = <String, dynamic>{
      'id': termDepositId,
      'customerId': cid,
      'principalMinor': principal,
      'currency': currency,
      'tenorMonths': tenorMonths,
      'annualRate': annualRate,
      'interestEarnedMinor': 0,
      'maturityAmountMinor': maturityAmount,
      'maturityDate': maturityDate.toIso8601String(),
      'renewalChoice': renewalChoice,
      'status': 'ACTIVE',
      'createdAt': now.toIso8601String(),
    };
    
    _writeList('termDeposits', _list('termDeposits')..add(termDeposit));

    final journals = _list('journals');
    journals.add({
      'id': _nextId('jnl'),
      'customerId': cid,
      'walletId': wallet['id'],
      'type': 'TERM_DEPOSIT_OPEN',
      'direction': 'DEBIT',
      'currency': currency,
      'amountMinor': principal,
      'balanceAfterMinor': newAvailable,
      'refType': 'TERM_DEPOSIT',
      'refId': termDepositId,
      'narration': 'Term deposit opened',
      'postedAt': now.toIso8601String(),
    });
    _writeList('journals', journals);

    return {
      ...termDeposit,
      'principalMinor': _str(principal),
      'interestEarnedMinor': '0',
      'maturityAmountMinor': _str(maturityAmount),
    };
  }

  Map<String, dynamic> closeTermDepositEarly({
    required String termDepositId,
    required String pin,
  }) {
    final cid = _requireCustomer();
    final now = DateTime.now().toUtc();

    if (!verifyPin(pin: pin)) {
      throw Exception('Invalid PIN');
    }

    final termDeposits = _list('termDeposits');
    final tdIdx = termDeposits.indexWhere((td) => td['id'] == termDepositId);
    if (tdIdx < 0) {
      throw Exception('Term deposit not found');
    }
    
    final td = termDeposits[tdIdx];
    if (td['customerId'] != cid) {
      throw Exception('Unauthorized');
    }

    if (td['status'] != 'ACTIVE') {
      throw Exception('Term deposit is not active');
    }

    final principal = _int(td['principalMinor']);
    final currency = td['currency'] as String;
    final maturityDate = DateTime.parse(td['maturityDate'] as String);
    final penaltyRate = 0.02;
    final penalty = (principal * penaltyRate).round();
    final amountToReturn = principal - penalty;

    final wallets = _list('wallets');
    final walletIdx = wallets.indexWhere(
      (w) => w['customerId'] == cid && w['currency'] == currency,
    );
    
    if (walletIdx < 0) {
      throw Exception('Wallet not found');
    }
    
    final wallet = wallets[walletIdx];
    final availableMinor = _int(wallet['availableMinor']);
    final newAvailable = availableMinor + amountToReturn;
    final newLedger = _int(wallet['ledgerMinor']) + amountToReturn;
    
    wallets[walletIdx] = {
      ...wallet,
      'availableMinor': newAvailable,
      'ledgerMinor': newLedger,
    };
    _writeList('wallets', wallets);

    termDeposits[tdIdx] = {
      ...td,
      'status': 'CLOSED_EARLY',
      'closedAt': now.toIso8601String(),
      'penaltyMinor': penalty,
      'returnedMinor': amountToReturn,
    };
    _writeList('termDeposits', termDeposits);

    final journals = _list('journals');
    journals.add({
      'id': _nextId('jnl'),
      'customerId': cid,
      'walletId': wallet['id'],
      'type': 'TERM_DEPOSIT_CLOSE_EARLY',
      'direction': 'CREDIT',
      'currency': currency,
      'amountMinor': amountToReturn,
      'balanceAfterMinor': newAvailable,
      'refType': 'TERM_DEPOSIT',
      'refId': termDepositId,
      'narration': 'Term deposit closed early (2% penalty)',
      'postedAt': now.toIso8601String(),
    });
    _writeList('journals', journals);

    return {
      'success': true,
      'termDepositId': termDepositId,
      'principalMinor': _str(principal),
      'penaltyMinor': _str(penalty),
      'returnedMinor': _str(amountToReturn),
    };
  }

  // ---------------------------------------------------------------------------
  // Insurance (Poste Finance)
  // ---------------------------------------------------------------------------

  /// List insurance products (static catalog from constants)
  List<Map<String, dynamic>> listInsuranceProducts() {
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
        policies[pi] = Map<String, dynamic>.from({
          ...policies[pi],
          'premiumMode': premiumMode,
          'fixedSchedule': fixedSchedule,
          'fixedMinor': fixedMinor,
          'percentBps': percentBps,
          'deductFrom': deductFrom,
        });
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
        policies[pi] = Map<String, dynamic>.from({
          ...policies[pi],
          'active': false,
        });
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
          policies[pi] = Map<String, dynamic>.from({
            ...policies[pi],
            'lastMonthlyCollectedYm': currentYm,
          });
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
}
