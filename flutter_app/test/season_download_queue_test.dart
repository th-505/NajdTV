import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/models.dart';
import 'package:mitv/src/season_download_queue.dart';

const item = CatalogItem(
  id: '42',
  title: 'Work',
  poster: '',
  type: 'series',
  ref: 'source:ahwak:aaaaaaaaaaaaaaaaaaaaaaaa',
  season: 1,
);
SeasonDownloadJob episode(String owner, int number) => SeasonDownloadJob(
  id: SeasonDownloadJob.key(owner, 'episode:$number'),
  ref: 'episode:$number',
  title: 'Episode $number',
  item: item,
);
void main() {
  late Directory root;
  SeasonDownloadQueue create() =>
      SeasonDownloadQueue(directory: () async => root);
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('najd-season-queue-'),
  );
  tearDown(() async => root.delete(recursive: true));
  test('owner-scoped jobs persist and completed work is idempotent', () async {
    final queue = create(), first = episode('A', 1);
    await queue.add('A', [first, first]);
    var calls = 0;
    await queue.run('A', (job, token) async {
      calls++;
    });
    await queue.run('A', (job, token) async {
      calls++;
    });
    expect(calls, 1);
    final recovered = create();
    await recovered.load('A');
    await recovered.load('B');
    expect(recovered.jobsFor('A').single.state, 'completed');
    expect(recovered.jobsFor('B'), isEmpty);
    await recovered.add('A', [first], restartCompleted: true);
    await recovered.run('A', (job, token) async {
      calls++;
    });
    expect(calls, 2);
    queue.dispose();
    recovered.dispose();
  });
  test(
    'a process-recovered active record resumes without dropping its reference',
    () async {
      final queue = create(), job = episode('A', 2);
      await queue.add('A', [job]);
      final file =
          await root
                  .list(recursive: true)
                  .where(
                    (entry) =>
                        entry is File && entry.path.endsWith('${job.id}.json'),
                  )
                  .first
              as File;
      await file.writeAsString(jsonEncode(job.withState('active').toJson()));
      final recovered = create();
      var calls = 0;
      await recovered.run('A', (row, token) async {
        expect(row.ref, job.ref);
        calls++;
      });
      expect(calls, 1);
      expect(recovered.jobsFor('A').single.state, 'completed');
      queue.dispose();
      recovered.dispose();
    },
  );
  test('cursor pages are committed before files; duplicate references never duplicate jobs', () async {
    final queue = create();
    final index = SeasonDownloadJob(
      id: SeasonDownloadJob.key('A', 'work', season: 1),
      ref: 'work',
      title: 'Index',
      item: item,
      indexSeason: 1,
      indexOffset: 0,
    );
    await queue.add('A', [index]);
    final calls = <String>[];
    await queue.run('A', (job, token) async {
      calls.add(job.isIndex ? 'index:${job.indexOffset}' : job.ref);
      if (job.isIndex && job.indexOffset == 0) {
        await queue.add('A', [episode('A', 1), episode('A', 1)]);
        await queue.advanceIndex('A', job, 100);
      } else if (job.isIndex) {
        await queue.add('A', [episode('A', 2)]);
      }
    });
    expect(calls, ['index:0', 'index:100', 'episode:1', 'episode:2']);
    expect(queue.jobsFor('A').length, 3);
    expect(queue.jobsFor('A').every((job) => job.state == 'completed'), isTrue);
    await expectLater(queue.advanceIndex('A', index, 0), throwsFormatException);
    queue.dispose();
  });
  test('clearing downloads cancels the active job and leaves no queued surprise transfer', () async {
    final queue = create();
    await queue.add('A', [episode('A', 1), episode('A', 2)]);
    final entered = Completer<void>();
    var calls = 0;
    final running = queue.run('A', (job, token) async {
      calls++;
      entered.complete();
      await token.whenCancelled;
    });
    await entered.future;
    await queue.cancelLoadedJobs();
    await running;
    expect(calls, 1);
    expect(queue.jobsFor('A').every((row) => row.state == 'cancelled'), isTrue);
    final recovered = create();
    await recovered.run('A', (job, token) async {
      fail('cancelled job restarted');
    });
    queue.dispose();
    recovered.dispose();
  });
  test(
    'account switching stops future jobs without cancelling the active file',
    () async {
      final queue = create();
      await queue.add('A', [episode('A', 1), episode('A', 2)]);
      var active = true, calls = 0;
      await queue.run('A', (job, token) async {
        calls++;
        active = false;
        expect(token.isCancelled, isFalse);
      }, isCurrent: () => active);
      expect(calls, 1);
      expect(
        queue.jobsFor('A').where((row) => row.state == 'queued').length,
        1,
      );
      await queue.run('A', (job, token) async {
        calls++;
      });
      expect(calls, 2);
      queue.dispose();
    },
  );
  test(
    'more than one hundred observed jobs are retained and executed',
    () async {
      final queue = create();
      await queue.add('A', [for (var n = 1; n <= 151; n++) episode('A', n)]);
      var calls = 0;
      await queue.run('A', (job, token) async {
        calls++;
      });
      expect(calls, 151);
      expect(queue.jobsFor('A').length, 151);
      queue.dispose();
    },
  );
  test(
    'media credentials and substituted queue directories fail closed',
    () async {
      final queue = create();
      final unsafe = SeasonDownloadJob(
        id: SeasonDownloadJob.key('A', 'episode:1'),
        ref: 'episode:1',
        title: 'Bad',
        item: item.copyWith(
          sourceRefs: {'bad': 'https://cdn.example/video.mp4?token=private'},
        ),
      );
      await expectLater(queue.add('A', [unsafe]), throwsFormatException);
      final other = await Directory.systemTemp.createTemp('najd-queue-other-');
      await Directory('${root.path}/najd-season-downloads')
          .delete(recursive: true);
      await Link('${root.path}/najd-season-downloads').create(other.path);
      final fresh = create();
      await expectLater(fresh.load('B'), throwsA(isA<FileSystemException>()));
      expect(await other.list().isEmpty, isTrue);
      await Link('${root.path}/najd-season-downloads').delete();
      await other.delete();
      queue.dispose();
      fresh.dispose();
    },
  );
}
