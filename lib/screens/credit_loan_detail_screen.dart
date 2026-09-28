import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';

class CreditLoanDetailScreen extends StatefulWidget {
  final String loanId;

  const CreditLoanDetailScreen({super.key, required this.loanId});

  @override
  State<CreditLoanDetailScreen> createState() => _CreditLoanDetailScreenState();
}

class _CreditLoanDetailScreenState extends State<CreditLoanDetailScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  Map<String, dynamic>? _loan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadLoan();
  }

  Future<void> _loadLoan() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.getLoan(widget.loanId);
      setState(() => _loan = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLoan,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load loan',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadLoan,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLoan,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusBanner(theme),
                              const SizedBox(height: 24),
                              _buildAmountCard(theme),
                              const SizedBox(height: 16),
                              _buildDetailsCard(theme),
                              const SizedBox(height: 16),
                              _buildTimelineCard(theme),
                              if (_loan?['repaymentSchedule'] != null) ...[
                                const SizedBox(height: 16),
                                _buildScheduleCard(theme),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_canRepay()) _buildRepayButton(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    final status = _loan?['status'] ?? 'UNKNOWN';
    Color bgColor = Colors.grey[100]!;
    Color textColor = Colors.grey[800]!;
    IconData icon = Icons.info_outline;

    switch (status) {
      case 'ACTIVE':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_outline;
        break;
      case 'PENDING':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        icon = Icons.pending_outlined;
        break;
      case 'REPAID':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[800]!;
        icon = Icons.done_all;
        break;
      case 'DEFAULTED':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        icon = Icons.warning_amber_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $status',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusMessage(status),
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(ThemeData theme) {
    final principal = _loan?['principalMinor'];
    final currency = _loan?['currency'] ?? 'USD';
    final type = _loan?['type'] ?? '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatType(type),
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '$currency ${(int.parse(principal.toString()) / 100).toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Loan Principal',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
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
                  'Loan Information',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.loanId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loan ID copied')),
                    );
                  },
                  tooltip: 'Copy Loan ID',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Loan ID',
              value: widget.loanId,
              mono: true,
            ),
            _DetailRow(
              label: 'Customer ID',
              value: _loan?['customerId'] ?? 'N/A',
              mono: true,
            ),
            _DetailRow(
              label: 'Term',
              value: '${_loan?['termMonths'] ?? 'N/A'} months',
            ),
            _DetailRow(
              label: 'Interest Rate',
              value: '${_loan?['interestRateBps'] != null ? (_loan!['interestRateBps'] / 100).toStringAsFixed(2) : 'N/A'}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(ThemeData theme) {
    final requestedAt = _loan?['requestedAt'];
    final disbursedAt = _loan?['disbursedAt'];
    final dueAt = _loan?['dueAt'];
    final repaidAt = _loan?['repaidAt'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (requestedAt != null)
              _TimelineItem(
                icon: Icons.request_page,
                label: 'Requested',
                date: requestedAt,
                isCompleted: true,
              ),
            if (disbursedAt != null)
              _TimelineItem(
                icon: Icons.payments,
                label: 'Disbursed',
                date: disbursedAt,
                isCompleted: true,
              ),
            if (dueAt != null)
              _TimelineItem(
                icon: Icons.event,
                label: 'Due Date',
                date: dueAt,
                isCompleted: repaidAt != null,
                isFuture: repaidAt == null,
              ),
            if (repaidAt != null)
              _TimelineItem(
                icon: Icons.check_circle,
                label: 'Repaid',
                date: repaidAt,
                isCompleted: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ThemeData theme) {
    final schedule = _loan?['repaymentSchedule'] as List?;
    if (schedule == null || schedule.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repayment Schedule',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...schedule.map((installment) {
              final isPaid = installment['paidAt'] != null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isPaid ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Installment ${installment['installmentNumber']}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Due: ${_formatDate(installment['dueAt'])}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${installment['currency']} ${(int.parse(installment['amountMinor'].toString()) / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Your loan is active and in good standing';
      case 'PENDING':
        return 'Your loan application is being processed';
      case 'REPAID':
        return 'This loan has been fully repaid';
      case 'DEFAULTED':
        return 'This loan is past due. Please contact support.';
      default:
        return 'Loan status unknown';
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _canRepay() {
    final status = _loan?['status'];
    final receivable = int.tryParse(_loan?['receivableMinor']?.toString() ?? '0') ?? 0;
    return status == 'ACTIVE' && receivable > 0;
  }

  Widget _buildRepayButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showRepayDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
            ),
            child: const Text(
              'Make Repayment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRepayDialog() async {
    final receivable = int.tryParse(_loan?['receivableMinor']?.toString() ?? '0') ?? 0;
    final currency = _loan?['currency'] ?? 'USD';
    
    final amountController = TextEditingController(
      text: (receivable / 100).toStringAsFixed(0),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Repayment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outstanding Balance: ${_formatCurrency(receivable, currency)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount ($currency)',
                hintText: 'Enter amount to pay',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final amountStr = amountController.text.trim();
      if (amountStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount')),
        );
        amountController.dispose();
        return;
      }

      final amount = double.tryParse(amountStr);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        amountController.dispose();
        return;
      }

      final amountMinor = (amount * 100).toInt();
      if (amountMinor > receivable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount exceeds outstanding balance')),
        );
        amountController.dispose();
        return;
      }

      try {
        setState(() => _loading = true);
        await _api.repayLoan(
          loanId: widget.loanId,
          amountMinor: amountMinor.toString(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Repayment successful')),
          );
          await _loadLoan();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Repayment failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }

    amountController.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String date;
  final bool isCompleted;
  final bool isFuture;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.date,
    this.isCompleted = false,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? Colors.green : (isFuture ? Colors.orange : Colors.grey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 0 && diff.inDays > -7) return 'In ${-diff.inDays} days';
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
