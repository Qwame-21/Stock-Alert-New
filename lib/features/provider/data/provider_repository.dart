import '../../../core/network/api_client.dart';

class ConsultationProvider {
  final String id;
  final String name;
  final String specialty;
  final int yearsExperience;
  final String? bio;
  final String consultationMode;
  final String? location;
  final int durationMinutes;
  final List<DateTime> slots;
  final String? avatarUrl;
  final double videoFee;
  final double inPersonFee;
  final String currency;

  const ConsultationProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.yearsExperience,
    required this.consultationMode,
    required this.durationMinutes,
    required this.slots,
    this.bio,
    this.location,
    this.avatarUrl,
    this.videoFee = 0,
    this.inPersonFee = 0,
    this.currency = 'GHS',
  });

  factory ConsultationProvider.fromJson(Map<String, dynamic> json) {
    return ConsultationProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String?,
      consultationMode: json['consultationMode'] as String? ?? 'video',
      location: json['location'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      avatarUrl: json['avatarUrl'] as String?,
      videoFee: (json['videoFee'] as num?)?.toDouble() ?? 0,
      inPersonFee: (json['inPersonFee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'GHS',
      slots: (json['slots'] as List? ?? const [])
          .map((slot) => DateTime.parse(slot as String).toLocal())
          .toList(),
    );
  }
}

class ProviderRepository {
  final ApiClient _api;

  ProviderRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<List<ConsultationProvider>> list(DateTime date) async {
    final value =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _api.get(
      '/api/v1/consultation-providers',
      query: {'date': value},
    );
    return (response.data as List)
        .map((item) => ConsultationProvider.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _api.get('/api/v1/consultation-providers/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> saveAvailability({
    required bool accepting,
    required int duration,
    required String consultationMode,
    required double videoFee,
    required double inPersonFee,
    required List<Map<String, dynamic>> availability,
  }) async {
    await _api.put('/api/v1/consultation-providers/me', body: {
      'isAcceptingBookings': accepting,
      'consultationDuration': duration,
      'consultationMode': consultationMode,
      'videoFee': videoFee,
      'inPersonFee': inPersonFee,
      'availability': availability,
    });
  }
}
