import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_db_service.dart';

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
  final String licenseNumber;
  final String registrationAuthority;
  final String location;
  final String operatingHours;
  final String supplierPreference;

  // Step 2 Verification Document
  final String docType; // 'National ID', 'Passport', 'Driver\'s License' / 'Pharmacy License'
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
      licenseNumber: licenseNumber ?? this.licenseNumber,
      registrationAuthority: registrationAuthority ?? this.registrationAuthority,
      location: location ?? this.location,
      operatingHours: operatingHours ?? this.operatingHours,
      supplierPreference: supplierPreference ?? this.supplierPreference,
      docType: docType ?? this.docType,
      attachedFilePath: clearAttachedFilePath ? null : (attachedFilePath ?? this.attachedFilePath),
      bloodGroup: bloodGroup ?? this.bloodGroup,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedication: currentMedication ?? this.currentMedication,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactEmail: emergencyContactEmail ?? this.emergencyContactEmail,
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
  final _supabase = Supabase.instance.client;

  RegistrationCubit() : super(RegistrationState());

  Future<void> saveProgress(int step) async {
    await _db.saveRegistrationProgress(step, state.toJson());
  }

  Future<int?> loadSavedProgress() async {
    try {
      // 1. If Supabase session exists, load profile from server
      final session = _supabase.auth.currentSession;
      if (session != null) {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .single();
        emit(RegistrationState.fromJson(data));
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

  /// Sign up with Supabase Auth and insert the profile row.
  ///
  /// Strategy:
  /// - All profile metadata is passed in the `data` field of signUp so that
  ///   a DB trigger (handle_new_user) can always create the profiles row
  ///   server-side, bypassing RLS entirely — this works even when email
  ///   confirmation is required (unauthenticated client).
  /// - If confirmation is OFF and a live session is returned, we also attempt
  ///   a client-side upsert as a belt-and-suspenders fallback.
  ///
  /// Returns true on success, false on failure (error stored in state.submitError).
  Future<bool> submitRegistrationToSupabase() async {
    emit(state.copyWith(submitStatus: RegistrationSubmitStatus.loading, clearSubmitError: true));

    try {
      // Step 1: Create the auth user — embed all profile fields in user_meta_data
      // so the `handle_new_user` DB trigger can populate the profiles row
      // regardless of email-confirmation settings.
      final profileMeta = {
        'role': state.role,
        'full_name': state.fullName,
        'phone_number': state.phoneNumber,
        'dob': state.dob,
        'gender': state.gender,
        if (state.pharmacyName.isNotEmpty) 'pharmacy_name': state.pharmacyName,
        if (state.licenseNumber.isNotEmpty) 'license_number': state.licenseNumber,
        if (state.location.isNotEmpty) 'location': state.location,
      };

      final response = await _supabase.auth.signUp(
        email: state.email,
        password: state.password,
        data: profileMeta,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Registration failed — no user returned. Please try again.');
      }

      // Step 2: If we already have a live session (email confirmation OFF),
      // perform a client-side upsert as a safety net in case the trigger
      // is not set up yet.
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'role': state.role,
          'full_name': state.fullName,
          'email': state.email,
          'phone_number': state.phoneNumber,
          'dob': state.dob,
          'gender': state.gender,
          'pharmacy_name': state.pharmacyName.isNotEmpty ? state.pharmacyName : null,
          'license_number': state.licenseNumber.isNotEmpty ? state.licenseNumber : null,
          'location': state.location.isNotEmpty ? state.location : null,
        });
      }

      // Step 3: Clear local in-progress registration data
      await _db.clearRegistrationProgress();

      emit(state.copyWith(submitStatus: RegistrationSubmitStatus.success));

      // If email confirmation is required, session will be null here.
      // Caller should navigate to a "check your email" screen when this
      // returns true but currentSession is still null.
      return true;
    } on AuthException catch (e) {
      // Supabase-specific errors (e.g. email already registered)
      String friendlyMessage = e.message;
      final lowerMsg = e.message.toLowerCase();
      if (lowerMsg.contains('already registered') ||
          lowerMsg.contains('already exists')) {
        friendlyMessage = 'An account with this email already exists. Please log in instead.';
      } else if (lowerMsg.contains('rate limit') || lowerMsg.contains('rate_limit')) {
        friendlyMessage = 'Email verification limit exceeded. Please wait a few minutes before trying again, or contact support.';
      }
      emit(state.copyWith(
        submitStatus: RegistrationSubmitStatus.error,
        submitError: friendlyMessage,
      ));
      return false;
    } catch (e) {
      // Only surface RLS/insert errors gracefully — the trigger should prevent these.
      final msg = e.toString();
      final isRls = msg.toLowerCase().contains('row-level security') ||
          msg.toLowerCase().contains('violates row-level');
      emit(state.copyWith(
        submitStatus: RegistrationSubmitStatus.error,
        submitError: isRls
            ? 'Account created — please check your email to confirm, then log in.'
            : 'Registration failed. Please try again.',
      ));
      // If the error was purely an RLS insert issue but the auth user was created,
      // we still treat it as a partial success so the trigger can fill the profile.
      return isRls;
    }
  }

  Future<void> clearSavedProgress() async {
    await _db.clearRegistrationProgress();
  }

  void reset() {
    emit(RegistrationState());
  }

  void setRole(String role) {
    emit(state.copyWith(role: role, docType: role == 'patient' ? 'National ID' : 'Pharmacy License'));
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
