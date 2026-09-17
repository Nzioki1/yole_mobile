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
  // Enroll
  // ---------------------------------------------------------------------------

  Map<String, dynamic> enrollCustomer({
    required String firstName,
    required String lastName,
    required String password,
    String? phoneE164,
    String? email,
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

    return {
      'customerId': id,
      'walletId': cdfWalletId,
      'wallets': [cdfWalletId, usdWalletId],
      'status': 'ACTIVE',
      'kycStatus': 'PENDING',
    };
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
      if (floatBal < amount) {
        throw Exception('Cash-in failed: insufficient agent float');
      }
      floatBal -= amount;
      custAvail += amount;
      custLedger += amount;
    } else {
      if (custAvail < amount) {
        throw Exception('Cash-out failed: insufficient customer balance');
      }
      custAvail -= amount;
      custLedger -= amount;
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
      'type': cashIn ? 'AGENT_CASH_IN' : 'AGENT_CASH_OUT',
    };
  }
}
