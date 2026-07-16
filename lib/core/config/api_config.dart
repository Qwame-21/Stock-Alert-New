import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiConfig {
  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final value = _definedBaseUrl.isNotEmpty
        ? _definedBaseUrl
        : dotenv.env['API_BASE_URL'] ?? _developmentBaseUrl;
    return value.replaceAll(RegExp(r'/$'), '');
  }

  static String get _developmentBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulators expose the host machine's loopback at 10.0.2.2.
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  static bool get remoteInventoryEnabled =>
      _flag('REMOTE_INVENTORY_ENABLED', defaultValue: true);

  static bool get remoteBookingsEnabled =>
      _flag('REMOTE_BOOKINGS_ENABLED', defaultValue: true);

  static bool get backgroundSyncEnabled =>
      _flag('BACKGROUND_SYNC_ENABLED', defaultValue: true);

  static bool _flag(String name, {required bool defaultValue}) {
    final value = dotenv.env[name];
    if (value == null || value.isEmpty) return defaultValue;
    return value.toLowerCase() == 'true';
  }
}
