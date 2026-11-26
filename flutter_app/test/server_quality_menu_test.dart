import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/source_picker.dart';

void main() {
  testWidgets(
    'each server lists its own qualities and a fifth server remains selectable',
    (tester) async {
      final items = [
        for (var i = 1; i <= 4; i++)
          StreamSource.fromJson({
            'provider': 'شوف لايف',
            'server_id': 'server-$i',
            'server_name': 'سيرفر $i',
            'url': 'https://cdn.example/$i.m3u8',
            'format': 'hls',
            'quality_levels': [
              {'height': 360, 'bandwidth': 500000},
              {'height': 720, 'bandwidth': 2500000},
            ],
          }),
        StreamSource.fromJson({
          'provider': 'شوف لايف',
          'server_id': 'server-5',
          'server_name': 'سيرفر 5',
          'url': 'https://cdn.example/fixed.mp4',
          'format': 'mp4',
          'quality': '480p',
        }),
        StreamSource.fromJson({
          'provider': 'شوف لايف',
          'server_id': 'server-5',
          'server_name': 'سيرفر 5',
          'url': 'https://cdn.example/5.m3u8',
          'format': 'hls',
          'quality_levels': [
            {'height': 360, 'bandwidth': 500000},
            {'height': 720, 'bandwidth': 2500000},
          ],
        }),
        StreamSource.fromJson({
          'provider': 'شوف لايف',
          'server_id': 'server-1',
          'server_name': 'سيرفر 1',
          'url': 'https://cdn.example/hi.mp4',
          'format': 'mp4',
          'quality': '1080p',
        }),
      ];
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SourcePickerButton(
              sources: items,
              selected: 0,
              onSelected: (value) async => selected = value,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('سيرفرات التشغيل'));
      await tester.pumpAndSettle();
      expect(find.text('سيرفر 1'), findsOneWidget);
      expect(
        find.textContaining(
          'المصدر: شوف لايف · تلقائي حسب الشبكة، 360p، 720p، 1080p',
        ),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(tester.element(find.text('سيرفر 5')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سيرفر 5'));
      await tester.pumpAndSettle();
      expect(selected, 5);
    },
  );
}
