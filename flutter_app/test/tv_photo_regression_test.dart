import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/najd_theme.dart';
import 'package:mitv/src/stitch_design.dart';
import 'package:mitv/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Geometry assertions use real Arabic glyph metrics, not Flutter test Ahem boxes.
    await (FontLoader(
      'NajdArabicFallback',
    )..addFont(rootBundle.load('assets/fallback/NotoSansArabic.ttf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(640, 360),
    const Size(960, 540),
    const Size(1280, 720),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'TV photograph: complete verse, author and Continue fit $size without scrolling',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var backgroundPressed = false;
        final background = FocusNode();
        addTearDown(background.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: NajdThemes.dark,
            home: NajdTvViewport(
              child: NajdIntro(
                child: TextButton(
                  focusNode: background,
                  autofocus: true,
                  onPressed: () => backgroundPressed = true,
                  child: const Text('خلف المقدمة'),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(background.hasFocus, isFalse);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        final verse = tester.getRect(
          find.byKey(const Key('najd-intro-poetry')),
        );
        final author = tester.getRect(find.text('محمد بن قرملة'));
        final button = tester.getRect(
          find.byKey(const Key('najd-intro-continue')),
        );
        expect(verse.top, greaterThanOrEqualTo(0));
        expect(author.bottom, lessThan(button.top));
        expect(button.bottom, lessThanOrEqualTo(size.height - 20));
        expect(
          find.byKey(const Key('najd-intro-continue')).hitTestable(),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(find.byKey(const Key('najd-intro-continue')), findsNothing);
        expect(backgroundPressed, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
  testWidgets('large text keeps Continue fixed while verse can scroll', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: const NajdIntro(child: Text('الرئيسية')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    final button = find.byKey(const Key('najd-intro-continue'));
    expect(button.hitTestable(), findsOneWidget);
    final before = tester.getRect(button);
    await tester.drag(
      find.byKey(const Key('najd-intro-content')),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(tester.getRect(button), before);
    await tester.tap(button);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'duplicate hero inputs do not repeat a work on a wide screen or expose catalog IDs',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const item = CatalogItem(
        id: '1',
        ref: 'tmdb:movie:1',
        title: 'عمل حقيقي',
        type: 'movie',
        poster: '',
        genres: ['catalog:movie:all', 'دراما'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NajdFeatureCarousel(
              items: const [item, item, item],
              isSaved: (_) => false,
              onWatch: (_) {},
              onSave: (_) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('stitch-feature-hero')), findsOneWidget);
      expect(find.textContaining('catalog:'), findsNothing);
      expect(find.text('دراما'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
