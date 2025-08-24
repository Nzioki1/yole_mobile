abstract class IAuthTokenStore {
  Future<void> saveToken(String value, {String? expiration});
  Future<void> clearToken();
  Future<bool> hasToken();
}
