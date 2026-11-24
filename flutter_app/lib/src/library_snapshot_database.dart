abstract interface class LibrarySnapshotDatabase {
  String? read(String ownerKey);
  void write(String ownerKey, String snapshot);
  void close();
}
