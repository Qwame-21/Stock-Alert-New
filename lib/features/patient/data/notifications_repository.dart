import '../../../core/network/api_client.dart';

class PatientNotification {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime? scheduledAt;
  final String? actionPath;

  const PatientNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.scheduledAt,
    this.actionPath,
  });

  factory PatientNotification.fromJson(Map<String, dynamic> json) {
    return PatientNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'Updates',
      title: json['title'] as String? ?? 'Notification',
      description: json['description'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] as String? ?? '')?.toLocal(),
      actionPath: json['actionPath'] as String?,
    );
  }
}

class NotificationsRepository {
  final ApiClient _api;

  NotificationsRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<List<PatientNotification>> load() async {
    final response = await _api.get('/api/v1/notifications');
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['notifications'] as List? ?? const [])
        .map((item) => PatientNotification.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
