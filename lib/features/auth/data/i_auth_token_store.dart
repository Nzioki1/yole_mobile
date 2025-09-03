abstract class IAuthTokenStore {
  Future<void> saveToken(
    String value, {
    String? refreshToken,
    String? expiration,
  });
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<String?> getTokenExpiration();
  Future<void> clearToken();
  Future<bool> hasToken();
  Future<bool> isTokenExpired();
}
