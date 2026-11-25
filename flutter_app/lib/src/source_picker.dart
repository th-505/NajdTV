import 'package:flutter/material.dart';

import 'models.dart';
import 'najd_panels.dart';
import 'stitch_design.dart';

class SourcePickerButton extends StatelessWidget {
  const SourcePickerButton({
    super.key,
    required this.sources,
    required this.selected,
    required this.onSelected,
    this.onOpened,
    this.onClosed,
  });
  final List<PlaybackSource> sources;
  final int selected;
  final Future<void> Function(int) onSelected;
  final VoidCallback? onOpened, onClosed;
  Map<String, List<int>> get _servers {
    final groups = <String, List<int>>{};
    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      final key = source.serverLabel.isEmpty ? 'unknown:$i' : source.serverKey;
      (groups[key] ??= []).add(i);
    }
    return groups;
  }

  String _summary(List<int> indices) {
    final rows = indices.map((i) => sources[i]);
    final labels = <String>{
      if (rows.any((source) => source.adaptive)) 'تلقائي حسب الشبكة',
      for (final source in rows)
        for (final quality in source.knownQualities) quality.label,
    };
    final provider = sources[indices.first].provider;
    return [
      if (provider.isNotEmpty) 'المصدر: $provider',
      if (labels.isNotEmpty) labels.join('، ') else 'الجودة غير معلنة',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'سيرفرات التشغيل',
    child: OutlinedButton.icon(
      icon: const Icon(Icons.dns_outlined, size: 20),
      label: const Text('السيرفرات'),
      onPressed: () async {
        onOpened?.call();
        try {
          final index = await showNajdOptions<int>(
            context,
            title: 'سيرفرات التشغيل',
            icon: Icons.dns_outlined,
            options: [
              for (final indices in _servers.values)
                NajdOption(
                  indices.contains(selected) ? selected : indices.first,
                  sources[indices.first].serverLabel.isEmpty
                      ? 'سيرفر ${indices.first + 1}'
                      : sources[indices.first].serverLabel,
                  selected: indices.contains(selected),
                  icon: indices.contains(selected)
                      ? Icons.play_circle_outline
                      : Icons.dns_outlined,
                  subtitle: _summary(indices),
                ),
            ],
            empty: const NajdEmptyState(kind: NajdEmptyKind.source),
          );
          if (index != null && index != selected) await onSelected(index);
        } finally {
          onClosed?.call();
        }
      },
    ),
  );
}
