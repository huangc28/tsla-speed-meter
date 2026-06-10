import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/trip/mode_controller.dart';

void main() {
  group('ModeController', () {
    test('starts parked', () {
      expect(ModeController().mode, HudMode.parked);
    });

    test('switches to drive above the drive threshold', () {
      final m = ModeController(driveAboveMs: 2.0);
      expect(m.update(5), HudMode.drive);
    });

    test('hysteresis: mid-band speed keeps the current mode', () {
      final m = ModeController(parkedBelowMs: 0.5, driveAboveMs: 2.0);
      m.update(5); // -> drive
      expect(m.update(1.0), HudMode.drive, reason: 'mid-band keeps drive');
    });

    test('returns to parked below the parked threshold', () {
      final m = ModeController(parkedBelowMs: 0.5, driveAboveMs: 2.0);
      m.update(5); // drive
      expect(m.update(0.2), HudMode.parked);
    });
  });
}
