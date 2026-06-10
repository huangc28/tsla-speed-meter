import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tsla_speed_meter/src/data/gps_source.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';

Position _pos({
  double speed = 0,
  double accuracy = 5,
  double lat = 0,
  double lon = 0,
}) =>
    Position(
      longitude: lon,
      latitude: lat,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 0,
    );

void main() {
  test('maps each position to a Reading and stops delivery once cancelled',
      () async {
    final ctrl = StreamController<Position>();
    final src = GpsSource(positionStream: () => ctrl.stream);
    final got = <Reading>[];
    final sub = src.readings().listen(got.add);

    ctrl.add(_pos(speed: 10, accuracy: 4, lat: 1, lon: 2));
    await Future<void>.delayed(Duration.zero);

    expect(got.length, 1);
    expect(got.first.speedMs, 10);
    expect(got.first.accuracyM, 4);
    expect(got.first.latitude, 1);
    expect(got.first.longitude, 2);

    await sub.cancel();
    ctrl.add(_pos(speed: 20));
    await Future<void>.delayed(Duration.zero);

    expect(got.length, 1, reason: 'no delivery after cancel');
    await ctrl.close();
  });
}
