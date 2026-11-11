import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the access token in memory only and the refresh token in the
/// Android Keystore / iOS Keychain, as the backend security guide requires.
class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  static const String _refreshTokenKey = 'icetrack.refresh_token';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<bool> hasRefreshToken() async => (await readRefreshToken())?.isNotEmpty ?? false;

  /// Saves both tokens together. Every refresh returns a NEW refresh token
  /// (the previous one is spent), so it must always replace the stored one.
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _secure.delete(key: _refreshTokenKey);
  }
}
