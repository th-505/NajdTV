import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as background;

import 'alooy_policy.dart';
import 'cloud_runtime_io.dart';

/// OS-owned transfers on Android/iOS. Desktop retains the existing Dart transfer.
/// The OS may cancel work after an explicit force-stop; this is not bypassed.
class NativeDownloadEngine {
  static bool get supported =>
      !kIsWeb && !cloudRuntimeIsTest && (Platform.isAndroid || Platform.isIOS);
  static const group = 'najd_downloads_v1';
  static String fileName(String resumeKey) =>
      'najd-${sha256.convert(utf8.encode(resumeKey)).toString().substring(0, 32)}.mp4';
  static Future<void>? _starting;
  static Future<void> start() =>
      _starting ??= _start().catchError((Object error) {
        _starting = null;
        throw error;
      });
  static Future<void> _start() async {
    final downloader = background.FileDownloader();
    await downloader.configure(
      globalConfig: [
        (background.Config.holdingQueue, (3, 2, 3)),
        (background.Config.checkAvailableSpace, 100),
      ],
      androidConfig: [
        (background.Config.runInForeground, true),
        (background.Config.useCacheDir, background.Config.never),
      ],
      iOSConfig: (background.Config.excludeFromCloudBackup, true),
    );
    await downloader.start(
      markDownloadedComplete: false,
      autoCleanDatabase: true,
    );
    downloader.configureNotification(
      running: const background.TaskNotification('تنزيل نجد', '{displayName}'),
      error: const background.TaskNotification('تعذر التنزيل', '{displayName}'),
      progressBar: true,
    );
  }

  static void validate(Uri uri, Map<String, String> headers) {
    if (!isPublicMediaUri(uri) || !uri.path.toLowerCase().endsWith('.mp4')) {
      throw const FormatException('INVALID_DOWNLOAD_REFERENCE');
    }
    if (headers.keys.any(
          (key) => !['Referer', 'Origin', 'User-Agent'].contains(key),
        ) ||
        headers.values.any((value) => value.contains(RegExp(r'[\r\n]')))) {
      throw const FormatException('INVALID_DOWNLOAD_HEADERS');
    }
  }

