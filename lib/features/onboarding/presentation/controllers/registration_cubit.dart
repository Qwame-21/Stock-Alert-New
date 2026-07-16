import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../data/profile_repository.dart';

// ── Registration Submit Status ─────────────────────────────────────────────────

enum RegistrationSubmitStatus { idle, loading, success, error }

class RegistrationState {
  final String role;
  // Patient Fields
  final String fullName;
  final String dob;
  final String gender;
  final String phoneNumber;
  final String email;

  // Password is held in memory only during the registration session.
  // It is NEVER written to toJson() or any local database.
  final String password;

  // Pharmacy Fields
  final String pharmacyName;
  final String pharmacyId;
  final String licenseNumber;
  final String registrationAuthority;
  final String location;
  final String operatingHours;
  final String supplierPreference;

  // Step 2 Verification Document
  final String
      docType; // 'National ID', 'Passport', 'Driver\'s License' / 'Pharmacy License'
  final String? attachedFilePath;

  // Step 3 Health Profile (Patient only)
  final String bloodGroup;
  final List<String> knownAllergies;
  final List<String> chronicConditions;
  final String currentMedication;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactEmail;

  // Supabase submission state
  final RegistrationSubmitStatus submitStatus;
  final String? submitError;

  RegistrationState({
    this.role = '',
    this.fullName = '',
    this.dob = '',
    this.gender = '',
    this.phoneNumber = '',
    this.email = '',
    this.password = '',
    this.pharmacyName = '',
    this.pharmacyId = '',
    this.licenseNumber = '',
    this.registrationAuthority = '',
    this.location = '',
    this.operatingHours = '',
    this.supplierPreference = '',
    this.docType = 'National ID',
    this.attachedFilePath,
    this.bloodGroup = 'A+',
    this.knownAllergies = const [],
    this.chronicConditions = const [],
    this.currentMedication = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactEmail = '',
    this.submitStatus = RegistrationSubmitStatus.idle,
    this.submitError,
  });

