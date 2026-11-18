import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitv/src/api_client.dart';
import 'package:mitv/src/details_page.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/models.dart';

const work = 'source:ahwak:aaaaaaaaaaaaaaaaaaaaaaaa';
http.Response reply(Map<String, dynamic> data) =>
    http.Response(jsonEncode({'status': 'success', 'data': data}), 200);
void main() {
  testWidgets(
    'a growing source index continues after the currently last page and stops at completion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalLibraryStore.create();
      final offsets = <String>[];
      final api = MitvApi(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/harvest/work');
          final offset = request.url.queryParameters['offset'] ?? '0';
          offsets.add(offset);
          final next = offset == '1';
          return reply({
            'ref': work,
            'source_work_ref': work,
            'title': 'Observed work',
            'type': 'series',
            'source_index_authoritative': true,
            'source_index_state': next ? 'ready' : 'indexing',
            'browser_progress': {'partial': !next},
            'available_seasons': [1],
            'episodes': [
              {
                'ref': '$work:s1:e${next ? 8 : 3}',
                'episode_number': next ? 8 : 3,
                'season_number': 1,
                'title': next
                    ? 'Observed episode eight'
                    : 'Observed episode three',
                'watch_available': true,
              },
            ],
            'episode_pagination': {'has_more': false},
          });
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DetailsPage(
            api: api,
            store: store,
            item: const CatalogItem(
              id: work,
              ref: work,
              title: 'Observed work',
              poster: '',
              type: 'series',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(offsets, ['0']);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(offsets, ['0', '1']);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(offsets, [
        '0',
        '1',
      ], reason: 'completed indexes must stop polling');
      await tester.pumpWidget(const SizedBox());
      api.close();
    },
  );
  test('confirmed source preview is readable while indexing, without waiting for unrelated pages', () async {
    var statusCalls = 0;
    final api = MitvApi(
      providerBrowser: true,
      sourcePollInterval: Duration.zero,
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/request')) {
          return reply({'ref': work, 'state': 'running'});
        }
        if (path.endsWith('/status')) {
          statusCalls++;
          return reply({
            'state': 'running',
            'index_state': 'indexing',
            'source_editions': [
              {'ref': work, 'available': true, 'index_preview_ready': true},
            ],
          });
        }
        if (path.endsWith('/work')) {
          return reply({
            'ref': work,
            'source_work_ref': work,
            'title': 'Observed source title',
            'type': 'movie',
            'source_index_state': 'indexing',
            'browser_progress': {'partial': true},
            'episodes': [],
          });
        }
        throw StateError('unexpected fixture route');
      }),
    );
    final details = await api.details('ahwak:fixture');
    expect(statusCalls, 1);
    expect(details.sourceIndexState, 'indexing');
    expect(details.sourceIndexPartial, isTrue);
    api.close();
  });
}
