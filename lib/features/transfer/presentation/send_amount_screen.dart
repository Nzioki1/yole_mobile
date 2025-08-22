import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/models.dart';
import 'transfer_providers.dart';

class SendAmountScreen extends ConsumerStatefulWidget {
  const SendAmountScreen({super.key});

  @override
  ConsumerState<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends ConsumerState<SendAmountScreen> {
  final _recipient = TextEditingController();
  final _amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _recipient, decoration: const InputDecoration(labelText: 'Recipient ID')),
            const SizedBox(height: 12),
            TextField(controller: _amount, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Review', onPressed: () {
              final draft = TransferDraft(recipientId: _recipient.text, amount: num.tryParse(_amount.text) ?? 0);
              ref.read(transferProvider.notifier).setDraft(draft);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewScreen()));
            }),
          ],
        ),
      ),
    );
  }
}