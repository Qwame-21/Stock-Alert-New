import '../../../core/network/api_client.dart';

class PatientIdentityCardData {
  const PatientIdentityCardData({
    required this.patientId,
    required this.qrToken,
    required this.sharingEnabled,
    required this.shareFullName,
    required this.shareDateOfBirth,
    required this.shareEmergencyContact,
  });

  final String patientId;
  final String qrToken;
  final bool sharingEnabled;
  final bool shareFullName;
  final bool shareDateOfBirth;
  final bool shareEmergencyContact;

  factory PatientIdentityCardData.fromJson(Map<String, dynamic> json) =>
      PatientIdentityCardData(
        patientId: json['public_id'] as String,
        qrToken: json['qr_token'] as String,
        sharingEnabled: json['sharing_enabled'] as bool? ?? true,
        shareFullName: json['share_full_name'] as bool? ?? true,
        shareDateOfBirth: json['share_date_of_birth'] as bool? ?? false,
        shareEmergencyContact:
            json['share_emergency_contact'] as bool? ?? false,
      );
}

class IdentityCardRepository {
  Future<PatientIdentityCardData> getMine() async {
    final response = await ApiClient.instance.get('/api/v1/identity/me');
    return PatientIdentityCardData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PatientIdentityCardData> updatePrivacy({
    bool? sharingEnabled,
    bool? shareFullName,
    bool? shareDateOfBirth,
    bool? shareEmergencyContact,
    bool rotateToken = false,
  }) async {
    final response = await ApiClient.instance.patch(
      '/api/v1/identity/me',
      body: {
        if (sharingEnabled != null) 'sharingEnabled': sharingEnabled,
        if (shareFullName != null) 'shareFullName': shareFullName,
        if (shareDateOfBirth != null) 'shareDateOfBirth': shareDateOfBirth,
        if (shareEmergencyContact != null)
          'shareEmergencyContact': shareEmergencyContact,
        if (rotateToken) 'rotateToken': true,
      },
    );
    return PatientIdentityCardData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> resolve(String token) async {
    final response = await ApiClient.instance.post(
      '/api/v1/identity/resolve',
      body: {'token': token},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
