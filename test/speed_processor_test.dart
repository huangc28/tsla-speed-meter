import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/speed/speed_processor.dart';
import 'package:tsla_speed_meter/src/speed/speed_unit.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';

DateTime _t(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

void main() {
  group('SpeedUnit', () {
    test('km/h converts m/s by 3.6', () {
      expect(SpeedUnit.kmh.fromMs(10), closeTo(36, 1e-6));
    });

    test('mph converts m/s by ~2.23694', () {
      expect(SpeedUnit.mph.fromMs(10), closeTo(22.3694, 1e-3));
    });
  });

  group('SpeedProcessor', () {
    test('first reading initialises to its own speed (no smoothing lag on the first sample)', () {
      final p = SpeedProcessor();
      expect(p.process(Reading(speedMs: 10, timestamp: _t(0))), closeTo(10, 1e-6));
    });

    test('subsequent readings are smoothed toward the target (lags, does not jump)', () {
      final p = SpeedProcessor();
      p.process(Reading(speedMs: 10, timestamp: _t(0)));
      final v = p.process(Reading(speedMs: 20, timestamp: _t(1000)));
      expect(v, greaterThan(10));
      expect(v, lessThan(20));
    });

    test('repeated readings converge to the target without overshoot', () {
      final p = SpeedProcessor();
      p.process(Reading(speedMs: 0, timestamp: _t(0)));
      double v = 0;
      for (var i = 1; i <= 60; i++) {
        v = p.process(Reading(speedMs: 30, timestamp: _t(i * 1000)));
        expect(v, lessThanOrEqualTo(30 + 1e-9), reason: 'must never overshoot');
      }
      expect(v, closeTo(30, 0.5), reason: 'must converge');
    });

    test('near-zero speed resolves to a steady 0 (stationary)', () {
      final p = SpeedProcessor(stationaryMs: 0.5);
      p.process(Reading(speedMs: 0.3, timestamp: _t(0)));
      final v = p.process(Reading(speedMs: 0.2, timestamp: _t(1000)));
      expect(v, 0, reason: 'jittery sub-threshold speed must read a clean 0');
    });

    test('null device speed falls back to distance/time from coordinates', () {
      final p = SpeedProcessor(smoothing: 1.0); // isolate the raw fallback value
      // First sample only establishes position (no prior → no derivable speed).
      p.process(Reading(latitude: 0, longitude: 0, timestamp: _t(0)));
      // ~0.001° latitude ≈ 111.2 m; over 10 s ≈ 11.1 m/s.
      final v = p.process(Reading(latitude: 0.001, longitude: 0, timestamp: _t(10000)));
      expect(v, closeTo(11.1, 0.6));
    });

    test('low-accuracy readings are ignored (value is held, not yanked)', () {
      final p = SpeedProcessor(accuracyThresholdM: 20);
      p.process(Reading(speedMs: 25, accuracyM: 5, timestamp: _t(0)));
      final v = p.process(Reading(speedMs: 0, accuracyM: 100, timestamp: _t(1000)));
      expect(v, closeTo(25, 1e-6), reason: 'a garbage fix must not move the reading');
    });
  });
}
