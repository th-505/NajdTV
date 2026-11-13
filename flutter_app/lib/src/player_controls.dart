import 'package:flutter/material.dart';

import 'playback_policy.dart';
import 'najd_panels.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isTv,
    required this.playbackSpeed,
    required this.onRewind,
    required this.onTogglePlay,
    required this.onForward,
    required this.onPlaybackSpeedChanged,
    this.showSpeed = true,
    this.seekSeconds = 10,
  });

  final int seekSeconds;
  final bool showSpeed;
  final bool isPlaying;
  final bool isTv;
  final double playbackSpeed;
  final VoidCallback onRewind;
  final VoidCallback onTogglePlay;
  final VoidCallback onForward;
  final ValueChanged<double> onPlaybackSpeedChanged;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  final FocusNode _rewindFocus = FocusNode(debugLabel: 'player-rewind');
  final FocusNode _playFocus = FocusNode(debugLabel: 'player-play');
  final FocusNode _forwardFocus = FocusNode(debugLabel: 'player-forward');
  final FocusNode _speedFocus = FocusNode(debugLabel: 'player-speed');

  @override
  void dispose() {
    _rewindFocus.dispose();
    _playFocus.dispose();
    _forwardFocus.dispose();
    _speedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        !widget.isTv && MediaQuery.sizeOf(context).shortestSide < 600;
    final side = compact ? 52.0 : (widget.isTv ? 88.0 : 76.0);
    final sideHeight = compact ? 48.0 : (widget.isTv ? 80.0 : 72.0);
    final play = compact ? 58.0 : (widget.isTv ? 96.0 : 84.0);
    const outline = <Shadow>[
      Shadow(color: Colors.black, blurRadius: 1, offset: Offset(-1, 0)),
      Shadow(color: Colors.black, blurRadius: 1, offset: Offset(1, 0)),
      Shadow(color: Colors.black, blurRadius: 1, offset: Offset(0, -1)),
      Shadow(color: Colors.black, blurRadius: 1, offset: Offset(0, 1)),
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: compact ? 6 : 12,
          runSpacing: 8,
          children: [
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: Size(side, sideHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                iconSize: compact ? 27 : 36,
              ),
              key: const Key('player-rewind'),
              focusNode: _rewindFocus,
              tooltip: 'رجوع ${widget.seekSeconds} ثانية',
              onPressed: widget.onRewind,
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.replay, shadows: outline),
                  Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      '${widget.seekSeconds}',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        fontSize: compact ? 9 : 11,
                        color: Colors.white,
                        shadows: outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('player-play-toggle'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: Size(play, compact ? 54 : (widget.isTv ? 88 : 80)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                iconSize: compact ? 36 : 40,
              ),
              focusNode: _playFocus,
              autofocus: widget.isTv,
              tooltip: widget.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
              onPressed: widget.onTogglePlay,
              icon: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                shadows: outline,
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: Size(side, sideHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                iconSize: compact ? 27 : 36,
              ),
              key: const Key('player-forward'),
              focusNode: _forwardFocus,
              tooltip: 'تقديم ${widget.seekSeconds} ثانية',
              onPressed: widget.onForward,
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.rotate_right, shadows: outline),
                  Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      '${widget.seekSeconds}',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        fontSize: compact ? 9 : 11,
                        color: Colors.white,
                        shadows: outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showSpeed)
              NajdChoiceButton<double>(
                key: const Key('player-speed'),
                focusNode: _speedFocus,
                label: playbackSpeedLabel(widget.playbackSpeed),
                icon: Icons.speed,
                options: [
                  for (final speed in supportedPlaybackSpeeds)
                    NajdOption(
                      speed,
                      playbackSpeedLabel(speed),
                      key: Key('player-speed-${playbackSpeedLabel(speed)}'),
                      selected: speed == widget.playbackSpeed,
                      icon: Icons.speed,
                    ),
                ],
                onSelected: (speed) async =>
                    widget.onPlaybackSpeedChanged(speed),
              ),
          ],
        ),
      ),
    );
  }
}
