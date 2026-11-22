import 'models.dart';
import 'search_work_groups.dart';
import 'unified_media.dart';

String normalizeSearchTitle(String title) {
  return MediaTaxonomy.normalizeTitle(title)
      .replaceFirst(RegExp(r'^the\s+'), '')
      .replaceAllMapped(
        RegExp(r'(^|\s)ال(?=[\u0621-\u064A]{3,})'),
        (match) => match[1]!,
      )
      .replaceAll('ة', 'ه');
}

class SearchScoring {
  SearchScoring(String query)
    : title = normalizeSearchTitle(query.replaceFirst(_yearSuffix, '')),
      requestedYear = int.tryParse(
        _yearSuffix.firstMatch(query)?.group(1) ?? '',
      );

  static final _yearSuffix = RegExp(r'\s+\(?(19\d{2}|20\d{2})\)?\s*$');

  final String title;
  final int? requestedYear;

  int score(String candidate, {int? year, int? referenceYear}) {
    final normalized = normalizeSearchTitle(candidate);
    if (title.isEmpty || normalized.isEmpty) return 0;
    if (title == normalized) {
      final expected = requestedYear ?? referenceYear;
      if (expected == null || year == null) return 70;
      return switch ((expected - year).abs()) {
        0 => 100,
        1 => 85,
        _ => 0,
      };
    }
    if (requestedYear != null &&
        year != null &&
        (requestedYear! - year).abs() > 1) {
      return 0;
    }
    final queryWords = title.split(' ').toSet();
    final candidateWords = normalized.split(' ').toSet();
    final common = queryWords.intersection(candidateWords).length;
    final overlap = 2 * common / (queryWords.length + candidateWords.length);
    return overlap >= .7 || _similarity(title, normalized) >= .7 ? 70 : 0;
  }

  static double _similarity(String left, String right) {
    if (left.length > 160 || right.length > 160) return 0;
    final length = left.length > right.length ? left.length : right.length;
    if ((left.length - right.length).abs() > length * .3) return 0;
    var previous = List<int>.generate(right.length + 1, (i) => i);
    for (var i = 0; i < left.length; i++) {
      final next = List<int>.filled(right.length + 1, 0)..[0] = i + 1;
      for (var j = 0; j < right.length; j++) {
        final edit =
            previous[j] + (left.codeUnitAt(i) == right.codeUnitAt(j) ? 0 : 1);
        final gap = (previous[j + 1] < next[j] ? previous[j + 1] : next[j]) + 1;
        next[j + 1] = edit < gap ? edit : gap;
      }
      previous = next;
    }
    return 1 - previous.last / length;
  }

  int? referenceYear(Iterable<CatalogItem> catalogue) {
    final years = {
      for (final item in catalogue)
        if (item.ref.startsWith('tmdb:') &&
            item.year != null &&
            normalizeSearchTitle(item.title) == title)
          item.year!,
    };
    return years.length == 1 ? years.single : null;
  }

  ({List<SearchWorkGroup> exact, List<SearchWorkGroup> possible}) partition(
    List<SearchWorkGroup> groups, {
    int? catalogueYear,
  }) {
    final anchor =
        catalogueYear ??
        referenceYear(groups.map((group) => group.representative));
    final exact = <SearchWorkGroup>[];
    final nearby = <SearchWorkGroup>[];
    final possible = <SearchWorkGroup>[];
    for (final group in groups) {
      switch (score(
        group.title,
        year: group.representative.year,
        referenceYear: anchor,
      )) {
        case 100:
          exact.add(group);
        case 85:
          nearby.add(group);
        case 70:
          possible.add(group);
      }
    }
    return (exact: [...exact, ...nearby], possible: possible);
  }
}
