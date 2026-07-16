import 'dart:io';

/// Platform-specific Google Maps API key resolution.
///
/// Keys are injected at build time via --dart-define flags:
///   --dart-define=MAPS_API_KEY_ANDROID=<key>
///   --dart-define=MAPS_API_KEY_IOS=<key>
///
/// If a key is absent (empty string), [hasKey] returns false and the
/// locator screen falls back to the mock/painted map layer automatically.
class MapsConfig {
  MapsConfig._();

  static const String _androidKey =
      String.fromEnvironment('MAPS_API_KEY_ANDROID', defaultValue: '');

  static const String _iosKey =
      String.fromEnvironment('MAPS_API_KEY_IOS', defaultValue: '');

  /// Returns the correct key for the current platform.
  static String get apiKey {
    if (Platform.isAndroid) return _androidKey;
    if (Platform.isIOS) return _iosKey;
    return '';
  }

  /// True when a non-empty key is available for the current platform.
  static bool get hasKey => apiKey.isNotEmpty;
}
