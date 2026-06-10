import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/ble_constants.dart';

void main() {
  group('TeslaBle.localNameForVin', () {
    // S + hex(SHA1(vin)[:8]) + C, per vehicle-command VehicleLocalName.
    // Expected value cross-computed with Python hashlib.
    test('derives the advertised BLE name from the VIN', () {
      expect(TeslaBle.localNameForVin('5YJ30123456789ABC'), 'Sade9a822faa374f8C');
    });

    test('is 18 chars: S + 16 hex + C', () {
      final name = TeslaBle.localNameForVin('5YJSA1E14HF000000');
      expect(name, hasLength(18));
      expect(name, startsWith('S'));
      expect(name, endsWith('C'));
      expect(name.substring(1, 17), matches(RegExp(r'^[0-9a-f]{16}$')));
    });
  });
}
