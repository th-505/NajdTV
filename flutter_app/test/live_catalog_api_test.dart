import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitv/src/api_client.dart';

http.Response reply(Object value) =>
    http.Response.bytes(utf8.encode(jsonEncode(value)), 200);
void main() {
  test('concurrent public catalogs coalesce and clear refetches', () async {
    var calls = 0;
    final gate = Completer<void>();
    final api = MitvApi(
      useEdge: false,
      client: MockClient((request) async {
        calls++;
        await gate.future;
        return reply({
          'status': 'success',
          'data': [
            {'id': 'one', 'ref': 'tmdb:movie:1', 'title': 'Fixture'},
          ],
        });
      }),
    );
    final requests = List.generate(
      20,
      (_) => api.category('catalog:movie:all'),
    );
    gate.complete();
    final rows = await Future.wait(requests);
    expect(calls, 1);
    expect(() => rows.first.clear(), throwsUnsupportedError);
    expect((await api.category('catalog:movie:all')).length, 1);
    expect(calls, 1);
    api.clearBrowsingCache();
    await api.category('catalog:movie:all');
    expect(calls, 2);
    api.close();
  });
  test('failed catalogs retry instead of caching errors', () async {
    var calls = 0;
    final api = MitvApi(
      useEdge: false,
      client: MockClient((request) async {
        calls++;
        if (calls == 1) return http.Response('unavailable', 503);
        return reply({'status': 'success', 'data': []});
      }),
    );
    await expectLater(
      api.category('catalog:movie:all'),
      throwsA(isA<ApiException>()),
    );
    expect(await api.category('catalog:movie:all'), isEmpty);
    expect(calls, 2);
    api.close();
  });
  test('live playback registers direct media and opens fresh sessions on the same server', () async {
    var opens = 0;
    final api = MitvApi(
      useEdge: true,
      client: MockClient((request) async {
        expect(request.url.host, 'najdtv.onrender.com');
        if (request.url.path.endsWith('/catalog')) {
          expect(request.url.queryParameters['group'], 'sports');
          expect(request.url.queryParameters['page'], '2');
          return reply({
            'status': 'success',
            'data': [],
            'pagination': {'has_more': false},
          });
        }
        expect(request.url.path, '/api/v1/live/playback');
        opens++;
        final expiry = DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String();
        return reply({
          'status': 'success',
          'data': {
            'title': 'Fixture',
            'media_path': 'https://cdn.example.com/live.m3u8',
            'media_type': 'application/vnd.apple.mpegurl',
            'playback_mode': 'direct',
            'expires_at': expiry,
            'media_sources': [
              {
                'url': 'https://cdn.example.com/live.m3u8',
                'media_type': 'application/vnd.apple.mpegurl',
                'playback_mode': 'direct',
                'expires_at': expiry,
              },
            ],
          },
        });
      }),
    );
    await api.liveChannels('sports', page: 2);
    final first = await api.resolvePlayback(
      'live:iptv-org:sa:aaaaaaaaaaaaaaaaaaaaaaaa',
    );
    expect(
      api.mediaUri(first.mediaPath, playbackMode: first.playbackMode).scheme,
      'https',
    );
    await api.resolvePlayback('live:iptv-org:sa:aaaaaaaaaaaaaaaaaaaaaaaa');
    expect(opens, 2);
    api.close();
  });
}
