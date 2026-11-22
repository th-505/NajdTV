import 'dart:async';

import 'package:flutter/material.dart';

import 'app_target.dart';
import 'app_theme.dart';
import 'browser_navigation_stub.dart'
    if (dart.library.js_interop) 'browser_navigation_web.dart';

class NajdIntro extends StatefulWidget {
  const NajdIntro({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
  });
  final Widget child;
  final Duration duration;
  @override
  State<NajdIntro> createState() => _NajdIntroState();
}

class _NajdIntroState extends State<NajdIntro> {
  Timer? _timer;
  late bool _visible;
  @override
  void initState() {
    super.initState();
    _visible =
        !BrowserNavigation().skipIntro &&
        !Uri.base.queryParameters.containsKey('ref') &&
        !Uri.base.fragment.contains('najd_link=');
    if (_visible) {
      BrowserNavigation().markIntroSeen();
      _timer = Timer(widget.duration, _dismiss);
    }
  }

  void _dismiss() {
    _timer?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: _visible,
        child: ExcludeFocus(
          excluding: _visible,
          child: TickerMode(enabled: !_visible, child: widget.child),
        ),
      ),
      if (_visible)
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final horizontal =
                    bounds.maxWidth >= 600 &&
                    bounds.maxWidth > bounds.maxHeight;
                final compact = bounds.maxHeight < 600;
                final markSize = compact
                    ? 88.0
                    : bounds.maxWidth < 500
                    ? 124.0
                    : 148.0;
                final brand = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/najd_logo.png',
                      width: markSize,
                      height: markSize,
                    ),
                    Text(
                      'نجد',
                      style: TextStyle(
                        fontSize: compact ? 32 : 44,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Najd TV',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                );
                final poetry = NajdGlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'أن كان رمحك بأول الخيل ملحوم\nفـ أنا برمحي حـامي نجد كلـه\n\nمن شافنا بالحلم يقعد من النوم\nومن شـافنا بالعـلم بطـنـه يهلـه',
                        key: const Key('najd-intro-poetry'),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: horizontal
                              ? (bounds.maxHeight < 400
                                    ? 20
                                    : compact
                                    ? 22
                                    : 26)
                              : 19,
                          height: 1.65,
                          fontFamily: NajdThemeExtension.of(context)
                              .serifFontFamily,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('محمد بن قرملة'),
                    ],
                  ),
                );
                return Padding(
                  padding: EdgeInsets.all(isTvTarget ? 24 : 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, space) => SingleChildScrollView(
                            key: const Key('najd-intro-content'),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: space.maxHeight,
                              ),
                              child: horizontal
                                  ? Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Expanded(flex: 3, child: brand),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 7, child: poetry),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        brand,
                                        const SizedBox(height: 24),
                                        poetry,
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: isTvTarget ? 64 : 52,
                        child: FilledButton.icon(
                          key: const Key('najd-intro-continue'),
                          autofocus: true,
                          onPressed: _dismiss,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('تخطي'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
    ],
  );
}
