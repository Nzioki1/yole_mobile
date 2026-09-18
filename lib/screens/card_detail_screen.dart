import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';

class CardDetailScreen extends StatefulWidget {
  final String cardId;

  const CardDetailScreen({super.key, required this.cardId});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  Map<String, dynamic>? _card;
  List<dynamic> _transactions = [];
  bool _showCardNumber = false;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cardFuture = _api.getCard(widget.cardId);
      final txnsFuture = _api.getCardTransactions(widget.cardId);

      final results = await Future.wait([cardFuture, txnsFuture]);
      setState(() {
        _card = results[0] as Map<String, dynamic>;
        _transactions = results[1] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading card: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _freezeCard() async {
    try {
      await _api.freezeCard(widget.cardId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card frozen'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to freeze card: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _activateCard() async {
    try {
      await _api.activateCard(widget.cardId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card activated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate card: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Card'),
        content: const Text(
          'Blocking a card is permanent and cannot be undone. You will need to issue a new card.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block Card'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.blockCard(widget.cardId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card blocked'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block card: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateLimits() async {
    final dailyController = TextEditingController(
      text: (_card!['dailyLimitMinor'] != null
              ? (int.parse(_card!['dailyLimitMinor'].toString()) / 100)
              : 0)
          .toString(),
    );
    final monthlyController = TextEditingController(
      text: (_card!['monthlyLimitMinor'] != null
              ? (int.parse(_card!['monthlyLimitMinor'].toString()) / 100)
              : 0)
          .toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Limits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dailyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Limit',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: monthlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Limit',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final daily = double.tryParse(dailyController.text);
    final monthly = double.tryParse(monthlyController.text);

    if (daily == null || monthly == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid limits')),
      );
      return;
    }

    try {
      await _api.updateCardLimits(
        cardId: widget.cardId,
        dailyLimitMinor: (daily * 100).toInt().toString(),
        monthlyLimitMinor: (monthly * 100).toInt().toString(),
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limits updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update limits: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardDisplay(theme),
                    const SizedBox(height: 24),
                    _buildControls(theme),
                    const SizedBox(height: 24),
                    _buildLimits(theme),
                    const SizedBox(height: 24),
                    _buildTransactions(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardDisplay(ThemeData theme) {
    final status = _card?['status'] ?? 'UNKNOWN';
    final cardNumber = _card?['cardNumber']?.toString() ?? '0000000000000000';
    final cvv = _card?['cvv']?.toString() ?? '000';
    final expiryMonth = _card?['expiryMonth']?.toString() ?? '12';
    final expiryYear = _card?['expiryYear']?.toString() ?? '25';
    final currency = _card?['currency'] ?? '';

    Color bgColor = Colors.blue[700]!;
    if (status == 'FROZEN') bgColor = Colors.orange[700]!;
    if (status == 'BLOCKED') bgColor = Colors.grey[700]!;

    final maskedNumber = _showCardNumber
        ? '${cardNumber.substring(0, 4)} ${cardNumber.substring(4, 8)} ${cardNumber.substring(8, 12)} ${cardNumber.substring(12)}'
        : '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currency,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => setState(() => _showCardNumber = !_showCardNumber),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    maskedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Icon(
                  _showCardNumber ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VALID THRU',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$expiryMonth/$expiryYear',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: cvv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CVV copied')),
                      );
                    },
                    child: Text(
                      _showCardNumber ? cvv : '•••',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cardNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card number copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final status = _card?['status'] ?? 'UNKNOWN';
    final isActive = status == 'ACTIVE';
    final isFrozen = status == 'FROZEN';
    final isBlocked = status == 'BLOCKED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Controls',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (isActive)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _freezeCard,
                  icon: const Icon(Icons.ac_unit),
                  label: const Text('Freeze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (isFrozen) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _activateCard,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (!isBlocked) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _blockCard,
                  icon: const Icon(Icons.block, color: Colors.red),
                  label: const Text('Block', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (isBlocked)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This card is permanently blocked',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLimits(ThemeData theme) {
    final dailyLimit = _card?['dailyLimitMinor'] != null
        ? (int.parse(_card!['dailyLimitMinor'].toString()) / 100)
        : 0;
    final monthlyLimit = _card?['monthlyLimitMinor'] != null
        ? (int.parse(_card!['monthlyLimitMinor'].toString()) / 100)
        : 0;
    final currency = _card?['currency'] ?? '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending Limits',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _updateLimits,
                  tooltip: 'Update Limits',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '$currency ${dailyLimit.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '$currency ${monthlyLimit.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._transactions.map((txn) {
            final merchant = txn['merchant'] ?? 'Unknown';
            final amount = (int.parse(txn['amountMinor'].toString()) / 100);
            final currency = txn['currency'] ?? '';
            final status = txn['status'] ?? '';
            final createdAt = txn['createdAt'];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: status == 'APPROVED' ? Colors.green[50] : Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == 'APPROVED' ? Icons.check : Icons.close,
                    color: status == 'APPROVED' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(merchant),
                subtitle: Text(
                  createdAt != null ? _formatDate(createdAt) : 'Unknown date',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        color: status == 'APPROVED' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
