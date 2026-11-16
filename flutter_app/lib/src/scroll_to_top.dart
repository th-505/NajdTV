import 'package:flutter/material.dart';

class ScrollToTopNavigatorObserver extends NavigatorObserver {
  static final revision = ValueNotifier<int>(0);
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      revision.value++;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      revision.value++;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      revision.value++;
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      revision.value++;
}

class ScrollToTopOverlay extends StatefulWidget {
  const ScrollToTopOverlay({super.key, required this.child});
  final Widget child;
  @override
  State<ScrollToTopOverlay> createState() => _ScrollToTopOverlayState();
}

class _ScrollToTopOverlayState extends State<ScrollToTopOverlay> {
  ScrollPosition? _position;
  bool _visible = false, _scheduled = false;
  ModalRoute<dynamic>? _route;
  @override
  void initState() {
    super.initState();
    ScrollToTopNavigatorObserver.revision.addListener(_reset);
  }

  void _reset() {
    _position = null;
    _route = null;
    _visible = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ScrollToTopNavigatorObserver.revision.removeListener(_reset);
    super.dispose();
  }

  bool _notification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.context == null) return false;
    final position = Scrollable.maybeOf(n.context!)?.position;
    if (position == null) return false;
    final route = ModalRoute.of(n.context!);
    if (route != null && !route.isCurrent) return false;
    _route = route;
    _position = position;
    final show = n.metrics.maxScrollExtent > 0 && n.metrics.pixels > 600;
    if (show != _visible && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (mounted) {
          final p = _position;
          setState(
            () => _visible =
                p != null &&
                p.hasContentDimensions &&
                (_route == null || _route!.isCurrent) &&
                p.maxScrollExtent > 0 &&
                p.pixels > 600,
          );
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Overlay.wrap(
    child: NotificationListener<ScrollNotification>(
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
                  if (p != null &&
                      p.hasContentDimensions &&
                      (_route == null || _route!.isCurrent)) {
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
    ),
  );
}
