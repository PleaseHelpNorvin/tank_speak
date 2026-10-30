import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the backend `UserToken` bearer token in secure storage
/// (Android Keystore / iOS Keychain / Windows Credential Manager / encrypted
/// browser storage on web).
///
/// Earlier versions of the app kept the token in plain SharedPreferences
/// under `token`; it is moved to secure storage once and then removed.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'tankspeak_api_token';
  static const String _legacyKey = 'token';

  final FlutterSecureStorage _storage;
  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;

    String? token;
    try {
      token = await _storage.read(key: _key);
    } catch (_) {
      token = null;
    }

    if (token == null || token.isEmpty) {
      token = await _migrateLegacyToken();
    }

    _cached = (token == null || token.isEmpty) ? null : token;
    _loaded = true;
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing more can be done; the in-memory copy is already gone.
    }
    await _removeLegacyToken();
  }

  Future<String?> _migrateLegacyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyKey);
      if (legacy == null || legacy.isEmpty) return null;
      await _storage.write(key: _key, value: legacy);
      await prefs.remove(_legacyKey);
      return legacy;
    } catch (_) {
      return null;
    }
  }

  Future<void> _removeLegacyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);
    } catch (_) {}
  }
}
