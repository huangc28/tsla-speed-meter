import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/data/data_source.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';
import 'package:tsla_speed_meter/src/trip/mode_controller.dart';
import 'package:tsla_speed_meter/src/ui/hud_controller.dart';

class _FakeSource implements DataSource {
  _FakeSource(this._s);
  final Stream<Reading> _s;
  @override
  Stream<Reading> readings() => _s;
}

DateTime _t(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);
Reading _r(double speedMs, int s) =>
    Reading(speedMs: speedMs, accuracyM: 5, timestamp: _t(s));

void main() {
  test('processes readings into speed, fix, mode and notifies', () async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    final c = HudController(_FakeSource(ctrl.stream))..start();
    var notified = 0;
    c.addListener(() => notified++);

    ctrl.add(_r(30, 0)); // driving
    await Future<void>.delayed(Duration.zero);

    expect(c.hasFix, isTrue);
    expect(c.speedMs, closeTo(30, 1e-6));
    expect(c.mode, HudMode.drive);
    expect(c.tripMaxMs, 30);
    expect(notified, greaterThan(0));
  });

  test('low speed resolves to parked', () async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    final c = HudController(_FakeSource(ctrl.stream))..start();

    ctrl.add(_r(0, 0));
    await Future<void>.delayed(Duration.zero);

    expect(c.mode, HudMode.parked);
  });

  test('dispose cancels the subscription (no further updates)', () async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    final c = HudController(_FakeSource(ctrl.stream))..start();

    ctrl.add(_r(30, 0));
    await Future<void>.delayed(Duration.zero);
    final speedAfterFirst = c.speedMs;
    c.dispose();

    ctrl.add(_r(60, 1));
    await Future<void>.delayed(Duration.zero);
    expect(c.speedMs, speedAfterFirst, reason: 'no updates after dispose');
  });
}
