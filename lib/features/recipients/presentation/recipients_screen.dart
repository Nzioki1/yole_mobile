import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recipients_providers.dart';

class RecipientsScreen extends ConsumerWidget {
  const RecipientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(recipientsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recipients')),
      body: asyncList.when(
        data: (items) => ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            title: Text(items[i].name),
            subtitle: Text(items[i].account),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}