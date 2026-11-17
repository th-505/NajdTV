import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/work_sharing.dart';

const sender = '11111111-1111-4111-8111-111111111111';
const recipient = '22222222-2222-4222-8222-222222222222';
const shareId = '33333333-3333-4333-8333-333333333333';
const entry = WatchEntry(
  contentRef: 'tmdb:movie:42',
  contentId: '42',
  title: 'عمل مشارك',
  poster: '',
  type: 'movie',
  positionMs: 12000,
  durationMs: 60000,
  updatedAtMs: 1,
);
Map<String, dynamic> row() => {
  'id': shareId,
  'sender_id': sender,
  'recipient_id': recipient,
  'payload': entry.toJson(),
};
void main() {
  test(
    'sharing sends metadata and clock without granting library access',
    () async {
      final calls = <Map<String, dynamic>>[];
      final sharing = WorkSharing(
        rpc: (name, args) async {
          calls.add({'name': name, ...args});
          return shareId;
        },
      );
      await sharing.send(recipient, entry);
      expect(calls.single['name'], 'najd_share_work');
      expect(calls.single['p_recipient'], recipient);
      final payload = calls.single['p_payload'] as Map;
      expect(payload['position_ms'], 12000);
      expect(payload.containsKey('headers'), isFalse);
      expect(payload.containsKey('media_url'), isFalse);
      await expectLater(
        sharing.send('not-an-account', entry),
        throwsFormatException,
      );
      expect(calls.length, 1);
    },
  );
  test(
    'untrusted inbox payload never passes media credentials to navigation',
    () {
      final data = row();
      data['payload'] = {
        ...entry.toJson(),
        'headers': {'Cookie': 'fixture'},
      };
      expect(() => SharedWork.fromJson(data), throwsFormatException);
    },
  );
  for (final accept in [false, true]) {
    testWidgets(
      'receiver opens only after explicit successful consent: $accept',
      (tester) async {
        var pending = true;
        final responses = <bool>[];
        WatchEntry? opened;
        final bridge = WorkSharing(
          rpc: (name, args) async {
            if (name == 'najd_share_inbox') return pending ? [row()] : [];
            if (name == 'najd_share_respond') {
              pending = false;
              responses.add(args['p_accept'] as bool);
              return true;
            }
            throw StateError('unexpected RPC');
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: WorkShareInbox(
              transport: bridge,
              onOpen: (value) => opened = value,
              child: const Scaffold(body: Text('المكتبة الشخصية')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(opened, isNull);
        expect(find.text('وصلتك مشاركة'), findsOneWidget);
        await tester.tap(find.text(accept ? 'قبول وفتح' : 'رفض'));
        await tester.pumpAndSettle();
        expect(responses, [accept]);
        expect(opened?.contentRef, accept ? entry.contentRef : null);
        expect(find.text('المكتبة الشخصية'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        expect(responses.length, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'failed acknowledgement cannot open a work or change personal state',
    (tester) async {
      var opened = false;
      final bridge = WorkSharing(
        rpc: (name, args) async {
          if (name == 'najd_share_inbox') return [row()];
          throw StateError('network interrupted');
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkShareInbox(
            transport: bridge,
            onOpen: (_) => opened = true,
            child: const Scaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('قبول وفتح'));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'shared list reads accepted work without writing favorites or history',
    (tester) async {
      final calls = <String>[];
      final bridge = WorkSharing(
        rpc: (name, args) async {
          calls.add(name);
          return [row()];
        },
      );
      WatchEntry? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: SharedLibraryPage(
            transport: bridge,
            onOpen: (entry) => opened = entry,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.title));
      expect(opened?.contentRef, entry.contentRef);
      expect(calls, ['najd_shared_works']);
    },
  );
}
