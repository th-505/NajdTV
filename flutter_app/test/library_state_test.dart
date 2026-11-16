import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('library classifications survive persistence without duplicating works or erasing history', () async {
    SharedPreferences.setMockInitialValues({});
    const item = CatalogItem(
      id: '1',
      ref: 'tmdb:movie:1',
      title: 'عمل',
      poster: '',
      type: 'movie',
    );
    final store = await LocalLibraryStore.create();
    await store.recordProgress(
      item: item,
      position: const Duration(minutes: 2),
      duration: const Duration(minutes: 90),
    );
    for (final state in ['favorite', 'watchlist', 'watching', 'watched']) {
      await store.setLibraryState(item, state);
      expect(store.favorites, hasLength(1));
      expect(store.favorites.single.libraryState, state);
      expect(store.history, hasLength(1));
      expect(
        CatalogItem.fromJson(store.favorites.single.toJson()).libraryState,
        state,
      );
    }
    await store.setLibraryState(item, 'invalid');
    expect(store.favorites.single.libraryState, 'watched');
    store.dispose();
    final restored = await LocalLibraryStore.create();
    expect(restored.favorites.single.libraryState, 'watched');
    expect(restored.history, hasLength(1));
    expect(CatalogItem.fromJson(item.toJson()).libraryState, 'favorite');
    restored.dispose();
  });
  test(
    'catalog metadata cannot decide the user library classification',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalLibraryStore.create();
      final item = CatalogItem.fromJson({
        'id': 'x',
        'ref': 'tmdb:movie:2',
        'title': 'عمل',
        'poster': '',
        'type': 'movie',
        'library_state': 'watched',
      });
      await store.toggleFavorite(item);
      expect(store.favorites.single.libraryState, 'favorite');
      store.dispose();
    },
  );
}
