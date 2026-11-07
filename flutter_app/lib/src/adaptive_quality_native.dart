import 'package:media_kit/media_kit.dart' as mk;

/// No proxy or re-encoding: libmpv selects an observed master rendition.
Future<bool> configureNativeHlsQuality(mk.Player player, String mode) async {
  final platform = player.platform;
  if (platform is! mk.NativePlayer) return false;
  try {
    String bitrate;
    if (mode == 'best') {
      bitrate = 'max';
    } else if (mode == 'low') {
      bitrate = 'min';
    } else {
      final bytes =
          double.tryParse(await platform.getProperty('cache-speed')) ?? 0;
      bitrate =
          (bytes.isFinite && bytes > 0
                  ? (bytes * 8 * .65).round().clamp(96000, 100000000)
                  : 2500000)
              .toString();
    }
    await platform.setProperty('hls-bitrate', bitrate);
    return true;
  } catch (_) {
    return false;
  }
}
