import 'src/app_theme.dart';
import 'src/deferred_client_features.dart';
import 'src/season_download_queue.dart';
import 'src/season_download_queue_ui.dart';
import 'src/work_sharing.dart';
import 'src/quick_unlock_ui.dart';
import 'src/remote_bindings.dart';
import 'src/live_channels_panel.dart';
import 'src/catalog_collection_defs.dart';
import 'src/catalog_shelf.dart';
import 'src/scroll_to_top.dart';
import 'src/episode_preferences.dart';
import 'src/browser_content_route.dart';
import 'src/browser_navigation_stub.dart'
    if (dart.library.js_interop) 'src/browser_navigation_web.dart';
import 'src/catalog_collections_page.dart';
import 'src/playback_handoff.dart';
import 'src/service_checks_page.dart';
import 'src/playback_resume.dart';
import 'src/app_preferences.dart';
import 'src/provider_browser_page.dart';
import 'src/search_work_groups.dart';
import 'src/search_scoring.dart';
import 'src/account_settings.dart';
import 'src/stitch_design.dart';
import 'src/najd_panels.dart';
import 'src/product_version.dart';
import 'src/najd_theme.dart';

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/ui_contract.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/api_client.dart';
import 'src/app_target.dart';
import 'src/details_page.dart';
import 'src/download_library_section.dart';
import 'src/library_store.dart';
import 'src/match_player_page.dart';
import 'src/models.dart';
import 'src/adaptive_viewport.dart';
import 'src/focus_highlight.dart';
import 'src/player_page.dart';
import 'src/virtual_pointer.dart';
import 'src/unified_media.dart';
import 'src/storage_cleanup.dart';
import 'src/cloud_library.dart';

bool _fontLicensesRegistered = false;
const _brandAccent = NajdUi.accent;
const _brandAccentMuted = NajdUi.accentLight;

void main() => runApp(const NajdApp());

class NajdApp extends StatefulWidget {
  const NajdApp({super.key});
  @override
  State<NajdApp> createState() => _NajdAppState();
}

class _NajdAppState extends State<NajdApp> with WidgetsBindingObserver {
  late final Future<LocalLibraryStore> storeFuture = LocalLibraryStore.create();
  String _queueOwner = '';
  LocalLibraryStore? _queueStore;
  VoidCallback? _queueOwnerListener;
  final _pointer = VirtualPointerController();
  final _browserObserver = BrowserRouteObserver();
  final _scrollObserver = ScrollToTopNavigatorObserver();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final Future<CloudLibrarySync?> _cloudFuture;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(NajdPreferences.instance.load());
    unawaited(RemoteBindings.instance.load());
    if (!_fontLicensesRegistered) {
      _fontLicensesRegistered = true;
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks([
          'Noto Sans Arabic',
        ], await rootBundle.loadString('assets/fallback/OFL.txt'));
      });
    }
    unawaited(NajdAppearance.instance.load());
    unawaited(loadPrivateNajdFonts());
    _cloudFuture = storeFuture
        .then(CloudLibrarySync.startDefault)
        .catchError((Object _, StackTrace _) => null);
    unawaited(
      _cloudFuture
          .then((_) async {
            final store = await storeFuture;
            if (!mounted) return;
            void followOwner() {
              if (_queueOwner == store.ownerScope) return;
              _queueOwner = store.ownerScope;
              unawaited(resumeSeasonDownloads(store).catchError((Object _) {}));
            }

            _queueStore = store;
            _queueOwnerListener = followOwner;
            store.addListener(followOwner);
            followOwner();
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_queueOwnerListener != null) {
      _queueStore?.removeListener(_queueOwnerListener!);
    }
    _pointer.dispose();
    unawaited(CloudLibrarySync.closeDefault());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _queueStore != null) {
      unawaited(resumeSeasonDownloads(_queueStore!).catchError((Object _) {}));
    }
  }

  // Web section URLs are handled by BrowserNavigation. Do not let the
  // legacy Navigator push a second Shell for the same popstate event.
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => kIsWeb;

  @override
  Future<bool> didPopRoute() async => kIsWeb
      ? true
      : await (_navigatorKey.currentState?.maybePop() ?? Future.value(false));

  Widget _navigationTree() => Navigator(
    key: _navigatorKey,
    // The URL/history bridge owns browser entries. Navigator's default single
    // entry mode unwinds existing multi-entry history on a page refresh.
    reportsRouteUpdateToEngine: false,
    observers: [_browserObserver, _scrollObserver],
    onGenerateRoute: (settings) =>
        MaterialPageRoute(settings: settings, builder: _buildHome),
  );

  Widget _buildHome(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: FutureBuilder<LocalLibraryStore>(
      future: storeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        void openSharedEntry(WatchEntry entry) {
          final api = MitvApi();
          final scoped = entry.catalogItem.discoveryScope == 'beta'
              ? api.browserSession(origin: entry.catalogItem)
              : api;
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => PlayerPage(
                    api: scoped,
                    store: snapshot.data!,
                    item: entry.catalogItem,
                    title: entry.title,
                    sourceRef: historyPlaybackReference(entry),
                    episodeId: entry.episodeId,
                    episodeNumber: entry.episodeNumber,
                    initialPosition: Duration(milliseconds: entry.positionMs),
                    watchEntry: entry,
                  ),
                ),
              )
              .whenComplete(() {
                if (!identical(scoped, api)) scoped.close();
                api.close();
              });
        }

        return WorkShareInbox(
          onOpen: openSharedEntry,
          child: PlaybackInbox(
            onOpen: openSharedEntry,
            child: Shell(store: snapshot.data!, pointer: _pointer),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NajdAppearance.instance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: NajdUi.brand,
        theme: NajdTheme.light(isTv: isTvTarget),
        darkTheme: NajdTheme.dark(isTv: isTvTarget),
        themeMode: NajdAppearance.instance.mode,
        builder: (context, child) => ScrollToTopOverlay(
          child: DeviceUnlockGate(
            storeFuture: storeFuture,
            child: NajdTvViewport(
              child: NajdIntro(
                child: isTvTarget
                    ? VirtualPointerScope(
                        controller: _pointer,
                        child: FocusScrollScope(child: _navigationTree()),
                      )
                    : _navigationTree(),
              ),
            ),
          ),
        ),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}

void openDetails(
  BuildContext context,
  MitvApi api,
  LocalLibraryStore store,
  CatalogItem item,
) {
  if (item.type == 'live' && item.ref.startsWith('live:iptv-org:')) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          api: api,
          store: store,
          item: item,
          title: item.title,
          sourceRef: item.ref,
          isLive: true,
        ),
      ),
    );
    return;
  }
  final scopedApi = item.discoveryScope == 'beta' && !api.providerBrowser
      ? api.browserSession(origin: item)
      : api;
  scopedApi.rememberIdentity(item);
  Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (_) => DetailsPage(api: scopedApi, store: store, item: item),
        ),
      )
      .whenComplete(() {
        if (!identical(scopedApi, api)) scopedApi.close();
      });
}

void openHistoryEntry(
  BuildContext context,
  MitvApi api,
  LocalLibraryStore store,
  WatchEntry entry,
) {
  final scopedApi =
      entry.catalogItem.discoveryScope == 'beta' && !api.providerBrowser
      ? api.browserSession(origin: entry.catalogItem)
      : api;
  Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (_) => PlayerPage(
            api: scopedApi,
            store: store,
            item: entry.catalogItem,
            title: entry.title,
            sourceRef: historyPlaybackReference(entry),
            episodeId: entry.episodeId,
            episodeNumber: entry.episodeNumber,
            watchEntry: entry,
          ),
        ),
      )
      .whenComplete(() {
        if (!identical(scopedApi, api)) scopedApi.close();
      });
}

class _NajdMark extends StatelessWidget {
  const _NajdMark({this.size = 38});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/najd/mark.png',
    width: size,
    height: size,
    semanticLabel: 'نجد',
  );
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _NajdMark(size: 38),
      SizedBox(width: 10),
      Flexible(
        child: Text(
          NajdUi.brand,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
      ),
    ],
  );
}

class ConfiguredTvChannel {
  const ConfiguredTvChannel({
    required this.title,
    required this.package,
    required this.sourceRef,
  });
  final String title;
  final String package;
  final String sourceRef;
}

class Shell extends StatefulWidget {
  const Shell({
    super.key,
    required this.store,
    this.api,
    this.pointer,
    this.channels = const [],
    this.clearCache,
    this.clearDownloads,
  });
  final LocalLibraryStore store;
  final MitvApi? api;
  final VirtualPointerController? pointer;
  final List<ConfiguredTvChannel> channels;
  final Future<void> Function()? clearCache;
  final Future<void> Function()? clearDownloads;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _browserNavigation = BrowserNavigation();
  int index = 0;
  DateTime? _lastRootBack;

