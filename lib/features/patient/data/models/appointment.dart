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
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final DateTime? respondedAt;
  final String? decisionNote;
  final String? consultationMode;
  final String? clinicalReason;
  final String? patientCondition;
  final String? requestedSupport;
  final double? consultationFee;
  final double? depositAmount;
  final String paymentStatus;
  final String? cancellationCategory;

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
    this.requestedAt,
    this.reviewedAt,
    this.respondedAt,
    this.decisionNote,
    this.consultationMode,
    this.clinicalReason,
    this.patientCondition,
    this.requestedSupport,
    this.consultationFee,
    this.depositAmount,
    this.paymentStatus = 'unpaid',
    this.cancellationCategory,
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
      'requestedAt': requestedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'decisionNote': decisionNote,
      'consultationMode': consultationMode,
      'clinicalReason': clinicalReason,
      'patientCondition': patientCondition,
      'requestedSupport': requestedSupport,
      'consultationFee': consultationFee,
      'depositAmount': depositAmount,
      'paymentStatus': paymentStatus,
      'cancellationCategory': cancellationCategory,
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
      requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      respondedAt: DateTime.tryParse(json['respondedAt'] as String? ?? ''),
      decisionNote: json['decisionNote'] as String?,
      consultationMode: json['consultationMode'] as String?,
      clinicalReason: json['clinicalReason'] as String?,
      patientCondition: json['patientCondition'] as String?,
      requestedSupport: json['requestedSupport'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      cancellationCategory: json['cancellationCategory'] as String?,
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
      providerId: json['provider_profile_id'] as String?,
      requestedAt:
          DateTime.tryParse(json['requested_at'] as String? ?? '')?.toLocal(),
      reviewedAt:
          DateTime.tryParse(json['reviewed_at'] as String? ?? '')?.toLocal(),
      respondedAt:
          DateTime.tryParse(json['responded_at'] as String? ?? '')?.toLocal(),
      decisionNote: json['decision_note'] as String?,
      consultationMode: json['consultation_mode'] as String?,
      clinicalReason: json['clinical_reason'] as String?,
      patientCondition: json['patient_condition'] as String?,
      requestedSupport: json['requested_support'] as String?,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
      depositAmount: (json['deposit_amount'] as num?)?.toDouble(),
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      cancellationCategory: json['cancellation_category'] as String?,
    );
  }
}
