import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/gen/common.pb.dart';
import 'package:tsla_speed_meter/src/ble/gen/vehicle.pb.dart';
import 'package:tsla_speed_meter/src/ble/tesla_reading_mapper.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';

void main() {
  final ts = DateTime.utc(2026, 1, 1);

  group('TeslaReadingMapper.fromVehicleData', () {
    test('maps a moving, charged vehicle into a Reading (mph→m/s)', () {
      final reading = TeslaReadingMapper.fromVehicleData(
        timestamp: ts,
        drive: DriveState()
          ..speedFloat = 60.0 // mph
          ..power = 45
          ..shiftState = (ShiftState()..d = Void()),
        charge: ChargeState()
          ..batteryLevel = 72
          ..batteryRange = 211.5, // miles
      );

      // 60 mph == 26.8224 m/s; the seam is unit-consistent with GPS speed.
      expect(reading.speedMs, closeTo(26.8224, 1e-4));
      expect(reading.gear, Gear.drive);
      expect(reading.powerKw, 45);
      expect(reading.batteryPercent, 72);
      expect(reading.rangeMiles, closeTo(211.5, 1e-6));
      expect(reading.timestamp, ts);
    });

    test('prefers integer speed when speed_float is absent', () {
      final reading = TeslaReadingMapper.fromVehicleData(
        timestamp: ts,
        drive: DriveState()..speed = 30, // mph
      );

      expect(reading.speedMs, closeTo(13.4112, 1e-4)); // 30 mph
    });

    test('maps each gear and treats Invalid/absent as unknown', () {
      Gear gearOf(ShiftState? s) => TeslaReadingMapper.fromVehicleData(
            timestamp: ts,
            drive: s == null ? DriveState() : (DriveState()..shiftState = s),
          ).gear!;

      expect(gearOf(ShiftState()..p = Void()), Gear.park);
      expect(gearOf(ShiftState()..r = Void()), Gear.reverse);
      expect(gearOf(ShiftState()..n = Void()), Gear.neutral);
      expect(gearOf(ShiftState()..d = Void()), Gear.drive);
      expect(gearOf(ShiftState()..invalid = Void()), Gear.unknown);
      expect(gearOf(null), Gear.unknown);
    });

    test('leaves fields null when the vehicle data omits them', () {
      final reading = TeslaReadingMapper.fromVehicleData(
        timestamp: ts,
        drive: DriveState(),
      );

      expect(reading.speedMs, isNull);
      expect(reading.powerKw, isNull);
      expect(reading.batteryPercent, isNull);
      expect(reading.rangeMiles, isNull);
      // No GPS in a BLE reading.
      expect(reading.accuracyM, isNull);
      expect(reading.latitude, isNull);
    });
  });
}
