import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Platform-specific Google Maps API key resolution.
///
/// Keys are injected at build time via --dart-define flags:
///   --dart-define=MAPS_API_KEY_ANDROID=<key>
///   --dart-define=MAPS_API_KEY_IOS=<key>
///
/// If a key is absent (empty string), [hasKey] returns false and the
/// locator screen displays a configuration message.
class MapsConfig {
  MapsConfig._();

  static const String _definedAndroidKey =
      String.fromEnvironment('MAPS_API_KEY_ANDROID');

  static const String _definedIosKey =
      String.fromEnvironment('MAPS_API_KEY_IOS');

  static String get _androidKey => _definedAndroidKey.isNotEmpty
      ? _definedAndroidKey
      : dotenv.env['MAPS_API_KEY_ANDROID'] ?? '';

  static String get _iosKey => _definedIosKey.isNotEmpty
      ? _definedIosKey
      : dotenv.env['MAPS_API_KEY_IOS'] ?? '';

  /// Returns the correct key for the current platform.
  static String get apiKey {
    if (Platform.isAndroid) return _androidKey;
    if (Platform.isIOS) return _iosKey;
    return '';
  }

  /// True when a non-empty key is available for the current platform.
  static bool get hasKey => apiKey.isNotEmpty;

  static const String androidPackageName = String.fromEnvironment(
    'ANDROID_PACKAGE_NAME',
    defaultValue: 'com.example.stock_a_app',
  );
  static const String androidCertificateSha1 = String.fromEnvironment(
    'ANDROID_CERT_SHA1',
    defaultValue: 'E048C45F329978E1F12DCE3BAD964300553D377B',
  );
}
