import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // Create storage
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  /// Save tokens
  static Future<void> saveTokens({required String accessToken,required String refreshToken,}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(
      key: _keyAccessToken,
      value: accessToken,
    );
  }

  /// Read tokens
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Delete tokens (logout)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  /// Check if user is logged in
  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
