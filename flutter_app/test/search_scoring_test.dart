import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/search_scoring.dart';
import 'package:mitv/src/search_work_groups.dart';

void main() {
  test('normalizes articles, Arabic letters and presentation prefixes', () {
    expect(normalizeSearchTitle('The Batman'), 'batman');
    expect(normalizeSearchTitle('مسلسل الأَسطورة المَخفية'), 'اسطوره مخفيه');
    expect(normalizeSearchTitle('آثار إلى إسبانيا'), 'اثار الي اسبانيا');
    expect(normalizeSearchTitle('الشرق The East'), 'شرق the east');
  });

  test('compares years, excludes unrelated works and retains close titles', () {
    final scoring = SearchScoring('The Dark Knight (2008)');
    expect(scoring.score('Dark Knight', year: 2008), 100);
    expect(scoring.score('Dark Knight', year: 2009), 85);
    expect(scoring.score('Dark Knight', year: 2012), 0);
    expect(scoring.score('Dark Knigt', year: 2008), 70);
    expect(scoring.score('Toy Story', year: 2008), 0);
    expect(scoring.score('Dark Knight'), 70);
  });

  test(
    'uses a unique TMDB year and retains unverified editions separately',
    () {
      SearchWorkGroup group(String ref, String title, int? year) =>
          SearchWorkGroup(title, [
            CatalogItem(
              id: ref,
              ref: ref,
              title: title,
              year: year,
              poster: '',
              type: 'movie',
            ),
          ]);
      final canonical = group('tmdb:movie:155', 'The Dark Knight', 2008);
      final nearby = group('source:a:1', 'Dark Knight', 2009);
      final unknown = group('source:b:1', 'Dark Knight', null);
      final unrelated = group('source:c:1', 'Toy Story', 2008);
      final result = SearchScoring('Dark Knight')
          .partition([nearby, unknown, unrelated, canonical]);
      expect(result.exact, [canonical, nearby]);
      expect(result.possible, [unknown]);
    },
  );
}
