import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'cloud_runtime_io.dart';
import 'download_service.dart';
import 'library_store.dart';
import 'library_sync_record.dart';
import 'models.dart';
import 'native_download_engine.dart';

typedef SeasonDownloadWorker = Future<void> Function(
  SeasonDownloadJob job,
  DownloadCancellationToken token,
);

class SeasonDownloadJob {
  const SeasonDownloadJob({
    required this.id,
    required this.ref,
    required this.title,
    required this.item,
    this.state = 'queued',
    this.indexSeason,
    this.indexOffset,
  });
  final String id, ref, title, state;
  final CatalogItem item;
  final int? indexSeason, indexOffset;
  bool get isIndex => indexSeason != null;
  Map<String, dynamic> toJson() => {
    'v': 1,
    'id': id,
    'ref': ref,
    'title': title,
    'state': state,
    'item': item.toJson(),
    if (indexSeason != null) 'index_season': indexSeason,
    if (indexOffset != null) 'index_offset': indexOffset,
  };
  SeasonDownloadJob withState(String value) => SeasonDownloadJob(
    id: id,
    ref: ref,
    title: title,
    item: item,
    state: value,
    indexSeason: indexSeason,
    indexOffset: indexOffset,
  );
  static String key(String owner, String ref, {int? season}) => sha256
      .convert(
        utf8.encode(
          '$owner\u0000$ref${season == null ? '' : '\u0000season:$season'}',
        ),
      )
      .toString()
      .substring(0, 32);
  factory SeasonDownloadJob.read(Map<String, dynamic> data, String owner) {
    if (data['index_season'] != null &&
        (data['index_season'] is! int ||
            data['index_offset'] is! int ||
            data['index_season'] < 0 ||
            data['index_offset'] < 0)) {
      throw const FormatException('INVALID_SEASON_INDEX');
    }
    if (data['v'] != 1 ||
        data['ref'] is! String ||
        data['title'] is! String ||
        data['item'] is! Map ||
        !{
          'queued',
          'active',
          'completed',
          'failed',
          'cancelled',
        }.contains(data['state']) ||
        data['id'] != key(owner, data['ref'], season: data['index_season'])) {
      throw const FormatException('INVALID_SEASON_DOWNLOAD_JOB');
    }
    final record = LibrarySyncRecord(
      kind: 'history',
      itemKey: data['ref'],
      metadata: data,
      updatedAt: DateTime.now(),
    );
    if (!record.fitsCloudBudget) {
      throw const FormatException('UNSAFE_SEASON_DOWNLOAD_JOB');
    }
    return SeasonDownloadJob(
      id: data['id'],
      ref: data['ref'],
      title: data['title'],
      state: data['state'],
      item: CatalogItem.fromJson(Map<String, dynamic>.from(data['item'])),
      indexSeason: data['index_season'],
      indexOffset: data['index_offset'],
    );
  }
}

/// Owner-scoped metadata files survive route/process teardown. Signed media and
/// headers are resolved only when a job is ready to transfer, never persisted here.
class SeasonDownloadQueue extends ChangeNotifier {
  SeasonDownloadQueue({Future<Directory> Function()? directory})
    : _directoryProvider = directory ?? getApplicationSupportDirectory;
  static final instance = SeasonDownloadQueue();
  final Future<Directory> Function() _directoryProvider;
  final _jobs = <String, Map<String, SeasonDownloadJob>>{};
  final _loading = <String, Future<void>>{},
      _running = <String, Future<void>>{},
      _writes = <String, Future<void>>{};
  final _tokens = <String, DownloadCancellationToken>{};
  bool _cancelling = false;
  bool isTransferring(String owner, String id) =>
      _tokens.containsKey('$owner:$id');
  List<SeasonDownloadJob> jobsFor(String owner) =>
      List.unmodifiable(_jobs[owner]?.values ?? const <SeasonDownloadJob>[]);
  Future<Directory> _directory(String owner) async {
    final base = await _directoryProvider();
    await base.create(recursive: true);
    var dir = Directory(await base.resolveSymbolicLinks());
    for (final part in [
      'najd-season-downloads',
      SeasonDownloadJob.key(owner, 'owner'),
    ]) {
      dir = Directory('${dir.path}${Platform.pathSeparator}$part');
      final type = await FileSystemEntity.type(dir.path, followLinks: false);
      if (type != FileSystemEntityType.directory &&
          type != FileSystemEntityType.notFound) {
        throw const FileSystemException('UNSAFE_QUEUE_DIRECTORY');
      }
      await dir.create();
    }
    return dir;
  }

