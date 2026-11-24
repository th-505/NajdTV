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
  Iterable<int> get _visibleSources sync* {
    final count = sources.length < 4 ? sources.length : 4;
    for (var i = 0; i < count; i++) {
      yield i == 3 && selected >= count && selected < sources.length
          ? selected
          : i;
    }
  }

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
            description: 'اختر المصدر المناسب. تظهر هنا المصادر المستخرجة فعلياً لهذا العمل.',
            icon: Icons.dns_outlined,
            options: [
              for (final i in _visibleSources)
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
