import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitv/src/api_client.dart';

void main() {
  for (final beta in [false, true]) {
    for (final name in ['Anakapalli', 'The Odyssey']) {
      test('$name provider movie requests actual playback in beta=$beta', () async {
        const source = 'source:akwam:aaaaaaaaaaaaaaaaaaaaaaaa';
        final ref = 'akwam:${base64Url.encode(utf8.encode('https://akwam.ss/movie/42/test')).replaceAll('=', '')}';
        final prefix = beta ? '/api/v1/browser/' : '/api/v1/harvest/';
        final calls = <String>[];
        final api = MitvApi(
          providerBrowser: beta,
          browserOrigin: beta ? ref : '',
          sourcePollInterval: Duration.zero,
          client: MockClient((request) async {
            final path = request.url.path;
            calls.add(path);
            Map<String, dynamic> data;
            if (path == '${prefix}request') {
              expect(request.method, 'POST');
              data = {'ref': source, 'state': 'ready'};
            } else if (path == '${prefix}status') {
              data = {
                'state': 'ready',
                'index_state': 'ready',
                'source_editions': [{'ref': source, 'available': true}],
              };
            } else if (path == '${prefix}work') {
              data = {'ref': source, 'title': name, 'type': 'movie', 'episodes': [], 'seasons': []};
            } else if (path == '${prefix}playback') {
              expect(request.url.queryParameters['ref'], source);
              expect(request.url.queryParameters['season'], '0');
              expect(request.url.queryParameters['episode'], '0');
              data = {
                'state': 'ready',
                'servers': [{
                  'url': 'https://cdn.example/movie.mp4',
                  'kind': 'direct',
                  'headers': <String, String>{},
                  'expires_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
                }],
              };
            } else {
              fail('Unexpected endpoint $path');
            }
            return http.Response(jsonEncode({'status': 'success', 'data': data}), 200);
          }),
        );
        addTearDown(api.close);
        final result = await api.resolvePlayback(ref);
        expect(result.hasDirectMedia, true);
        expect(calls, ['${prefix}request', '${prefix}status', '${prefix}work', '${prefix}playback']);
      });
    }
  }
}