  static Future<File> download(
    Uri uri, {
    required Map<String, String> headers,
    required String title,
    required String resumeKey,
    required Future<void> cancelled,
    required void Function(int received, int? total) onProgress,
  }) async {
    validate(uri, headers);
    var wasCancelled = false;
    unawaited(cancelled.then((_) => wasCancelled = true));
    await start();
    final downloader = background.FileDownloader();
    final permission = background.PermissionType.notifications;
    if (await downloader.permissions.status(permission) !=
        background.PermissionStatus.granted) {
      await downloader.permissions.request(permission);
    }
    if (wasCancelled) throw const FileSystemException('DOWNLOAD_CANCELLED');
    final name = fileName(resumeKey);
    var task = background.DownloadTask(
      taskId: name.substring(0, name.length - 4),
      filename: '$name.part',
      url: uri.toString(),
      headers: headers,
      directory: 'MITV/Downloads',
      baseDirectory: background.BaseDirectory.applicationDocuments,
      group: group,
      updates: background.Updates.statusAndProgress,
      displayName: title.substring(0, title.length > 120 ? 120 : title.length),
      retries: 3,
      allowPause: true,
      transferHints: {
        background.TransferHint.userInitiated,
        background.TransferHint.largeFile,
      },
    );
    final freshTask = task;
    final previous = await downloader.database.recordForId(task.taskId);
    var continuing =
        previous != null &&
        ![
          background.TaskStatus.failed,
          background.TaskStatus.canceled,
          background.TaskStatus.notFound,
        ].contains(previous.status);
    if (continuing) {
      if (previous.task is! background.DownloadTask ||
          previous.task.group != group ||
          previous.task.directory != 'MITV/Downloads' ||
          previous.task.baseDirectory !=
              background.BaseDirectory.applicationDocuments) {
        throw const FileSystemException('INVALID_NATIVE_TASK_RECORD');
      }
      task = previous.task as background.DownloadTask;
    }
    final pendingPath = await task.filePath();
    final finalFile = File(pendingPath.substring(0, pendingPath.length - 5));
    if (await finalFile.exists()) return finalFile;
    if (continuing && previous.status == background.TaskStatus.complete) {
      if (await File(pendingPath).exists()) return File(pendingPath);
      continuing = false;
      task = freshTask;
    }
    var finished = false;
    final terminal = Completer<background.TaskStatusUpdate>();
    unawaited(
      cancelled.then((_) async {
        if (finished) return;
        var cancelled = false;
        try {
          cancelled = await downloader.cancelTaskWithId(task.taskId);
        } catch (_) {}
        if (!terminal.isCompleted) {
          terminal.complete(
            background.TaskStatusUpdate(
              task,
              cancelled
                  ? background.TaskStatus.canceled
                  : background.TaskStatus.failed,
            ),
          );
        }
      }),
    );
    final subscription = downloader.updates.listen((event) {
      if (event.task.taskId != task.taskId) return;
      if (event is background.TaskStatusUpdate &&
          [
            background.TaskStatus.complete,
            background.TaskStatus.failed,
            background.TaskStatus.canceled,
            background.TaskStatus.notFound,
          ].contains(event.status) &&
          !terminal.isCompleted) {
        terminal.complete(event);
      }
      if (event is background.TaskProgressUpdate &&
          event.task.taskId == task.taskId) {
        final total = event.expectedFileSize > 0
            ? event.expectedFileSize
            : null;
        onProgress(
          total == null ? 0 : (event.progress.clamp(0, 1) * total).round(),
          total,
        );
      }
    });
    try {
      if (!continuing && !await downloader.enqueue(task)) {
        throw const FileSystemException('NATIVE_DOWNLOAD_NOT_ENQUEUED');
      }
      if (wasCancelled) await downloader.cancelTaskWithId(task.taskId);
      // A recovered transfer may have finished between reading its record and subscribing.
      if (continuing) {
        final current = await downloader.database.recordForId(task.taskId);
        if (current != null &&
            current.status.isFinalState &&
            !terminal.isCompleted) {
          terminal.complete(background.TaskStatusUpdate(task, current.status));
        }
      }
      final result = await terminal.future;
      if (result.status != background.TaskStatus.complete) {
        throw const FileSystemException('NATIVE_DOWNLOAD_INCOMPLETE');
      }
      return File(await task.filePath());
    } finally {
      finished = true;
      await subscription.cancel();
    }
  }

  /// Completion records survive Dart teardown. Only this app's own group is read.
  static Future<List<File>> completedFiles() async {
    await start();
    final records = await background.FileDownloader().database
        .allRecordsWithStatus(background.TaskStatus.complete, group: group);
    final files = <File>[];
    for (final record in records) {
      final task = record.task;
      if (task.directory != 'MITV/Downloads' ||
          task.baseDirectory != background.BaseDirectory.applicationDocuments ||
          !RegExp(r'^najd-[a-zA-Z0-9-]+\.mp4\.part$').hasMatch(task.filename)) {
        continue;
      }
      files.add(File(await task.filePath()));
    }
    return files;
  }

  static Future<void> forgetFinal(String resumeKey) async {
    final downloader = background.FileDownloader();
    final name = fileName(resumeKey);
    final id = name.substring(0, name.length - 4);
    final record = await downloader.database.recordForId(id);
    if (record?.status.isFinalState == true) {
      await downloader.database.deleteRecordWithId(id);
    }
  }

  static Future<void> cancelAll() async {
    if (!supported) return;
    await start();
    final downloader = background.FileDownloader();
    final records = await downloader.database.allRecords(group: group);
    final active = records
        .where(
          (record) => ![
            background.TaskStatus.complete,
            background.TaskStatus.failed,
            background.TaskStatus.canceled,
            background.TaskStatus.notFound,
          ].contains(record.status),
        )
        .map((record) => record.taskId)
        .toList();
    if (active.isEmpty) return;
    if (!await downloader.cancelTasksWithIds(active)) {
      throw const FileSystemException('NATIVE_DOWNLOAD_CANCEL_FAILED');
    }
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (true) {
      final remaining = await downloader.database.recordsForIds(active);
      if (remaining.every((record) => record.status.isFinalState)) return;
      if (DateTime.now().isAfter(deadline)) {
        throw const FileSystemException('NATIVE_DOWNLOAD_CANCEL_UNCONFIRMED');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
