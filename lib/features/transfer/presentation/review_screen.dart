import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/primary_button.dart';
import 'transfer_providers.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferProvider);
    final draft = state.draft;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Transfer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: ${draft?.recipientId ?? '-'}'),
            const SizedBox(height: 8),
            Text('Amount: ${draft?.amount ?? 0}'),
            const Spacer(),
            PrimaryButton(label: 'Confirm', onPressed: () async {
              await ref.read(transferProvider.notifier).confirm();
              if (context.mounted) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfirmationScreen()));
              }
            }),
          ],
        ),
      ),
    );
  }
}