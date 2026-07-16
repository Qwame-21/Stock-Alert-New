import '../network/api_client.dart';
import '../storage/local_db_service.dart';

/// Sits between a Repository and the two actual data sources (sqflite and
/// Supabase). A Repository never talks to Supabase directly - it goes
/// through here, so the rest of the app doesn't care whether we're online.
///
/// This is deliberately simple right now: write local first, mark pending,
/// try to push, update status based on what happens. Conflict resolution
/// (comparing updated_at timestamps) is left as a clear extension point
/// rather than solved here, since it depends on the record type.
class SyncManager {
  final LocalDbService _db;
  final ApiClient _api;

  SyncManager({LocalDbService? db, ApiClient? api})
      : _db = db ?? LocalDbService(),
        _api = api ?? ApiClient.instance;

  /// Queues a record for upload. In the full implementation this would
  /// write to a local "outbox" table (record type + id + payload + status)
  /// and a background isolate/timer would drain it whenever connectivity
  /// is available.
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

  /// Attempts to push everything currently pending. Called on connectivity
  /// regain, app resume, or a manual pull-to-refresh.
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

  /// Called when a push succeeds but the backend row was already changed
  /// by someone else since the local copy was last read.
  Future<void> resolveConflict({
    required String table,
    required String recordId,
  }) async {
    // Conflicts stay in the outbox with their backend error so the feature
    // repository can refresh the server record and ask the user to retry.
  }
}
