import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'library_snapshot_database.dart';

Future<LibrarySnapshotDatabase?> openPlatformLibrarySnapshots() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return SqliteLibrarySnapshots.open(
    '${directory.path}${Platform.pathSeparator}najd-library.sqlite3',
  );
}

class SqliteLibrarySnapshots implements LibrarySnapshotDatabase {
  SqliteLibrarySnapshots._(this._database);

  final Database _database;

  static SqliteLibrarySnapshots open(String path) {
    final database = sqlite3.open(path);
    try {
      database.execute('PRAGMA busy_timeout = 2500');
      database.execute('''
        CREATE TABLE IF NOT EXISTS library_snapshots (
          owner_key TEXT PRIMARY KEY NOT NULL,
          snapshot TEXT NOT NULL
        ) WITHOUT ROWID
      ''');
      return SqliteLibrarySnapshots._(database);
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  @override
  String? read(String ownerKey) =>
      _database.select(
            'SELECT snapshot FROM library_snapshots WHERE owner_key = ?',
            [ownerKey],
          ).firstOrNull?['snapshot']
          as String?;

  @override
  void write(String ownerKey, String snapshot) {
    _database.execute(
      '''
      INSERT INTO library_snapshots (owner_key, snapshot) VALUES (?, ?)
      ON CONFLICT(owner_key) DO UPDATE SET snapshot = excluded.snapshot
    ''',
      [ownerKey, snapshot],
    );
  }

  @override
  void close() => _database.close();
}
