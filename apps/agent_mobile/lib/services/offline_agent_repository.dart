import 'package:demo_universe/demo_universe.dart';

/// Agent offline demo repository (float / enroll / cash-in/out).
///
/// Backed by shared [DemoUniverse] seed via embedded [DemoUniverse.load]
/// (no dart:io). Session mutations stay in-memory; [createFresh]/[reset]
/// reload the seed. Wired from AgentApiService when
/// `--dart-define=OFFLINE_DEMO=true`.
class OfflineAgentRepository {
  OfflineAgentRepository._(this._universe);

  final DemoUniverse _universe;
  String? _currentAgentId;
  int _seq = 0;

  static OfflineAgentRepository? _instance;

  /// Shared session instance used by AgentApiService offline gates.
  static OfflineAgentRepository get instance =>
      _instance ??= createFresh();

  /// Load a fresh deep-cloned universe (also replaces [instance]).
  /// Optional [json] overrides the embedded seed (tests only).
  static OfflineAgentRepository createFresh({String? json}) {
    final repo = OfflineAgentRepository._(DemoUniverse.load(json: json));
    _instance = repo;
    return repo;
  }

  /// Discard session mutations and reload seed into [instance].
  static void reset({String? json}) {
    createFresh(json: json);
  }

  String? get currentAgentId => _currentAgentId;

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

  String _requireAgent() {
    final aid = _currentAgentId;
    if (aid == null || aid.isEmpty) {
      throw Exception('Not logged in');
    }
    return aid;
  }

  Map<String, dynamic>? _findAgent(String agentId) {
    for (final a in _list('agents')) {
      if (a['id'] == agentId) return a;
    }
    return null;
  }

  Map<String, dynamic>? _findCustomer(String customerId) {
    for (final c in _list('customers')) {
      if (c['id'] == customerId) return c;
    }
    return null;
  }

  Map<String, dynamic>? _findCustomerByPhone(String phoneE164) {
    for (final c in _list('customers')) {
      if (c['phoneE164'] == phoneE164) return c;
    }
    return null;
  }

  /// Find customer by phone (E.164) or customer ID.
  /// Throws if not found.
  Map<String, dynamic> findCustomerByPhoneOrId(String phoneOrId) {
    final query = phoneOrId.trim();
    Map<String, dynamic>? customer;

    if (query.startsWith('+')) {
      customer = _findCustomerByPhone(query);
    } else {
      customer = _findCustomer(query);
    }

    if (customer == null) {
      throw Exception('Customer not found. Enroll first?');
    }

    return Map<String, dynamic>.from(customer);
  }

  /// Find customer by ID (public helper for history screen).
  /// Returns null if not found.
  Map<String, dynamic>? findCustomerById(String customerId) {
    return _findCustomer(customerId);
  }

  /// Get all wallets for a customer (public helper for history screen).
  List<Map<String, dynamic>> getCustomerWallets(String customerId) {
    return _list('wallets')
        .where((w) => w['customerId'] == customerId)
        .map((w) => Map<String, dynamic>.from(w))
        .toList();
  }

  /// Get all KYCs (public helper for history screen).
  List<Map<String, dynamic>> getAllKycs() {
    return _list('kycs');
  }

  Map<String, dynamic>? _findWallet({
    required String customerId,
    required String currency,
  }) {
    for (final w in _list('wallets')) {
      if (w['customerId'] == customerId && w['currency'] == currency) {
        return w;
      }
    }
    return null;
  }

  void _saveAgent(Map<String, dynamic> agent) {
    final agents = _list('agents');
    final idx = agents.indexWhere((a) => a['id'] == agent['id']);
    if (idx >= 0) {
      agents[idx] = agent;
    } else {
      agents.add(agent);
    }
    _writeList('agents', agents);
  }

  void _saveWallet(Map<String, dynamic> wallet) {
    final wallets = _list('wallets');
    final idx = wallets.indexWhere((w) => w['id'] == wallet['id']);
    if (idx >= 0) {
      wallets[idx] = wallet;
    } else {
      wallets.add(wallet);
    }
    _writeList('wallets', wallets);
  }

  // ---------------------------------------------------------------------------
  // Auth / agent lookup
  // ---------------------------------------------------------------------------

  /// Login by agent id (matches AgentLoginScreen: verify then setAgentId).
  Map<String, dynamic> login({required String agentId}) {
    final agent = getAgentInfo(agentId);
    _currentAgentId = agentId;
    return agent;
  }

