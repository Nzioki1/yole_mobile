import 'models.dart';

class TransferRepository {
  Future<String> create(TransferDraft draft) async {
    // TODO: integrate API
    return 'TX-${DateTime.now().millisecondsSinceEpoch}';
  }
}