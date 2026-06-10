import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/tesla_session.dart';

Uint8List _hex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
    ]);

String _hexEnc(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('TeslaSession.deriveSessionKey', () {
    // Official known-answer vector from teslamotors/vehicle-command
    // pkg/protocol/protocol.md: K = SHA1(BIG_ENDIAN(Sx, 32))[:16] over NIST P-256.
    // Cross-validated independently with Python `cryptography`.
    test('matches Tesla protocol.md known-answer vector', () {
      final key = TeslaSession.deriveSessionKey(
        clientPrivateKey: _hex(
            '2538cdc29a97c19c1e99a637d6cf4f8c970c118b56ede1e6323e6d162c4b30db'),
        vehiclePublicKey: _hex(
            '04c7a1f47138486aa4729971494878d33b1a24e39571f748a6e16c5955b3d877'
            'd3a6aaa0e955166474af5d32c410f439a2234137ad1bb085fd4e8813c958f11d97'),
      );

      expect(key, hasLength(16));
      expect(_hexEnc(key), '1b2fce19967b79db696f909cff89ea9a');
    });
  });
}
