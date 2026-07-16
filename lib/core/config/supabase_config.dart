// ── Supabase Configuration ────────────────────────────────────────────────────
//
// Values are injected at compile-time via --dart-define flags.
// NEVER hardcode the URL or keys here.
//
// Required build flags:
//   --dart-define=SUPABASE_URL=https://...
//   --dart-define=SUPABASE_ANON_KEY=eyJ...

abstract final class SupabaseConfig {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    assert(_url.isNotEmpty, 'SUPABASE_URL is not set. Pass --dart-define=SUPABASE_URL=...');
    return _url;
  }

  static String get anonKey {
    assert(_anonKey.isNotEmpty, 'SUPABASE_ANON_KEY is not set. Pass --dart-define=SUPABASE_ANON_KEY=...');
    return _anonKey;
  }

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;
}
