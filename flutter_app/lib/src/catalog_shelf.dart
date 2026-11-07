import 'package:flutter/material.dart';

import 'api_client.dart';
import 'models.dart';
import 'stitch_design.dart';
import 'app_target.dart';

class CatalogCollectionShelf extends StatefulWidget {
  const CatalogCollectionShelf({
    super.key,
    required this.api,
    required this.definition,
    required this.onItem,
    required this.onMore,
    required this.signatures,
  });
  final MitvApi api;
  final Map<String, String> definition;
  final ValueChanged<CatalogItem> onItem;
  final VoidCallback onMore;
  final Map<String, String> signatures;
  @override
  State<CatalogCollectionShelf> createState() => _CatalogCollectionShelfState();
}

class _CatalogCollectionShelfState extends State<CatalogCollectionShelf> {
  late Future<List<CatalogItem>> _future = widget.api.category(
    widget.definition['id']!,
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<List<CatalogItem>>(
    future: _future,
    builder: (context, snapshot) {
      final id = widget.definition['id']!,
          items = (snapshot.data ?? []).take(10).toList();
      if (items.isNotEmpty) {
        final signature = (items.map((e) => e.ref).toList()..sort()).join('|');
        if (widget.signatures.entries.any(
          (e) => e.key != id && e.value == signature,
        )) {
          return const SizedBox.shrink();
        }
        widget.signatures[id] = signature;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NajdSectionHeading(
            widget.definition['title']!,
            action: 'المزيد',
            onAction: widget.onMore,
          ),
          if (snapshot.hasError)
            TextButton(
              onPressed: () =>
                  setState(() => _future = widget.api.category(id)),
              child: const Text('تعذر تحميل القائمة؛ أعد المحاولة'),
            ),
          if (!snapshot.hasData && !snapshot.hasError)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (items.isNotEmpty)
            SizedBox(
              height: isTvTarget ? 350 : 285,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: isTvTarget ? 210 : 155,
                  child: NajdWorkCard(
                    item: items[i],
                    rank: id.endsWith('-top') ? i + 1 : null,
                    onTap: () => widget.onItem(items[i]),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      );
    },
  );
}
