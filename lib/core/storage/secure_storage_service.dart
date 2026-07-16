import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Anything that is a credential, a key, or a sensitive setting goes through
/// here — never into sqflite. Wraps Keychain on iOS and Keystore on Android.
///
/// NOTE: Auth tokens are no longer managed here — Supabase handles session
/// persistence internally via its own secure storage. This class is retained
/// for any future app-specific secrets (e.g. biometric PIN, local encryption keys).
class SecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _webMemCache = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      _webMemCache[key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (kIsWeb) return _webMemCache[key];
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      _webMemCache.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      _webMemCache.clear();
      return;
    }
    await _storage.deleteAll();
  }
}
