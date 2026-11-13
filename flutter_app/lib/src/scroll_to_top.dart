import 'package:flutter/material.dart';

class ScrollToTopOverlay extends StatefulWidget {
  const ScrollToTopOverlay({super.key, required this.child});
  final Widget child;
  @override
  State<ScrollToTopOverlay> createState() => _ScrollToTopOverlayState();
}

class _ScrollToTopOverlayState extends State<ScrollToTopOverlay> {
  ScrollPosition? _position;
  bool _visible = false, _scheduled = false;
  bool _notification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.context == null) return false;
    final position = Scrollable.maybeOf(n.context!)?.position;
    if (position == null) return false;
    _position = position;
    final show = n.metrics.pixels > 600;
    if (show != _visible && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (mounted) setState(() => _visible = show);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _notification,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_visible)
              Positioned(
                left: MediaQuery.paddingOf(context).left + 8,
                bottom: MediaQuery.paddingOf(context).bottom + 144,
                child: FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'الرجوع للأعلى',
                  onPressed: () {
                    final p = _position;
                    if (p != null && p.hasContentDimensions) {
                      p.animateTo(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
          ],
        ),
      );
}
