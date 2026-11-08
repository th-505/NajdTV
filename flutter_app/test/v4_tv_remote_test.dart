import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/main.dart';
import 'package:mitv/src/api_client.dart';
import 'package:mitv/src/app_target.dart';
import 'package:mitv/src/focus_highlight.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/poster_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/shell_navigation.dart';

class _Api extends MitvApi {
  @override
  Future<List<CatalogItem>> category(String categoryId, {int page = 1}) async =>
      [];
}

void main() {
  testWidgets(
    'remote focus scrolls to offscreen controls and activates with Enter',
    (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusScrollScope(
              child: SizedBox(
                height: 180,
                child: ListView(
                  children: List.generate(
                    12,
                    (i) => SizedBox(
                      height: 80,
                      child: TextButton(
                        autofocus: i == 0,
                        onPressed: () => selected = i,
                        child: Text('زر $i'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 7; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 7);
      expect(find.text('زر 7').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'poster preview has a focused remote close action and Escape preserves underlying page',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPosterPreview(
                  context,
                  'https://image.example/poster.jpg',
                ),
                child: const Text('افتح الصورة'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح الصورة'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('poster-preview-close')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('poster-preview-close')), findsNothing);
      expect(find.text('افتح الصورة'), findsOneWidget);
    },
  );
  testWidgets(
    'TV Back from a section returns home, then requires a second exit press',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = _Api(), store = await LocalLibraryStore.create();
      await tester.pumpWidget(
        MaterialApp(
          home: Shell(api: api, store: store),
        ),
      );
      await tester.pumpAndSettle();
      await selectShellDestination(tester, 'search');
      expect(find.byType(SearchPage), findsOneWidget);
      if (isTvTarget) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(SearchPage), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('اضغط رجوع مرة أخرى للخروج'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      api.close();
      store.dispose();
    },
  );
}
