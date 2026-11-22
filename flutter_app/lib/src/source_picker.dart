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
    this.scan = const {},
    this.onOpened,
    this.onClosed,
  });
  final Map<String, dynamic> scan;
  final List<PlaybackSource> sources;
  final int selected;
  final Future<void> Function(int) onSelected;
  final VoidCallback? onOpened, onClosed;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'السيرفر / الجودة',
    child: OutlinedButton.icon(
      icon: const Icon(Icons.dns_outlined, size: 20),
      label: const Text('المصادر'),
      onPressed: () async {
        onOpened?.call();
        try {
          final index = await showNajdOptions<int>(
            context,
            title: 'مصادر التشغيل',
            glass: true,
            description: scan['observed_servers'] is num
                ? 'اكتُشف ${scan['observed_servers']} سيرفرًا؛ اجتاز الفحص ${scan['playable_servers']}. التبديل بين خوادم الحلقة من المصدر نفسه.'
                : 'اختر خادمًا صالحًا لهذه الحلقة من المصدر نفسه.',
            icon: Icons.dns_outlined,
            options: [
              for (var i = 0; i < sources.length; i++)
                NajdOption(
                  i,
                  sources[i].displayLabel,
                  selected: i == selected,
                  icon: i == selected
                      ? Icons.play_circle_outline
                      : Icons.dns_outlined,
                  subtitle: i == selected
                      ? 'قيد التشغيل'
                      : 'التبديل إلى هذا المصدر',
                ),
              if (scan['server_inventory'] is List)
                for (final (index, row)
                    in (scan['server_inventory'] as List)
                        .whereType<Map>()
                        .indexed)
                  if (row['state'] != 'playable')
                    NajdOption(
                      -index - 1,
                      '${row['label'] ?? 'سيرفر'}',
                      enabled: false,
                      icon: Icons.block,
                      subtitle: row['state'] == 'unavailable'
                          ? 'لم يُعثر على فيديو قابل للتشغيل'
                          : 'لم يكتمل فحص هذا السيرفر',
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
