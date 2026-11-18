import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/models.dart';

void main() {
  test('evidence labels survive storage without changing canonical movie/series identity', () {
    final anime = CatalogItem.fromJson({
      'id': '1',
      'ref': 'tmdb:tv:1',
      'type': 'series',
      'genres': ['أنمي'],
    });
    final restored = CatalogItem.fromJson(anime.toJson());
    expect(restored.type, 'series');
    expect(restored.matchesLibraryKind('anime'), isTrue);
    expect(restored.matchesLibraryKind('series'), isFalse);
    expect(restored.matchesLibraryKind('all'), isTrue);
    final turkish = CatalogItem.fromJson({
      'id': '2',
      'ref': 'tmdb:tv:2',
      'type': 'series',
      'genres': ['تركي'],
    });
    expect(turkish.matchesLibraryKind('turkish'), isTrue);
    expect(turkish.matchesLibraryKind('series'), isTrue);
  });
  test('Western animation and unknown genres do not become anime', () {
    for (final genres in [
      <String>[],
      ['Animation'],
      ['رسوم متحركة'],
    ]) {
      final item = CatalogItem(
        id: '3',
        title: 'Cartoon',
        poster: '',
        ref: 'tmdb:tv:3',
        type: 'series',
        genres: genres,
      );
      expect(item.matchesLibraryKind('anime'), isFalse);
      expect(item.matchesLibraryKind('series'), isTrue);
    }
  });
  test('existing saved catalogue category evidence remains compatible', () {
    final anime = CatalogItem.fromJson({
      'type': 'movie',
      'category': 'catalog:anime:movie',
    });
    expect(anime.matchesLibraryKind('anime'), isTrue);
    expect(anime.matchesLibraryKind('movie'), isFalse);
    final turkish = CatalogItem.fromJson({
      'type': 'series',
      'category': 'catalog:collection:turkish-top',
    });
    expect(turkish.matchesLibraryKind('turkish'), isTrue);
  });
}
