class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String? avatarUrl;
  final String? videoLink;
  final String? notes;
  final int version;
  final String status;
  final String? providerId;

  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    this.avatarUrl,
    this.videoLink,
    this.notes,
    this.version = 1,
    this.status = 'pending',
    this.providerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'date': date,
      'time': time,
      'avatarUrl': avatarUrl,
      'videoLink': videoLink,
      'notes': notes,
      'version': version,
      'status': status,
      'providerId': providerId,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      specialty: json['specialty'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      videoLink: json['videoLink'] as String?,
      notes: json['notes'] as String?,
      version: json['version'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
      providerId: json['providerId'] as String?,
    );
  }

  factory Appointment.fromApi(Map<String, dynamic> json) {
    final scheduled = DateTime.parse(json['scheduled_at'] as String).toLocal();
    final hour = scheduled.hour == 0
        ? 12
        : scheduled.hour > 12
            ? scheduled.hour - 12
            : scheduled.hour;
    final minute = scheduled.minute.toString().padLeft(2, '0');
    return Appointment(
      id: json['id'] as String,
      doctorName: json['provider_name'] as String,
      specialty: json['specialty'] as String? ?? '',
      date: '${scheduled.day}/${scheduled.month}/${scheduled.year}',
      time: '$hour:$minute ${scheduled.hour >= 12 ? 'PM' : 'AM'}',
      videoLink: json['video_link'] as String?,
      notes: json['notes'] as String?,
      version: json['version'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
