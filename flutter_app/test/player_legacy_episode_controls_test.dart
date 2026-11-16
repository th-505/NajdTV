import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/player_page.dart';
import 'package:mitv/src/app_preferences.dart';
import 'package:mitv/src/player_controls.dart';

import 'phase2_player_test.dart' show FakeEngine;
import 'player_timeline_test.dart' show TimelineApi, source, settle;

class LegacyEpisodesApi extends TimelineApi {
  LegacyEpisodesApi() : super([source('alooy', 'alooy')]);
  int detailsCalls = 0;
  @override
  Future<TitleDetails> details(String ref) async {
    detailsCalls++;
    return const TitleDetails(
      title: 'تحت الأرض ج2',
      poster: '',
      episodes: [
        EpisodeItem(
          id: 'one',
          number: 1,
          season: 2,
          title: 'الحلقة 1',
          ref: 'alooy:one',
          watchAvailable: true,
        ),
        EpisodeItem(
          id: 'two',
          number: 2,
          season: 2,
          title: 'الحلقة 2',
          ref: 'alooy:two',
          watchAvailable: true,
        ),
      ],
      mediaPath: '',
      mediaType: '',
      playbackUnavailable: false,
      playbackReason: '',
    );
  }
}

class SeasonBrowsingApi extends LegacyEpisodesApi {
  final refs = <String>[];
  @override
  Future<TitleDetails> details(String ref) async {
    refs.add(ref);
    final season = ref.contains(':s2:') ? 2 : 1;
    return TitleDetails.fromJson({
      'title': 'عمل المصدر',
      'source_work_ref': 'source:ahwak:observed',
      'source_index_authoritative': true,
      'available_seasons': [1, 2],
      'episodes': [
        {
          'id': 's${season}e1',
          'ref': 'source:ahwak:observed:s$season:e1',
          'episode_number': 1,
          'season_number': season,
          'title': 'حلقة الموسم $season',
          'watch_available': true,
        },
      ],
    });
  }
}

void main() {
  testWidgets(
    'legacy Alooy episode refs recover their queue without a supplied episode number; lock blocks seeking',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalLibraryStore.create();
      final api = LegacyEpisodesApi();
      late FakeEngine engine;
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerPage(
            api: api,
            store: store,
            item: const CatalogItem(
              id: 'work',
              ref: 'alooy:work',
              title: 'تحت الأرض ج2',
              poster: '',
              type: 'series',
            ),
            title: 'تحت الأرض ج2',
            sourceRef: 'alooy:one',
            playerFactory: (u, t, h, s) => engine = FakeEngine(
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
      expect(api.detailsCalls, 1);
      expect(find.text('الحلقة التالية'), findsOneWidget);
      expect(find.byKey(const ValueKey('player-track-slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-track-slot-4')), findsOneWidget);
      final center = tester.getCenter(find.byKey(const Key('player-more'))).dx;
      final rowCenter = tester
          .getCenter(find.byKey(const ValueKey('player-track-slot-2')))
          .dx;
      expect(center, closeTo(rowCenter, 0.5));
      expect(find.byKey(const Key('player-previous-episode')), findsNothing);
      expect(find.byKey(const Key('player-next-episode')), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);
      await tester.tap(find.byKey(const Key('player-control-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('قفل التحكم'));
      await tester.pump();
      expect(find.byKey(const Key('player-forward')), findsNothing);
      final before = engine.value.position;
      await tester.tapAt(const Offset(500, 200));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(const Offset(500, 200));
      await tester.pump();
      expect(engine.value.position, before);
      await tester.tap(find.byKey(const Key('player-control-lock')));
      await tester.pump();
      expect(find.byKey(const Key('player-forward')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      store.dispose();
      api.close();
    },
  );
  testWidgets('player loads another observed season without leaving playback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalLibraryStore.create();
    final api = SeasonBrowsingApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerPage(
          api: api,
          store: store,
          item: const CatalogItem(
            id: 'observed',
            ref: 'source:ahwak:observed',
            title: 'عمل المصدر',
            poster: '',
            type: 'series',
            season: 1,
          ),
          title: 'عمل المصدر',
          sourceRef: 'source:ahwak:observed:s1:e1',
          episodeNumber: 1,
          episodeQueue: const [
            EpisodeItem(
              id: 's1e1',
              ref: 'source:ahwak:observed:s1:e1',
              number: 1,
              season: 1,
              title: 'حلقة الموسم 1',
              watchAvailable: true,
            ),
          ],
          playerFactory: (u, t, h, sw) => FakeEngine(
            u,
            mediaType: t,
            headers: h,
            software: sw,
            fail: false,
          ),
        ),
      ),
    );
    await settle(tester);
    final playerState = tester.state(find.byType(PlayerPage));
    await tester.tap(find.byTooltip('أدوات سريعة'));
    await tester.pumpAndSettle();
    expect(find.text('جودة الفيديو'), findsOneWidget);
    await tester.tap(find.text('المواسم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الموسم 2'));
    await tester.pumpAndSettle();
    expect(find.text('حلقة الموسم 2'), findsOneWidget);
    expect(tester.state(find.byType(PlayerPage)), same(playerState));
    expect(api.refs, [
      'source:ahwak:observed:s1:e1',
      'source:ahwak:observed:s2:e1',
    ]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    store.dispose();
    api.close();
  });
  testWidgets('seek interval persists and appears as original-font numerals', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = NajdPreferences.instance;
    await prefs.setSeekSeconds(30);
    await prefs.load();
    expect(prefs.seekSeconds, 30);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerControls(
            isPlaying: true,
            isTv: false,
            playbackSpeed: 1,
            seekSeconds: prefs.seekSeconds,
            onRewind: () {},
            onForward: () {},
            onTogglePlay: () {},
            onPlaybackSpeedChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('30'), findsNWidgets(2));
    expect(
      tester.widget<Text>(find.text('30').first).style!.fontFamily,
      'ThmanyahSans',
    );
    await prefs.setSeekSeconds(10);
  });
}
