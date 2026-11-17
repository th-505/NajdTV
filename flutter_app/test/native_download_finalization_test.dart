import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/download_service.dart';
import 'package:mitv/src/native_download_engine.dart';

void main() {
  late Directory directory;
  setUp(
    () async =>
        directory = await Directory.systemTemp.createTemp('najd-os-download-'),
  );
  tearDown(() async => directory.delete(recursive: true));
  const mp4 = [0, 0, 0, 16, 102, 116, 121, 112, 105, 115, 111, 109, 0, 0, 0, 0];
  test('OS-completed MP4 is verified then atomically exposed', () async {
    final file = File('${directory.path}/najd-123.mp4.part');
    await file.writeAsBytes(mp4);
    final result = await DownloadService.adoptNativeFile(file, directory);
    expect(result.path, '${directory.path}/najd-123.mp4');
    expect(result.bytes, mp4.length);
    expect(await file.exists(), isFalse);
    expect(await File(result.path).readAsBytes(), mp4);
  });
  test(
    'simultaneous reconciliation and live completion share one finalization',
    () async {
      final file = File('${directory.path}/najd-456.mp4.part');
      await file.writeAsBytes(mp4);
      final results = await Future.wait([
        DownloadService.adoptNativeFile(file, directory),
        DownloadService.adoptNativeFile(file, directory),
      ]);
      expect(results[0].path, results[1].path);
      expect(await File(results.first.path).readAsBytes(), mp4);
    },
  );
  test('HTML completion never becomes a completed download', () async {
    final file = File('${directory.path}/najd-123.mp4.part');
    await file.writeAsString('<html>access denied</html>');
    await expectLater(
      DownloadService.adoptNativeFile(file, directory),
      throwsA(isA<DownloadException>()),
    );
    expect(await File('${directory.path}/najd-123.mp4').exists(), isFalse);
  });
  test('OS reconciliation cannot overwrite a prior final file', () async {
    final file = File('${directory.path}/najd-123.mp4.part');
    final existing = File('${directory.path}/najd-123.mp4');
    await file.writeAsBytes(mp4);
    await existing.writeAsString('preserve this file');
    await expectLater(
      DownloadService.adoptNativeFile(file, directory),
      throwsA(isA<DownloadException>()),
    );
    expect(await existing.readAsString(), 'preserve this file');
  });
  test('outside paths and substituted symbolic links fail closed', () async {
    final nested = await Directory('${directory.path}/other').create();
    final file = File('${nested.path}/najd-123.mp4.part');
    await file.writeAsBytes(mp4);
    await expectLater(
      DownloadService.adoptNativeFile(file, directory),
      throwsA(isA<DownloadException>()),
    );
    final link = Link('${directory.path}/najd-123.mp4.part');
    await link.create(file.path);
    await expectLater(
      DownloadService.adoptNativeFile(File(link.path), directory),
      throwsA(isA<DownloadException>()),
    );
    expect(await file.readAsBytes(), mp4);
  });
  test('native boundary rejects unsafe references and injected headers', () {
    for (final url in [
      'http://example.org/a.mp4',
      'https://127.0.0.1/a.mp4',
      'https://example.local/a.mp4',
      'https://example.org/a.m3u8',
      'https://u:p@example.org/a.mp4',
    ]) {
      expect(
        () => NativeDownloadEngine.validate(Uri.parse(url), {}),
        throwsFormatException,
      );
    }
    expect(
      () => NativeDownloadEngine.validate(
        Uri.parse('https://example.org/a.mp4'),
        {'Cookie': 'secret'},
      ),
      throwsFormatException,
    );
    expect(
      () => NativeDownloadEngine.validate(
        Uri.parse('https://example.org/a.mp4'),
        {'Referer': 'https://example.org/\r\nCookie: secret'},
      ),
      throwsFormatException,
    );
    expect(
      () => NativeDownloadEngine.validate(
        Uri.parse('https://example.org/a.mp4'),
        {},
      ),
      returnsNormally,
    );
  });
}
