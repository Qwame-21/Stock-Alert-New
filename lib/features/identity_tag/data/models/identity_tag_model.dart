import '../../../../core/sync/sync_status.dart';

enum VerificationStatus { pending, verified, rejected }

/// Patient identity tag. The QR stores a random token, not personal details.
class IdentityTagModel {
  final String id;
  final String patientId;
  final String qrToken;
  final VerificationStatus verificationStatus;
  final DateTime memberSince;
  final SyncStatus syncStatus;

  const IdentityTagModel({
    required this.id,
    required this.patientId,
    required this.qrToken,
    required this.verificationStatus,
    required this.memberSince,
    this.syncStatus = SyncStatus.pending,
  });

  factory IdentityTagModel.fromMap(Map<String, dynamic> map) {
    return IdentityTagModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      qrToken: map['qr_token'] as String,
      verificationStatus: VerificationStatus.values.firstWhere(
        (s) => s.name == map['verification_status'],
        orElse: () => VerificationStatus.pending,
      ),
      memberSince: DateTime.parse(map['member_since'] as String),
      syncStatus: SyncStatusStorage.fromDbValue(
        map['sync_status'] as String? ?? 'pending',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'qr_token': qrToken,
      'verification_status': verificationStatus.name,
      'member_since': memberSince.toIso8601String(),
      'sync_status': syncStatus.asDbValue,
    };
  }

  IdentityTagModel copyWith({
    VerificationStatus? verificationStatus,
    SyncStatus? syncStatus,
  }) {
    return IdentityTagModel(
      id: id,
      patientId: patientId,
      qrToken: qrToken,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      memberSince: memberSince,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
