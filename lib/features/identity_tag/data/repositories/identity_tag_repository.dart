import '../models/identity_tag_model.dart';
import '../../../../core/sync/sync_manager.dart';

/// Reads and saves identity tags.
abstract class IdentityTagRepository {
  Future<IdentityTagModel?> getLocalTag(String patientId);
  Future<void> saveTag(IdentityTagModel tag);
}

class IdentityTagRepositoryImpl implements IdentityTagRepository {
  final SyncManager _syncManager;

  // TODO: add the local database cache here later.
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
