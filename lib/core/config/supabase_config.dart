import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Supabase Configuration ────────────────────────────────────────────────────
//
// Values come from .env or these build flags:
//   --dart-define=SUPABASE_URL=https://...
//   --dart-define=SUPABASE_ANON_KEY=eyJ...
abstract final class SupabaseConfig {
  static const String _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _definedAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get _url =>
      _definedUrl.isNotEmpty ? _definedUrl : dotenv.env['SUPABASE_URL'] ?? '';

  static String get _anonKey => _definedAnonKey.isNotEmpty
      ? _definedAnonKey
      : dotenv.env['SUPABASE_ANON_KEY'] ??
          dotenv.env['SUPABASE_ANNON_KEY'] ??
          '';

  static String get url {
    assert(_url.isNotEmpty,
        'SUPABASE_URL is not set. Pass --dart-define=SUPABASE_URL=...');
    return _url;
  }

  static String get anonKey {
    assert(_anonKey.isNotEmpty,
        'SUPABASE_ANON_KEY is not set. Pass --dart-define=SUPABASE_ANON_KEY=...');
    return _anonKey;
  }

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;
}
