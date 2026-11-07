/// Two taps arm a seek burst; subsequent same-side taps each add one step.
class SeekBurst {
  DateTime? _last;
  bool? _right;
  int _taps = 0;
  int total = 0;
  int tap({required bool right, required DateTime now, required int seconds}) {
    final elapsed = _last == null
        ? 99999
        : now.difference(_last!).inMilliseconds;
    final continues =
        _right == right && elapsed >= 0 && elapsed <= (_taps >= 2 ? 700 : 350);
    if (!continues) {
      _taps = 0;
      total = 0;
    }
    _right = right;
    _last = now;
    _taps++;
    if (_taps < 2) return 0;
    total += seconds;
    return right ? seconds : -seconds;
  }

  void reset() {
    _last = null;
    _right = null;
    _taps = 0;
    total = 0;
  }
}
