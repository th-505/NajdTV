import 'package:flutter/material.dart';

import 'models.dart';
import 'stitch_design.dart';

class PersonWorksGrid extends StatefulWidget {
  const PersonWorksGrid({super.key, required this.items, required this.onItem});
  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onItem;
  @override
  State<PersonWorksGrid> createState() => _PersonWorksGridState();
}

class _PersonWorksGridState extends State<PersonWorksGrid> {
  String _sort = 'newest';
  int? _year;
  @override
  Widget build(BuildContext context) {
    final years =
        widget.items.map((e) => e.year).whereType<int>().toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    final rows =
        widget.items.where((e) => _year == null || e.year == _year).toList()
          ..sort((a, b) {
            final order = _sort == 'popular'
                ? b.popularity.compareTo(a.popularity)
                : _sort == 'oldest'
                ? (a.year ?? 9999).compareTo(b.year ?? 9999)
                : (b.year ?? 0).compareTo(a.year ?? 0);
            return order == 0 ? a.title.compareTo(b.title) : order;
          });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final option in const {
                'newest': 'الأحدث',
                'oldest': 'الأقدم',
                'popular': 'الرائج',
              }.entries)
                ChoiceChip(
                  label: Text(option.value),
                  selected: _sort == option.key,
                  onSelected: (_) => setState(() => _sort = option.key),
                ),
              DropdownButton<int>(
                hint: const Text('كل السنوات'),
                value: _year,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('كل السنوات'),
                  ),
                  for (final year in years)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (value) => setState(() => _year = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 340,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: rows.length,
            itemBuilder: (_, i) => NajdWorkCard(
              item: rows[i],
              onTap: () => widget.onItem(rows[i]),
            ),
          ),
        ),
      ],
    );
  }
}
