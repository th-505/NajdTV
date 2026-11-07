import 'package:mitv/src/media_format_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  test('direct media retains its real container and ignores query-string extensions', () {
    for (final kind in ['mkv', 'webm', 'mpd', 'mov', 'avi', 'ts']) {
      expect(runtimeMediaTypeFor('https://cdn.example/movie.$kind'), kind);
    }
    expect(runtimeMediaTypeFor('https://cdn.example/media', 'dash'), 'mpd');
    expect(
      runtimeMediaTypeFor('https://cdn.example/media?ad=film.mkv', 'video/mp4'),
      'mp4',
    );
  });

  test('classifies HLS aliases and supplies hls format hint', () {
    expect(classifyRuntimeMediaType('m3u8'), RuntimeMediaKind.hls);
    expect(
      classifyRuntimeMediaType('application/vnd.apple.mpegurl'),
      RuntimeMediaKind.hls,
    );
    expect(videoFormatHintForRuntimeMedia('hls'), VideoFormat.hls);
    expect(runtimeMediaLabel('m3u8'), 'HLS');
  });

  test('classifies MP4 without forcing a platform hint', () {
    expect(classifyRuntimeMediaType('mp4'), RuntimeMediaKind.mp4);
    expect(classifyRuntimeMediaType('video/mp4'), RuntimeMediaKind.mp4);
    expect(videoFormatHintForRuntimeMedia('mp4'), isNull);
    expect(runtimeMediaLabel('video/mp4'), 'MP4');
  });

  test(
    'classifies MPEG-TS explicitly while leaving platform detection native',
    () {
      expect(classifyRuntimeMediaType('mpeg-ts'), RuntimeMediaKind.mpegTs);
      expect(classifyRuntimeMediaType('video/mp2t'), RuntimeMediaKind.mpegTs);
      expect(videoFormatHintForRuntimeMedia('mpeg-ts'), isNull);
      expect(runtimeMediaLabel('ts'), 'MPEG-TS');
    },
  );

  test('unknown media types fail open to native platform detection', () {
    expect(classifyRuntimeMediaType('stream'), RuntimeMediaKind.unknown);
    expect(videoFormatHintForRuntimeMedia('stream'), isNull);
    expect(runtimeMediaLabel('stream'), 'stream');
    expect(runtimeMediaLabel(''), 'تلقائي');
  });
}
