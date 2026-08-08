import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  final FlutterSecureStorage _storage;
  Storage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateWithBackup: true),
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          );

  static const _kAccessToken = 'ACCESS_TOKEN';
  static const _kRefreshToken = 'REFRESH_TOKEN';
  static const _kExpiresAt = 'EXPIRES_AT';
  static const _kIsLoggedIn = 'IS_LOGGED_IN';
  static const _kRole = 'ROLE';
  static const _kLocale = 'LOCALE';
  static const _kFcmToken = 'FCM_TOKEN';

  Future<void> writeTokens({required String accessToken, required String refreshToken, required int expiresInSeconds}) async {
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(Duration(seconds: expiresInSeconds)).millisecondsSinceEpoch.toString();
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kExpiresAt, value: expiresAt),
    ]);
  }

  Future<String?> get readAccessToken => _storage.read(key: _kAccessToken);
  Future<String?> get readRefreshToken => _storage.read(key: _kRefreshToken);

  Future<DateTime?> readExpiresAt() async {
    final s = await _storage.read(key: _kExpiresAt);
    if (s == null) return null;
    final ms = int.tryParse(s);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> setIsLoggedIn(String value) async {
    await _storage.write(key: _kIsLoggedIn, value: value);
  }

  Future<bool?> get readIsLoggedIn => _storage
      .read(key: _kIsLoggedIn)
      .then(
        (value) => value == 'true'
            ? true
            : value == 'false'
            ? false
            : null,
      );

  Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.write(key: _kIsLoggedIn, value: 'false');
    await _storage.delete(key: _kRole);
    await _storage.delete(key: _kExpiresAt);
  }

  Future<void> writeRole(String value) async {
    await _storage.write(key: _kRole, value: value);
  }

  Future<String?> readRole() async {
    return await _storage.read(key: _kRole);
  }

  Future<void> writeLocale(String value) async {
    await _storage.write(key: _kLocale, value: value);
  }

  Future<String?> readLocale() async {
    return await _storage.read(key: _kLocale);
  }

  Future<void> writeFcmToken(String value) async {
    await _storage.write(key: _kFcmToken, value: value);
  }

  Future<String?> readFcmToken() async {
    return await _storage.read(key: _kFcmToken);
  }
}
