import 'models.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi api;
  AuthRepository(this.api);

  Future<User> login(String email, String password) async {
    // final res = await api.login(email, password);
    // Parse and return actual user from res.data
    return User(id: 'demo', email: email);
  }

  Future<User> signup(String email, String password) async {
    // final res = await api.signup(email, password);
    return User(id: 'demo', email: email);
  }
}