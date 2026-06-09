import 'dart:math' as math;

import '../data/reading.dart';

/// Turns raw [Reading]s into a stable display speed in m/s.
///
/// Pure and stateful (smoothing and the coordinate-delta fallback need the
/// previous sample). Unit conversion lives in [SpeedUnit]; this class is the
/// canonical m/s producer.
class SpeedProcessor {
  SpeedProcessor({
    this.smoothing = 0.3,
    this.stationaryMs = 0.5,
    this.accuracyThresholdM = 50,
  });

  /// Exponential smoothing factor in (0, 1]. Higher = more responsive, less smooth.
  final double smoothing;

  /// Speeds at or below this (m/s) read as a clean 0, so parked GPS jitter
  /// does not flicker the numeral.
  final double stationaryMs;

  /// Readings whose horizontal accuracy is worse than this (m) are discarded;
  /// the last good value is held rather than yanked by a bad fix.
  final double accuracyThresholdM;

  double? _smoothed;
  Reading? _prevPositioned;

  /// Whether at least one acceptable reading has been processed. Until then the
  /// UI has no fix to show.
  bool get hasValue => _smoothed != null;

  /// Smoothed speed in m/s for [r].
  double process(Reading r) {
    // Discard a poor fix: hold the last good value rather than let it jump.
    if (r.accuracyM != null && r.accuracyM! > accuracyThresholdM) {
      return _smoothed ?? 0;
    }
    final target = r.speedMs ?? _derivedSpeed(r);
    if (r.latitude != null && r.longitude != null) _prevPositioned = r;
    if (_smoothed == null) {
      _smoothed = target; // first sample: no lag
    } else {
      _smoothed = _smoothed! + smoothing * (target - _smoothed!);
    }
    if (_smoothed! <= stationaryMs) _smoothed = 0;
    return _smoothed!;
  }

  /// Speed derived from the move between the previous positioned reading and
  /// [r], when the source did not report speed directly. 0 if not derivable.
  double _derivedSpeed(Reading r) {
    final prev = _prevPositioned;
    if (prev == null ||
        r.latitude == null ||
        r.longitude == null ||
        prev.latitude == null ||
        prev.longitude == null) {
      return 0;
    }
    final dtSeconds =
        r.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
    if (dtSeconds <= 0) return 0;
    final meters = _haversineMeters(
      prev.latitude!,
      prev.longitude!,
      r.latitude!,
      r.longitude!,
    );
    return meters / dtSeconds;
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}
