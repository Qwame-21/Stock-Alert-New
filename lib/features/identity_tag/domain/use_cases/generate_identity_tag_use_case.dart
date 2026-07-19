import 'package:uuid/uuid.dart';
import '../../data/models/identity_tag_model.dart';
import '../../data/repositories/identity_tag_repository.dart';

/// Creates a tag unless the patient already has one.
class GenerateIdentityTagUseCase {
  final IdentityTagRepository _repository;
  final Uuid _uuid = const Uuid();

  GenerateIdentityTagUseCase({required IdentityTagRepository repository})
      : _repository = repository;

  Future<IdentityTagModel> call({required String patientId}) async {
    final existing = await _repository.getLocalTag(patientId);
    if (existing != null) {
      // Don't make two live tags for one patient.
      return existing;
    }

    final tag = IdentityTagModel(
      id: _uuid.v4(),
      patientId: patientId,
      // The QR only contains this random token.
      qrToken: _uuid.v4(),
      verificationStatus: VerificationStatus.pending,
      memberSince: DateTime.now(),
    );

    await _repository.saveTag(tag);
    return tag;
  }
}