  Future<void> load(String owner) =>
      _loading[owner] ??= _load(owner).catchError((Object error) {
        _loading.remove(owner);
        throw error;
      });
  Future<void> _load(String owner) async {
    final dir = await _directory(owner), rows = <String, SeasonDownloadJob>{};
    await for (final file in dir.list(followLinks: false)) {
      if (file is! File ||
          !RegExp(r'^[a-f0-9]{32}\.json$')
              .hasMatch(file.uri.pathSegments.last)) {
        continue;
      }
      if (await file.length() > 32768) continue;
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map) continue;
        final row = SeasonDownloadJob.read(
          Map<String, dynamic>.from(decoded),
          owner,
        );
        if (file.uri.pathSegments.last != '${row.id}.json') continue;
        rows[row.id] = row;
      } on FormatException {
        continue;
      }
    }
    _jobs[owner] = rows;
    notifyListeners();
  }

  Future<void> _save(String owner, SeasonDownloadJob row) {
    final key = '$owner:${row.id}';
    final previous = _writes[key] ?? Future<void>.value();
    final pending = previous.catchError((Object _) {}).then((_) async {
      final dir = await _directory(owner);
      final target = File('${dir.path}${Platform.pathSeparator}${row.id}.json');
      final temporary = File('${target.path}.tmp');
      for (final file in [target, temporary]) {
        final type = await FileSystemEntity.type(file.path, followLinks: false);
        if (type != FileSystemEntityType.file &&
            type != FileSystemEntityType.notFound) {
          throw const FileSystemException('UNSAFE_QUEUE_FILE');
        }
      }
      await temporary.writeAsString(jsonEncode(row.toJson()), flush: true);
      await temporary.rename(target.path);
      (_jobs[owner] ??= {})[row.id] = row;
      notifyListeners();
    });
    _writes[key] = pending;
    return pending.whenComplete(() {
      if (identical(_writes[key], pending)) _writes.remove(key);
    });
  }

  Future<void> add(
    String owner,
    List<SeasonDownloadJob> rows, {
    bool restartCompleted = false,
  }) async {
    if (_cancelling) throw StateError('DOWNLOAD_CLEANUP_IN_PROGRESS');
    await load(owner);
    for (final row in rows) {
      if (_cancelling) throw StateError('DOWNLOAD_CLEANUP_IN_PROGRESS');
      SeasonDownloadJob.read(row.toJson(), owner);
      final previous = _jobs[owner]?[row.id];
      if (previous != null &&
          ({'queued', 'active'}.contains(previous.state) ||
              previous.state == 'completed' && !restartCompleted)) {
        continue;
      }
      await _save(owner, row.withState('queued'));
    }
  }

  Future<void> cancel(String owner, String id) async {
    await load(owner);
    final row = _jobs[owner]?[id];
    if (row == null || row.state == 'completed') return;
    _jobs[owner]![id] = row.withState('cancelled');
    _tokens['$owner:$id']?.cancel();
    await _save(owner, row.withState('cancelled'));
  }

  Future<void> retry(String owner, String id) async {
    await load(owner);
    final row = _jobs[owner]?[id];
    if (!isTransferring(owner, id) &&
        row != null &&
        {'failed', 'cancelled'}.contains(row.state)) {
      await _save(owner, row.withState('queued'));
    }
  }

  Future<void> advanceIndex(
    String owner,
    SeasonDownloadJob row,
    int offset,
  ) async {
    if (offset <= row.indexOffset!) {
      throw const FormatException('EPISODE_CURSOR_DID_NOT_ADVANCE');
    }
    await _save(
      owner,
      SeasonDownloadJob(
        id: row.id,
        ref: row.ref,
        title: row.title,
        item: row.item,
        indexSeason: row.indexSeason,
        indexOffset: offset,
      ),
    );
  }

  Future<void> cancelWork(String owner, String ref) async {
    await load(owner);
    for (final row in jobsFor(owner).where(
      (row) => row.item.ref == ref && {'active', 'queued'}.contains(row.state),
    )) {
      await cancel(owner, row.id);
    }
  }

  Future<void> cancelLoadedJobs() async {
    _cancelling = true;
    try {
      await Future.wait(
        _loading.values
            .map((future) => future.catchError((Object _) {}))
            .toList(),
      );
      await Future.wait(_writes.values.toList());
      for (final token in _tokens.values) {
        token.cancel();
      }
      for (final owner in _jobs.keys.toList()) {
        for (final row in jobsFor(
          owner,
        ).where((row) => {'active', 'queued'}.contains(row.state))) {
          await cancel(owner, row.id);
        }
      }
      await Future.wait(_running.values.toList());
    } finally {
      _cancelling = false;
    }
  }

  Future<void> run(
    String owner,
    SeasonDownloadWorker worker, {
    bool Function()? isCurrent,
  }) {
    if (_cancelling) return Future<void>.value();
    return _running[owner] ??= _run(owner, worker, isCurrent).whenComplete(() {
      _running.remove(owner);
    });
  }

  Future<void> _run(
    String owner,
    SeasonDownloadWorker worker,
    bool Function()? isCurrent,
  ) async {
    await load(owner);
    while (!_cancelling && (isCurrent?.call() ?? true)) {
      final pending = _jobs[owner]!.values.where(
        (row) => {'queued', 'active'}.contains(row.state),
      );
      final next =
          pending.where((row) => row.isIndex).firstOrNull ??
          pending.firstOrNull;
      if (next == null) return;
      final token = DownloadCancellationToken(), key = '$owner:${next.id}';
      _tokens[key] = token;
      await _save(owner, next.withState('active'));
      try {
        if (token.isCancelled) {
          throw const DownloadException('DOWNLOAD_CANCELLED');
        }
        await worker(next, token);
        final latest = _jobs[owner]?[next.id];
        if (!token.isCancelled && next.isIndex && latest?.state == 'queued') {
          continue;
        }
        await _save(
          owner,
          next.withState(token.isCancelled ? 'cancelled' : 'completed'),
        );
      } catch (_) {
        await _save(
          owner,
          next.withState(token.isCancelled ? 'cancelled' : 'failed'),
        );
      } finally {
        _tokens.remove(key);
        notifyListeners();
      }
    }
  }
}

