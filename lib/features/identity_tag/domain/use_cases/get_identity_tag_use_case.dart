import '../../data/models/identity_tag_model.dart';
import '../../data/repositories/identity_tag_repository.dart';

class GetIdentityTagUseCase {
  final IdentityTagRepository _repository;

  GetIdentityTagUseCase({required IdentityTagRepository repository})
      : _repository = repository;

  Future<IdentityTagModel?> call({required String patientId}) {
    return _repository.getLocalTag(patientId);
  }
}
