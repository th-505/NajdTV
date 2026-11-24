import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/library_snapshot_database_native.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'migrates a checkpoint and its sync queue and reloads after SQLite reopen',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final root = await Directory.systemTemp.createTemp('najd-sqlite-');
      addTearDown(() => root.delete(recursive: true));
      final path = '${root.path}/library.sqlite3';
      const item = CatalogItem(
        id: 'film',
        ref: 'tmdb:movie:7',
        title: 'Fixture',
        poster: '',
        type: 'movie',
      );
      final old = await LocalLibraryStore.create();
      await old.recordProgress(
        item: item,
        position: const Duration(milliseconds: 41250),
        duration: const Duration(minutes: 5),
      );
      old.dispose();

      final database = SqliteLibrarySnapshots.open(path);
      final migrated = await LocalLibraryStore.create(database: database);
      expect(migrated.resumePosition(item.ref).inMilliseconds, 41250);
      expect(migrated.pendingCloudRows.single.kind, 'history');
      await migrated.bindOwner('first-owner');
      await migrated.recordProgress(
        item: item,
        position: const Duration(milliseconds: 73125),
        duration: const Duration(minutes: 5),
      );
      migrated.dispose();
      await Future<void>.delayed(Duration.zero);

      SharedPreferences.setMockInitialValues({
        'library.local.owner.v1': 'first-owner',
      });
      final reopened = await LocalLibraryStore.create(
        database: SqliteLibrarySnapshots.open(path),
      );
      expect(reopened.resumePosition(item.ref).inMilliseconds, 73125);
      expect(reopened.pendingCloudRows.single.kind, 'history');
      await reopened.bindOwner('second-owner');
      expect(reopened.history, isEmpty);
      expect(reopened.pendingCloudRows, isEmpty);
      await reopened.bindOwner('first-owner');
      expect(reopened.resumePosition(item.ref).inMilliseconds, 73125);
      reopened.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
}
