class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String? avatarUrl;
  final String? videoLink;
  final String? notes;

  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    this.avatarUrl,
    this.videoLink,
    this.notes,
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
    );
  }
}
