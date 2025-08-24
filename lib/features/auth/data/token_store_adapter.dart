// token_store_adapter.dart
import 'auth_token_store.dart';
import 'i_auth_token_store.dart';

class TokenStoreAdapter implements IAuthTokenStore {
  @override
  Future<void> saveToken(String value, {String? expiration}) {
    return AuthTokenStore.saveToken(value, expiration: expiration);
  }

  @override
  Future<void> clearToken() {
    return AuthTokenStore.clearToken();
  }

  @override
  Future<bool> hasToken() {
    return AuthTokenStore.hasToken();
  }
}