Future<void> resumeSeasonDownloads(
  LocalLibraryStore store, {
  MitvApi? originApi,
}) async {
  if (kIsWeb || cloudRuntimeIsTest) return;
  final owner = store.ownerScope;
  await SeasonDownloadQueue.instance.run(
    owner,
    seasonDownloadWorker(
      owner,
      apiFactory: (item) =>
          originApi?.detachedSession(origin: item) ??
          MitvApi(
            providerBrowser: item.discoveryScope == 'beta',
            useEdge: item.discoveryScope != 'beta',
          ),
    ),
    isCurrent: () => store.ownerScope == owner,
  );
}

SeasonDownloadWorker seasonDownloadWorker(
  String owner, {
  SeasonDownloadQueue? tasks,
  required MitvApi Function(CatalogItem) apiFactory,
  DownloadService Function()? downloadsFactory,
}) {
  final queue = tasks ?? SeasonDownloadQueue.instance;
  return (job, token) async {
    final api = apiFactory(job.item);
    final downloads = downloadsFactory?.call() ?? DownloadService();
    try {
      if (job.isIndex) {
        var workRef = job.ref;
        TitleDetails? legacy;
        if (!workRef.startsWith('source:')) {
          legacy = await api.details(workRef);
          if (legacy.sourceWorkRef.isNotEmpty) {
            workRef = legacy.sourceWorkRef;
          } else if (workRef.startsWith('tmdb:') || job.indexOffset != 0) {
            throw const DownloadException('SOURCE_INDEX_REQUIRED');
          }
        }
        final details = workRef.startsWith('source:')
            ? await api.moreSourceEpisodes(
                workRef,
                season: job.indexSeason!,
                offset: job.indexOffset!,
              )
            : legacy!;
        if (token.isCancelled) {
          throw const DownloadException('DOWNLOAD_CANCELLED');
        }
        final next = details.episodeNextOffset;
        if (next != null && next <= job.indexOffset!) {
          throw const FormatException('EPISODE_CURSOR_DID_NOT_ADVANCE');
        }
        await queue.add(
          owner,
          seasonJobs(owner, job.item, details.episodes),
          restartCompleted: true,
        );
        if (next != null) {
          await queue.advanceIndex(owner, job, next);
        } else if (details.sourceIndexPartial) {
          final status = await api.harvestStatus(workRef);
          if (!{'running', 'indexing'}.contains(status['index_state']) &&
              (status['progress'] is! Map ||
                  status['progress']['partial'] == true)) {
            throw const DownloadException('SOURCE_INDEX_PARTIAL');
          }
          await Future<void>.delayed(const Duration(seconds: 2));
          if (token.isCancelled) {
            throw const DownloadException('DOWNLOAD_CANCELLED');
          }
          await queue._save(owner, job.withState('queued'));
        }
        return;
      }
      final existing = await downloads.verifiedDownload(
        NativeDownloadEngine.fileName(job.id),
      );
      if (existing != null) return;
      await api.resolvePlayback(job.ref, refresh: true);
      final source = api.downloadableSource(job.ref);
      if (source == null) {
        throw const DownloadException('HLS_DOWNLOAD_UNSUPPORTED');
      }
      await downloads.download(
        api.mediaUri(
          source.mediaPath,
          download: true,
          playbackMode: 'edge_direct',
        ),
        fallbackName: job.title,
        headers: source.headers,
        resumeKey: job.id,
        cancellationToken: token,
      );
    } finally {
      downloads.closeWhenIdle();
      api.close();
    }
  };
}

List<SeasonDownloadJob> seasonJobs(
  String owner,
  CatalogItem item,
  List<EpisodeItem> episodes,
) => [
  for (final episode in episodes)
    if (episode.watchAvailable &&
        episode.ref.isNotEmpty &&
        (episode.season == null ||
            item.season == null ||
            episode.season == item.season))
      SeasonDownloadJob(
        id: SeasonDownloadJob.key(owner, episode.ref),
        ref: episode.ref,
        title: '${item.title} — الحلقة ${episode.number}',
        item: item,
      ),
];