  /// Find agent by email (helper for email-based login routing).
  Map<String, dynamic>? _findAgentByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final a in _list('agents')) {
      final agentEmail = a['email'] as String?;
      if (agentEmail?.toLowerCase() == normalized) {
        return a;
      }
    }
    return null;
  }

  /// Login by email and password (Phase 2).
  /// Throws specific exceptions for routing/error handling:
  /// - 'CUSTOMER_EMAIL' if email is not agent domain
  /// - 'Invalid password' if password mismatch
  /// - 'Agent not found' if email unknown
  Map<String, dynamic> loginByEmail({
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    
    // Check if email matches agent domain pattern
    if (!normalized.endsWith('@postefinance-agents.cd')) {
      // Customer email or other domain
      throw Exception('CUSTOMER_EMAIL');
    }

    // Find agent by email
    final agent = _findAgentByEmail(email);
    if (agent == null) {
      throw Exception('Agent not found');
    }

    // Validate password
    final storedPassword = agent['password'] as String?;
    if (storedPassword != password) {
      throw Exception('Invalid password');
    }

    // Success: set session and return agent info
    _currentAgentId = agent['id'] as String;
    return Map<String, dynamic>.from(agent);
  }

  void setAgentId(String agentId) {
    if (_findAgent(agentId) == null) {
      throw Exception('Get agent info failed: agent not found');
    }
    _currentAgentId = agentId;
  }

  void clearSession() {
    _currentAgentId = null;
  }

  /// Agent row as returned to AgentApiService.getAgentInfo.
  Map<String, dynamic> getAgentInfo(String agentId) {
    final agent = _findAgent(agentId);
    if (agent == null) {
      throw Exception('Get agent info failed: agent not found');
    }
    return Map<String, dynamic>.from(agent);
  }

  /// Brief-mandated helper — seed float CDF/USD for agent-001.
  Map<String, dynamic> floatFor(String agentId) {
    final agent = getAgentInfo(agentId);
    return {
      'agentId': agentId,
      'floatCdfMinor': _int(agent['floatCdfMinor']),
      'floatUsdMinor': _int(agent['floatUsdMinor']),
      'floatWalletId': agent['floatWalletId'],
    };
  }

  /// Wallet-shaped float balances with CDF + USD pockets (home screen).
  Map<String, dynamic> getFloatBalances({String? agentId}) {
    final aid = agentId ?? _requireAgent();
    final agent = getAgentInfo(aid);
    final floatWalletId =
        agent['floatWalletId'] as String? ?? 'wallet_float_$aid';
    final cdf = _int(agent['floatCdfMinor']);
    final usd = _int(agent['floatUsdMinor']);
    return {
      'id': floatWalletId,
      'agentId': aid,
      'pockets': [
        {
          'id': '${floatWalletId}_cdf',
          'currency': 'CDF',
          'availableMinor': _str(cdf),
          'ledgerMinor': _str(cdf),
          'blockedMinor': '0',
          'pendingOutMinor': '0',
          'pendingInMinor': '0',
        },
        {
          'id': '${floatWalletId}_usd',
          'currency': 'USD',
          'availableMinor': _str(usd),
          'ledgerMinor': _str(usd),
          'blockedMinor': '0',
          'pendingOutMinor': '0',
          'pendingInMinor': '0',
        },
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // Fee calculation
  // ---------------------------------------------------------------------------

  /// Get transaction fee from feeLimits seed.
  /// Returns fee in minor units.
  Map<String, dynamic> getFee({
    required String paymentType,
    required String currency,
    required int amountMinor,
  }) {
    final limits = _list('feeLimits');
    Map<String, dynamic>? feeLimit;

    for (final limit in limits) {
      if (limit['kind'] == 'FEE' &&
          limit['paymentType'] == paymentType &&
          limit['currency'] == currency &&
          limit['status'] == 'ACTIVE') {
        feeLimit = limit;
        break;
      }
    }

    if (feeLimit == null) {
      return {'feeMinor': 0};
    }

    final feePercent = (feeLimit['feePercent'] as num?)?.toDouble() ?? 0.0;
    final minFeeMinor = _int(feeLimit['minFeeMinor']);
    final maxFeeMinor = _int(feeLimit['maxFeeMinor']);

    var calculatedFee = (amountMinor * feePercent / 100).toInt();
    if (calculatedFee < minFeeMinor) calculatedFee = minFeeMinor;
    if (calculatedFee > maxFeeMinor) calculatedFee = maxFeeMinor;

    return {
      'feeMinor': calculatedFee,
      'feePercent': feePercent,
      'minFeeMinor': minFeeMinor,
      'maxFeeMinor': maxFeeMinor,
    };
  }

  /// Get customer wallet for currency.
  Map<String, dynamic> getWallet({
    required String customerId,
    required String currency,
  }) {
    final wallet = _findWallet(customerId: customerId, currency: currency);
    if (wallet == null) {
      throw Exception('Wallet not found for customer $customerId, $currency');
    }
    return Map<String, dynamic>.from(wallet);
  }

  // ---------------------------------------------------------------------------
  // Daily limits
  // ---------------------------------------------------------------------------

  /// Get today's usage for the current agent.
  /// Returns total amounts and transaction counts for today.
  Map<String, dynamic> getTodayUsage({String? agentId}) {
    final aid = agentId ?? _requireAgent();
    final today = DateTime.now().toUtc();
    final todayStr = today.toIso8601String().split('T').first;

    final journals = _list('journals');
    int totalCdfMinor = 0;
    int totalUsdMinor = 0;
    int cashInCount = 0;
    int cashOutCount = 0;

    for (final j in journals) {
      if (j['agentId'] != aid) continue;

      final postedAt = j['postedAt'] as String?;
      if (postedAt == null) continue;

      final postedDate = postedAt.split('T').first;
      if (postedDate != todayStr) continue;

      final type = j['type'] as String?;
      final currency = j['currency'] as String?;
      final amountMinor = _int(j['amountMinor']);

      if (type == 'AGENT_CASH_IN') {
        cashInCount++;
        if (currency == 'CDF') totalCdfMinor += amountMinor;
        if (currency == 'USD') totalUsdMinor += amountMinor;
      } else if (type == 'AGENT_CASH_OUT') {
        cashOutCount++;
        if (currency == 'CDF') totalCdfMinor += amountMinor;
        if (currency == 'USD') totalUsdMinor += amountMinor;
      }
    }

    final agent = getAgentInfo(aid);
    return {
      'totalCdfMinor': totalCdfMinor,
      'totalUsdMinor': totalUsdMinor,
      'cashInCount': cashInCount,
      'cashOutCount': cashOutCount,
      'dailyLimitCdfMinor': _int(agent['dailyLimitCdfMinor']),
      'dailyLimitUsdMinor': _int(agent['dailyLimitUsdMinor']),
      'perTxnLimitCdfMinor': _int(agent['perTxnLimitCdfMinor']),
      'perTxnLimitUsdMinor': _int(agent['perTxnLimitUsdMinor']),
    };
  }

  /// Check if transaction is within agent limits.
  Map<String, dynamic> isWithinLimits({
    required int amountMinor,
    required String currency,
  }) {
    final usage = getTodayUsage();
    final dailyLimit = currency == 'CDF'
        ? _int(usage['dailyLimitCdfMinor'])
        : _int(usage['dailyLimitUsdMinor']);
    final perTxnLimit = currency == 'CDF'
        ? _int(usage['perTxnLimitCdfMinor'])
        : _int(usage['perTxnLimitUsdMinor']);
    final todayTotal = currency == 'CDF'
        ? _int(usage['totalCdfMinor'])
        : _int(usage['totalUsdMinor']);

    if (amountMinor > perTxnLimit) {
      final symbol = currency == 'CDF' ? 'FC' : '\$';
      final limit = perTxnLimit / 100;
      return {
        'withinLimits': false,
        'reason': 'Per-transaction limit exceeded. Max: $symbol${limit.toStringAsFixed(2)}',
      };
    }

    if (todayTotal + amountMinor > dailyLimit) {
      final symbol = currency == 'CDF' ? 'FC' : '\$';
      final remaining = (dailyLimit - todayTotal) / 100;
      return {
        'withinLimits': false,
        'reason': 'Daily limit exceeded. Remaining: $symbol${remaining.toStringAsFixed(2)}',
      };
    }

    return {'withinLimits': true};
  }

  // ---------------------------------------------------------------------------
  // Enroll
  // ---------------------------------------------------------------------------

  Map<String, dynamic> enrollCustomer({
    required String firstName,
    required String lastName,
    required String password,
    String? phoneE164,
    String? email,
    String? idNumber,
    String? idType,
  }) {
    _requireAgent();
    if (email != null && email.isNotEmpty) {
      final normalized = email.trim().toLowerCase();
      for (final c in _list('customers')) {
        if ((c['email'] as String?)?.toLowerCase() == normalized) {
          throw Exception('Enroll customer failed: email already registered');
        }
      }
    }

    final id = _nextId('cust');
    final now = DateTime.now().toUtc().toIso8601String();
    
    // Determine KYC status: PENDING_REVIEW if ID provided, otherwise PENDING
    final hasIdInfo = idNumber != null && idNumber.isNotEmpty && idType != null;
    final kycStatus = hasIdInfo ? 'PENDING_REVIEW' : 'PENDING';
    
    final customer = <String, dynamic>{
      'id': id,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phoneE164': phoneE164,
      'segment': 'OPEN',
      'status': 'ACTIVE',
      'kycStatus': kycStatus,
      'enrolledByAgentId': _currentAgentId,
      'createdAt': now,
    };
    _writeList('customers', _list('customers')..add(customer));

    final wallets = _list('wallets');
    final cdfWalletId = 'wal_${id}_cdf';
    final usdWalletId = 'wal_${id}_usd';
    wallets.add({
      'id': cdfWalletId,
      'customerId': id,
      'currency': 'CDF',
      'availableMinor': 0,
      'ledgerMinor': 0,
      'blockedMinor': 0,
      'pendingMinor': 0,
    });
    wallets.add({
      'id': usdWalletId,
      'customerId': id,
      'currency': 'USD',
      'availableMinor': 0,
      'ledgerMinor': 0,
      'blockedMinor': 0,
      'pendingMinor': 0,
    });
    _writeList('wallets', wallets);

    // Create KYC record if ID information provided
    if (hasIdInfo) {
      final kycId = _nextId('kyc');
      final kycs = _list('kycs');
      kycs.add({
        'id': kycId,
        'customerId': id,
        'idNumber': idNumber,
        'idType': idType,
        'status': 'PENDING_REVIEW',
        'submittedAt': now,
      });
      _writeList('kycs', kycs);
    }

    return {
      'customerId': id,
      'walletId': cdfWalletId,
      'wallets': [cdfWalletId, usdWalletId],
      'status': 'ACTIVE',
      'kycStatus': kycStatus,
    };
  }

  // ---------------------------------------------------------------------------
  // History queries
  // ---------------------------------------------------------------------------

  /// Get today's cash operation history for the current agent.
  /// Returns journals sorted by postedAt descending.
  List<Map<String, dynamic>> getTodayHistory({String? agentId}) {
    final aid = agentId ?? _requireAgent();
    final today = DateTime.now().toUtc();
    final todayStr = today.toIso8601String().split('T').first;

    final journals = _list('journals');
    final todayJournals = <Map<String, dynamic>>[];

    for (final j in journals) {
      if (j['agentId'] != aid) continue;

      final postedAt = j['postedAt'] as String?;
      if (postedAt == null) continue;

      final postedDate = postedAt.split('T').first;
      if (postedDate != todayStr) continue;

      todayJournals.add(Map<String, dynamic>.from(j));
    }

    // Sort by postedAt descending
    todayJournals.sort((a, b) {
      final aTime = DateTime.parse(a['postedAt'] as String);
      final bTime = DateTime.parse(b['postedAt'] as String);
      return bTime.compareTo(aTime);
    });

    return todayJournals;
  }

  /// Get today's customer enrollments by the current agent.
  /// Returns customers sorted by createdAt descending.
  List<Map<String, dynamic>> getTodayEnrollments({String? agentId}) {
    final aid = agentId ?? _requireAgent();
    final today = DateTime.now().toUtc();
    final todayStr = today.toIso8601String().split('T').first;

    final customers = _list('customers');
    final todayEnrollments = <Map<String, dynamic>>[];

    for (final c in customers) {
      if (c['enrolledByAgentId'] != aid) continue;

      final createdAt = c['createdAt'] as String?;
      if (createdAt == null) continue;

      final createdDate = createdAt.split('T').first;
      if (createdDate != todayStr) continue;

      todayEnrollments.add(Map<String, dynamic>.from(c));
    }

    // Sort by createdAt descending
    todayEnrollments.sort((a, b) {
      final aTime = DateTime.parse(a['createdAt'] as String);
      final bTime = DateTime.parse(b['createdAt'] as String);
      return bTime.compareTo(aTime);
    });

    return todayEnrollments;
  }

  // ---------------------------------------------------------------------------
  // Cash-in / cash-out (session-local)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> cashIn({
    required String customerId,
    required String amountMinor,
    required String currency,
  }) {
    return _moveCash(
      customerId: customerId,
      amountMinor: amountMinor,
      currency: currency,
      cashIn: true,
    );
  }

  Map<String, dynamic> cashOut({
    required String customerId,
    required String amountMinor,
    required String currency,
  }) {
    return _moveCash(
      customerId: customerId,
      amountMinor: amountMinor,
      currency: currency,
      cashIn: false,
    );
  }

  Map<String, dynamic> _moveCash({
    required String customerId,
    required String amountMinor,
    required String currency,
    required bool cashIn,
  }) {
    final aid = _requireAgent();
    final amount = _int(amountMinor);
    if (amount <= 0) {
      throw Exception(
        '${cashIn ? 'Cash-in' : 'Cash-out'} failed: amount must be > 0',
      );
    }
    final cur = currency.toUpperCase();
    if (cur != 'CDF' && cur != 'USD') {
      throw Exception(
        '${cashIn ? 'Cash-in' : 'Cash-out'} failed: unsupported currency',
      );
    }

    if (_findCustomer(customerId) == null) {
      throw Exception(
        '${cashIn ? 'Cash-in' : 'Cash-out'} failed: customer not found',
      );
    }

    // Calculate fee
    final paymentType = cashIn ? 'AGENT_CASH_IN' : 'AGENT_CASH_OUT';
    final feeResult = getFee(
      paymentType: paymentType,
      currency: cur,
      amountMinor: amount,
    );
    final feeMinor = _int(feeResult['feeMinor']);

    final agent = Map<String, dynamic>.from(getAgentInfo(aid));
    final floatKey = cur == 'CDF' ? 'floatCdfMinor' : 'floatUsdMinor';
    var floatBal = _int(agent[floatKey]);

    var wallet = _findWallet(customerId: customerId, currency: cur);
    if (wallet == null) {
      throw Exception(
        '${cashIn ? 'Cash-in' : 'Cash-out'} failed: wallet not found',
      );
    }
    wallet = Map<String, dynamic>.from(wallet);
    var custAvail = _int(wallet['availableMinor']);
    var custLedger = _int(wallet['ledgerMinor']);

    if (cashIn) {
      // Cash-in: agent gives amount, customer receives full amount (no fee deduction)
      if (floatBal < amount) {
        throw Exception('Cash-in failed: insufficient agent float');
      }
      floatBal -= amount;
      custAvail += amount;
      custLedger += amount;
    } else {
      // Cash-out: customer debited amount + fee, agent receives amount only
      final totalDebit = amount + feeMinor;
      if (custAvail < totalDebit) {
        throw Exception('Cash-out failed: insufficient customer balance');
      }
      custAvail -= totalDebit;
      custLedger -= totalDebit;
      floatBal += amount;
    }

    agent[floatKey] = floatBal;
    _saveAgent(agent);

    wallet['availableMinor'] = custAvail;
    wallet['ledgerMinor'] = custLedger;
    _saveWallet(wallet);

    final journalId = _nextId(cashIn ? 'jnl_cashin' : 'jnl_cashout');
    final txnId = _nextId(cashIn ? 'atx_cashin' : 'atx_cashout');
    final now = DateTime.now().toUtc().toIso8601String();
    final journals = _list('journals');
    journals.add({
      'id': journalId,
      'customerId': customerId,
      'walletId': wallet['id'],
      'agentId': aid,
      'type': cashIn ? 'AGENT_CASH_IN' : 'AGENT_CASH_OUT',
      'direction': cashIn ? 'CREDIT' : 'DEBIT',
      'currency': cur,
      'amountMinor': amount,
      'feeMinor': feeMinor,
      'balanceAfterMinor': custLedger,
      'refType': 'AGENT_TXN',
      'refId': txnId,
      'narration':
          'Agent ${cashIn ? 'cash-in' : 'cash-out'} via $aid (session)',
      'postedAt': now,
    });
    _writeList('journals', journals);

    return {
      'journalId': journalId,
      'status': 'POSTED',
      'customerId': customerId,
      'agentId': aid,
      'currency': cur,
      'amountMinor': _str(amount),
      'feeMinor': _str(feeMinor),
      'type': cashIn ? 'AGENT_CASH_IN' : 'AGENT_CASH_OUT',
      'balanceAfterMinor': custLedger,
    };
  }
}
