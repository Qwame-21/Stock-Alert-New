import 'package:uuid/uuid.dart';
import '../../data/models/identity_tag_model.dart';
import '../../data/repositories/identity_tag_repository.dart';

/// Handles the actual rule of "what does it mean to generate a tag" -
/// this is where a real app would also check things like "does this
/// patient already have a verified tag" before making a new one.
class GenerateIdentityTagUseCase {
  final IdentityTagRepository _repository;
  final Uuid _uuid = const Uuid();

  GenerateIdentityTagUseCase({required IdentityTagRepository repository})
      : _repository = repository;

  Future<IdentityTagModel> call({required String patientId}) async {
    final existing = await _repository.getLocalTag(patientId);
    if (existing != null) {
      // a patient shouldn't end up with two live tags - return the
      // existing one rather than silently creating a duplicate
      return existing;
    }

    final tag = IdentityTagModel(
      id: _uuid.v4(),
      patientId: patientId,
      // this token is what actually gets embedded in the QR - it carries
      // no personal information on its own, see identity_tag_model.dart
      qrToken: _uuid.v4(),
      verificationStatus: VerificationStatus.pending,
      memberSince: DateTime.now(),
    );

    await _repository.saveTag(tag);
    return tag;
  }
}
