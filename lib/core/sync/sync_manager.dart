import 'sync_status.dart';

/// Sits between a Repository and the two actual data sources (sqflite and
/// Supabase). A Repository never talks to Supabase directly - it goes
/// through here, so the rest of the app doesn't care whether we're online.
///
/// This is deliberately simple right now: write local first, mark pending,
/// try to push, update status based on what happens. Conflict resolution
/// (comparing updated_at timestamps) is left as a clear extension point
/// rather than solved here, since it depends on the record type.
class SyncManager {
  /// Queues a record for upload. In the full implementation this would
  /// write to a local "outbox" table (record type + id + payload + status)
  /// and a background isolate/timer would drain it whenever connectivity
  /// is available.
  Future<void> queueForSync({
    required String table,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    // TODO: insert into local sync_queue table with SyncStatus.pending
    // TODO: kick off an attemptSync() call if currently online
  }

  /// Attempts to push everything currently pending. Called on connectivity
  /// regain, app resume, or a manual pull-to-refresh.
  Future<void> attemptSync() async {
    // TODO: read all sync_queue rows where status is pending or failed
    // TODO: for each, mark uploading, push to Supabase, then mark
    //       synced on success or failed on error (with retry backoff)
  }

  /// Called when a push succeeds but the backend row was already changed
  /// by someone else since the local copy was last read.
  Future<void> resolveConflict({
    required String table,
    required String recordId,
  }) async {
    // TODO: compare local vs remote updated_at, or surface to the user
    //       for records where silent resolution isn't safe (e.g. inventory
    //       counts edited by two pharmacy staff at once)
  }
}
