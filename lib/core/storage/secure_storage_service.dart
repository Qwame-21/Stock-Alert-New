import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive app values in Keychain or Android Keystore.
/// Supabase manages its own auth tokens separately.
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