  void _handleTvBack() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _closeNavigation();
    } else if (index != 0) {
      _selectPage(0);
      _lastRootBack = null;
    } else {
      final now = DateTime.now();
      if (_lastRootBack != null &&
          now.difference(_lastRootBack!) < const Duration(seconds: 2)) {
        if (!kIsWeb) SystemNavigator.pop();
      } else {
        _lastRootBack = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اضغط رجوع مرة أخرى للخروج'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _drawerOpen = false;
  bool _headerVisible = true;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _menuFocus = FocusNode(debugLabel: 'open-navigation');
  final _navFocus = List.generate(
    NajdUi.pageIds.length + 1,
    (i) => FocusNode(
      debugLabel:
          'nav-${i < NajdUi.pageIds.length ? NajdUi.pageIds[i] : 'provider-beta'}',
    ),
  );
  int _pageGeneration = 0;
  late final MitvApi api;
  late final bool _ownsApi;
  final _pages = List<Widget?>.filled(NajdUi.pageIds.length, null);
  @override
  void initState() {
    super.initState();
    final initialBrowserPage = _browserNavigation.page;
    final restoredPage = NajdUi.pageIds.indexOf(initialBrowserPage);
    if (restoredPage >= 0) index = restoredPage;
    _browserNavigation.listen(_applyBrowserPage);
    _ownsApi = widget.api == null;
    api = widget.api ?? MitvApi();
    final restoringContent = ['title', 'player'].contains(initialBrowserPage);
    if (!restoringContent) _pages[index] = _createPage(index);
    if (restoringContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _browserNavigation.ready;
        if (mounted) _applyBrowserPage(initialBrowserPage);
      });
    }
    if (kIsWeb && Uri.base.fragment.contains('najd_link=')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NajdAccountPage(store: widget.store),
            ),
          );
        }
      });
    }
    final ref = kIsWeb && !['title', 'player'].contains(_browserNavigation.page)
        ? Uri.base.queryParameters['ref'] ?? ''
        : '';
    if (['alooy:', '3isk:', 'legacy:', 'laroza:'].any(ref.startsWith)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          openDetails(
            context,
            api,
            widget.store,
            CatalogItem(
              id: ref,
              title: 'التفاصيل',
              poster: '',
              type: 'series',
              ref: ref,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _browserNavigation.dispose();
    _menuFocus.dispose();
    for (final node in _navFocus) {
      node.dispose();
    }
    if (_ownsApi) api.close();
    super.dispose();
  }

  void _applyBrowserPage(String page) {
    if (!mounted) return;
    final target = _browserNavigation.currentRoute;
    final navigator = Navigator.of(context);
    var found = false;
    _browserNavigation.applyHistory(
      () => navigator.popUntil((route) {
        if (_browserNavigation.matchesRoute(route, target)) {
          found = true;
          return true;
        }
        return route.isFirst;
      }),
    );
    if (found) return;
    final panel = _browserNavigation.restorePanel(target);
    if (panel != null) {
      navigator.push(panel);
      return;
    }
    final section = NajdUi.pageIds.indexOf(page.isEmpty ? 'home' : page);
    if (section >= 0) {
      _selectPage(section, updateUrl: false);
      return;
    }
    final content = BrowserContentRoute.parse(target);
    if (content == null) {
      _selectPage(0, updateUrl: false);
      _browserNavigation.push('home', replace: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط العمل غير صالح. يمكنك البحث عنه من جديد.'),
        ),
      );
      return;
    }
    final scoped = content.item.discoveryScope == 'beta'
        ? api.browserSession(origin: content.item)
        : api;
    scoped.rememberIdentity(content.item);
    navigator
        .push(
          MaterialPageRoute<void>(
            builder: (_) => content.page == 'player'
                ? PlayerPage(
                    api: scoped,
                    store: widget.store,
                    item: content.item,
                    title: content.item.title,
                    isLive: content.item.type == 'live',
                    sourceRef: content.sourceRef,
                    episodeId: content.episodeId,
                    episodeNumber: content.episodeNumber,
                    providerCatalogRef: content.providerCatalogRef,
                  )
                : DetailsPage(
                    api: scoped,
                    store: widget.store,
                    item: content.item,
                  ),
          ),
        )
        .whenComplete(() {
          if (!identical(scoped, api)) scoped.close();
        });
  }

  Future<void> _clearBrowsingCache() async {
    await widget.clearCache?.call();
    api.clearBrowsingCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!mounted) return;
    setState(() {
      _pageGeneration++;
      for (var i = 0; i < _pages.length; i++) {
        if (i != 8) _pages[i] = null;
      }
      // Settings owns the confirmation/action in progress. If navigation
      // changed while it was awaiting, recreate only the newly visible tab.
      if (index != 8) _pages[index] = _createPage(index);
    });
  }

  Future<void> _clearDownloads() async {
    if (widget.clearDownloads != null) {
      await widget.clearDownloads!();
    } else {
      await StorageCleanup.clearDownloads();
    }
  }

  Widget _createPage(int page) => switch (page) {
    0 => HomePage(api: api, store: widget.store, onNavigate: _selectPage),
    1 => CatalogPage(
      api: api,
      store: widget.store,
      title: 'الأفلام',
      categoryId: 'catalog:movie:all',
      collections: true,
      mediaKind: 'movie',
      unified: true,
    ),
    2 => CatalogPage(
      api: api,
      store: widget.store,
      title: 'المسلسلات',
      categoryId: 'catalog:tv:all',
      collections: true,
      mediaKind: 'series',
      unified: true,
    ),
    3 => CatalogPage(
      api: api,
      store: widget.store,
      title: 'الأنمي',
      categoryId: 'catalog:anime:movie',
      collections: true,
      mediaKind: 'anime',
      unified: true,
    ),
    4 => CatalogPage(
      api: api,
      store: widget.store,
      title: 'التركي',
      categoryId: 'catalog:turkish:tv',
      collections: true,
      mediaKind: 'turkish',
      unified: true,
    ),
    5 => SearchPage(api: api, store: widget.store),
    6 => LivePage(api: api, store: widget.store, channels: widget.channels),
    7 => LibraryPage(api: api, store: widget.store),
    8 => SettingsPage(
      api: api,
      store: widget.store,
      pointer: widget.pointer,
      clearCache: _clearBrowsingCache,
      clearDownloads:
          widget.clearDownloads != null || StorageCleanup.downloadsSupported
          ? _clearDownloads
          : null,
    ),
    _ => throw RangeError.index(page, _pages),
  };
  void _selectPage(int value, {bool updateUrl = true}) {
    if (index == value && _pages[value] != null) return;
    if (updateUrl) _browserNavigation.push(NajdUi.pageIds[value]);
    setState(() {
      _pages[value] ??= _createPage(value);
      index = value;
      _headerVisible = true;
    });
  }

  void _closeNavigation() {
    _scaffoldKey.currentState?.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _menuFocus.canRequestFocus) _menuFocus.requestFocus();
    });
  }

  Widget _navigation({required bool drawer}) => Material(
    key: const Key('tatv-right-sidebar'),
    color: isTvTarget
        ? Colors.transparent
        : Theme.of(context).colorScheme.surface,
    child: _NavigationSurface(
      child: SafeArea(
        child: SizedBox(
          width: 232,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: _BrandTitle()),
                    if (drawer)
                      IconButton(
                        tooltip: 'إغلاق القائمة',
                        onPressed: _closeNavigation,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: ListView.builder(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: NajdUi.pageIds.length + 1,
                    itemBuilder: (context, i) {
                      if (i >= NajdUi.pageIds.length) {
                        return Column(
                          children: [
                            ServerFeatureTile(
                              api: api,
                              feature: 'short_drama_v1',
                              title: 'الدراما القصيرة',
                              icon: Icons.video_collection_outlined,
                              onTap: () {
                                if (drawer) _closeNavigation();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => Scaffold(
                                      appBar: AppBar(
                                        title: const Text('الدراما القصيرة'),
                                      ),
                                      body: CatalogPage(
                                        api: api,
                                        store: widget.store,
                                        title: 'الدراما القصيرة',
                                        categoryId: 'catalog:short-drama:all',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              key: const Key('nav-provider-beta'),
                              focusNode: _navFocus[i],
                              minTileHeight: isTvTarget ? 64 : 48,
                              leading: const Icon(Icons.science_outlined),
                              title: const Text('تصفح المزود — تجريبي'),
                              subtitle: const Text('ميزة تحت التجربة'),
                              onTap: () {
                                if (drawer) _closeNavigation();
                                if (!NajdPreferences.instance.providerBeta) {
                                  _selectPage(8);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'فعّل تصفح المزود التجريبي من الإعدادات',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProviderBrowserPage(
                                      api: api,
                                      store: widget.store,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return FocusTraversalOrder(
                        order: NumericFocusOrder(i.toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: (node, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowDown ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.arrowUp) {
                                final next =
                                    (i +
                                        (event.logicalKey ==
                                                LogicalKeyboardKey.arrowDown
                                            ? 1
                                            : -1)) %
                                    _navFocus.length;
                                _navFocus[next].requestFocus();
                                return KeyEventResult.handled;
                              }
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.select) {
                                _selectPage(i);
                                if (drawer) _closeNavigation();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: FocusHighlight(
                              child: TextButton(
                                key: ValueKey('nav-${NajdUi.pageIds[i]}'),
                                focusNode: _navFocus[i],
                                autofocus: !drawer && i == index,
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerRight,
                                  minimumSize: Size.fromHeight(
                                    isTvTarget ? 64 : 50,
                                  ),
                                  foregroundColor: i == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  backgroundColor: i == index
                                      ? _brandAccent.withAlpha(26)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  _selectPage(i);
                                  if (drawer) _closeNavigation();
                                },
                                child: Row(
                                  children: [
                                    Icon(NajdUi.icons[i]),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(NajdUi.labels[i])),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _header() => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (isTvTarget ||
                  MediaQuery.sizeOf(context).width < NajdUi.sidebarBreakpoint)
                IconButton(
                  key: const Key('tatv-open-navigation'),
                  focusNode: _menuFocus,
                  tooltip: 'القائمة',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              const Expanded(child: Center(child: _BrandTitle())),
              const SizedBox(width: 48),
            ],
          ),
          if (index == 0 || index == 1 || index == 2 || index == 3)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final filter in [
                    (0, 'الكل'),
                    (1, 'أفلام'),
                    (2, 'مسلسلات'),
                    (3, 'أنمي'),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ChoiceChip(
                        label: Text(filter.$2),
                        selected: index == filter.$1,
                        onSelected: (_) => _selectPage(filter.$1),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AdaptiveViewport(
      builder: (context, viewport) {
        final content = IndexedStack(
          index: index,
          children: List.generate(_pages.length, (page) {
            final child = _pages[page];
            return child == null
                ? const SizedBox.shrink()
                : KeyedSubtree(
                    key: ValueKey((page, page == 8 ? 0 : _pageGeneration)),
                    child: ExcludeFocus(
                      excluding: page != index,
                      child: TickerMode(enabled: page == index, child: child),
                    ),
                  );
          }),
        );
        final side =
            !isTvTarget && viewport.size.width >= NajdUi.sidebarBreakpoint;
        final browsing = NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical &&
                (notification.scrollDelta?.abs() ?? 0) > 3) {
              final visible =
                  notification.scrollDelta! < 0 ||
                  notification.metrics.pixels <= 0;
              if (visible != _headerVisible) {
                setState(() => _headerVisible = visible);
              }
            }
            return false;
          },
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _headerVisible ? _header() : const SizedBox.shrink(),
              ),
              Expanded(child: content),
            ],
          ),
        );
        return PopScope(
          canPop: !isTvTarget,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && isTvTarget) _handleTvBack();
          },
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) {
                    if (isTvTarget) {
                      _handleTvBack();
                      return null;
                    }
                    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                      _closeNavigation();
                    }
                    return null;
                  },
                ),
              },
              child: Scaffold(
                key: _scaffoldKey,
                // In RTL, the start drawer opens on the physical right.
                drawer: side
                    ? null
                    : Drawer(
                        width: isTvTarget ? 340 : 272,
                        child: _navigation(drawer: true),
                      ),
                onDrawerChanged: (open) {
                  setState(() => _drawerOpen = open);
                  if (open) {
                    _navFocus[index].requestFocus();
                  } else if (!side) {
                    _menuFocus.requestFocus();
                  }
                },
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.startFloat,
                floatingActionButton: !side && !_headerVisible
                    ? FloatingActionButton.small(
                        key: const Key('tatv-open-navigation'),
                        focusNode: _menuFocus,
                        tooltip: 'القائمة',
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        child: const Icon(Icons.menu),
                      )
                    : null,
                drawerScrimColor: Colors.black.withAlpha(160),
                bottomNavigationBar: side || isTvTarget
                    ? null
                    : NavigationBar(
                        key: const Key('najd-bottom-navigation'),
                        selectedIndex: !NajdUi.bottomPages.contains(index)
                            ? 0
                            : NajdUi.bottomPages.indexOf(index),
                        onDestinationSelected: (value) =>
                            _selectPage(NajdUi.bottomPages[value]),
                        destinations: [
                          for (final page in NajdUi.bottomPages)
                            NavigationDestination(
                              icon: Icon(NajdUi.icons[page]),
                              selectedIcon: Icon(
                                page == 0
                                    ? Icons.home_rounded
                                    : NajdUi.icons[page],
                              ),
                              label: page == 7 ? 'قائمتي' : NajdUi.labels[page],
                            ),
                        ],
                      ),
                body: SafeArea(
                  child: Stack(
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          if (side) ...[
                            _navigation(drawer: false),
                            const VerticalDivider(width: 1),
                          ],
                          Expanded(child: browsing),
                        ],
                      ),
                      if (isTvTarget && _drawerOpen)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: const ColoredBox(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.api,
    required this.store,
    this.onNavigate,
    this.refreshInterval = const Duration(minutes: 10),
    this.now,
  });
  final Duration refreshInterval;
  final DateTime Function()? now;
  final ValueChanged<int>? onNavigate;
  final MitvApi api;
  final LocalLibraryStore store;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  late DateTime _lastRefresh;
  bool _visible = false;
  bool _foreground = true;
  DateTime get _now => widget.now?.call() ?? DateTime.now();
  @override
  void initState() {
    super.initState();
    _lastRefresh = _now;
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _scheduleRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    if (!_visible || !_foreground || !mounted) return;
    final remaining = widget.refreshInterval - _now.difference(_lastRefresh);
    _refreshTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (!mounted || !_visible || !_foreground) return;
      _lastRefresh = _now;
      setState(() {
        _featured = _freshShelf('catalog:collection:home-daily', _featured);
        _latest = _freshShelf('catalog:movie:all', _latest);
        _series = _freshShelf('catalog:tv:all', _series);
        _anime = _freshShelf('catalog:anime:tv', _anime);
        _topMovies = _freshShelf('catalog:collection:movie-top', _topMovies);
        _topSeries = _freshShelf('catalog:collection:series-top', _topSeries);
      });
      _scheduleRefresh();
    });
  }

  Future<List<CatalogItem>> _freshShelf(
    String ref,
    Future<List<CatalogItem>> old,
  ) => widget.api.category(ref).catchError((Object _) => old);
  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final Map<String, String> _homeSignatures = {};
  late Future<List<CatalogItem>> _featured = widget.api.category(
    'catalog:collection:home-daily',
  );
  late Future<List<CatalogItem>> _topMovies = widget.api.category(
    'catalog:collection:movie-top',
  );
  late Future<List<CatalogItem>> _topSeries = widget.api.category(
    'catalog:collection:series-top',
  );
  late Future<List<CatalogItem>> _latest = widget.api.category(
    'catalog:movie:all',
  );
  late Future<List<CatalogItem>> _series = widget.api.category(
    'catalog:tv:all',
  );
  late Future<List<CatalogItem>> _anime = widget.api.category(
    'catalog:anime:tv',
  );
  void _retry() => setState(() {
    _featured = widget.api.category('catalog:collection:home-daily');
    _homeSignatures.clear();
    _latest = widget.api.category('catalog:movie:all');
    _series = widget.api.category('catalog:tv:all');
    _anime = widget.api.category('catalog:anime:tv');
    _topMovies = widget.api.category('catalog:collection:movie-top');
    _topSeries = widget.api.category('catalog:collection:series-top');
  });
  void _retryShelf(int target) => setState(() {
    if (target == 3) {
      _anime = widget.api.category('catalog:anime:tv');
    } else if (target == 2) {
      _series = widget.api.category('catalog:tv:all');
    } else {
      _latest = widget.api.category('catalog:movie:all');
    }
  });
  void _history() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('سجل المشاهدة')),
        body: LibraryPage(
          api: widget.api,
          store: widget.store,
          mode: NajdLibraryMode.history,
        ),
      ),
    ),
  );
  Widget _shelf(
    String title,
    Future<List<CatalogItem>> source,
    int target, {
    String? collectionRef,
    int? limit,
  }) => FutureBuilder<List<CatalogItem>>(
    future: source,
    builder: (context, snapshot) {
      final fetched = snapshot.data ?? const <CatalogItem>[];
      final items = limit == null ? fetched : fetched.take(limit).toList();
      if (snapshot.hasError ||
          (snapshot.connectionState == ConnectionState.done && items.isEmpty)) {
        return NajdSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                snapshot.hasError
                    ? 'تعذر تحميل هذا القسم.'
                    : 'لا تتوفر أعمال في هذا القسم الآن.',
              ),
              TextButton.icon(
                onPressed: () {
                  if (collectionRef == null) {
                    _retryShelf(target);
                  } else {
                    setState(() {
                      if (collectionRef.endsWith('movie-top')) {
                        _topMovies = widget.api.category(collectionRef);
                      } else {
                        _topSeries = widget.api.category(collectionRef);
                      }
                    });
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة تحميل القسم'),
              ),
            ],
          ),
        );
      }
      if (items.isEmpty) {
        return const SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NajdSectionHeading(
            title,
            action: 'عرض الكل',
            onAction: () {
              if (collectionRef == null) {
                widget.onNavigate?.call(target);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(title)),
                      body: CatalogPage(
                        api: widget.api,
                        store: widget.store,
                        title: title,
                        categoryId: collectionRef,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          SizedBox(
            height: isTvTarget ? 300 : 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => SizedBox(
                width: isTvTarget ? 180 : 140,
                child: NajdWorkCard(
                  item: items[i],
                  rank: collectionRef?.endsWith('-top') == true ? i + 1 : null,
                  onTap: () =>
                      openDetails(context, widget.api, widget.store, items[i]),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => FutureBuilder<List<CatalogItem>>(
      future: _latest,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CatalogItem>[];
        final children = <Widget>[
          if (snapshot.hasError)
            NajdEmptyState(
              kind: NajdEmptyKind.offline,
              onRetry: _retry,
              onExplore: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('التحميلات')),
                    body: LibraryPage(
                      api: widget.api,
                      store: widget.store,
                      mode: NajdLibraryMode.downloads,
                    ),
                  ),
                ),
              ),
            ),
          if (snapshot.connectionState != ConnectionState.done && items.isEmpty)
            const SizedBox(height: 200, child: NajdSkeleton()),
          if (items.isNotEmpty)
            FutureBuilder<List<CatalogItem>>(
              future: _featured,
              builder: (context, featured) => NajdFeatureCarousel(
                items: featured.data?.isNotEmpty == true
                    ? featured.data!
                    : items,
                isSaved: (item) => widget.store.isFavorite(item.ref),
                onWatch: (item) =>
                    openDetails(context, widget.api, widget.store, item),
                onSave: (item) => unawaited(widget.store.toggleFavorite(item)),
              ),
            ),
          if (widget.store.continueWatching.isNotEmpty) ...[
            NajdSectionHeading(
              'متابعة المشاهدة',
              action: 'عرض السجل',
              onAction: _history,
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.store.continueWatching.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final entry = widget.store.continueWatching[i];
                  return SizedBox(
                    width: 270,
                    child: NajdSurface(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => openHistoryEntry(
                          context,
                          widget.api,
                          widget.store,
                          entry,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    NajdPoster(url: entry.poster),
                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 42,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: LinearProgressIndicator(
                                value: entry.durationMs > 0
                                    ? entry.progress
                                    : 0,
                                minHeight: 4,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                entry.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (widget.store.continueWatching.isEmpty) ...[
            const NajdSectionHeading('متابعة المشاهدة'),
            const Text('الأعمال التي تبدأها ستظهر هنا.'),
          ],
          NajdSectionHeading(
            'قائمتي',
            action: 'المزيد',
            onAction: () => widget.onNavigate?.call(7),
          ),
          if (widget.store.favorites.isEmpty)
            const Text('أضف أعمالك المفضلة لتجدها هنا.'),
          if (widget.store.favorites.isNotEmpty)
            SizedBox(
              height: isTvTarget ? 300 : 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.store.favorites.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final item = widget.store.favorites[index];
                  return SizedBox(
                    width: isTvTarget ? 180 : 135,
                    child: NajdWorkCard(
                      item: item,
                      onTap: () =>
                          openDetails(context, widget.api, widget.store, item),
                    ),
                  );
                },
              ),
            ),
          _shelf(
            'أفضل عشرة أفلام · تقييم TMDB',
            _topMovies,
            1,
            collectionRef: 'catalog:collection:movie-top',
            limit: 10,
          ),
          _shelf(
            'أفضل عشرة مسلسلات · تقييم TMDB',
            _topSeries,
            2,
            collectionRef: 'catalog:collection:series-top',
            limit: 10,
          ),
          _shelf('أحدث الإضافات', _latest, 1),
          if (items.isNotEmpty) ...[
            _shelf('مسلسلات تستحق المشاهدة', _series, 2),
            _shelf('عالم الأنمي', _anime, 3),
          ],
          if (items.isEmpty &&
              !snapshot.hasError &&
              snapshot.connectionState == ConnectionState.done)
            NajdEmptyState(
              kind: NajdEmptyKind.search,
              onExplore: () => widget.onNavigate?.call(5),
            ),
          const SizedBox(height: 20),
          for (final definition in najdCatalogCollections.where(
            (r) =>
                snapshot.connectionState == ConnectionState.done &&
                r['group'] == 'home' &&
                ![
                  'catalog:collection:home-top',
                  'catalog:collection:home-series-top',
                  'catalog:collection:home-anime',
                ].contains(r['id']),
          ))
            CatalogCollectionShelf(
              api: widget.api,
              definition: definition,
              signatures: _homeSignatures,
              onItem: (item) =>
                  openDetails(context, widget.api, widget.store, item),
              onMore: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(definition['title']!)),
                    body: CatalogPage(
                      api: widget.api,
                      store: widget.store,
                      title: definition['title']!,
                      categoryId: definition['id']!,
                    ),
                  ),
                ),
              ),
            ),
        ];
        return ListView.builder(
          key: const Key('stitch-home'),
          padding: EdgeInsets.all(isTvTarget ? 32 : 18),
          itemCount: children.length,
          itemBuilder: (_, i) => children[i],
        );
      },
    ),
  );
}

class LivePage extends StatelessWidget {
  const LivePage({
    super.key,
    required this.api,
    required this.store,
    this.channels = const [],
  });
  final MitvApi api;
  final LocalLibraryStore store;
  final List<ConfiguredTvChannel> channels;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: channels.isEmpty ? 2 : 3,
    child: Column(
      children: [
        TabBar(
          tabs: [
            Tab(text: 'المباريات', height: isTvTarget ? 64 : 48),
            Tab(text: 'القنوات المباشرة', height: isTvTarget ? 64 : 48),
            if (channels.isNotEmpty)
              Tab(text: 'قنوات مخصصة', height: isTvTarget ? 64 : 48),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              MatchesPage(api: api, store: store),
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sensors),
                    title: const Text('مصادر البث المباشر'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProviderBrowserPage(
                          api: api,
                          store: store,
                          liveOnly: true,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LiveChannelsPanel(api: api, store: store),
                  ),
                ],
              ),
              if (channels.isNotEmpty)
                ListView(
                  children: [
                    for (final package
                        in channels.map((c) => c.package).toSet()) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(package),
                      ),
                      for (final channel in channels.where(
                        (c) => c.package == package,
                      ))
                        FocusHighlight(
                          child: ListTile(
                            title: Text(channel.title),
                            leading: const Icon(Icons.live_tv),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerPage(
                                  api: api,
                                  store: store,
                                  item: CatalogItem(
                                    id: channel.sourceRef,
                                    title: channel.title,
                                    poster: '',
                                    type: 'live',
                                    ref: channel.sourceRef,
                                  ),
                                  title: channel.title,
                                  sourceRef: channel.sourceRef,
                                  isLive: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.api,
    required this.store,
    this.pointer,
    this.clearCache,
    this.clearDownloads,
  });
  final MitvApi api;
  final LocalLibraryStore store;
  final VirtualPointerController? pointer;
  final Future<void> Function()? clearCache;
  final Future<void> Function()? clearDownloads;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;
  bool _confirming = false;
  Future<void> _clear(String title, Future<void> Function() action) async {
    if (_busy || _confirming) return;
    _confirming = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(
            title == 'مسح سجل المشاهدة'
                ? 'سيُحذف تقدم المشاهدة فقط. لن تتأثر قائمتك أو الملفات المحمّلة.'
                : 'تأكيد حذف البيانات المحددة من هذا الجهاز فقط؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر إكمال التنظيف')));
      }
    } finally {
      _confirming = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _selectedSection;

  ({String title, IconData icon, List<Widget> children}) _section(
    String title,
    IconData icon,
    List<Widget> children,
  ) => (title: title, icon: icon, children: children);

  Widget _sectionTile(
    ({String title, IconData icon, List<Widget> children}) section, {
    bool inline = false,
    bool selected = false,
  }) => ListTile(
    key: PageStorageKey('settings-${section.title}'),
    minTileHeight: isTvTarget ? 64 : 48,
    selected: selected,
    leading: Icon(section.icon),
    title: Text(section.title),
    trailing: inline ? null : const Icon(Icons.chevron_left),
    onTap: () {
      if (inline) {
        setState(() => _selectedSection = section.title);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(section.title)),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: section.children,
            ),
          ),
        ),
      );
    },
  );

  Widget _open(String title, IconData icon, WidgetBuilder builder) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_left),
    onTap: () =>
        Navigator.of(context).push(MaterialPageRoute(builder: builder)),
  );
  void _information(String title, String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(text)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final sections = [
      _section('الحساب والمكتبة', Icons.person_outline, [
        _open(
          'تسجيل الدخول وإدارة الحساب',
          Icons.link,
          (_) => NajdAccountPage(store: widget.store),
        ),
        _open(
          'مكتبتي والتنزيلات',
          Icons.video_library_outlined,
          (_) => Scaffold(
            appBar: AppBar(title: const Text('قائمتي والتنزيلات')),
            body: LibraryPage(api: widget.api, store: widget.store),
          ),
        ),
      ]),
      _section('المظهر والحلقات', Icons.palette_outlined, [
        const _NajdAppearanceOptions(),
        const EpisodePreferencesTile(),
      ]),
      _section('المشغل', Icons.play_circle_outline, [
        const _PlaybackPreferencesPanel(),
        ListTile(
          leading: const Icon(Icons.picture_in_picture_alt),
          title: const Text('صورة داخل صورة'),
          subtitle: const Text('تفعيلها من المزيد داخل المشغل'),
          onTap: () => _information(
            'صورة داخل صورة',
            'على الآيفون يستخدم الفيديو المتوافق AVKit، وعلى أندرويد يستخدم وضع النظام. في المتصفح يعتمد الدعم على Safari أو واجهة المتصفح. الكمبيوتر يستخدم نافذة مصغرة عائمة. تختلف الصيغ المدعومة بين الأنظمة.',
          ),
        ),
      ]),
      _section('المصادر والتصفح', Icons.travel_explore, [
        const _ProviderBetaPreferencesPanel(),
      ]),
      _section('التخزين والخصوصية', Icons.storage_outlined, [
        if (widget.clearCache != null)
          ListTile(
            title: const Text('مسح الكاش المحلي'),
            leading: const Icon(Icons.cleaning_services_outlined),
            enabled: !_busy,
            onTap: () => _clear('مسح الكاش المحلي', widget.clearCache!),
          ),
        if (!kIsWeb && widget.clearDownloads != null)
          ListTile(
            title: const Text('حذف الملفات المحمّلة'),
            leading: const Icon(Icons.delete_outline),
            enabled: !_busy,
            onTap: () => _clear('حذف الملفات المحمّلة', widget.clearDownloads!),
          ),
        ListTile(
          title: const Text('مسح سجل المشاهدة'),
          leading: const Icon(Icons.history),
          enabled: !_busy,
          onTap: () => _clear('مسح سجل المشاهدة', widget.store.clearHistory),
        ),
        ListTile(
          title: const Text('مسح سجل البحث'),
          leading: const Icon(Icons.search_off),
          enabled: !_busy,
          onTap: () => _clear('مسح سجل البحث', widget.store.clearSearchHistory),
        ),
      ]),
      _section('الأجهزة والتحكم', Icons.devices_outlined, [
        _open(
          'تخصيص أزرار الريموت',
          Icons.settings_remote,
          (_) => const RemoteBindingsPage(),
        ),
        if (isTvTarget && widget.pointer != null)
          AnimatedBuilder(
            animation: widget.pointer!,
            builder: (context, _) => SwitchListTile(
              title: const Text('الفأرة الافتراضية'),
              subtitle: const Text(
                'زر القائمة أو F8 للتبديل؛ الأسهم للحركة وOK للاختيار',
              ),
              value: widget.pointer!.enabled,
              onChanged: widget.pointer!.setEnabled,
            ),
          ),
        ListTile(
          leading: const Icon(Icons.keyboard_outlined),
          title: const Text('اختصارات التحكم'),
          onTap: () => _information(
            'التحكم بالمشغل',
            'Space للتشغيل والإيقاف، F لملء الشاشة، Esc للخروج منها، وسهما اليمين واليسار للتقديم والرجوع على الكمبيوتر. في الريموت تحرك بالأسهم واختر بزر OK. اسحب جانب الشاشة للصوت أو السطوع على الأجهزة اللمسية.',
          ),
        ),
        if (kIsWeb)
          ListTile(
            leading: const Icon(Icons.install_mobile),
            title: const Text('تثبيت نجد كتطبيق'),
            onTap: () {
              if (BrowserNavigation().requestInstall()) return;
              _information(
                'إضافة نجد إلى جهازك',
                'على iPhone أو iPad: افتح الموقع في Safari ثم مشاركة ← إضافة إلى الشاشة الرئيسية. على الكمبيوتر وأندرويد: افتح قائمة المتصفح واختر تثبيت التطبيق.',
              );
            },
          ),
      ]),
      _section('الفحص والمساعدة', Icons.fact_check_outlined, [
        _open(
          'فحص الخدمات والقواشط',
          Icons.fact_check_outlined,
          (_) => ServiceChecksPage(api: widget.api, store: widget.store),
        ),
        ListTile(
          leading: const Icon(Icons.video_file_outlined),
          title: const Text('صيغ الفيديو المدعومة'),
          onTap: () => _information(
            'صيغ الفيديو والبث',
            'MP4 حاوية ملف، وHLS بث متكيف بفهرس M3U8. توجد أيضًا DASH وWebM وMKV وMPEG-TS. التوافق يعتمد على النظام والترميز داخل الحاوية، وليس الامتداد وحده؛ الآيفون وPiP لهما قيود AVKit. الجودة الفعلية تأتي من المصدر ولا يزيدها تكبير الصورة.',
          ),
        ),
        if (const bool.fromEnvironment('NAJD_DEVELOPER_DIAGNOSTICS'))
          ListTile(
            leading: const Icon(Icons.aspect_ratio),
            title: const Text('قياسات الشاشة الحالية'),
            subtitle: Text(
              '${MediaQuery.sizeOf(context).width.round()} × ${MediaQuery.sizeOf(context).height.round()} · كثافة ${MediaQuery.devicePixelRatioOf(context).toStringAsFixed(2)}',
            ),
          ),
      ]),
    ];
    return ListView(
      padding: EdgeInsets.all(isTvTarget ? 24 : 16),
      children: [
        const NajdSectionHeading('الإعدادات'),
        LayoutBuilder(
          builder: (context, bounds) {
            if (bounds.maxWidth < 900) {
              return Column(
                children: [
                  for (final section in sections)
                    NajdSurface(
                      padding: EdgeInsets.zero,
                      child: _sectionTile(section),
                    ),
                ],
              );
            }
            final selected = sections.firstWhere(
              (section) => section.title == _selectedSection,
              orElse: () => sections[1],
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NajdSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NajdSectionHeading(selected.title),
                        ...selected.children,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: NajdSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final section in sections)
                          _sectionTile(
                            section,
                            inline: true,
                            selected: section == selected,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const AboutListTile(
          applicationName: NajdUi.brand,
          applicationVersion: '$productVersion $productChannel ($productBuild)',
          child: Text('عن نجد والتراخيص'),
        ),
        Padding(
          key: const Key('settings-product-version'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'الإصدار v$productVersion · $productChannel · البناء $productBuild',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}

class _PlaybackPreferencesPanel extends StatelessWidget {
  const _PlaybackPreferencesPanel();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: NajdPreferences.instance,
    builder: (context, _) {
      final prefs = NajdPreferences.instance;
      return NajdSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NajdSectionHeading('إعدادات المشغل'),
            NajdChoiceButton<int>(
              label: 'مدة التقديم والترجيع: ${prefs.seekSeconds} ثانية',
              icon: Icons.fast_forward_outlined,
              options: [
                for (final seconds in NajdPreferences.seekChoices)
                  NajdOption(
                    seconds,
                    '$seconds ثانية',
                    selected: seconds == prefs.seekSeconds,
                  ),
              ],
              onSelected: prefs.setSeekSeconds,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              key: const Key('setting-hold-boost'),
              title: const Text('التسريع بالضغط المطوّل'),
              subtitle: const Text(
                'اضغط مطولاً على الفيديو للتسريع، وارفع إصبعك لاستعادة السرعة السابقة',
              ),
              value: prefs.holdToBoost,
              onChanged: prefs.setHold,
            ),
            NajdChoiceButton<double>(
              label: 'سرعة الضغط المطوّل: ${prefs.holdSpeed}×',
              icon: Icons.fast_forward_outlined,
              options: [
                for (final speed in NajdPreferences.holdSpeeds)
                  NajdOption(
                    speed,
                    '$speed×',
                    selected: speed == prefs.holdSpeed,
                    icon: Icons.fast_forward_outlined,
                  ),
              ],
              onSelected: prefs.setHoldSpeed,
            ),
            const SizedBox(height: 12),
            NajdChoiceButton<String>(
              label: 'لغة بيانات الأعمال',
              icon: Icons.translate,
              options: [
                NajdOption(
                  'auto',
                  'تلقائي حسب لغة العمل',
                  selected: prefs.metadataLanguage == 'auto',
                  icon: Icons.auto_awesome_outlined,
                ),
                NajdOption(
                  'ar',
                  'العربية',
                  selected: prefs.metadataLanguage == 'ar',
                  icon: Icons.translate,
                ),
                NajdOption(
                  'en',
                  'English',
                  selected: prefs.metadataLanguage == 'en',
                  icon: Icons.translate,
                ),
              ],
              onSelected: prefs.setMetadataLanguage,
            ),
          ],
        ),
      );
    },
  );
}

class _ProviderBetaPreferencesPanel extends StatelessWidget {
  const _ProviderBetaPreferencesPanel();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: NajdPreferences.instance,
    builder: (context, _) {
      final prefs = NajdPreferences.instance;
      return NajdSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NajdSectionHeading('ميزات تحت التجربة'),
            SwitchListTile.adaptive(
              key: const Key('setting-provider-beta'),
              contentPadding: EdgeInsets.zero,
              title: const Text('تصفح المزود — تجريبي'),
              subtitle: const Text(
                'افتح فهرس موقع مختار من القائمة الجانبية، مستقلاً عن التصفح المعتاد',
              ),
              value: prefs.providerBeta,
              onChanged: prefs.setProviderBeta,
            ),
          ],
        ),
      );
    },
  );
}

class _NajdAppearanceOptions extends StatelessWidget {
  const _NajdAppearanceOptions();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: NajdAppearance.instance,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.palette_outlined),
          title: Text('المظهر'),
          subtitle: Text('اختر أسلوب العرض المفضل لواجهة نجد'),
        ),
        Row(
          children: [
            for (final mode in [ThemeMode.light, ThemeMode.dark])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: InkWell(
                    key: Key('stitch-theme-${mode.name}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => NajdAppearance.instance.setMode(mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: mode == ThemeMode.dark
                            ? const Color(0xff211c2e)
                            : const Color(0xfffaf8ff),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          width: 2,
                          color: NajdAppearance.instance.mode == mode
                              ? NajdDesign.primary
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            mode == ThemeMode.dark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: mode == ThemeMode.dark
                                ? Colors.white
                                : NajdDesign.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode == ThemeMode.dark ? 'داكن' : 'فاتح',
                            style: TextStyle(
                              color: mode == ThemeMode.dark
                                  ? Colors.white
                                  : const Color(0xff211b30),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            NajdAppearance.instance.mode == mode
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: NajdDesign.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

String _matchStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'live':
      return 'جاري الآن';
    case 'ended':
      return 'انتهت';
    case 'scheduled':
      return 'لم تبدأ';
    default:
      return status;
  }
}

String _localizedMatchTime(String time) => time
    .replaceAll(RegExp(r'\bPM\b', caseSensitive: false), 'م')
    .replaceAll(RegExp(r'\bAM\b', caseSensitive: false), 'ص');

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.name, required this.logo});
  final String name;
  final String logo;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final diameter = bounds.maxWidth.clamp(0.0, isTvTarget ? 82.0 : 62.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: diameter,
            height: diameter,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A18),
              border: Border.all(color: const Color(0x448480FF)),
            ),
            child: logo.isEmpty
                ? const Icon(Icons.shield_outlined, color: _brandAccentMuted)
                : Image.network(
                    logo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.shield_outlined,
                      color: _brandAccentMuted,
                    ),
                  ),
          ),
          const SizedBox(height: 7),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    },
  );
}

