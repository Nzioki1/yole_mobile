import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/services/offline_demo_repository.dart';

void main() {
  test("walletsFor('cust_kasee') length 2", () {
    final repo = OfflineDemoRepository.createFresh(
      universePath: 'packages/demo_universe/data/universe.json',
    );
    expect(repo.walletsFor('cust_kasee'), hasLength(2));
  });
}
