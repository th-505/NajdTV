import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'focus_highlight.dart';
import 'library_store.dart';
import 'models.dart';
import 'player_page.dart';

/// The eight public feeds use the same API and player as the existing app.
class LiveChannelsPanel extends StatefulWidget {
  const LiveChannelsPanel({super.key, required this.api, required this.store});
  final MitvApi api;
  final LocalLibraryStore store;
  @override
  State<LiveChannelsPanel> createState() => _LiveChannelsPanelState();
}

class _LiveChannelsPanelState extends State<LiveChannelsPanel> {
  static const _groups = {
    'ae': 'الإمارات',
    'sa': 'السعودية',
    'eg': 'مصر',
    'sports': 'الرياضة',
    'movies': 'الأفلام',
    'news': 'الأخبار',
    'kids': 'الأطفال',
    'entertainment': 'الترفيه',
  };
  final _rows = <CatalogItem>[];
  final _scroll = ScrollController();
  String _group = 'sa', _query = '';
  int _page = 0, _generation = 0;
  bool _busy = false, _more = true, _failed = false;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 300 && !_failed) {
      unawaited(_load());
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _generation++;
      _page = 0;
      _rows.clear();
      _more = true;
      _busy = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    if (_busy || !_more) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final data = await widget.api.liveChannels(
        _group,
        page: _page + 1,
        query: _query,
      );
      if (!mounted || generation != _generation) return;
      final values = data['data'];
      if (values is! List) throw const ApiException('LIVE_INVALID_CATALOG');
      final rows = values.whereType<Map>().map(
        (row) => CatalogItem.fromJson(row.cast<String, dynamic>()),
      );
      setState(() {
        final seen = _rows.map((row) => row.ref).toSet();
        _rows.addAll(
          rows.where((row) => row.ref.isNotEmpty && seen.add(row.ref)),
        );
        _page++;
        _more =
            data['pagination'] is Map && data['pagination']['has_more'] == true;
      });
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            DropdownButton<String>(
              value: _group,
              items: _groups.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null || value == _group) return;
                _group = value;
                unawaited(_load(reset: true));
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'ابحث عن قناة',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _query = value.length > 120 ? value.substring(0, 120) : value;
                  _generation++; // Ignore the response for the previous search immediately.
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => unawaited(_load(reset: true)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          itemCount: _rows.length + 1,
          itemBuilder: (context, index) {
            if (index == _rows.length) {
              if (_busy) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (_failed) {
                return TextButton(
                  onPressed: () => unawaited(_load()),
                  child: const Text('تعذّر تحميل القنوات — أعد المحاولة'),
                );
              }
              if (_rows.isEmpty) {
                return const ListTile(title: Text('لا توجد قنوات مطابقة'));
              }
              if (_more) {
                return TextButton(
                  onPressed: () => unawaited(_load()),
                  child: const Text('عرض المزيد'),
                );
              }
              return const SizedBox(height: 16);
            }
            final row = _rows[index];
            return FocusHighlight(
              child: ListTile(
                key: ValueKey(row.ref),
                leading: const Icon(Icons.live_tv),
                title: Text(row.title),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerPage(
                      api: widget.api,
                      store: widget.store,
                      item: row,
                      title: row.title,
                      sourceRef: row.ref,
                      isLive: true,
                    ),
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
