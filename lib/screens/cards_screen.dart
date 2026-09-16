import 'package:flutter/material.dart';
import '../services/core_api_service.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _api = CoreApiService();
  bool _loading = false;
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Cards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('No cards yet. Issue a card from wallet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Card(
                      color: card['status'] == 'ACTIVE' ? Colors.blue[50] : Colors.grey[200],
                      child: ListTile(
                        leading: const Icon(Icons.credit_card),
                        title: Text('Card •••• ${card['cardNumber'].toString().substring(card['cardNumber'].toString().length - 4)}'),
                        subtitle: Text('${card['currency']} • ${card['status']}'),
                        trailing: Text('Limit: ${card['dailyLimitMinor']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
