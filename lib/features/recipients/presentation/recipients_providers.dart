import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipients_repository.dart';
import '../data/models.dart';

final recipientsProvider = FutureProvider<List<Recipient>>((ref) async {
  final repo = RecipientsRepository();
  return repo.list();
});