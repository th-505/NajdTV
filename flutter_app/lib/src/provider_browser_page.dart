import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'source_editions_panel.dart' show sourceHarvestMessage;

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'details_page.dart';
import 'player_page.dart';
import 'library_store.dart';
import 'models.dart';
import 'najd_panels.dart';
import 'stitch_design.dart';

/// A selected site's catalogue, isolated from global discovery preferences.
class ProviderBrowserPage extends StatefulWidget {
  const ProviderBrowserPage({
    super.key,
    required this.api,
    required this.store,
    this.liveOnly = false,
  });
  final MitvApi api;
  final LocalLibraryStore store;
  final bool liveOnly;
  @override
  State<ProviderBrowserPage> createState() => _ProviderBrowserPageState();
}

class _ProviderBrowserPageState extends State<ProviderBrowserPage> {
  final _query = TextEditingController();
  late final MitvApi _browserApi;
  List<Map<String, dynamic>> _sources = [];
  List<CatalogItem> _items = [];
  List<Map<String, dynamic>> _external = [];
  String _group = '';
  bool _usedGlobalSearch = false;

  static const _groups = {
    '': 'كل التصنيفات',
    'arabic': 'عربي',
    'foreign': 'أجنبي',
    'turkish': 'تركي',
    'anime': 'أنمي',
    'asian': 'آسيوي',
    'indian': 'هندي',
  };

  bool _matchesGroup(Map source) =>
      _group.isEmpty || (source['groups'] as List?)?.contains(_group) == true;

