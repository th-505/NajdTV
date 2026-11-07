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
