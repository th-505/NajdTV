import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitv/src/api_client.dart';
import 'package:mitv/src/deferred_client_features.dart';

void main() {
  test('old servers hide optional actions; only advertised contracts are accepted and cached', () async {
    var calls = 0;
    final api = MitvApi(
      client: MockClient((r) async {
        calls++;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'features': ['quick_watch_v1', 'untrusted', 'short_drama_v1'],
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    expect(await api.clientFeatures(), {'quick_watch_v1', 'short_drama_v1'});
    await api.clientFeatures();
    expect(calls, 1);
    final old = MitvApi(
      client: MockClient((r) async => http.Response('not found', 404)),
    );
    addTearDown(old.close);
    expect(await old.clientFeatures(), isEmpty);
  });
  test('quick watch sends selected identity, never raw media; validates public server-owned capability URL', () async {
    final api = MitvApi(
      baseUri: Uri.parse('https://najdtv.onrender.com'),
      client: MockClient((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, '/api/v1/watch-links');
        expect(r.headers['authorization'], 'Bearer fixture-only');
        expect(jsonDecode(r.body), {
          'ref': 'source:observed-work',
          'season': 2,
          'episode': 9,
        });
        return http.Response(
          jsonEncode({
            'url': 'https://najdtv.onrender.com/watch/abcdefghijklmnopqrstuvwx/film.m3u8',
          }),
          201,
        );
      }),
    );
    addTearDown(api.close);
    expect(
      (await api.createQuickWatchLink(
        'source:observed-work',
        bearer: 'fixture-only',
        season: 2,
        episode: 9,
      )).path,
      endsWith('.m3u8'),
    );
    for (final url in [
      'https://evil.example/watch/abcdefghijklmnopqrstuvwx/film.m3u8',
      'https://najdtv.onrender.com/watch/short/film.m3u8',
      'https://najdtv.onrender.com/watch/abcdefghijklmnopqrstuvwx/film.m3u8?token=secret',
    ]) {
      final unsafe = MitvApi(
        client: MockClient(
          (r) async => http.Response(jsonEncode({'url': url}), 201),
        ),
      );
      addTearDown(unsafe.close);
      await expectLater(
        unsafe.createQuickWatchLink('source:work', bearer: 'fixture'),
        throwsA(isA<ApiException>()),
      );
    }
  });
  testWidgets(
    'optional menu entry appears only after the server declares readiness',
    (tester) async {
      var opened = 0;
      final api = MitvApi(
        client: MockClient(
          (r) async => http.Response(
            '{"status":"success","features":["short_drama_v1"]}',
            200,
          ),
        ),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ServerFeatureTile(
                  api: api,
                  feature: 'short_drama_v1',
                  title: 'الدراما القصيرة',
                  icon: Icons.video_collection,
                  onTap: () => opened++,
                ),
                ServerFeatureTile(
                  api: api,
                  feature: 'quick_watch_v1',
                  title: 'إنشاء رابط مشاهدة سريعة',
                  icon: Icons.link,
                  onTap: () => opened++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('الدراما القصيرة'), findsOneWidget);
      expect(find.text('إنشاء رابط مشاهدة سريعة'), findsNothing);
      await tester.tap(find.text('الدراما القصيرة'));
      expect(opened, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
