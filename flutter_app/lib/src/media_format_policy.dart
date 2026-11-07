import 'package:video_player/video_player.dart';

enum RuntimeMediaKind { hls, mp4, mpegTs, unknown }

RuntimeMediaKind classifyRuntimeMediaType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'm3u8' ||
      normalized == 'hls' ||
      normalized.contains('mpegurl')) {
    return RuntimeMediaKind.hls;
  }
  if (normalized == 'mp4' || normalized.contains('video/mp4')) {
    return RuntimeMediaKind.mp4;
  }
  if (normalized == 'mpeg-ts' ||
      normalized == 'mpegts' ||
      normalized == 'ts' ||
      normalized.contains('video/mp2t')) {
    return RuntimeMediaKind.mpegTs;
  }
  return RuntimeMediaKind.unknown;
}

VideoFormat? videoFormatHintForRuntimeMedia(String value) {
  switch (classifyRuntimeMediaType(value)) {
    case RuntimeMediaKind.hls:
      return VideoFormat.hls;
    case RuntimeMediaKind.mp4:
    case RuntimeMediaKind.mpegTs:
    case RuntimeMediaKind.unknown:
      return null;
  }
}

String runtimeMediaLabel(String value) {
  switch (classifyRuntimeMediaType(value)) {
    case RuntimeMediaKind.hls:
      return 'HLS';
    case RuntimeMediaKind.mp4:
      return 'MP4';
    case RuntimeMediaKind.mpegTs:
      return 'MPEG-TS';
    case RuntimeMediaKind.unknown:
      return value.trim().isEmpty ? 'تلقائي' : value.trim();
  }
}

// Container selection is separate from codec support on each device.
bool usesExtendedMediaEngine(String mediaType, String path) {
  final type = mediaType.toLowerCase();
  return [
        'matroska',
        'matroska-webm',
        'mkv',
        'webm',
        'dash',
        'mpd',
        'mpeg-ts',
        'stream',
        'ts',
      ].contains(type) ||
      RegExp(r'\.(mkv|webm|mpd|ts|m2ts)$', caseSensitive: false).hasMatch(path);
}

/// Retain declared/observed formats instead of relabeling every direct URL MP4.
String runtimeMediaTypeFor(String url, [String declared = '']) {
  const aliases = {
    'hls': 'm3u8',
    'application/vnd.apple.mpegurl': 'm3u8',
    'application/x-mpegurl': 'm3u8',
    'dash': 'mpd',
    'application/dash+xml': 'mpd',
    'matroska': 'mkv',
    'video/x-matroska': 'mkv',
    'video/mp4': 'mp4',
    'video/webm': 'webm',
    'video/quicktime': 'mov',
    'video/mp2t': 'ts',
    'video/x-msvideo': 'avi',
    'mpeg-ts': 'ts',
  };
  const formats = [
    'mp4',
    'm3u8',
    'mpd',
    'mkv',
    'webm',
    'mov',
    'm4v',
    'avi',
    'ts',
    'm2ts',
    'mpeg',
    'mpg',
    'ogv',
    'flv',
  ];
  final type = declared.trim().toLowerCase().split(';').first;
  if (aliases.containsKey(type)) return aliases[type]!;
  if (formats.contains(type)) return type;
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  final suffix = path.split('.').last;
  return formats.contains(suffix) ? suffix : 'mp4';
}