  RegistrationState copyWith({
    String? role,
    String? fullName,
    String? dob,
    String? gender,
    String? phoneNumber,
    String? email,
    String? password,
    String? pharmacyName,
    String? pharmacyId,
    String? licenseNumber,
    String? registrationAuthority,
    String? location,
    String? operatingHours,
    String? supplierPreference,
    String? docType,
    String? attachedFilePath,
    bool clearAttachedFilePath = false,
    String? bloodGroup,
    List<String>? knownAllergies,
    List<String>? chronicConditions,
    String? currentMedication,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactEmail,
    RegistrationSubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return RegistrationState(
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      password: password ?? this.password,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      registrationAuthority:
          registrationAuthority ?? this.registrationAuthority,
      location: location ?? this.location,
      operatingHours: operatingHours ?? this.operatingHours,
      supplierPreference: supplierPreference ?? this.supplierPreference,
      docType: docType ?? this.docType,
      attachedFilePath: clearAttachedFilePath
          ? null
          : (attachedFilePath ?? this.attachedFilePath),
      bloodGroup: bloodGroup ?? this.bloodGroup,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedication: currentMedication ?? this.currentMedication,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactEmail:
          emergencyContactEmail ?? this.emergencyContactEmail,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'fullName': fullName,
      'dob': dob,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'email': email,
      'hasAccount': true,
      'pharmacyName': pharmacyName,
      'pharmacyId': pharmacyId,
      'licenseNumber': licenseNumber,
      'registrationAuthority': registrationAuthority,
      'location': location,
      'operatingHours': operatingHours,
      'supplierPreference': supplierPreference,
      'docType': docType,
      'attachedFilePath': attachedFilePath,
      'bloodGroup': bloodGroup,
      'knownAllergies': knownAllergies,
      'chronicConditions': chronicConditions,
      'currentMedication': currentMedication,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactEmail': emergencyContactEmail,
    };
  }

  factory RegistrationState.fromJson(Map<String, dynamic> json) {
    return RegistrationState(
      role: json['role'] ?? '',
      fullName: json['fullName'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      // password intentionally NOT loaded from JSON
      pharmacyName: json['pharmacyName'] ?? '',
      pharmacyId: json['pharmacyId'] ?? json['pharmacy_id'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      registrationAuthority: json['registrationAuthority'] ?? '',
      location: json['location'] ?? '',
      operatingHours: json['operatingHours'] ?? '',
      supplierPreference: json['supplierPreference'] ?? '',
      docType: json['docType'] ?? 'National ID',
      attachedFilePath: json['attachedFilePath'],
      bloodGroup: json['bloodGroup'] ?? 'A+',
      knownAllergies: List<String>.from(json['knownAllergies'] ?? []),
      chronicConditions: List<String>.from(json['chronicConditions'] ?? []),
      currentMedication: json['currentMedication'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      emergencyContactEmail: json['emergencyContactEmail'] ?? '',
    );
  }
}

class RegistrationCubit extends Cubit<RegistrationState> {
  final _db = LocalDbService();
  final _profiles = ProfileRepository();

  RegistrationCubit() : super(RegistrationState());

  Future<void> saveProgress(int step) async {
    await _db.saveRegistrationProgress(step, state.toJson());
  }

  Future<int?> loadSavedProgress() async {
    try {
      // 1. If an auth session exists, load profile through the backend.
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final data = await _profiles.getMe();
        emit(RegistrationState.fromJson({
          ...data,
          'fullName': data['full_name'] ?? '',
          'phoneNumber': data['phone_number'] ?? '',
          'pharmacyName': data['pharmacy_name'] ?? '',
          'pharmacyId': data['pharmacy_id'] ?? '',
          'licenseNumber': data['license_number'] ?? '',
        }));
        return null;
      }

      // 2. Check if in-progress registration exists in sqflite
      final step = await _db.getRegistrationStep();
      final savedState = await _db.getRegistrationState();
      if (step != null && savedState != null) {
        emit(RegistrationState.fromJson(savedState));
        return step;
      }
    } catch (e) {
      // Safely catch platform channel errors in test environments
    }
    return null;
  }

  /// Creates the account and role-specific profile through the backend.
  Future<bool> submitRegistrationToSupabase() async {
    emit(state.copyWith(
        submitStatus: RegistrationSubmitStatus.loading,
        clearSubmitError: true));

    try {
      if (state.password.length < 8) {
        emit(state.copyWith(
          submitStatus: RegistrationSubmitStatus.error,
          submitError:
              'Please return to step 1 and enter your password again before completing registration.',
        ));
        return false;
      }

      final payload = {
        'role': state.role,
        'email': state.email.trim().toLowerCase(),
        'password': state.password,
        'phoneNumber': state.phoneNumber,
        if (state.docType.trim().isNotEmpty)
          'documentType': state.docType.trim(),
        if (state.attachedFilePath != null)
          'documentPath': state.attachedFilePath,
        if (state.role == 'patient') ...{
          'fullName': state.fullName,
          'dateOfBirth': state.dob,
          'gender': state.gender,
          'bloodGroup': state.bloodGroup,
          'knownAllergies': state.knownAllergies,
          'chronicConditions': state.chronicConditions,
          if (state.currentMedication.trim().isNotEmpty)
            'currentMedication': state.currentMedication.trim(),
          if (state.emergencyContactName.trim().isNotEmpty)
            'emergencyContactName': state.emergencyContactName.trim(),
          if (state.emergencyContactPhone.trim().isNotEmpty)
            'emergencyContactPhone': state.emergencyContactPhone.trim(),
          if (state.emergencyContactEmail.trim().isNotEmpty)
            'emergencyContactEmail':
                state.emergencyContactEmail.trim().toLowerCase(),
        } else ...{
          'pharmacyName': state.pharmacyName,
          'licenseNumber': state.licenseNumber,
          if (state.registrationAuthority.trim().isNotEmpty)
            'registrationAuthority': state.registrationAuthority.trim(),
          'location': state.location,
          if (state.operatingHours.trim().isNotEmpty)
            'operatingHours': state.operatingHours.trim(),
          if (state.supplierPreference.trim().isNotEmpty)
            'supplierPreference': state.supplierPreference.trim(),
        },
      };

      final result = await _profiles.register(payload);
      final session = result['session'] as Map?;
      final refreshToken = session?['refreshToken'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await Supabase.instance.client.auth.setSession(refreshToken);
      }

      await _db.clearRegistrationProgress();

      emit(state.copyWith(submitStatus: RegistrationSubmitStatus.success));

      // If email confirmation is required, session will be null here.
      // Caller should navigate to a "check your email" screen when this
      // returns true but currentSession is still null.
      return true;
    } catch (e) {
      String friendlyMessage = e.toString();
      final lowerMsg = friendlyMessage.toLowerCase();
      if (lowerMsg.contains('already registered') ||
          lowerMsg.contains('already exists')) {
        friendlyMessage =
            'An account with this email already exists. Please log in instead.';
      } else if (lowerMsg.contains('rate limit') ||
          lowerMsg.contains('rate_limit')) {
        friendlyMessage =
            'Email verification limit exceeded. Please wait a few minutes before trying again, or contact support.';
      }
      emit(state.copyWith(
        submitStatus: RegistrationSubmitStatus.error,
        submitError: friendlyMessage,
      ));
      return false;
    }
  }

  Future<void> clearSavedProgress() async {
    await _db.clearRegistrationProgress();
  }

  void reset() {
    emit(RegistrationState());
  }

  void setRole(String role) {
    emit(state.copyWith(
        role: role,
        docType: role == 'patient' ? 'National ID' : 'Pharmacy License'));
  }

  void updatePatientInfo({
    String? fullName,
    String? dob,
    String? gender,
    String? phoneNumber,
    String? email,
    String? password,
  }) {
    emit(state.copyWith(
      fullName: fullName,
      dob: dob,
      gender: gender,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    ));
  }

  void updatePharmacyInfo({
    String? pharmacyName,
    String? licenseNumber,
    String? registrationAuthority,
    String? location,
    String? operatingHours,
    String? supplierPreference,
  }) {
    emit(state.copyWith(
      pharmacyName: pharmacyName,
      licenseNumber: licenseNumber,
      registrationAuthority: registrationAuthority,
      location: location,
      operatingHours: operatingHours,
      supplierPreference: supplierPreference,
    ));
  }

  void setDocType(String docType) {
    emit(state.copyWith(docType: docType));
  }

  void attachDocument(String path) {
    emit(state.copyWith(attachedFilePath: path));
  }

  void clearDocument() {
    emit(state.copyWith(clearAttachedFilePath: true));
  }

  void updateHealthProfile({
    String? bloodGroup,
    List<String>? knownAllergies,
    List<String>? chronicConditions,
    String? currentMedication,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactEmail,
  }) {
    emit(state.copyWith(
      bloodGroup: bloodGroup,
      knownAllergies: knownAllergies,
      chronicConditions: chronicConditions,
      currentMedication: currentMedication,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactEmail: emergencyContactEmail,
    ));
  }

  void updateProfile(RegistrationState newState) {
    emit(newState);
  }

  void updatePassword(String password) {
    emit(state.copyWith(password: password));
  }
}
