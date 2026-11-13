import 'dart:async';
import 'dart:io';

import 'package:volume_controller/volume_controller.dart';
import 'package:flutter/services.dart';

/// One normalized 0–1 bridge for Android, iOS and desktop system volume.
class NajdSystemVolume {
  final _controller = VolumeController.instance;
  static const _events = EventChannel(
    'com.kurenai7968.volume_controller.volume_listener_event',
  );
  StreamSubscription<double>? _subscription;

  Future<double?> read() async {
    _controller.showSystemUI = false;
    return (await _controller.getVolume()).clamp(0.0, 1.0);
  }

  Future<void> write(double value) =>
      _controller.setVolume(value.clamp(0.0, 1.0));

  StreamSubscription<double>? listen(void Function(double value) onChanged) {
    if (Platform.environment['FLUTTER_TEST'] == 'true') return null;
    _subscription?.cancel();
    _subscription = _events
        .receiveBroadcastStream({'fetchInitialVolume': true})
        .map((value) => (value as num).toDouble())
        .listen(
          (value) => onChanged(value.clamp(0.0, 1.0)),
          // Widget tests and unsupported desktop runners have no native
          // registrar. Reading/writing remains best-effort in that case.
          onError: (_) {},
        );
    return _subscription;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
