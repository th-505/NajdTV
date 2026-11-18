import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'library_store.dart';
import 'season_download_queue.dart';

class SeasonQueueSummary extends StatefulWidget {
  const SeasonQueueSummary({super.key, required this.store, required this.api});
  final LocalLibraryStore store;
  final MitvApi api;
  @override
  State<SeasonQueueSummary> createState() => _SeasonQueueSummaryState();
}

class _SeasonQueueSummaryState extends State<SeasonQueueSummary> {
  String? error;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      unawaited(
        resumeSeasonDownloads(widget.store, originApi: widget.api).catchError((
          Object _,
        ) {
          if (mounted) setState(() => error = 'تعذر قراءة طابور المواسم.');
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: SeasonDownloadQueue.instance,
      builder: (context, _) {
        final owner = widget.store.ownerScope;
        final rows = SeasonDownloadQueue.instance.jobsFor(owner);
        if (rows.isEmpty && error == null) return const SizedBox.shrink();
        final pending = rows
            .where((row) => {'queued', 'active'}.contains(row.state))
            .length;
        return ListTile(
          leading: const Icon(Icons.playlist_add_check),
          title: const Text('طابور المواسم'),
          subtitle: Text(error ?? '$pending مهمة قيد الانتظار أو التنفيذ'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _SeasonQueuePage(
                owner: owner,
                store: widget.store,
                api: widget.api,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeasonQueuePage extends StatelessWidget {
  const _SeasonQueuePage({
    required this.owner,
    required this.store,
    required this.api,
  });
  final String owner;
  final LocalLibraryStore store;
  final MitvApi api;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('طابور المواسم')),
    body: AnimatedBuilder(
      animation: SeasonDownloadQueue.instance,
      builder: (context, _) {
        if (store.ownerScope != owner) {
          return const Center(
            child: Text('تغيّر الحساب. ارجع إلى تنزيلات الحساب الحالي.'),
          );
        }
        final queue = SeasonDownloadQueue.instance, rows = queue.jobsFor(owner);
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final label = switch (row.state) {
              'queued' => 'في الانتظار',
              'active' => row.isIndex ? 'جارٍ فهرسة المصدر' : 'جارٍ التنزيل',
              'completed' => row.isIndex ? 'اكتمل الفهرس' : 'مكتمل',
              'cancelled' => 'ملغى',
              _ => 'تعذر التنفيذ — يمكنك إعادة المحاولة',
            };
            return ListTile(
              leading: Icon(
                row.isIndex ? Icons.list_alt : Icons.download_outlined,
              ),
              title: Text(
                row.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(label),
              trailing: {'queued', 'active'}.contains(row.state)
                  ? IconButton(
                      tooltip: 'إيقاف مهام هذا الموسم',
                      icon: const Icon(Icons.stop_circle_outlined),
                      onPressed: () async {
                        for (final job
                            in queue
                                .jobsFor(owner)
                                .where(
                                  (job) =>
                                      job.item.ref == row.item.ref &&
                                      job.item.season == row.item.season &&
                                      {'active', 'queued'}.contains(job.state),
                                )) {
                          await queue.cancel(owner, job.id);
                        }
                      },
                    )
                  : {'failed', 'cancelled'}.contains(row.state) &&
                        !queue.isTransferring(owner, row.id)
                  ? IconButton(
                      tooltip: 'إعادة المحاولة',
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        await queue.retry(owner, row.id);
                        unawaited(
                          resumeSeasonDownloads(
                            store,
                            originApi: api,
                          ).catchError((Object _) {}),
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    ),
  );
}
