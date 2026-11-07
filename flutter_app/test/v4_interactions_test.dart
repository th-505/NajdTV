import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/seek_burst.dart';
import 'package:mitv/src/player_level_rail.dart';
import 'package:mitv/src/person_works_grid.dart';
import 'package:mitv/src/models.dart';

void main() {
  test('double tap arms a burst, each further tap adds a step and changing side resets', () {
    final s = SeekBurst(), start = DateTime(2026);
    var n = 0;
    int tap(bool right, int ms) => s.tap(
      right: right,
      now: start.add(Duration(milliseconds: ms)),
      seconds: 10,
    );
    expect(tap(true, 0), 0);
    n += tap(true, 120);
    expect(n, 10);
    n += tap(true, 240);
    expect(n, 20);
    n += tap(true, 360);
    expect(n, 30);
    expect(s.total, 30);
    expect(tap(false, 420), 0);
    expect(tap(false, 520), -10);
    expect(tap(false, 2000), 0);
  });
  testWidgets(
    'vertical rails force physical minimum below maximum even within RTL',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: PlayerLevelRail(
              value: .5,
              label: 'الصوت',
              icon: Icons.volume_up,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final slider = find.byType(Slider);
      expect(Directionality.of(tester.element(slider)), TextDirection.ltr);
      final box = tester.getRect(slider);
      await tester.tapAt(Offset(box.center.dx, box.top + 4));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('person filters use real popularity and observed years', (
    tester,
  ) async {
    final rows = [
      const CatalogItem(
        id: '1',
        ref: 'tmdb:movie:1',
        title: 'قديم',
        poster: '',
        type: 'movie',
        year: 2000,
        popularity: 100,
      ),
      const CatalogItem(
        id: '2',
        ref: 'tmdb:movie:2',
        title: 'جديد',
        poster: '',
        type: 'movie',
        year: 2026,
        popularity: 5,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonWorksGrid(items: rows, onItem: (_) {}),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('جديد')).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('قديم')).dy),
    );
    await tester.tap(find.text('الرائج'));
    await tester.pump();
    expect(find.text('قديم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
