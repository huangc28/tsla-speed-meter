import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ui/gauge_geometry.dart';

void main() {
  group('GaugeGeometry.fraction', () {
    const g = GaugeGeometry();

    test('0 maps to 0, max maps to 1, midpoint to 0.5', () {
      expect(g.fraction(0), 0);
      expect(g.fraction(240), 1);
      expect(g.fraction(120), closeTo(0.5, 1e-9));
    });

    test('clamps below 0 and above max', () {
      expect(g.fraction(-10), 0);
      expect(g.fraction(300), 1);
    });
  });

  group('GaugeGeometry.tipAngleDeg', () {
    const g = GaugeGeometry();

    test('0 sits at the start, max at the end, midpoint halfway along the sweep',
        () {
      expect(g.tipAngleDeg(0), closeTo(215, 1e-9));
      expect(g.tipAngleDeg(240), closeTo(-35, 1e-9)); // 215 + (-250)
      expect(g.tipAngleDeg(120), closeTo(90, 1e-9)); // 215 + (-125)
    });
  });
}
