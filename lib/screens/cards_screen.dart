import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';
import '../router_types.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  List<dynamic> _cards = [];

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    try {
      final cards = await _api.listCards();
      setState(() => _cards = cards);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _navigateToIssueCard() {
    Navigator.of(context).pushNamed(RouteNames.cardIssue).then((_) => _loadCards());
  }

  void _navigateToCardDetail(String cardId) {
    Navigator.of(context).pushNamed(
      RouteNames.cardDetail,
      arguments: {'cardId': cardId},
    ).then((_) => _loadCards());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadCards,
                    child: _cards.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              final card = _cards[index];
                              return _CardTile(
                                card: card,
                                onTap: () => _navigateToCardDetail(card['id']),
                                theme: theme,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToIssueCard,
        icon: const Icon(Icons.add_card),
        label: const Text('Issue Card'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Virtual Cards',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Issue a virtual card linked to your wallet\nfor secure online payments',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToIssueCard,
              icon: const Icon(Icons.add_card),
              label: const Text('Issue Your First Card'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onTap;
  final ThemeData theme;

  const _CardTile({
    required this.card,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final status = card['status'] ?? 'UNKNOWN';
    final cardNumber = card['cardNumber']?.toString() ?? '0000';
    final last4 = cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber;
    final currency = card['currency'] ?? '';
    final cardholderName = card['cardholderName']?.toString() ?? 'Cardholder';
    final network = card['mockNetwork']?.toString() ?? 'VISA';

    Color statusColor = Colors.grey;
    Color cardColor = Colors.grey[200]!;
    if (status == 'ACTIVE') {
      statusColor = Colors.green;
      cardColor = Colors.blue[50]!;
    } else if (status == 'FROZEN') {
      statusColor = Colors.orange;
      cardColor = Colors.orange[50]!;
    } else if (status == 'BLOCKED') {
      statusColor = Colors.red;
      cardColor = Colors.red[50]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.credit_card, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardholderName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '•••• •••• •••• $last4',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          network,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
