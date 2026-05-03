import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  StorageService() : _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Secure Storage (Refresh Token) ---
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // --- Shared Preferences (Access Token) ---
  static const String _accessTokenKey = 'access_token';

  Future<void> saveAccessToken(String token) async {
    if (_prefs == null) await init();
    await _prefs!.setString(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    if (_prefs == null) await init();
    return _prefs!.getString(_accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_accessTokenKey);
  }

  Future<void> clearAll() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }
}
