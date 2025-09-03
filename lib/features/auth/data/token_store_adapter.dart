// token_store_adapter.dart
import 'auth_token_store.dart';
import 'i_auth_token_store.dart';

class TokenStoreAdapter implements IAuthTokenStore {
  @override
  Future<void> saveToken(
    String value, {
    String? refreshToken,
    String? expiration,
  }) {
    return AuthTokenStore.saveToken(
      value,
      refreshToken: refreshToken,
      expiration: expiration,
    );
  }

  @override
  Future<String?> getToken() {
    return AuthTokenStore.getToken();
  }

  @override
  Future<String?> getRefreshToken() {
    return AuthTokenStore.getRefreshToken();
  }

  @override
  Future<String?> getTokenExpiration() {
    return AuthTokenStore.getTokenExpiration();
  }

  @override
  Future<void> clearToken() {
    return AuthTokenStore.clearToken();
  }

  @override
  Future<bool> hasToken() {
    return AuthTokenStore.hasToken();
  }

  @override
  Future<bool> isTokenExpired() {
    return AuthTokenStore.isTokenExpired();
  }
}
