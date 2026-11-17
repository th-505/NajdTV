import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/player_page.dart';
import 'package:mitv/src/source_picker.dart';

import 'phase2_player_test.dart' show FakeEngine;
import 'player_timeline_test.dart' show TimelineApi, source, settle;

class ScanningApi extends TimelineApi {
  ScanningApi() : super([source('first', 'ahwak'), source('second', 'ahwak')]);
  @override
  Future<TitleDetails> resolvePlayback(
    String ref, {
    bool refresh = false,
  }) async {
    resolutions++;
    final result = await super.resolvePlayback(ref, refresh: refresh);
    resolutions--;
    return result.copyWith(
      mediaSources: resolutions == 1 ? [sources.first] : sources,
      serverScan: {
        'in_progress': resolutions == 1,
        'server_scan_complete': resolutions > 1,
      },
    );
  }
}

void main() {
  testWidgets(
    'later servers update choices without restarting or seeking the active decoder',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = ScanningApi();
      final store = await LocalLibraryStore.create();
      final engines = <FakeEngine>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerPage(
            api: api,
            store: store,
            item: const CatalogItem(
              id: '42',
              title: 'Work',
              poster: '',
              type: 'movie',
              ref: 'source:ahwak:aaaaaaaaaaaaaaaaaaaaaaaa',
            ),
            title: 'Work',
            sourceRef: 'source:ahwak:aaaaaaaaaaaaaaaaaaaaaaaa',
            playerFactory: (u, t, h, s) {
              final engine = FakeEngine(
                u,
                mediaType: t,
                headers: h,
                software: s,
                fail: false,
              );
              engines.add(engine);
              return engine;
            },
          ),
        ),
      );
      await settle(tester);
      expect(engines.length, 1);
      await engines.single.seekTo(const Duration(seconds: 25));
      final seeks = engines.single.seeks.length;
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(api.resolutions, 2);
      expect(engines.length, 1);
      expect(engines.single.value.position, const Duration(seconds: 25));
      expect(engines.single.seeks.length, seeks);
      await tester.tap(find.byType(PlayerPage));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('player-more')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SourcePickerButton>(find.byType(SourcePickerButton))
            .sources
            .length,
        2,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      api.close();
    },
  );
}
