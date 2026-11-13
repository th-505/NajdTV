import 'dart:async';

/// Web browsers expose per-media volume, not the operating-system mixer.
class NajdSystemVolume {
  Future<double?> read() async => null;
  Future<void> write(double value) async {}
  StreamSubscription<double>? listen(void Function(double value) onChanged) =>
      null;
  Future<void> dispose() async {}
}
