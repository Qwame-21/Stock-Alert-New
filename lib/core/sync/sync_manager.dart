import '../network/api_client.dart';
import '../storage/local_db_service.dart';

/// Keeps local changes in sync with the backend.
class SyncManager {
  final LocalDbService _db;
  final ApiClient _api;

  SyncManager({LocalDbService? db, ApiClient? api})
      : _db = db ?? LocalDbService(),
        _api = api ?? ApiClient.instance;

  /// Queues a record to upload later.
  Future<void> queueForSync({
    required String table,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.enqueueSyncMutation({
      'mutationId': recordId,
      'entityType': table,
      'operation': payload['operation'] ?? 'update',
      'entityId': payload['entityId'],
      'payload': payload['payload'] ?? payload,
    });
  }

  /// Tries to send all pending records.
  Future<void> attemptSync() async {
    final pending = await _db.getPendingSyncMutations();
    if (pending.isEmpty) return;

    final response = await _api.post('/api/v1/sync/push', body: {
      'mutations': pending
          .map((item) => {
                'mutationId': item['mutationId'],
                'entityType': item['entityType'],
                'operation': item['operation'],
                if (item['entityId'] != null) 'entityId': item['entityId'],
                'payload': item['payload'],
              })
          .toList(),
    });

    for (final raw in response.data as List) {
      final result = Map<String, dynamic>.from(raw as Map);
      final mutationId = result['mutationId'] as String;
      if (result['status'] == 'synced') {
        await _db.removeSyncMutation(mutationId);
      } else {
        final error = result['error'] as Map?;
        await _db.markSyncMutationFailed(
          mutationId,
          error?['message'] as String? ?? 'Synchronization failed.',
        );
      }
    }
  }

  /// Keeps a conflict pending so it can be retried.
  Future<void> resolveConflict({
    required String table,
    required String recordId,
  }) async {
    // Keep the error so the user can retry after a refresh.
  }
}
