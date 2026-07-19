/// Current state of a record waiting to sync.
enum SyncStatus {
  pending, // Saved locally and waiting.
  uploading, // Sending now.
  synced, // Saved on the backend.
  conflict, // Local and backend versions differ.
  failed, // Failed and will retry.
}

extension SyncStatusStorage on SyncStatus {
  String get asDbValue => name;

  static SyncStatus fromDbValue(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
