/// Every record that can move between the device and Supabase carries one
/// of these. Screens can read this to show something like "syncing..." or
/// a small warning dot, instead of pretending sync always just works.
enum SyncStatus {
  pending,   // written locally, waiting to be sent
  uploading, // actively being sent right now
  synced,    // confirmed saved on the backend
  conflict,  // backend version and local version disagree, needs resolving
  failed,    // upload attempted and failed, will retry
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
