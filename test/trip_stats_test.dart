import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/trip/trip_stats.dart';

DateTime _t(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);

void main() {
  group('TripStats', () {
    test('accumulates distance from speed over time and computes avg', () {
      final t = TripStats();
      t.add(10, _t(0)); // start; no elapsed yet
      t.add(10, _t(10)); // 10 m/s for 10 s -> 100 m
      expect(t.distanceM, closeTo(100, 1e-6));
      expect(t.avgMs, closeTo(10, 1e-6));
    });

    test('tracks the maximum speed seen', () {
      final t = TripStats();
      t.add(10, _t(0));
      t.add(30, _t(1));
      t.add(5, _t(2));
      expect(t.maxMs, 30);
    });

    test('reset returns everything to zero', () {
      final t = TripStats();
      t.add(10, _t(0));
      t.add(20, _t(5));
      t.reset();
      expect(t.distanceM, 0);
      expect(t.maxMs, 0);
      expect(t.avgMs, 0);
    });
  });
}