  Future<void> _openExternal(String value) async {
    final uri = Uri.tryParse(value);
    final opened =
        uri != null &&
        uri.scheme == 'https' &&
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ).catchError((_) => false);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر فتح موقع المزود')));
    }
  }

  Future<void> _browseExternal(Map<String, dynamic> source) async {
    final sections = (source['sections'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    if (sections.isEmpty) {
      await _openExternal(source['url'] as String);
      return;
    }
    final sectionId = await showNajdOptions<String>(
      context,
      title: source['name'] as String,
      icon: Icons.open_in_new,
      options: [
        for (final section in sections)
          NajdOption(section['id'] as String, section['label'] as String),
      ],
    );
    if (!mounted || sectionId == null) return;
    final section = sections.firstWhere((row) => row['id'] == sectionId);
    final url = section['url'] as String;
    if (section['browse'] != true) {
      await _openExternal(url);
      return;
    }
    final items = await _browserApi
        .browserExternalSection(source['id'] as String, sectionId)
        .catchError((_) => <Map<String, dynamic>>[]);
    if (!mounted) return;
    final selected = await showNajdOptions<String>(
      context,
      title: section['label'] as String,
      icon: Icons.open_in_new,
      options: [
        NajdOption(url, 'فتح القسم على موقع المزود', icon: Icons.open_in_new),
        for (final item in items)
          NajdOption(item['url'] as String, item['title'] as String),
      ],
    );
    if (mounted && selected != null) await _openExternal(selected);
  }

  String? _provider, _error;
  String _category = '';
  bool _loading = true, _hasMore = false;
  int _page = 1, _generation = 0;

  @override
  void initState() {
    super.initState();
    _browserApi = widget.api.browserSession();
    _loadSources();
  }

  @override
  void dispose() {
    ++_generation;
    _query.dispose();
    _browserApi.close();
    super.dispose();
  }

  Future<void> _loadSources() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sources = (await _browserApi.browserSources())
          .where(
            (s) => widget.liveOnly
                ? s['content_type'] == 'live'
                : s['content_type'] != 'live',
          )
          .toList();
      final external = widget.liveOnly
          ? <Map<String, dynamic>>[]
          : await _browserApi.browserDirectory().catchError(
              (_) => <Map<String, dynamic>>[],
            );
      final prefs = await SharedPreferences.getInstance();
      Map saved = const {};
      try {
        final value = jsonDecode(
          prefs.getString(
                widget.liveOnly
                    ? 'provider.browser.live-selection.v1'
                    : 'provider.browser.selection.v1',
              ) ??
              '{}',
        );
        if (value is Map) saved = value;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _sources = sources;
        _external = external;
        if (_provider == null) {
          final savedId = saved['provider'];
          if (sources.any((s) => s['id'] == savedId)) {
            _provider = savedId as String;
            _category = '${saved['category'] ?? ''}';
          }
        } else if (!sources.any((s) => s['id'] == _provider)) {
          _provider = null;
        }
        if (!_categories.any((c) => c['id'] == _category)) _category = '';
      });
      if (_provider == null) {
        setState(() {
          _loading = false;
          _error = sources.isEmpty ? 'لا يتوفر فهرس مزود حالياً' : null;
        });
        return;
      }
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر تحميل قائمة المزودين';
        });
      }
    }
  }

  List<Map> get _categories =>
      (_sources.where((s) => s['id'] == _provider).firstOrNull?['categories']
                  as List? ??
              [])
          .whereType<Map>()
          .toList();

  Future<void> _rememberProvider() async {
    final value = jsonEncode({'provider': _provider, 'category': _category});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        widget.liveOnly
            ? 'provider.browser.live-selection.v1'
            : 'provider.browser.selection.v1',
        value,
      );
    } catch (_) {}
  }

  Future<void> _load({bool more = false}) async {
    final provider = _provider;
    final query = _query.text.trim();
    final preferredGroups = _sources
        .where((s) => s['id'] == provider)
        .firstOrNull?['groups'];
    final group = _group.isNotEmpty
        ? _group
        : preferredGroups is List
        ? preferredGroups.whereType<String>().firstOrNull ?? ''
        : '';
    if (provider == null && (query.isEmpty || widget.liveOnly)) return;
    final request = ++_generation;
    final page = more ? _page + 1 : 1;
    setState(() {
      _loading = true;
      _error = null;
      _usedGlobalSearch = false;
      if (!more) _items = [];
    });
    try {
      final grouped = query.isNotEmpty && !widget.liveOnly
          ? group.isNotEmpty
                ? await _browserApi.browserGroupSearch(
                    group,
                    query,
                    provider: provider,
                  )
                : provider == null
                ? (items: await widget.api.search(query), fallback: true)
                : null
          : null;
      final result = grouped != null
          ? (items: grouped.items, hasMore: false)
          : query.isNotEmpty
          ? (items: await _browserApi.explore(query, provider!), hasMore: false)
          : await _browserApi.browserCatalog(provider!, _category, page);
      if (!mounted || request != _generation) return;
      setState(() {
        _usedGlobalSearch = grouped?.fallback == true;
        final previousCount = _items.length;
        final seen = <String>{};
        _items = [
          if (more) ..._items,
          ...result.items,
        ].where((i) => seen.add(i.ref)).toList();
        _page = page;
        _hasMore = result.hasMore && (!more || _items.length > previousCount);
        _loading = false;
      });
    } catch (error) {
      if (mounted && request == _generation) {
        setState(() {
          _loading = false;
          _error = error is ApiException ? sourceHarvestMessage(error.code) : 'تعذر جلب فهرس هذا المزود. يمكنك إعادة المحاولة أو اختيار مزود آخر.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('تصفح المزود — تجريبي'),
      actions: [
        IconButton(
          tooltip: 'تحديث قائمة المزودين',
          onPressed: _loading ? null : _loadSources,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (!widget.liveOnly)
                NajdChoiceButton<String>(
                  label: _groups[_group]!,
                  icon: Icons.category_outlined,
                  options: [
                    for (final entry in _groups.entries)
                      NajdOption(
                        entry.key,
                        entry.value,
                        selected: entry.key == _group,
                      ),
                  ],
                  onSelected: (value) async {
                    if (value == _group) return;
                    setState(() {
                      ++_generation;
                      _group = value;
                      _items = [];
                      _error = null;
                      _hasMore = false;
                      _usedGlobalSearch = false;
                      _loading = false;
                      if (!_sources.any(
                        (s) => s['id'] == _provider && _matchesGroup(s),
                      )) {
                        _provider = null;
                        _category = '';
                      }
                    });
                    _load();
                  },
                ),
              NajdChoiceButton<String>(
                label:
                    _sources
                            .where((s) => s['id'] == _provider)
                            .firstOrNull?['name']
                        as String? ??
                    'اختر المزود',
                icon: Icons.travel_explore,
                options: [
                  for (final source in _sources.where(_matchesGroup))
                    NajdOption(
                      source['id'] as String,
                      source['name'] as String,
                      selected: source['id'] == _provider,
                    ),
                  for (final source in _external.where(_matchesGroup))
                    NajdOption(
                      'external:${source['id']}',
                      '${source['name']} · موقع خارجي',
                      icon: Icons.open_in_new,
                    ),
                ],
                onSelected: (value) async {
                  if (value.startsWith('external:')) {
                    await _browseExternal(
                      _external.firstWhere(
                        (source) => 'external:${source['id']}' == value,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    ++_generation;
                    _items = [];
                    _hasMore = false;
                    _loading = true;
                    _provider = value;
                    _category = '';
                    _query.clear();
                  });
                  await _rememberProvider();
                  await _load();
                },
              ),
              TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'بحث داخل المزود المختار',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) => _load(),
              ),
              if (_usedGlobalSearch) const Text('نتائج البحث الشامل'),
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final category in _categories)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('${category['label']}'),
                            selected: category['id'] == _category,
                            onSelected: (_) {
                              setState(() {
                                ++_generation;
                                _items = [];
                                _hasMore = false;
                                _category = '${category['id']}';
                                _query.clear();
                              });
                              _rememberProvider();
                              _load();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _error != null
              ? NajdEmptyState(
                  kind: NajdEmptyKind.failure,
                  message: _error,
                  onRetry: () {
                    if (_sources.isEmpty) {
                      _loadSources();
                    } else {
                      _load();
                    }
                  },
                )
              : _provider == null && !_loading && _query.text.trim().isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'اختر المزود لتصفح أقسامه وأعماله',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _items.isEmpty && !_loading
              ? NajdEmptyState(
                  kind: NajdEmptyKind.search,
                  onRetry: () {
                    _query.clear();
                    _load();
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 340,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) => NajdWorkCard(
                    item: _items[index],
                    onTap: () {
                      final item = _items[index];
                      if (item.type == 'live') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerPage(
                              api: _browserApi.browserSession(origin: item),
                              store: widget.store,
                              item: item,
                              title: item.title,
                              sourceRef: item.ref,
                              isLive: true,
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsPage(
                            api: item.discoveryScope == 'beta'
                                ? _browserApi
                                : widget.api,
                            store: widget.store,
                            item: item,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (_hasMore && !_loading)
          TextButton.icon(
            onPressed: () => _load(more: true),
            icon: const Icon(Icons.expand_more),
            label: const Text('المزيد من الأعمال'),
          ),
      ],
    ),
  );
}
