import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/player_page.dart';

import 'phase2_player_test.dart' show FakeEngine;
import 'player_timeline_test.dart' show TimelineApi, source, settle;

const first = CatalogItem(
  id: 'one',
  ref: 'live:iptv-org:sa:aaaaaaaaaaaaaaaaaaaaaaaa',
  title: 'القناة الأولى',
  poster: '',
  type: 'live',
);
const second = CatalogItem(
  id: 'two',
  ref: 'live:iptv-org:sa:bbbbbbbbbbbbbbbbbbbbbbbb',
  title: 'القناة الثانية',
  poster: '',
  type: 'live',
);

class LiveApi extends TimelineApi {
  LiveApi() : super([source('live', 'live')]);
  final pages = <int>[];
  @override
  Future<Map<String, dynamic>> liveChannels(
    String group, {
    int page = 1,
    String query = '',
  }) async {
    pages.add(page);
    return {
      'data': [second.toJson()],
      'pagination': {'has_more': false},
    };
  }
}

void main() {
  testWidgets(
    'live controls change channel, continue group pagination and never seek',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalLibraryStore.create();
      final api = LiveApi();
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerPage(
            api: api,
            store: store,
            item: first,
            title: first.title,
            sourceRef: first.ref,
            isLive: true,
            liveSelection: const LiveChannelSelection(
              item: first,
              group: 'sa',
              channels: [first],
              page: 1,
              hasMore: true,
            ),
            playerFactory: (u, t, h, s) => FakeEngine(
              u,
              mediaType: t,
              headers: h,
              software: s,
              fail: false,
            ),
          ),
        ),
      );
      await settle(tester);
      expect(find.byTooltip('القناة التالية'), findsOneWidget);
      expect(find.byTooltip('القناة السابقة'), findsOneWidget);
      expect(find.text('القنوات والتصنيفات'), findsOneWidget);
      expect(find.byTooltip('تقديم 10 ثانية'), findsNothing);
      await tester.tap(find.byTooltip('القناة التالية'));
      await settle(tester);
      expect(api.pages, [2]);
      expect(
        tester.widget<PlayerPage>(find.byType(PlayerPage)).item.ref,
        second.ref,
      );
      expect(store.history, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      store.dispose();
      api.close();
    },
  );
}
