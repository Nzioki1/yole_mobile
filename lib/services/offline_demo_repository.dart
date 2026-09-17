
import 'package:demo_universe/demo_universe.dart';

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
  static OfflineDemoRepository createFresh({) {
    final repo = OfflineDemoRepository._(
      DemoUniverse.load(),
    );
    _instance = repo;
    return repo;
  }

  /// Discard session mutations and reload seed into [instance].
  static void reset({) {
    createFresh();
  }

  /// DEM-01 OTP — always accepted offline.
  static const String demoOtp = '123456';

  /// DEM-07 honesty string (also shown on CardsScreen).
  static const String cardsMockBanner =
      'MOCK — not Visa/Mastercard certified';

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
      final debit = amount + fee;
      balanceAfter = avail - debit;
      wallets[wi] = {
        ...wallets[wi],
        'availableMinor': balanceAfter,
        'ledgerMinor': ledger - debit,
      };
      _writeList('wallets', wallets);
    }

    final journalId = _nextId('jnl');
    final journals = _list('journals');
    journals.add({
      'id': journalId,
      'customerId': cid,
      'walletId': walletId,
      'type': 'PAYMENT',
      'direction': 'DEBIT',
      'currency': currency,
      'amountMinor': amount,
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

      if (employee != null && salaryRows.isNotEmpty) {
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
    final loanId = _nextId('loan');
    final now = DateTime.now().toUtc().toIso8601String();
    final principal = _int(principalMinor);
    final loan = <String, dynamic>{
      'id': loanId,
      'customerId': cid,
      'employerId': eligibility['employerId'],
      'productId': type.toUpperCase().contains('SALARY')
          ? 'prod_salary_advance'
          : 'prod_micro_loan',
      'status': 'ACTIVE',
      'principalMinor': principal,
      'currency': currency,
      'termMonths': termMonths,
      'scheduleId': _nextId('sched'),
      'receivableMinor': principal,
      'disbursedAt': now,
      'createdAt': now,
    };
    _writeList('loans', _list('loans')..add(loan));

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
    return {
      ...l,
      'principalMinor': _str(l['principalMinor']),
      'receivableMinor': _str(l['receivableMinor']),
    };
  }

  // ---------------------------------------------------------------------------
  // Cards (DEM-07)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _cardDto(Map<String, dynamic> c) {
    final last4 = (c['last4'] ?? '0000').toString();
    return {
      ...c,
      'last4': last4,
      'cardNumber': c['cardNumber'] ?? '************$last4',
      'dailyLimitMinor': _str(c['dailyLimitMinor']),
      'monthlyLimitMinor': _str(c['monthlyLimitMinor']),
      'mockNetwork': c['mockNetwork'] ?? 'MOCK',
      'honestyBanner': cardsMockBanner,
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
      'mockNetwork': 'MOCK',
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

  List<dynamic> getFxRates() => _list('fxRates');

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
}
