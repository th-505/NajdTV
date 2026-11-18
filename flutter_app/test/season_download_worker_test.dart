import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitv/src/api_client.dart';
import 'package:mitv/src/download_service.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/season_download_queue.dart';

const ref = 'source:ahwak:aaaaaaaaaaaaaaaaaaaaaaaa';
const item = CatalogItem(
  id: ref,
  ref: ref,
  title: 'Observed work',
  poster: '',
  type: 'series',
  season: 1,
);
void main() {
  test('persistent season worker exhausts index pages and downloads only observed episode numbers', () async {
    final root = await Directory.systemTemp.createTemp('najd-season-worker-');
    final files = await Directory('${root.path}/media').create();
    final queue = SeasonDownloadQueue(directory: () async => root);
    final offsets = <String>[], episodes = <String>[];
    const bytes = [
      0,
      0,
      0,
      16,
      102,
      116,
      121,
      112,
      105,
      115,
      111,
      109,
      0,
      0,
      0,
      0,
    ];
    MitvApi api(CatalogItem _) => MitvApi(
      client: MockClient((request) async {
        Map<String, dynamic> data;
        if (request.url.path.endsWith('/work')) {
          final offset = request.url.queryParameters['offset']!;
          offsets.add(offset);
          data = {
            'ref': ref,
            'source_work_ref': ref,
            'title': 'Observed work',
            'type': 'series',
            'source_index_authoritative': true,
            'source_index_state': 'ready',
            'episodes': [
              for (final n in offset == '0' ? [1, 4] : [9])
                {
                  'ref': '$ref:s1:e$n',
                  'title': 'Episode $n',
                  'episode_number': n,
                  'season_number': 1,
                  'watch_available': true,
                },
            ],
            'episode_pagination': {
              'has_more': offset == '0',
              'next_offset': offset == '0' ? 2 : null,
            },
          };
        } else if (request.url.path.endsWith('/playback')) {
          final number = request.url.queryParameters['episode'];
          episodes.add(number!);
          data = {
            'state': 'ready',
            'servers': [
              {
                'url': 'https://cdn.example/$number.mp4',
                'kind': 'direct',
                'provider_id': 'ahwak',
                'headers': <String, String>{},
                'expires_at': DateTime.now()
                    .add(const Duration(minutes: 5))
                    .toIso8601String(),
              },
            ],
          };
        } else {
          throw StateError('unexpected fixture route ${request.url.path}');
        }
        return http.Response(
          jsonEncode({'status': 'success', 'data': data}),
          200,
        );
      }),
    );
    try {
      await queue.add('owner', [
        SeasonDownloadJob(
          id: SeasonDownloadJob.key('owner', ref, season: 1),
          ref: ref,
          title: 'Index',
          item: item,
          indexSeason: 1,
          indexOffset: 0,
        ),
      ]);
      await queue.run(
        'owner',
        seasonDownloadWorker(
          'owner',
          tasks: queue,
          apiFactory: api,
          downloadsFactory: () => DownloadService(
            directoryProvider: () async => files,
            client: MockClient(
              (_) async => http.Response.bytes(
                bytes,
                200,
                headers: {'content-type': 'video/mp4', 'content-length': '16'},
              ),
            ),
          ),
        ),
      );
      expect(offsets, ['0', '2']);
      expect(episodes, ['1', '4', '9']);
      expect(
        queue.jobsFor('owner').every((row) => row.state == 'completed'),
        isTrue,
      );
      expect(await files.list().length, 3);
      await for (final entry in root.list(recursive: true)) {
        if (entry is File && entry.path.endsWith('.json')) {
          final metadata = await entry.readAsString();
          expect(metadata, isNot(contains('cdn.example')));
          expect(metadata, isNot(contains('headers')));
        }
      }
    } finally {
      queue.dispose();
      await root.delete(recursive: true);
    }
  });
}
