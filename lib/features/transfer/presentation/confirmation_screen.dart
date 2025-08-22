import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transfer_providers.dart';

class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Done')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            const SizedBox(height: 12),
            Text('Confirmation: ${state.confirmationId ?? '-'}'),
          ],
        ),
      ),
    );
  }
}