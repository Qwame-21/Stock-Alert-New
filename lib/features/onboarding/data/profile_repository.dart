import '../../../core/network/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final ApiClient _api;

  ProfileRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _api.get('/api/v1/auth/me');
      final data = Map<String, dynamic>.from(response.data as Map);
      final user = Map<String, dynamic>.from(data['user'] as Map);
      final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
      return {...profile, 'email': user['email']};
    } catch (_) {
      // Supabase authentication can be healthy while a local/mobile backend is
      // temporarily unreachable. Profiles are protected by RLS, so reading the
      // signed-in user's own row is a safe fallback that prevents a successful
      // login from being incorrectly treated as bad credentials.
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) rethrow;

      final profile = await client
          .from('profiles')
          .select(
              'role, full_name, email, phone_number, dob, gender, pharmacy_name, license_number, location')
          .eq('id', user.id)
          .maybeSingle();
      if (profile == null) rethrow;

      String? pharmacyId;
      if (profile['role'] == 'pharmacy') {
        final pharmacy = await client
            .from('pharmacies')
            .select('id')
            .eq('owner_profile_id', user.id)
            .maybeSingle();
        pharmacyId = pharmacy?['id'] as String?;
        if (pharmacyId == null) {
          final membership = await client
              .from('pharmacy_staff')
              .select('pharmacy_id')
              .eq('profile_id', user.id)
              .maybeSingle();
          pharmacyId = membership?['pharmacy_id'] as String?;
        }
      }

      return {
        ...profile,
        'email': user.email ?? profile['email'],
        'pharmacy_id': pharmacyId,
      };
    }
  }

  Future<Map<String, dynamic>> update(
    Map<String, dynamic> fields,
  ) async {
    final response = await _api.patch('/api/v1/profile', body: fields);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> fields,
  ) async {
    final response = await _api.post(
      '/api/v1/auth/register',
      body: fields,
      authenticated: false,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
