/// Accumulates per-trip distance, average and max speed from a stream of
/// speed samples. Works in SI (m, m/s); the UI converts. Resettable.
class TripStats {
  double _distanceM = 0;
  double _maxMs = 0;
  DateTime? _start;
  DateTime? _last;

  double get distanceM => _distanceM;
  double get maxMs => _maxMs;

  /// Average over elapsed trip time (distance / seconds since the first sample).
  double get avgMs {
    final start = _start;
    final last = _last;
    if (start == null || last == null) return 0;
    final seconds = last.difference(start).inMilliseconds / 1000.0;
    return seconds > 0 ? _distanceM / seconds : 0;
  }

  void add(double speedMs, DateTime t) {
    if (speedMs > _maxMs) _maxMs = speedMs;
    if (_last == null) {
      _start = t;
      _last = t;
      return;
    }
    final dt = t.difference(_last!).inMilliseconds / 1000.0;
    if (dt > 0) _distanceM += speedMs * dt;
    _last = t;
  }

  void reset() {
    _distanceM = 0;
    _maxMs = 0;
    _start = null;
    _last = null;
  }
}
