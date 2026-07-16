import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/identity_tag_model.dart';
import '../../domain/use_cases/generate_identity_tag_use_case.dart';
import '../../domain/use_cases/get_identity_tag_use_case.dart';

abstract class IdentityTagState {}

class IdentityTagLoading extends IdentityTagState {}

class IdentityTagLoaded extends IdentityTagState {
  final IdentityTagModel tag;
  IdentityTagLoaded(this.tag);
}

class IdentityTagError extends IdentityTagState {
  final String message;
  IdentityTagError(this.message);
}

class IdentityTagCubit extends Cubit<IdentityTagState> {
  final GetIdentityTagUseCase _getIdentityTag;
  final GenerateIdentityTagUseCase _generateIdentityTag;

  IdentityTagCubit({
    required GetIdentityTagUseCase getIdentityTag,
    required GenerateIdentityTagUseCase generateIdentityTag,
  })  : _getIdentityTag = getIdentityTag,
        _generateIdentityTag = generateIdentityTag,
        super(IdentityTagLoading());

  Future<void> loadOrCreateTag(String patientId) async {
    emit(IdentityTagLoading());
    try {
      final existing = await _getIdentityTag(patientId: patientId);
      if (existing != null) {
        emit(IdentityTagLoaded(existing));
        return;
      }
      final created = await _generateIdentityTag(patientId: patientId);
      emit(IdentityTagLoaded(created));
    } catch (e) {
      emit(IdentityTagError('Could not load identity tag. $e'));
    }
  }
}