class MatchesPage extends StatefulWidget {
  final LocalLibraryStore store;
  const MatchesPage({super.key, required this.api, required this.store});
  final MitvApi api;

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late Future<List<MatchItem>> _matches;
  final _carousel = ScrollController();
  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  void _scrollMatches(int direction) {
    if (!_carousel.hasClients) return;
    _carousel.animateTo(
      (_carousel.offset + direction * _carousel.position.viewportDimension * .8)
          .clamp(0, _carousel.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _matches = widget.api.matches();
  }

  @override
  void didUpdateWidget(covariant MatchesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api != widget.api) _matches = widget.api.matches();
  }

  void _reload() {
    final next = widget.api.matches();
    setState(() {
      _matches = next;
    });
  }

  void _open(BuildContext context, MatchItem match) {
    if (match.status == 'ended') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المباراة انتهت ولا يوجد بث مباشر الآن.')),
      );
      return;
    }
    if (match.ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مرجع تشغيل المباراة غير متاح حاليًا.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MatchPlayerPage(api: widget.api, match: match, store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('مباريات اليوم'),
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 700) ...[
            IconButton(
              tooltip: 'المباريات السابقة',
              onPressed: () => _scrollMatches(-1),
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'المباريات التالية',
              onPressed: () => _scrollMatches(1),
              icon: const Icon(Icons.chevron_left),
            ),
          ],
          IconButton(
            key: const Key('matches-refresh'),
            tooltip: 'تحديث المباريات',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      Expanded(
        child: FutureBuilder<List<MatchItem>>(
          future: _matches,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _ErrorState('تعذر تحميل المباريات حاليًا');
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const _ErrorState('لا توجد مباريات متاحة الآن');
            }
            return LayoutBuilder(
              builder: (context, bounds) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: bounds.maxHeight.clamp(160, 260),
                  width: bounds.maxWidth,
                  child: ListView.builder(
                    key: const Key('live-match-carousel'),
                    controller: _carousel,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(isTvTarget ? 24 : 12),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final m = items[i];
                      final time = _localizedMatchTime(m.time);
                      final status = _matchStatusLabel(m.status);
                      final score = m.hasScore
                          ? '${m.homeGoals} - ${m.awayGoals}'
                          : null;
                      final center = m.status == 'scheduled'
                          ? (time.isEmpty ? 'موعد غير متاح' : time)
                          : (score ?? 'النتيجة غير متاحة');
                      return FocusHighlight(
                        child: SizedBox(
                          width:
                              (bounds.maxWidth /
                                      (bounds.maxWidth >= 900
                                          ? 2.6
                                          : bounds.maxWidth >= 600
                                          ? 1.8
                                          : 1.08))
                                  .clamp(240, 460),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _open(context, m),
                              canRequestFocus: true,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTvTarget ? 24 : 14,
                                  vertical: isTvTarget ? 22 : 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _TeamBadge(
                                        name: m.home,
                                        logo: m.homeLogo,
                                      ),
                                    ),
                                    SizedBox(
                                      width: isTvTarget ? 180 : 110,
                                      child: Column(
                                        children: [
                                          Text(
                                            status,
                                            style: TextStyle(
                                              color: m.status == 'live'
                                                  ? Colors.redAccent
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            center,
                                            style: TextStyle(
                                              fontSize: isTvTarget ? 28 : 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (m.competition.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              m.competition,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: _TeamBadge(
                                        name: m.away,
                                        logo: m.awayLogo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.api,
    required this.store,
    required this.title,
    required this.categoryId,
    this.unified = false,
    this.collections = false,
    this.mediaKind,
  });
  final MitvApi api;
  final LocalLibraryStore store;
  final String title;
  final String categoryId;
  final bool unified;
  final bool collections;
  final String? mediaKind;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late String selectedCategory = widget.categoryId;
  static const seriesCategories = <String, String>{
    'laroza-series': 'لاروزا — مسلسلات',
    'alooy-series': 'Alooy TV',
    'series-foreign': 'أكوام — أجنبية',
    'series-arabic': 'أكوام — عربية',
    'series-turkish': 'أكوام — تركية',
  };
  static const iskCategories = <String, String>{
    '3isk-latest': 'قصة عشق (أحدث الحلقات)',
    '3isk-turkish': 'جميع المسلسلات (مترجم ومدبلج)',
    '3isk-dubbed': 'مسلسلات مدبلجة (مدبلج فقط)',
    '3isk-movies': 'جميع الأفلام',
  };
  Map<String, String> get _legacyCategories {
    switch (widget.mediaKind) {
      case 'movie':
        return {
          'movie-foreign': 'أكوام — أفلام أجنبية',
          'movie-arabic': 'أكوام — أفلام عربية',
          'laroza-movies': 'لاروزا — أفلام',
          '3isk-movies': 'قصة عشق — أفلام',
        };
      case 'series':
        return {
          ...seriesCategories,
          for (final entry in iskCategories.entries)
            if (entry.key != '3isk-movies') entry.key: entry.value,
        };
      case 'anime':
        return {
          'movie-anime': 'أكوام — أفلام أنمي',
          'series-anime': 'أكوام — مسلسلات أنمي',
          'laroza-anime': 'لاروزا — أنمي',
        };
      default:
        return widget.unified
            ? {
                'movie-foreign': 'أكوام — أفلام أجنبية',
                'movie-arabic': 'أكوام — أفلام عربية',
                ...seriesCategories,
                ...iskCategories,
              }
            : widget.categoryId.startsWith('3isk-')
            ? iskCategories
            : seriesCategories;
    }
  }

  Map<String, String> get _categories {
    if (!widget.categoryId.startsWith('catalog:')) {
      return _legacyCategories;
    }
    return switch (widget.mediaKind) {
      'movie' => {
        'catalog:movie:all': 'الكل',
        'catalog:movie:en': 'أجنبي',
        'catalog:movie:ar': 'عربي',
        'catalog:movie:hi': 'هندي',
        'catalog:movie:ko': 'آسيوي',
        'catalog:movie:tr': 'تركي',
      },
      'series' => {
        'catalog:tv:all': 'الكل',
        'catalog:tv:en': 'أجنبي',
        'catalog:tv:ar': 'عربي',
        'catalog:tv:tr': 'تركي',
        'catalog:tv:ko': 'آسيوي',
      },
      'anime' => {
        'catalog:anime:movie': 'أفلام أنمي',
        'catalog:anime:tv': 'مسلسلات أنمي',
      },
      'turkish' => {
        'catalog:turkish:tv': 'مسلسلات تركية',
        'catalog:turkish:movie': 'أفلام تركية',
      },
      _ => {widget.categoryId: widget.title},
    };
  }

  bool _matchesKind(CatalogItem item) {
    return selectedCategory.startsWith('catalog:') ||
        widget.mediaKind == null ||
        MediaTaxonomy.classify(item) == widget.mediaKind;
  }

  final controller = ScrollController();
  final items = <CatalogItem>[];
  int page = 0;
  bool loading = false;
  bool done = false;
  String? error;
  int requestGeneration = 0;
  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
    if (!widget.collections) _loadMore();
  }

  @override
  void dispose() {
    requestGeneration += 1;
    controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    _prefetchVisible();
    if (controller.position.extentAfter < (isTvTarget ? 1400 : 900)) {
      _loadMore();
    }
  }

  final _prefetched = <String>{};
  void _prefetchVisible() {
    if (!mounted || !controller.hasClients || items.isEmpty) return;
    final columns = ViewportMetrics(
      size: MediaQuery.sizeOf(context),
      safeInsets: MediaQuery.viewPaddingOf(context),
      textScaler: MediaQuery.textScalerOf(context),
    ).columns(minimumCardWidth: isTvTarget ? 200 : 160);
    final width = MediaQuery.sizeOf(context).width / columns;
    final rowHeight = width / (isTvTarget ? .68 : .62) + 18;
    final start = ((controller.offset / rowHeight).floor() * columns).clamp(
      0,
      items.length,
    );
    for (final item in items.skip(start).take(columns * 2)) {
      if (!_prefetched.add(item.ref)) continue;
      if (item.poster.isNotEmpty) {
        unawaited(
          precacheImage(
            ResizeImage(NetworkImage(item.poster), width: 320),
            context,
            onError: (_, _) {},
          ),
        );
      }
      unawaited(widget.api.prefetchMetadata(item.ref));
    }
  }

  Future<void> _loadMore() async {
    if (loading || done) return;
    final generation = requestGeneration;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = await widget.api.category(selectedCategory, page: page + 1);
      if (!mounted || generation != requestGeneration) return;
      final previousCount = items.length;
      final merged = UnifiedMedia.mergeSources([...items, ...next])
          .where((item) => item.ref.isNotEmpty && _matchesKind(item))
          .toList(growable: false);
      final hasMore = widget.api.categoryHasMore(selectedCategory, page + 1);
      setState(() {
        page += 1;
        items
          ..clear()
          ..addAll(merged);
        done = hasMore == null ? next.isEmpty : !hasMore;
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            generation != requestGeneration ||
            !controller.hasClients) {
          return;
        }
        _prefetchVisible();
        if (items.length > previousCount &&
            controller.position.extentAfter < (isTvTarget ? 1400 : 900)) {
          _loadMore();
        }
      });
    } catch (_) {
      if (mounted && generation == requestGeneration) {
        setState(() {
          loading = false;
          error = 'تعذر تحميل المزيد. اسحب للأسفل للمحاولة مجددًا.';
        });
      }
    }
  }

  Future<void> _refresh() async {
    requestGeneration += 1;
    setState(() {
      items.clear();
      _prefetched.clear();
      page = 0;
      done = false;
      loading = false;
      error = null;
    });
    if (!(widget.collections && selectedCategory == widget.categoryId)) {
      await _loadMore();
    }
  }

  Widget _selector() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: DropdownButton<String>(
      isExpanded: true,
      value: selectedCategory,
      items: _categories.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value == null || value == selectedCategory) return;
        setState(() {
          selectedCategory = value;
        });
        if (controller.hasClients) controller.jumpTo(0);
        unawaited(_refresh());
      },
    ),
  );

  @override
  Widget build(BuildContext context) =>
      widget.collections && selectedCategory == widget.categoryId
      ? Column(
          children: [
            _selector(),
            Expanded(
              child: CatalogCollectionsPage(
                api: widget.api,
                store: widget.store,
                group: widget.mediaKind == 'movie'
                    ? 'movie'
                    : widget.mediaKind == 'anime'
                    ? 'anime'
                    : widget.mediaKind == 'turkish'
                    ? 'turkish'
                    : 'series',
                onItem: (item) =>
                    openDetails(context, widget.api, widget.store, item),
                onMore: (ref, title) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(title)),
                      body: CatalogPage(
                        api: widget.api,
                        store: widget.store,
                        title: title,
                        categoryId: ref,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      : Column(
          children: [
            if (widget.unified ||
                widget.categoryId.startsWith('series-') ||
                widget.categoryId.startsWith('3isk-'))
              _selector(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: GridView.builder(
                  controller: controller,
                  padding: EdgeInsets.all(isTvTarget ? 24 : 12),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 185,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: isTvTarget ? 18 : 10,
                    mainAxisSpacing: isTvTarget ? 18 : 10,
                  ),
                  itemCount: items.length + 1,
                  itemBuilder: (context, i) {
                    if (i == items.length) {
                      return Center(
                        child: loading
                            ? const CircularProgressIndicator()
                            : error != null
                            ? TextButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              )
                            : done
                            ? const Text('تم عرض كل الأعمال المتاحة')
                            : TextButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('عرض الصفحة التالية'),
                              ),
                      );
                    }
                    final item = items[i];
                    return _CatalogCard(
                      rank: selectedCategory.endsWith('-top') ? i + 1 : null,
                      item: item,
                      onTap: () =>
                          openDetails(context, widget.api, widget.store, item),
                    );
                  },
                ),
              ),
            ),
          ],
        );
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.onTap,
    this.sourceLabel,
    this.rank,
  });
  final int? rank;
  final String? sourceLabel;
  final CatalogItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FocusHighlight(
    child: NajdWorkCard(
      item: item,
      onTap: onTap,
      sourceLabel: sourceLabel,
      rank: rank,
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.api, required this.store});
  final MitvApi api;
  final LocalLibraryStore store;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final query = TextEditingController();
  List<CatalogItem> items = const [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  int page = 1;
  final resultsController = ScrollController();
  @override
  void initState() {
    super.initState();
    resultsController.addListener(() {
      if (resultsController.hasClients &&
          resultsController.position.extentAfter < 700) {
        unawaited(loadMore());
      }
    });
  }

  Future<void> loadMore() async {
    if (advanced || loading || loadingMore || !hasMore) return;
    final request = generation, q = query.text.trim();
    final nextPage = page + 1;
    setState(() => loadingMore = true);
    try {
      final next = await widget.api.searchTmdbPage(q, page: nextPage);
      if (!mounted || request != generation) return;
      setState(() {
        items = UnifiedMedia.mergeSources([...items, ...next]);
        page = nextPage;
        hasMore = widget.api.searchHasMore(q, page) ?? next.length >= 20;
      });
    } catch (_) {
      if (mounted && request == generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحميل الصفحة التالية؛ حاول مجددًا'),
          ),
        );
      }
    } finally {
      if (mounted && request == generation) setState(() => loadingMore = false);
    }
  }

  bool submitted = false;
  String? error;
  bool advanced = false;
  bool exploring = false;
  List<String> sources = const [];
  String? selectedSource;
  String? sourceError;
  bool loadingSources = false;

  Future<void> _setAdvanced(bool value) async {
    debounce?.cancel();
    generation += 1;
    setState(() {
      advanced = value;
      exploring = false;
      items = const [];
      submitted = false;
      loading = false;
      error = null;
    });
    if (!value || loadingSources) return;
    setState(() {
      loadingSources = true;
      sourceError = null;
    });
    try {
      final available = await widget.api.explorationSources();
      if (!mounted) return;
      setState(() {
        sources = available;
        loadingSources = false;
        sourceError = available.isEmpty
            ? 'لا توجد مصادر بحث متاحة حاليًا'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loadingSources = false;
          sourceError = 'تعذر تحميل المصادر. أعد المحاولة.';
        });
      }
    }
  }

  String _submittedQuery = '';
  int? _catalogueYear;
  List<CatalogItem>? _groupedInput;
  bool? _groupedAdvanced;
  List<SearchWorkGroup> _grouped = [];
  final _liveSearchGroups = <String, SearchWorkGroup>{};
  List<SearchWorkGroup> get _resultGroups {
    if (!identical(_groupedInput, items) || _groupedAdvanced != advanced) {
      _groupedInput = items;
      _groupedAdvanced = advanced;
      _grouped = groupSearchWorks(items, enabled: advanced)
          .map((group) {
            if (!advanced) return group;
            final previous = _liveSearchGroups[group.key];
            if (previous != null) {
              previous.members
                ..clear()
                ..addAll(group.members);
              return previous;
            }
            _liveSearchGroups[group.key] = group;
            if (_liveSearchGroups.length > 256) {
              _liveSearchGroups.remove(_liveSearchGroups.keys.first);
            }
            return group;
          })
          .toList(growable: false);
    }
    return _grouped;
  }

  String _sourceLabel(String id) => widget.api.explorationSourceLabel(id);

  Timer? debounce;
  int generation = 0;

  @override
  void dispose() {
    generation += 1;
    debounce?.cancel();
    query.dispose();
    resultsController.dispose();
    super.dispose();
  }

  void onQueryChanged(String value) {
    debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      generation += 1;
      setState(() {
        items = const [];
        loading = false;
        exploring = false;
        submitted = false;
        error = null;
      });
      return;
    }
    if (q.length < 2) return;
    debounce = Timer(const Duration(milliseconds: 450), () => run(q));
  }

  Future<void> run([String? requested]) async {
    final q = (requested ?? query.text).trim();
    if (q.length < 2 || q.length > 120) return;
    final request = ++generation;
    setState(() {
      _submittedQuery = q;
      _catalogueYear = null;
      exploring = advanced;
      loading = true;
      loadingMore = false;
      hasMore = false;
      page = 1;
      submitted = true;
      error = null;
    });
    if (advanced) unawaited(_resolveSearchYear(q, request));
    try {
      // A newly registered source becomes searchable in this same app session.
      var currentSources = sources;
      if (advanced && selectedSource == null) {
        currentSources = await widget.api.explorationSources();
        if (!mounted || request != generation) return;
        setState(() => sources = currentSources);
      }
      final result = advanced
          ? selectedSource != null
                ? await widget.api.explore(q, selectedSource!)
                : await widget.api.exploreParallel(
                    q,
                    providers: currentSources,
                    isCurrent: () =>
                        mounted &&
                        request == generation &&
                        q == query.text.trim(),
                    onResults: (found) {
                      if (mounted && request == generation) {
                        setState(() {
                          items = found;
                          loading = false;
                        });
                      }
                    },
                  )
          : await widget.api.searchTmdb(q);
      if (!mounted || request != generation || q != query.text.trim()) return;
      setState(() {
        items = result;
        exploring = false;
        hasMore =
            !advanced &&
            (widget.api.searchHasMore(q, 1) ?? result.length >= 20);
        loading = false;
      });
    } catch (_) {
      if (!mounted || request != generation) return;
      setState(() {
        items = const [];
        loading = false;
        exploring = false;
        error =
            '${widget.api.lastSearchStage == 'client_no_response' ? 'لم يصل رد للتطبيق؛ قد يكون انقطاع اتصال أو مهلة.' : 'تعذر البحث حاليًا. أعد المحاولة.'}'
            '${widget.api.lastSearchTrace != null ? ' رقم التشخيص: ${widget.api.lastSearchTrace}' : ''}';
      });
    }
  }

  Future<void> _resolveSearchYear(String query, int request) async {
    final scoring = SearchScoring(query);
    if (scoring.requestedYear != null) return;
    try {
      final catalogue = await widget.api
          .searchTmdb(query)
          .timeout(const Duration(seconds: 5));
      final year = scoring.referenceYear(catalogue);
      if (year != null && mounted && request == generation) {
        setState(() => _catalogueYear = year);
      }
    } catch (_) {
      // Provider results remain available when the catalogue cannot confirm a year.
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 860 && constraints.maxHeight >= 420;
      final controls = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (constraints.maxHeight * (wide ? .92 : .62)).clamp(
            1,
            double.infinity,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const NajdSectionHeading('البحث'),
              TextField(
                controller: query,
                textInputAction: TextInputAction.search,
                onChanged: onQueryChanged,
                onSubmitted: (_) => run(),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيلم أو مسلسل',
                  prefixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: query,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const Icon(Icons.search)
                        : IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: () {
                              query.clear();
                              onQueryChanged('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  suffixIcon: IconButton(
                    key: const Key('search-submit'),
                    onPressed: loading ? null : () => run(),
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                key: const Key('search-advanced-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('بحث متقدم — استكشاف'),
                subtitle: const Text(
                  'ابحث في جميع المصادر بالتوازي أو اختر مصدراً محدداً',
                ),
                value: advanced,
                onChanged: _setAdvanced,
              ),
              if (advanced) ...[
                if (loadingSources) const LinearProgressIndicator(),
                if (sourceError != null)
                  Row(
                    children: [
                      Expanded(child: Text(sourceError!)),
                      TextButton(
                        onPressed: () => _setAdvanced(true),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                if (sources.isNotEmpty)
                  NajdSurface(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      key: const Key('search-explore-source'),
                      leading: const Icon(Icons.travel_explore),
                      title: Text(
                        selectedSource == null
                            ? 'جميع المصادر'
                            : _sourceLabel(selectedSource!),
                      ),
                      subtitle: Text(
                        selectedSource == null
                            ? 'بحث متوازٍ في جميع المزودين'
                            : 'نتائج هذا المصدر فقط',
                      ),
                      trailing: const Icon(Icons.expand_more),
                      onTap: () async {
                        try {
                          final latest = await widget.api.explorationSources();
                          if (!mounted) return;
                          setState(() => sources = latest);
                        } catch (_) {
                          if (!mounted) return;
                        }
                        if (!context.mounted) return;
                        final value = await showNajdOptions<String>(
                          context,
                          title: 'مصادر البحث',
                          description: 'ابحث في جميع المواقع معاً أو اختر موقعاً محدداً.',
                          icon: Icons.travel_explore,
                          options: [
                            NajdOption(
                              'all',
                              'جميع المصادر',
                              selected: selectedSource == null,
                              icon: Icons.public,
                            ),
                            for (final source in sources)
                              NajdOption(
                                source,
                                _sourceLabel(source),
                                selected: source == selectedSource,
                                icon: Icons.language,
                              ),
                          ],
                        );
                        if (!mounted || value == null) return;
                        debounce?.cancel();
                        generation += 1;
                        setState(() {
                          selectedSource = value == 'all' ? null : value;
                          exploring = false;
                          items = const [];
                          submitted = false;
                          loading = false;
                          error = null;
                        });
                      },
                    ),
                  ),
                if (wide)
                  ListenableBuilder(
                    listenable: widget.store,
                    builder: (context, _) {
                      final recent = widget.store.searchHistory.take(5);
                      if (recent.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const NajdSectionHeading('عمليات البحث الأخيرة'),
                          for (final term in recent)
                            ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(term),
                              onTap: () {
                                debounce?.cancel();
                                query.text = term;
                                unawaited(run(term));
                              },
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      );
      final ranked = SearchScoring(_submittedQuery)
          .partition(_resultGroups, catalogueYear: _catalogueYear);
      final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 185,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: isTvTarget ? 18 : 10,
        mainAxisSpacing: isTvTarget ? 18 : 10,
      );
      Widget card(BuildContext context, SearchWorkGroup group) => _CatalogCard(
        item: group.representative.copyWith(title: group.title),
        sourceLabel: !advanced
            ? null
            : group.providerChoices.length > 1
            ? '${group.providerChoices.length} مزودين'
            : _sourceLabel(group.representative.source),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailsPage(
              api: widget.api,
              store: widget.store,
              item: group.representative,
              searchMatches: group.members,
            ),
          ),
        ),
      );
      final results = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) const NajdSectionHeading('نتائج البحث'),
          if (loading || exploring) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          if (advanced && submitted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedSource == null
                          ? 'نتائج جميع المصادر'
                          : 'نتائج ${_sourceLabel(selectedSource!)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text('${ranked.exact.length + ranked.possible.length} عمل'),
                ],
              ),
            ),
          Expanded(
            child: loading
                ? const NajdSkeleton()
                : error != null
                ? NajdEmptyState(
                    kind: NajdEmptyKind.failure,
                    message: error,
                    onRetry: () => run(),
                  )
                : submitted &&
                      ranked.exact.isEmpty &&
                      ranked.possible.isEmpty &&
                      !hasMore
                ? NajdEmptyState(
                    kind: NajdEmptyKind.search,
                    message: advanced
                        ? 'لم يستخرج المصدر نتائج لهذا البحث. جرّب مصدراً آخر أو امسح الفلاتر.'
                        : null,
                    onRetry: () {
                      query.clear();
                      _setAdvanced(false);
                      setState(() {
                        items = const [];
                        submitted = false;
                      });
                    },
                  )
                : !submitted
                ? const Center(child: Text('اكتب اسم فيلم أو مسلسل للبحث'))
                : CustomScrollView(
                    controller: resultsController,
                    slivers: [
                      if (ranked.exact.isNotEmpty)
                        SliverGrid.builder(
                          gridDelegate: gridDelegate,
                          itemCount: ranked.exact.length,
                          itemBuilder: (context, i) =>
                              card(context, ranked.exact[i]),
                        ),
                      if (ranked.possible.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: NajdSectionHeading('أعمال محتملة'),
                        ),
                        SliverGrid.builder(
                          gridDelegate: gridDelegate,
                          itemCount: ranked.possible.length,
                          itemBuilder: (context, i) =>
                              card(context, ranked.possible[i]),
                        ),
                      ],
                      if (hasMore)
                        SliverToBoxAdapter(
                          child: Center(
                            child: loadingMore
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: loadMore,
                                    child: const Text('عرض المزيد'),
                                  ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );
      return Padding(
        padding: EdgeInsets.all(isTvTarget ? 24 : 12),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: results),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 340,
                    child: NajdSurface(
                      margin: EdgeInsets.zero,
                      child: controls,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  controls,
                  Expanded(child: results),
                ],
              ),
      );
    },
  );
}

enum NajdLibraryMode { favorites, history, downloads }

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.api,
    required this.store,
    this.mode = NajdLibraryMode.favorites,
  });
  final MitvApi api;
  final LocalLibraryStore store;
  final NajdLibraryMode mode;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late NajdLibraryMode mode = widget.mode;
  bool editing = false;
  String filter = 'all';
  String _libraryState = 'favorite';
  String _historyFilter = 'all', _historySort = 'recent';
  final selected = <String>{};
  Future<void> _clearHistory() async {
    if (await najdConfirm(
      context,
      title: 'مسح سجل المشاهدة؟',
      description: 'سيتم إزالة تقدم المشاهدة. لن تتأثر قائمتي أو التحميلات المحفوظة على جهازك.',
      confirm: 'مسح السجل',
    )) {
      await widget.store.clearHistory();
    }
  }

  Future<void> _removeSelected() async {
    final chosen = widget.store.favorites
        .where((e) => selected.contains(e.ref))
        .toList();
    for (final item in chosen) {
      await widget.store.toggleFavorite(item);
    }
    if (mounted) {
      setState(() {
        selected.clear();
        editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final favorites = widget.store
          .sortedFavorites()
          .where(
            (e) =>
                e.matchesLibraryKind(filter) && e.libraryState == _libraryState,
          )
          .toList();
      final history = widget.store.history
          .where(
            (entry) =>
                _historyFilter == 'all' ||
                (_historyFilter == 'completed'
                    ? entry.progress >= .95
                    : entry.progress < .95),
          )
          .toList();
      if (_historySort == 'title') {
        history.sort((a, b) => a.title.compareTo(b.title));
      }
      if (_historySort == 'progress') {
        history.sort((a, b) => b.progress.compareTo(a.progress));
      }
      return ListView(
        key: ValueKey('stitch-library-${mode.name}'),
        padding: EdgeInsets.all(isTvTarget ? 28 : 18),
        children: [
          Row(
            children: [
              Icon(switch (mode) {
                NajdLibraryMode.favorites => Icons.favorite_outline,
                NajdLibraryMode.history => Icons.history,
                NajdLibraryMode.downloads => Icons.download_outlined,
              }, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  switch (mode) {
                    NajdLibraryMode.favorites => 'قائمتي',
                    NajdLibraryMode.history => 'سجل المشاهدة',
                    NajdLibraryMode.downloads => 'التحميلات',
                  },
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (mode == NajdLibraryMode.favorites && favorites.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => editing = !editing),
                  icon: Icon(editing ? Icons.done : Icons.edit_outlined),
                  label: Text(editing ? 'تم' : 'تعديل'),
                ),
              if (mode == NajdLibraryMode.history && history.isNotEmpty)
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text('مسح السجل'),
                ),
            ],
          ),
          if (mode != NajdLibraryMode.downloads)
            Text(
              mode == NajdLibraryMode.history
                  ? 'تابع من حيث توقفت'
                  : 'الأعمال التي حفظتها للمشاهدة',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in NajdLibraryMode.values) ...[
                if (value == NajdLibraryMode.history)
                  ActionChip(
                    avatar: const Icon(Icons.people_outline),
                    label: const Text('القائمة المشتركة'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SharedLibraryPage(
                          onOpen: (entry) => openDetails(
                            context,
                            widget.api,
                            widget.store,
                            entry.catalogItem,
                          ),
                        ),
                      ),
                    ),
                  ),
                ChoiceChip(
                  selected: mode == value,
                  label: Text(switch (value) {
                    NajdLibraryMode.favorites => 'قائمتي',
                    NajdLibraryMode.history => 'سجل المشاهدة',
                    NajdLibraryMode.downloads => 'التحميلات',
                  }),
                  onSelected: (_) => setState(() => mode = value),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (mode == NajdLibraryMode.favorites) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label, icon) in [
                  ('favorite', 'المفضلة', Icons.favorite),
                  ('watched', 'تمت مشاهدته', Icons.check_circle_outline),
                  ('watching', 'أشاهد حاليًا', Icons.play_circle_outline),
                  ('watchlist', 'أرغب بمشاهدته', Icons.bookmark_add_outlined),
                ])
                  ChoiceChip(
                    label: Text(label),
                    avatar: Icon(icon, size: 18),
                    selected: _libraryState == value,
                    onSelected: (_) => setState(() => _libraryState = value),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in [
                  ('all', 'الكل'),
                  ('movie', 'أفلام'),
                  ('series', 'مسلسلات'),
                  ('anime', 'أنمي'),
                  ('turkish', 'تركي'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: filter == value,
                    onSelected: (_) => setState(() => filter = value),
                  ),
              ],
            ),
            Wrap(
              spacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${favorites.length} أعمال محفوظة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                NajdChoiceButton<String>(
                  label: widget.store.librarySort == 'rating'
                      ? 'التقييم'
                      : widget.store.librarySort == 'title'
                      ? 'الاسم'
                      : 'تاريخ الإضافة',
                  icon: Icons.sort,
                  options: [
                    NajdOption(
                      'recent',
                      'تاريخ الإضافة',
                      selected: widget.store.librarySort == 'recent',
                      icon: Icons.schedule,
                    ),
                    NajdOption(
                      'title',
                      'الاسم',
                      selected: widget.store.librarySort == 'title',
                      icon: Icons.sort_by_alpha,
                    ),
                    NajdOption(
                      'rating',
                      'التقييم',
                      selected: widget.store.librarySort == 'rating',
                      icon: Icons.star_outline,
                    ),
                  ],
                  onSelected: widget.store.setLibrarySort,
                ),
              ],
            ),
            if (favorites.isEmpty)
              const NajdEmptyState(kind: NajdEmptyKind.watchlist),
            if (favorites.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 185,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, i) {
                  final item = favorites[i];
                  return NajdWorkCard(
                    item: item,
                    selected: selected.contains(item.ref),
                    onTap: () =>
                        openDetails(context, widget.api, widget.store, item),
                    onSelect: editing
                        ? () => setState(
                            () => selected.contains(item.ref)
                                ? selected.remove(item.ref)
                                : selected.add(item.ref),
                          )
                        : null,
                  );
                },
              ),
            if (editing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton.icon(
                  onPressed: selected.isEmpty ? null : _removeSelected,
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  label: Text('إزالة المحدد (${selected.length})'),
                ),
              ),
          ],
          if (mode == NajdLibraryMode.history) ...[
            if (widget.store.history.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in [
                    ('all', 'الكل'),
                    ('continue', 'قيد المتابعة'),
                    ('completed', 'المكتملة'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: _historyFilter == option.$1,
                      onSelected: (_) =>
                          setState(() => _historyFilter = option.$1),
                    ),
                  NajdChoiceButton<String>(
                    label: _historySort == 'title'
                        ? 'الاسم'
                        : _historySort == 'progress'
                        ? 'تقدم المشاهدة'
                        : 'آخر مشاهدة',
                    icon: Icons.sort,
                    options: [
                      for (final option in [
                        ('recent', 'آخر مشاهدة'),
                        ('title', 'الاسم'),
                        ('progress', 'تقدم المشاهدة'),
                      ])
                        NajdOption(
                          option.$1,
                          option.$2,
                          selected: _historySort == option.$1,
                        ),
                    ],
                    onSelected: (value) async {
                      setState(() => _historySort = value);
                    },
                  ),
                ],
              ),
            if (history.isEmpty && widget.store.history.isNotEmpty)
              NajdEmptyState(
                kind: NajdEmptyKind.search,
                message: 'لا توجد أعمال ضمن هذا الفلتر',
                onRetry: () => setState(() => _historyFilter = 'all'),
              ),
            if (widget.store.history.isEmpty)
              const NajdEmptyState(kind: NajdEmptyKind.history),
            for (final entry in history)
              NajdSurface(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width < 420
                                ? 76
                                : 144,
                            height: 82,
                            child: NajdPoster(url: entry.poster),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (entry.episodeNumber != null)
                                Text(
                                  '${entry.metadata?.season != null ? 'الموسم ${entry.metadata?.season} • ' : ''}الحلقة ${entry.episodeNumber}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                entry.progress >= .95
                                    ? 'مكتمل'
                                    : 'متبقي ${((entry.durationMs - entry.positionMs) / 60000).ceil().clamp(0, 9999)} دقيقة',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: entry.progress >= .95
                              ? 'إعادة المشاهدة'
                              : 'متابعة المشاهدة',
                          onPressed: () => openHistoryEntry(
                            context,
                            widget.api,
                            widget.store,
                            entry,
                          ),
                          icon: Icon(
                            entry.progress >= .95
                                ? Icons.replay
                                : Icons.play_arrow,
                          ),
                        ),
                        IconButton(
                          tooltip: 'إزالة من السجل',
                          onPressed: () =>
                              widget.store.removeHistoryEntry(entry.key),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.progress,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(entry.progress * 100).round()}٪'),
                      ],
                    ),
                  ],
                ),
              ),
          ],
          if (mode == NajdLibraryMode.downloads) ...[
            SeasonQueueSummary(
              key: ValueKey(widget.store.ownerScope),
              store: widget.store,
              api: widget.api,
            ),
            const DownloadLibrarySection(),
          ],
        ],
      );
    },
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _NavigationSurface extends StatelessWidget {
  const _NavigationSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => isTvTarget
      ? NajdGlassContainer(
          child: Material(type: MaterialType.transparency, child: child),
        )
      : child;
}
