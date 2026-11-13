import 'package:mitv/src/player_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'TV player starts focused on play and D-Pad moves across controls',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              isTv: true,
              playbackSpeed: 1.0,
              onRewind: () {},
              onTogglePlay: () {},
              onForward: () {},
              onPlaybackSpeedChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final play = tester.widget<IconButton>(
        find.byKey(const Key('player-play-toggle')),
      );
      final forward = tester.widget<IconButton>(
        find.byKey(const Key('player-forward')),
      );
      final rewind = tester.widget<IconButton>(
        find.byKey(const Key('player-rewind')),
      );

      expect(play.focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(forward.focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(play.focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(rewind.focusNode?.hasFocus, isTrue);
    },
  );

  testWidgets('playback speed menu emits selected supported speed', (
    tester,
  ) async {
    double? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerControls(
            isPlaying: true,
            isTv: false,
            playbackSpeed: 1.0,
            onRewind: () {},
            onTogglePlay: () {},
            onForward: () {},
            onPlaybackSpeedChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('player-speed')));
    await tester.pumpAndSettle();
    final speed = find.byKey(const Key('player-speed-1.5x'));
    await tester.ensureVisible(speed);
    await tester.pumpAndSettle();
    await tester.tap(speed);
    await tester.pumpAndSettle();
    expect(selected, 1.5);
  });

  testWidgets('mobile player controls do not steal autofocus', (tester) async {
    tester.view.physicalSize = const Size(430, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerControls(
            isPlaying: true,
            isTv: false,
            playbackSpeed: 1.0,
            onRewind: () {},
            onTogglePlay: () {},
            onForward: () {},
            onPlaybackSpeedChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final play = tester.widget<IconButton>(
      find.byKey(const Key('player-play-toggle')),
    );
    expect(play.autofocus, isFalse);
    expect(play.style?.minimumSize?.resolve({})?.width, 58);
    final rewind = tester.widget<IconButton>(
      find.byKey(const Key('player-rewind')),
    );
    expect(rewind.style?.minimumSize?.resolve({})?.width, 52);
  });
}
