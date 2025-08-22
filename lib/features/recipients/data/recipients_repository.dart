import 'models.dart';

class RecipientsRepository {
  Future<List<Recipient>> list() async {
    return const [
      Recipient(id: '1', name: 'Amina', account: 'KE001234567'),
      Recipient(id: '2', name: 'Kwame', account: 'GH123456789'),
    ];
  }
}