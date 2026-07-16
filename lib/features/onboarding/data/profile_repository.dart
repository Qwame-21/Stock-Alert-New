import '../../../core/network/api_client.dart';

class ProfileRepository {
  final ApiClient _api;

  ProfileRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _api.get('/api/v1/auth/me');
    final data = Map<String, dynamic>.from(response.data as Map);
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
    return {...profile, 'email': user['email']};
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
