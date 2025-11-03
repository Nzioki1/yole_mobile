import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/status_chip.dart';
import '../l10n/app_localizations.dart';

StatusChipVariant mapStatus(TransactionStatus s) {
  switch (s) {
    case TransactionStatus.success:
      return StatusChipVariant.success;
    case TransactionStatus.processing:
    case TransactionStatus.pending:
      return StatusChipVariant.info;
    case TransactionStatus.failed:
      return StatusChipVariant.error;
    case TransactionStatus.cancelled:
      return StatusChipVariant.warning;
    case TransactionStatus.delivered:
      return StatusChipVariant.success;
  }
}

String statusText(TransactionStatus s, AppLocalizations l10n) {
  switch (s) {
    case TransactionStatus.success:
      return l10n.completed;
    case TransactionStatus.processing:
      return l10n.processing;
    case TransactionStatus.pending:
      return l10n.pending;
    case TransactionStatus.failed:
      return l10n.failed;
    case TransactionStatus.cancelled:
      return l10n.cancelled;
    case TransactionStatus.delivered:
      return l10n.delivered;
  }
}

class TransactionsHistorySimple extends ConsumerStatefulWidget {
  const TransactionsHistorySimple({super.key});

  @override
  ConsumerState<TransactionsHistorySimple> createState() =>
      _TransactionsHistorySimpleState();
}

class _TransactionsHistorySimpleState
    extends ConsumerState<TransactionsHistorySimple> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await ref
        .read(transactionsListProvider.notifier)
        .loadTransactions(refresh: true);
  }

  TransactionStatus _mapApiStatusToTransactionStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'completed':
      case 'success':
        return TransactionStatus.success;
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'delivered':
        return TransactionStatus.delivered;
      default:
        return TransactionStatus.pending;
    }
  }

  Widget _buildLoadingState(ThemeData theme, AppState appState) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, AppState appState, String error) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
      ThemeData theme,
      AppState appState,
      AppLocalizations l10n,
      List<TransactionModel> transactions,
      TransactionsState transactionsState) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, appState, l10n),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyState(theme, appState, l10n)
                  : _buildTransactionsListView(
                      theme, appState, l10n, transactions, transactionsState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsListView(
      ThemeData theme,
      AppState appState,
      AppLocalizations l10n,
      List<TransactionModel> transactions,
      TransactionsState transactionsState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionTile(theme, appState, l10n, transaction);
      },
    );
  }

  Widget _buildTransactionTile(ThemeData theme, AppState appState,
      AppLocalizations l10n, TransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2B2F58)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(transaction.recipientName ?? 'Unknown'),
          const SizedBox(width: 12),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.recipientName ?? 'Unknown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.recipientPhone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Amount and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.currency == 'USD' ? '\$' : '€'}${transaction.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              StatusChip(
                text: _getStatusText(transaction.status),
                variant: mapStatus(transaction.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
      case TransactionStatus.delivered:
        return 'Completed';
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  StatusChipVariant mapStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
      case TransactionStatus.delivered:
        return StatusChipVariant.success;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return StatusChipVariant.warning;
      case TransactionStatus.failed:
        return StatusChipVariant.error;
      case TransactionStatus.cancelled:
        return StatusChipVariant.neutral;
    }
  }

  Widget _buildAvatar(String name) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((word) => word[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);
    final transactionsState = ref.watch(transactionsListProvider);
    final l10n = AppLocalizations.of(context)!;

    // Convert API transactions to UI model or use fallback
    final List<TransactionModel> transactions;

    if (transactionsState.isLoading && transactionsState.transactions.isEmpty) {
      // Show loading state
      return _buildLoadingState(theme, appState);
    } else if (transactionsState.error != null &&
        transactionsState.transactions.isEmpty) {
      // Show error state with fallback data
      return _buildErrorState(theme, appState, transactionsState.error!);
    } else {
      // Use API data or fallback to mock data
      if (transactionsState.transactions.isNotEmpty) {
        transactions = transactionsState.transactions.map((apiTransaction) {
          return TransactionModel(
            id: apiTransaction.id,
            recipientName: apiTransaction.recipientName ?? 'Unknown',
            counterpart: apiTransaction.recipientPhone,
            amount: apiTransaction.amount,
            currency: apiTransaction.currency,
            status: _mapApiStatusToTransactionStatus(apiTransaction.status),
            date: apiTransaction.createdAt,
          );
        }).toList();
      } else {
        // Fallback to mock data
        transactions = _getMockTransactions();
      }
    }

    return _buildTransactionsList(
        theme, appState, l10n, transactions, transactionsState);
  }

  Widget _buildHeader(
      ThemeData theme, AppState appState, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              l10n.allTransactions,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, AppState appState, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _getMockTransactions() {
    return [
      TransactionModel(
        id: 'tx_001',
        recipientName: 'Marie Koffi',
        counterpart: '+243123456789',
        amount: 100.0,
        currency: 'USD',
        status: TransactionStatus.delivered,
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        id: 'tx_002',
        recipientName: 'Jean Mukendi',
        counterpart: '+243987654321',
        amount: 75.0,
        currency: 'EUR',
        status: TransactionStatus.processing,
        date: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      TransactionModel(
        id: 'tx_003',
        recipientName: 'Grace Mbuyi',
        counterpart: '+243456789123',
        amount: 200.0,
        currency: 'USD',
        status: TransactionStatus.delivered,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'tx_004',
        recipientName: 'Pierre Kasongo',
        counterpart: '+243789123456',
        amount: 50.0,
        currency: 'EUR',
        status: TransactionStatus.failed,
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
