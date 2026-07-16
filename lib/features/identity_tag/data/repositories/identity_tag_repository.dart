import '../models/identity_tag_model.dart';
import '../../../../core/sync/sync_manager.dart';

/// The repository's only job is reading/writing identity tag data.
/// No business rules here - "can this patient generate a new tag" or
/// "is this verification allowed" belongs in a use case, not here.
abstract class IdentityTagRepository {
  Future<IdentityTagModel?> getLocalTag(String patientId);
  Future<void> saveTag(IdentityTagModel tag);
}

class IdentityTagRepositoryImpl implements IdentityTagRepository {
  final SyncManager _syncManager;

  // In the full build this also takes a local db handle (sqflite) to
  // read/write the cached copy. Left out here to keep this slice focused -
  // the shape of the class is what matters for the pattern.
  IdentityTagRepositoryImpl({required SyncManager syncManager})
      : _syncManager = syncManager;

  @override
  Future<IdentityTagModel?> getLocalTag(String patientId) async {
    // TODO: query local sqflite table `identity_tags` where patient_id = ?
    return null;
  }

  @override
  Future<void> saveTag(IdentityTagModel tag) async {
    // TODO: write to local sqflite table first (offline-first)
    await _syncManager.queueForSync(
      table: 'identity_tags',
      recordId: tag.id,
      payload: tag.toMap(),
    );
  }
}
