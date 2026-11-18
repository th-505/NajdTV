import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/main.dart';
import 'package:mitv/src/api_client.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Shelves extends MitvApi {
  int calls = 0;
  int revision = 1;
  bool fail = false;
  @override
  Future<List<CatalogItem>> category(String id, {int page = 1}) async {
    calls++;
    if (fail) throw const ApiException('OFFLINE');
    return [
      CatalogItem(
        id: 'tmdb:movie:1',
        ref: 'tmdb:movie:1',
        title: 'Observed shelf $revision',
        poster: '',
        type: 'movie',
      ),
    ];
  }
}

void main() {
  testWidgets(
    'home refreshes stale shelves only when visible and foreground; offline refresh retains usable cards',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      SharedPreferences.setMockInitialValues({});
      final store = await LocalLibraryStore.create();
      final api = _Shelves();
      addTearDown(store.dispose);
      addTearDown(api.close);
      var now = DateTime.utc(2026, 11, 18);
      var visible = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return TickerMode(
                enabled: visible,
                child: Scaffold(
                  body: HomePage(api: api, store: store, now: () => now),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(api.calls, 6);
      expect(find.text('Observed shelf 1'), findsWidgets);
      update(() => visible = false);
      await tester.pump();
      now = now.add(const Duration(minutes: 20));
      await tester.pump(const Duration(minutes: 20));
      expect(
        api.calls,
        6,
        reason: 'hidden retained tabs must not fetch shelves',
      );
      api.revision = 2;
      update(() => visible = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(api.calls, 12);
      expect(find.text('Observed shelf 2'), findsWidgets);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 20));
      await tester.pump(const Duration(minutes: 20));
      expect(api.calls, 12, reason: 'background app must not poll catalog');
      api.revision = 3;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(api.calls, 18);
      expect(find.text('Observed shelf 3'), findsWidgets);
      api.fail = true;
      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(minutes: 10));
      await tester.pump();
      expect(api.calls, 24);
      expect(
        find.text('Observed shelf 3'),
        findsWidgets,
        reason: 'a transient refresh failure must not erase existing cards',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
