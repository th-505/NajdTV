import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/stitch_design.dart';

void main() {
  testWidgets(
    'carousel rotates real works and pauses after explicit navigation',
    (tester) async {
      final items = List.generate(
        3,
        (i) => CatalogItem(
          id: '$i',
          title: 'العمل $i',
          poster: '',
          type: 'movie',
          ref: 'tmdb:movie:$i',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: NajdFeatureCarousel(
                items: items,
                isSaved: (_) => false,
                onWatch: (_) {},
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );
      PageController pages() =>
          tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(pages().page, 0);
      expect(find.text('1 / 3'), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(milliseconds: 500));
      expect(pages().page, 1);
      await tester.tap(find.byTooltip('العمل التالي'));
      await tester.pumpAndSettle();
      expect(pages().page, 2);
      await tester.pump(const Duration(seconds: 9));
      expect(pages().page, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final width in [390.0, 1280.0]) {
    testWidgets('featured posters open details and fit width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final items = List.generate(
        3,
        (i) => CatalogItem(
          id: '$i',
          ref: 'tmdb:movie:$i',
          title: 'عنوان طويل لفيلم يعرض بشكل واضح $i',
          poster: '',
          type: 'movie',
          year: 2026,
          rating: 8.4,
        ),
      );
      var details = 0, saved = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: NajdFeatureCarousel(
                items: items,
                isSaved: (_) => false,
                onWatch: (_) => details++,
                onSave: (_) => saved++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final heroes = find.byType(NajdFeatureHero).hitTestable();
      expect(heroes, findsNWidgets(width >= 900 ? 3 : 2));
      await tester.tapAt(
        tester.getTopLeft(heroes.first) + const Offset(30, 30),
      );
      await tester.pump();
      expect(details, 1);
      await tester.tap(find.byTooltip('قائمتي').hitTestable().first);
      await tester.pump();
      expect(saved, 1);
      expect(details, 1, reason: 'nested save must not also open details');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
