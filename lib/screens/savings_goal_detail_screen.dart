import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';
import '../widgets/pin_confirm_sheet.dart';

class SavingsGoalDetailScreen extends StatefulWidget {
  final String goalId;

  const SavingsGoalDetailScreen({
    super.key,
    required this.goalId,
  });

  @override
  State<SavingsGoalDetailScreen> createState() =>
      _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  Map<String, dynamic>? _goal;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    setState(() => _loading = true);
    try {
      final goal = await _api.getSavingsGoal(widget.goalId);
      setState(() => _goal = goal);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goal: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddMoneyDialog() async {
    if (_goal == null) return;

    final targetMinor = int.tryParse(_goal!['targetMinor']?.toString() ?? '0') ?? 0;
    final depositedMinor = int.tryParse(_goal!['depositedMinor']?.toString() ?? '0') ?? 0;
    final remainingMinor = (targetMinor - depositedMinor).clamp(0, targetMinor);
    final remaining = remainingMinor / 100;

    final amountController = TextEditingController(
      text: remaining.toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add Money',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter amount to deposit to ${_goal!['name']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Remaining: ${remaining.toStringAsFixed(2)} ${_goal!['currency']}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              autofocus: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _confirmAddMoney(amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACAC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAddMoney(double amount) async {
    final pin = await PinConfirmSheet.show(
      context,
      title: 'Confirm Deposit',
      message: 'Enter your PIN to add ${amount.toStringAsFixed(2)} ${_goal!['currency']} to ${_goal!['name']}',
    );

    if (pin == null || pin.isEmpty) {
      return;
    }

    final amountMinor = (amount * 100).toInt();

    setState(() => _loading = true);

    try {
      final updatedGoal = await _api.addMoneyToGoal(
        goalId: widget.goalId,
        amountMinor: amountMinor.toString(),
        pin: pin,
      );

      setState(() {
        _goal = updatedGoal;
        _loading = false;
      });

      if (mounted) {
        final depositedMinor = int.tryParse(updatedGoal['depositedMinor']?.toString() ?? '0') ?? 0;
        final targetMinor = int.tryParse(updatedGoal['targetMinor']?.toString() ?? '0') ?? 0;
        final isComplete = depositedMinor >= targetMinor;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isComplete
                  ? '🎉 Goal achieved! You\'ve reached your target!'
                  : 'Successfully added ${amount.toStringAsFixed(2)} ${_goal!['currency']}',
            ),
            backgroundColor: isComplete ? Colors.green : const Color(0xFF00ACAC),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add money: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: Text('Goal not found')),
      );
    }

    final name = _goal!['name'] as String? ?? 'Untitled Goal';
    final currency = _goal!['currency'] as String? ?? 'USD';
    final targetMinor = int.tryParse(_goal!['targetMinor']?.toString() ?? '0') ?? 0;
    final depositedMinor = int.tryParse(_goal!['depositedMinor']?.toString() ?? '0') ?? 0;
    final autoDepositEnabled = _goal!['autoDepositEnabled'] == true;
    final autoDepositMinor = int.tryParse(_goal!['autoDepositMinor']?.toString() ?? '0') ?? 0;

    final target = targetMinor / 100;
    final deposited = depositedMinor / 100;
    final autoDeposit = autoDepositMinor / 100;
    final progress = targetMinor > 0 ? (depositedMinor / targetMinor).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();
    final isComplete = depositedMinor >= targetMinor;

    final currencySymbol = currency == 'CDF' ? 'FC' : '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ACAC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                          color: Color(0xFF00ACAC),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency,
                          style: const TextStyle(
                            color: Color(0xFF00ACAC),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00ACAC),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$percentage%',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00ACAC),
                                  ),
                                ),
                                if (isComplete)
                                  const Text(
                                    '🎉',
                                    style: TextStyle(fontSize: 32),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '$currencySymbol ${deposited.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'of $currencySymbol ${target.toStringAsFixed(2)} target',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isComplete) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Goal Achieved!',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (autoDepositEnabled) ...[
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.autorenew,
                              color: Color(0xFF00ACAC),
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-Deposit Enabled',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$currencySymbol ${autoDeposit.toStringAsFixed(2)}/month',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isComplete ? null : _showAddMoneyDialog,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        'Add Money',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00ACAC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Congratulations! You\'ve reached your savings goal.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
